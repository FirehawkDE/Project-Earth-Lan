# Automatische Prüfung und Anforderung von Administratorrechten
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms

$networkId = "091f0945fc5012f1"
$desiredProfileName = "Project Earth LAN"
$metricValue = 1
$mtuValue = 1380

try {
    # 1. ZeroTier beitreten
    $result = zerotier-cli join $networkId 2>&1

    if ($LASTEXITCODE -eq 0 -and $result -like "*200 join OK*") {
        
        # 2. Warten, bis ZeroTier-Interface aktiv ist
        $interface = $null
        $timeout = 10
        while (-not $interface -and $timeout -gt 0) {
            Start-Sleep -Seconds 1
            $interface = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*ZeroTier*" -and $_.Status -eq "Up" }
            $timeout--
        }

        if ($interface) {
            # 3. Metrik & MTU setzen
            Set-NetIPInterface -InterfaceIndex $interface.ifIndex -InterfaceMetric $metricValue -ErrorAction Stop
            Set-NetIPInterface -InterfaceIndex $interface.ifIndex -NlMtuBytes $mtuValue -ErrorAction Stop

            # 4. Warten auf Netzwerkprofil von Windows (kann kurz dauern)
            Start-Sleep -Seconds 2
            
            # 5. Gezieltes Umbenennen ausschließlich für diesen Adapter
            $profile = Get-NetConnectionProfile -InterfaceIndex $interface.ifIndex -ErrorAction SilentlyContinue
            if ($profile) {
                # Name im Netzwerkprofil aktualisieren
                Set-NetConnectionProfile -InterfaceIndex $interface.ifIndex -Name $desiredProfileName -ErrorAction SilentlyContinue
                
                # Exakte Registry-GUID dieses einen Netzwerks anpassen
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\$($profile.InstanceId)"
                if (Test-Path $regPath) {
                    Set-ItemProperty -Path $regPath -Name "ProfileName" -Value $desiredProfileName -Force -ErrorAction SilentlyContinue
                }
            }

            [System.Windows.Forms.MessageBox]::Show(
                "Verbindung hergestellt!`n`nAnzeigename im Freigabecenter: $desiredProfileName`nMetrik: $metricValue`nMTU: $mtuValue", 
                "ZeroTier - Erfolg", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        } else {
            [System.Windows.Forms.MessageBox]::Show("ZeroTier Adapter konnte nicht gefunden werden.", "Fehler", "OK", "Warning")
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
