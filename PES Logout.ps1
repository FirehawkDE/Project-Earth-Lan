Add-Type -AssemblyName System.Windows.Forms
$networkId = "091f0945fc5012f1"
zerotier-cli leave $networkId
[System.Windows.Forms.MessageBox]::Show("Verbindung zu Netzwerk $networkId getrennt.", "ZeroTier", "OK", "Information")
