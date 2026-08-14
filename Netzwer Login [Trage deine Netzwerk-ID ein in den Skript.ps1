# Automatische Prüfung und Anforderung von Administratorrechten
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms

# WICHTIG: Hier muss deine echte 16-stellige Netzwerk-ID stehen!
$networkId = "Trage deine Netzwerk-ID ein"
$metricValue = 1
$mtuValue = 1380

try {
    # 1. ZeroTier beitreten
    $result = zerotier-cli join $networkId 2>&1

    if ($LASTEXITCODE -eq 0 -and $result -like "*200 join OK*") {
        
        # 2. Warten, bis das EXAKTE ZeroTier-Interface aktiv ist
        $interface = $null
        $timeout = 15
        while (-not $interface -and $timeout -gt 0) {
            Start-Sleep -Seconds 1
            $interface = Get-NetAdapter | Where-Object { ($_.InterfaceAlias -match $networkId -or $_.InterfaceDescription -match $networkId) -and $_.Status -eq "Up" }
            $timeout--
        }

        if ($interface) {
            # 3. Metrik & MTU setzen
            Set-NetIPInterface -InterfaceIndex $interface.ifIndex -InterfaceMetric $metricValue -ErrorAction Stop
            Set-NetIPInterface -InterfaceIndex $interface.ifIndex -NlMtuBytes $mtuValue -ErrorAction Stop

            # 4. IP-Adresse des Adapters ermitteln und Txt-Datei auf dem Desktop erstellen
            $ipAddress = (Get-NetIPAddress -InterfaceIndex $interface.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress

            if ($ipAddress) {
                $desktopPath = [Environment]::GetFolderPath("Desktop")
                $txtFileName = "ZeroTier_$networkName.txt"
                $txtFilePath = Join-Path $desktopPath $txtFileName

                $fileContent = @"
Netzwerk-Name: $networkName
Netzwerk-ID: $networkId
Adapter-IP: $ipAddress
"@
                Set-Content -Path $txtFilePath -Value $fileContent -Encoding UTF8 -Force
            }

            [System.Windows.Forms.MessageBox]::Show(
                "Verbindung hergestellt!`n`nNetzwerk: $networkName`nIP-Adresse: $ipAddress`nMetrik: $metricValue`nMTU: $mtuValue", 
                "ZeroTier - Erfolg", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        } else {
            [System.Windows.Forms.MessageBox]::Show("Der ZeroTier Adapter für das Netzwerk $networkId konnte nicht gefunden werden.", "Fehler", "OK", "Warning")
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Beitritt zum Netzwerk $networkId.`n`nAntwort: $result", 
            "ZeroTier - Fehler", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Fehler: $_", "Systemfehler", "OK", "Error")
}
