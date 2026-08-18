Project Earth LAN hat ein einfaches Ziel: Wir wollen das unkomplizierte Gefühl der alten LAN-Partys zurückholen und Retro-Multiplayer-Games wieder gemeinsam in den Mainstream bringen.

​Egal ob Gamer oder Casual: Niemand sollte sich mit komplizierten Server-Setups, Port-Freigaben oder fehlerhaften Online-Lobbys herumschlagen müssen, nur um mit Freunden oder der Community eine Runde Klassiker zu zocken.

Mit Project Earth LAN verbindet ihr euch im Handumdrehen über ein virtuelles LAN-Netzwerk – extrem einfach, sicher und performanceorientiert.

​Klick & Play (Installer)

​Um euch den Einstieg so einfach wie möglich zu machen, gibt es zwei Varianten:
​PowerShell-Skripte (für Erfahrene): Wer Transparenz schätzt und den Code einsehen möchte, findet die Skripte direkt unter Codes.

​Kompilierte .exe (1-Klick-Lösung): 

Für alle, die sich nicht mit PowerShell auseinandersetzen wollen oder können. Perfekt für den schnellen Start, zu finden unter Releases.

​Keine komplizierten Netzwerkeinstellungen! Einfache Skripte übernehmen die Installation, Deinstallation sowie das Ein- und Ausloggen – der gesamte Rest läuft vollautomatisch im Hintergrund.

​Sicher & Direkt: Deine Daten fließen direkt von PC zu PC (Peer-to-Peer). 

Keine Umwege über langsame Drittanbieter-Server.

​Kein Router-Stress: Kein Ärger mit Router-Einstellungen, Port-Weiterleitungen oder CGNAT. Das Netzwerk regelt das Routing vollständig automatisch.

​Sicherheit & Firewall im Netz
​Sobald man dem ZeroTierOne-Netzwerk beigetreten ist, erstellt Windows standardmäßig einen öffentlichen LAN-Adapter, wodurch die lokale Windows-Konfiguration bereits viele Zugriffe blockiert.

​Zusätzlich wird das ZeroTierOne-Netzwerk durch maßgeschneiderte Flow Rules serverseitig gehärtet, um maximale Sicherheit bei minimaler Latenz zu garantieren:
​<img width="1374" height="1693" alt="Screenshot_20260730_052450_Firefox" src="[https://github.com/user-attachments/assets/7cf520f3-5c38-4dca-9170-c9e6da6f103e](https://github.com/user-attachments/assets/7cf520f3-5c38-4dca-9170-c9e6da6f103e)" />

​Kurze Übersicht der Regel-Blöcke:

​Block 1 (SMB / NetBIOS / RPC): Blockiert Ordnerfreigaben, NetBIOS-Namen und Windows-RPC. Schützt vor Ransomware und verhindert, dass private Geräte im Explorer anderer Spieler auftauchen.

​Block 2 (RDP / VNC): Blockiert die Ports für Windows Remotedesktop und VNC, damit niemand ungefragt auf Fremdrechner zugreifen kann.

​Block 3 (Discovery-Lärm): Schirmt unötige Broadcasts und Multicasts ab (z. B. "Ich bin ein Drucker", "Gibt es Dropbox-Clients?", "Welcher PC heißt X?"). Das verhindert Spam im Netz und ist absolut notwendig für maximale Netzwerk-Performance und niedrigen Ping.

​Block 4 (Accept): Erlaubt allen normalen Internet- und Spieletraffic, der nicht durch die oberen Filter blockiert wurde.

​Spezieller Schutz für macOS & Linux
​Damit auch Crossplay-Sessions plattformübergreifend sauber und sicher laufen, sind spezifische Filter für Apple- und Linux-Systeme integriert:
​macOS (Apple):

​Port 5353: Blockiert Bonjour (Apples mDNS) und verhindert, dass Mac-Geräte dauerhaft nach AirPlay-Zielen, Apple TVs oder iTunes-Freigaben im ZeroTier-Netz suchen.

​Port 548: Sperrt das AFP-Protokoll (Apple Filing Protocol).

​Port 5900: Stoppt die integrierte macOS-Bildschirmfreigabe (Screen Sharing).

​Linux:
​Port 5353: Stoppt Avahi (das Linux-Pendant zu Bonjour/mDNS).

​Port 445: Sperrt Samba-Dateifreigaben auf Linux-Systemen.

​Port 2049: Blockiert NFS (Network File System), den Linux-Standard für Dateifreigaben.

​Port 631: Stoppt CUPS (das Druckersystem von Linux und macOS), damit nicht Hunderte Clients nach Netzwerkdruckern suchen.

https://youtu.be/p41ukySUGts?si=hwT-Xnvb8ZC7t6cv

https://youtu.be/8btgkLx6LQA?si=NpsR9XeDdZXB8_8_
