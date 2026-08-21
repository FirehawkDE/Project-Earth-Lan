# ==========================================
# 1. Administrator-Rechte pruefen & anfordern
# ==========================================
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ==========================================
# 2. Einstellungen & Variablen
# ==========================================
$NetworkID1 = "091f0945fc744570"
$NetworkID2 = "091f0945fc5012f1"
$InstallerUrl = "https://download.zerotier.com/dist/ZeroTier%20One.msi"
$InstallerPath = "$env:TEMP\ZeroTierOneInstaller.msi"
$DesktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")
$TxtFile = Join-Path $DesktopPath "Project Earth Lan IP.txt"
$TargetMTU = 1380

# ==========================================
# 3. Download & Installation
# ==========================================
Write-Host "Lade ZeroTier One herunter..." -ForegroundColor White
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath

Write-Host "Installiere ZeroTier One..." -ForegroundColor White
$installProcess = Start-Process msiexec.exe -ArgumentList "/i `"$InstallerPath`" /qn /norestart" -Wait -PassThru

if ($installProcess.ExitCode -ne 0) {
    Write-Error "Installation fehlgeschlagen."
    exit
}

# PATH-Umgebungsvariable im laufenden Skript aktualisieren
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# ==========================================
# 4. Service-Start abwarten & Joins ausfuehren
# ==========================================
Write-Host "Warte auf ZeroTier-Dienst..." -ForegroundColor White
while ((Get-Service -Name "ZeroTierOneService" -ErrorAction SilentlyContinue).Status -ne "Running") {
    Start-Sleep -Seconds 2
}

Start-Sleep -Seconds 3

$cliExe = "$env:ProgramFiles\ZeroTier\One\zerotier-cli.exe"

Write-Host "Fuehre Join fuer Netzwerk 1 ($NetworkID1) aus..." -ForegroundColor White
if (Test-Path $cliExe) {
    cmd.exe /c "`"$cliExe`" join $NetworkID1"
    Start-Sleep -Seconds 2
    Write-Host "Fuehre Join fuer Netzwerk 2 ($NetworkID2) aus..." -ForegroundColor White
    cmd.exe /c "`"$cliExe`" join $NetworkID2"
} else {
    cmd.exe /c "zerotier-cli join $NetworkID1"
    Start-Sleep -Seconds 2
    Write-Host "Fuehre Join fuer Netzwerk 2 ($NetworkID2) aus..." -ForegroundColor White
    cmd.exe /c "zerotier-cli join $NetworkID2"
}

# ==========================================
# 5. IP-Adressen abwarten & extrahieren
# ==========================================
Write-Host "Warte auf Zuweisung der IP-Adressen..." -ForegroundColor White

function Get-ZeroTierIP {
    param ([string]$NetID)
    
    $maxRetries = 30
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        if (Test-Path $cliExe) {
            $listNet = & "$cliExe" listnetworks
        } else {
            $listNet = zerotier-cli listnetworks
        }
        
        $matchingLine = $listNet | Where-Object { $_ -match $NetID }
        if ($matchingLine) {
            # Extrahiere die IP/CIDR aus der CLI-Ausgabe (Spalte 8)
            $assignedIP = ($matchingLine -split "\s+")[8]
            if ($assignedIP -and $assignedIP -ne "-" -and $assignedIP -notlike "169.254.*") {
                # Nur IPv4 ohne Subnetz-Suffix (/24 etc.) Filtern
                $cleanIP = $assignedIP.Split('/')[0]
                if ($cleanIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                    # Netzwerkkarten-Adapter zuordnen
                    $adapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*ZeroTier*" }
                    foreach ($adapter in $adapters) {
                        $ipObj = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
                                 Where-Object { $_.IPAddress -eq $cleanIP }
                        if ($ipObj) {
                            return @{ Adapter = $adapter; IP = $cleanIP }
                        }
                    }
                }
            }
        }
        Start-Sleep -Seconds 2
        $retryCount++
    }
    return $null
}

$resNet1 = Get-ZeroTierIP -NetID $NetworkID1
$resNet2 = Get-ZeroTierIP -NetID $NetworkID2

if (-not $resNet1 -or -not $resNet2) {
    Write-Error "IP-Adresse(n) konnten nicht fuer beide Netzwerke bezogen werden."
    exit
}

$ip2 = $resNet2.IP

# ==========================================
# 6. Metrik & MTU fuer beide Adapter setzen
# ==========================================
Write-Host "Setze Netzwerk-Optimierungen (Metrik & MTU)..." -ForegroundColor White

Set-NetIPInterface -InterfaceIndex $resNet1.Adapter.InterfaceIndex -AddressFamily IPv4 -InterfaceMetric 2
Set-NetIPInterface -InterfaceIndex $resNet1.Adapter.InterfaceIndex -AddressFamily IPv4 -NlMtuBytes $TargetMTU

Set-NetIPInterface -InterfaceIndex $resNet2.Adapter.InterfaceIndex -AddressFamily IPv4 -InterfaceMetric 1
Set-NetIPInterface -InterfaceIndex $resNet2.Adapter.InterfaceIndex -AddressFamily IPv4 -NlMtuBytes $TargetMTU

# ==========================================
# 7. Textdatei mit IPv4 von Netzwerk 2 erstellen
# ==========================================
$fileContent = @"
Project Earth LAN IP: $ip2

==================================================
EINRICHTUNG & ERSTE SCHRITTE
==================================================
1. Oeffne http://10.147.0.34:3000 im Browser.
2. Klicke dort auf "Los Geht's".
3. Vergib Name, E-Mail und Passwort. Danach kannst du sofort ein Netzwerk erstellen.
4. Hinweis: Du kannst deinen Account zusaetzlich mit einer 2-Faktoren-Authentifizierung (2FA) sichern.

==================================================
FLOW RULES
(Unter 'Flow Rules' eintragen fuer absolute Sicherheit, keinen unnoetigen Broadcast-Laerm & maximale Performance fuer Gaming)
==================================================

--------------------------------------------------
# 1. Windows-Freigaben, NetBIOS & RPC
drop
    dport 135
    or dport 137:139
    or dport 445
;

# 2. Fernwartung & Remote Desktop
drop
    dport 3389
    or dport 5900
;

# 3. Discovery & Broadcast-Laerm
drop
    dport 111
    or dport 548
    or dport 631
    or dport 1900
    or dport 3702
    or dport 5353
    or dport 5355
    or dport 6320
    or dport 17500
;

# 4. Alles andere explizit erlauben
accept;
--------------------------------------------------
"@

Set-Content -Path $TxtFile -Value $fileContent -Encoding UTF8 -Force

Write-Host "Informationen gespeichert in '$TxtFile'." -ForegroundColor White
Write-Host "Project Earth LAN IP (Netzwerk 2): $ip2" -ForegroundColor White

# Aufraeumen
Remove-Item -Path $InstallerPath -Force -ErrorAction SilentlyContinue

Write-Host "Vorgang erfolgreich abgeschlossen!" -ForegroundColor White
