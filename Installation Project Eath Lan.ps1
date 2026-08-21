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
if (Test-Path $cliExe) { & "$cliExe" join $NetworkID1 } else { zerotier-cli join $NetworkID1 }

Start-Sleep -Seconds 2

Write-Host "Fuehre Join fuer Netzwerk 2 ($NetworkID2) aus..." -ForegroundColor White
if (Test-Path $cliExe) { & "$cliExe" join $NetworkID2 } else { zerotier-cli join $NetworkID2 }

# ==========================================
# 5. IP-Adressen abwarten & auslesen
# ==========================================
Write-Host "Warte auf Zuweisung der IP-Adressen..." -ForegroundColor White

function Get-ZeroTierNetworkIP {
    param ([string]$NetID)
    
    $maxRetries = 30
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        if (Test-Path $cliExe) {
            $output = & "$cliExe" listnetworks
        } else {
            $output = zerotier-cli listnetworks
        }
        
        $line = $output | Where-Object { $_ -match $NetID }
        if ($line) {
            # Suche nach einer gültigen IPv4-Adresse im Text der Netzwerkausgabe
            if ($line -match '(\b(?:[0-9]{1,3}\.){3}[0-9]{1,3})\/\d+') {
                return $matches[1]
            }
        }
        Start-Sleep -Seconds 2
        $retryCount++
    }
    return $null
}

$ip1 = Get-ZeroTierNetworkIP -NetID $NetworkID1
$ip2 = Get-ZeroTierNetworkIP -NetID $NetworkID2

if (-not $ip1 -or -not $ip2) {
    Write-Error "IP-Adresse(n) konnten nicht rechtzeitig abgerufen werden. Bitte pruefe die Netzwerkkonfiguration."
    exit
}

# ==========================================
# 6. Netzwerkadapter, Metrik & MTU anpassen
# ==========================================
Write-Host "Setze Netzwerk-Optimierungen (Metrik & MTU)..." -ForegroundColor White

# Adapter anhand der zugewiesenen IPs finden
$adapter1 = Get-NetIPAddress -IPAddress $ip1 -ErrorAction SilentlyContinue | Get-NetAdapter
$adapter2 = Get-NetIPAddress -IPAddress $ip2 -ErrorAction SilentlyContinue | Get-NetAdapter

if ($adapter1) {
    Set-NetIPInterface -InterfaceIndex $adapter1.InterfaceIndex -AddressFamily IPv4 -InterfaceMetric 2
    Set-NetIPInterface -InterfaceIndex $adapter1.InterfaceIndex -AddressFamily IPv4 -NlMtuBytes $TargetMTU
}

if ($adapter2) {
    Set-NetIPInterface -InterfaceIndex $adapter2.InterfaceIndex -AddressFamily IPv4 -InterfaceMetric 1
    Set-NetIPInterface -InterfaceIndex $adapter2.InterfaceIndex -AddressFamily IPv4 -NlMtuBytes $TargetMTU
}

# ==========================================
# 7. Textdatei erstellen
# ==========================================
$fileContent = @"
Deine ZeroTier-IP (Netzwerk 1): $ip1
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
Write-Host "IP Netzwerk 1: $ip1" -ForegroundColor White
Write-Host "Project Earth LAN IP: $ip2" -ForegroundColor White

# Aufraeumen
Remove-Item -Path $InstallerPath -Force -ErrorAction SilentlyContinue

Write-Host "Vorgang erfolgreich abgeschlossen!" -ForegroundColor White
