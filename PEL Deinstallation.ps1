# Als Administrator ausführen prüfen
If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Bitte führen Sie dieses Skript als Administrator aus!"
    Exit
}

# Aktuellen Benutzernamen für Rechte-Übernahme ermitteln
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Write-Host "1. Stoppe alle ZeroTier-Dienste und Prozesse..." -ForegroundColor Cyan
& sc.exe stop "ZeroTierOneService" 2>&1 | Out-Null
Get-Service -Name "*ZeroTier*" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
Stop-Process -Name "*zerotier*", "ZeroTier One UI" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 4

Write-Host "2. Deinstalliere ZeroTier One über MSI / Registry..." -ForegroundColor Cyan
$uninstalled = $false
$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach($key in $uninstallKeys) {
    Get-ItemProperty $key -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*ZeroTier*" } | ForEach-Object {
        if ($_.UninstallString) {
            $uninst = $_.UninstallString
            if ($uninst -match "msiexec") {
                $code = [regex]::Match($uninst, "\{[A-F0-9\-]+\}").Value
                Write-Host "Führe MSI-Deinstallation für Produkt-Code $code aus..." -ForegroundColor Yellow
                Start-Process msiexec.exe -ArgumentList "/x $code /qn /norestart" -Wait -ErrorAction SilentlyContinue
                $uninstalled = $true
            } else {
                Write-Host "Führe klassischen Uninstaller aus..." -ForegroundColor Yellow
                Start-Process cmd.exe -ArgumentList "/c $uninst /S" -Wait -ErrorAction SilentlyContinue
                $uninstalled = $true
            }
        }
    }
}

# Fallback: Direktes Entfernen über CIM, falls Registry-Key abweicht
if (-not $uninstalled) {
    $wmiApp = Get-CimInstance Win32_Product | Where-Object { $_.Name -like "*ZeroTier*" }
    if ($wmiApp) {
        $wmiApp | Remove-CimInstance -ErrorAction SilentlyContinue
    }
}

Write-Host "3. Entferne alle ZeroTier Netzwerkadapter..." -ForegroundColor Cyan
Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*ZeroTier*" -or $_.Name -like "*ZeroTier*" } | ForEach-Object {
    $interfaceGuid = $_.InterfaceGuid
    Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.GUID -eq $interfaceGuid } | Remove-CimInstance -ErrorAction SilentlyContinue
}

Write-Host "4. Starte radikale systemweite Suche (inkl. versteckter & System-Ordner)..." -ForegroundColor Cyan
# IMPORTANT: -Force erzwingt das Finden von versteckten (Hidden) und System-Verzeichnissen
$matchedFolders = Get-ChildItem -Path "C:\" -Recurse -Directory -Filter "*ZeroTier*" -Force -ErrorAction SilentlyContinue

if ($matchedFolders) {
    foreach ($dir in $matchedFolders) {
        $targetPath = $dir.FullName
        Write-Host "Gefunden & Bereinige: $targetPath" -ForegroundColor Yellow

        try {
            # 1. Entfernt Hidden-, ReadOnly- und System-Attribute von allen enthaltenen Dateien/Ordnern
            Get-ChildItem -Path $targetPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                $_.Attributes = 'Normal'
            }
            (Get-Item $targetPath -Force -ErrorAction SilentlyContinue).Attributes = 'Normal'

            # 2. Besitz explizit auf den AKTUELLEN BENUTZER und die Administratoren übertragen
            takeown.exe /f "$targetPath" /r /d y 2>&1 | Out-Null
            icacls.exe "$targetPath" /grant "${currentUser}:(F)" /t /c /q 2>&1 | Out-Null
            icacls.exe "$targetPath" /grant "Administratoren:(F)" /t /c /q 2>&1 | Out-Null

            # 3. Löschversuch via PowerShell
            Remove-Item -Path $targetPath -Recurse -Force -ErrorAction Stop
            Write-Host "Erfolgreich gelöscht: $targetPath" -ForegroundColor Green
        } 
        catch {
            # 4. Fallback über Robocopy (löscht selbst hartnäckigste Sperren durch Leerspiegelung)
            try {
                $emptyDir = New-Item -ItemType Directory -Path "$env:TEMP\EmptyDir_$(Get-Random)" -Force -ErrorAction SilentlyContinue
                robocopy.exe $emptyDir.FullName $targetPath /MIR /NJH /NJS /NC /NS /NP 2>&1 | Out-Null
                Remove-Item -Path $emptyDir.FullName -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $targetPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Erfolgreich gelöscht via Robocopy-Fallback: $targetPath" -ForegroundColor Green
            } catch {
                Write-Warning "Konnte Ordner nicht vollständig entfernen: $targetPath"
            }
        }
    }
} else {
    Write-Host "Keine verbleibenden ZeroTier-Ordner auf dem System gefunden." -ForegroundColor Green
}

Write-Host "5. Bereinige Registry-Einträge..." -ForegroundColor Cyan
$regPaths = @(
    "HKLM:\SOFTWARE\ZeroTier",
    "HKLM:\SYSTEM\CurrentControlSet\Services\ZeroTierOneService",
    "HKCU:\SOFTWARE\ZeroTier",
    "HKLM:\SOFTWARE\WOW6432Node\ZeroTier"
)

foreach ($path in $regPaths) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "ZeroTier One wurde restlos deinstalliert und das System komplett bereinigt!" -ForegroundColor Green
