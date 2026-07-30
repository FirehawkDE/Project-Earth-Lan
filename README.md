Klick & Play (Installer): 

Keine komplizierten Netzwerk-
Einstellungen. Ein Skript für die Installation, eins für die Deinstallation – der Rest läuft im Hintergrund.

​Sicher & Direkt: Deine Daten fließen direkt von PC zu PC (Peer-to-Peer). Keine Umwege über langsame Drittanbieter-Server.

Kein Stress mit Router-Einstellungen oder CGNAT. Das Netzwerk regelt das Routing automatisch.

Zum Thema Sicherheit und Firewall:

Wenn man dem Netzwerk beigetreten ist, erstellt Windows einen öffentlichen LAN-Adapter, wodurch die Windows-Konfiguration schon einiges blockiert.

Zudem schützt das ZeroTierOne Netzwerk mit den Flow Rules nochmals zusätzlich.

<img width="1374" height="1693" alt="Screenshot_20260730_052450_Firefox" src="https://github.com/user-attachments/assets/7cf520f3-5c38-4dca-9170-c9e6da6f103e" />

Kurze Übersicht der Blöcke
​Block 1 (SMB / NetBIOS / RPC): Blockiert Ordnerfreigaben, NetBIOS-Namen und Windows-RPC. Schützt vor Ransomware und verhindert, dass Geräte im Explorer auftauchen.

​Block 2 (RDP / VNC): Blockiert die Ports für Windows Remotedesktop und VNC, damit niemand ungefragt auf Fremdrechner zugreifen kann.

​Block 3 (Discovery-Lärm): Schirmt ab, was Geräte dauerhaft an Broadcasts/Multicasts schicken (z. B. "Ich bin ein Drucker", "Gibt es Dropbox-Clients?", "Welcher PC heißt X?"). Absolut notwendig für die Netzwerkspeed.
​Block 4 (Accept): Erlaubt allen normalen Internet- und Spieletraffic, der nicht durch die oberen Filter blockiert wurde.

Was für macOS & Linux speziell drin ist
​macOS (Apple):

​Port 5353 blockiert Bonjour (Apples mDNS), wodurch verhindert wird, dass Mac-Geräte dauerhaft AirPlay-Ziele, Apple TVs oder iTunes-Freigaben im ZeroTier-Netz suchen.

​Port 548 sperrt das AFP-Protokoll (Apple Filing Protocol).

​Port 5900 stoppt die integrierte macOS Bildschirmfreigabe (Screen Sharing).

​Linux:
​Port 5353 stoppt auch Avahi (das Linux-Pendant zu Bonjour/mDNS).

​Port 445 sperrt Samba-Freigaben auf Linux-Systemen.

​Port 2049 blockiert NFS (Network File System), den Linux-Standard für Dateifreigaben.

​Port 631 stoppt CUPS (das Druckersystem von Linux und macOS), damit nicht Hunderte Linux/Mac-Clients nach Netzwerkdruckern suchen.
