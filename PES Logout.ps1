Add-Type -AssemblyName System.Windows.Forms
$networkId = "Deine Netzwerk-ID"
zerotier-cli leave $networkId
[System.Windows.Forms.MessageBox]::Show("Verbindung zu Netzwerk $networkId getrennt.", "ZeroTier", "OK", "Information")
