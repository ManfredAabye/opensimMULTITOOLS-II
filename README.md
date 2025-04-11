# **opensimMULTITOOL II V25.3 – Skript-Dokumentation**  
Ein Bash-Skript zum Verwalten von OpenSim-Grids (Starten, Stoppen, Bereinigen, Installation).

**Benutzung ausschließlich auf eigene Gefahr**  
*Dieses Skript ist im Entwicklungsstadium und kann unbeabsichtigte Datenverluste verursachen.*

```diff
- WICHTIGE WARNUNGEN:
1. Dies ist ein ALPHA-Skript - Im Produktivbetrieb nur nach ausführlichem Testing verwenden
2. Immer Backups erstellen VOR jeder Ausführung
3. Keine Haftung für Datenverlust oder Grid-Ausfälle
```

### 📜 **Nutzungsbedingungen**  
> Durch die Ausführung dieses Skripts bestätigen Sie:  
> - Die Risiken vollständig zu verstehen  
> - Ausreichende Backups erstellt zu haben  
> - Dass der Autor nicht für Schäden haftet  

---

## **📋 Inhaltsverzeichnis**  
1. [OpenSim starten/stoppen](#-opensim-starten-stoppen-und-neustarten)  
2. [OpenSim-Grid erstellen/aktualisieren](#-opensim-grid-erstellen-oder-aktualisieren)  
3. [OpenSim bereinigen](#-opensim-grid-bereinigen)  

---

## **🔄 OpenSim starten, stoppen und neustarten**  
| Befehl | Beschreibung |  
|--------|-------------|  
| `opensimstart` | Startet den OpenSim-Server. |  
| `opensimstop` | Stoppt den OpenSim-Server. |  
| `opensimrestart` | Startet OpenSim neu. |  
| `check_screens` | Überprüft laufende OpenSim-Prozesse und startet sie bei Bedarf neu. |  

---

## **🛠️ OpenSim-Grid erstellen oder aktualisieren**  
### **Schritt 1: Vorbereitung**  
| Befehl | Beschreibung |  
|--------|-------------|  
| `servercheck` | Prüft, ob der Server für OpenSim bereit ist. |  
| `createdirectory` | Erstellt die benötigten Verzeichnisse. |  
| `mariasetup` | Erstellt und Richtet die MariaDB-Datenbanken ein. |  
| `sqlsetup` | Erstellt und Richtet die SQL-Datenbanken ein. |

### **Schritt 2: OpenSim herunterladen & kompilieren**  
| Befehl | Beschreibung |  
|--------|-------------|  
| `opensimgitcopy` | Lädt OpenSim aus dem Git-Repository herunter. |  
| `moneygitcopy` | Lädt den MoneyServer aus dem Git-Repository herunter. |  
| `opensimbuild` | Kompiliert OpenSim. |  

### **Schritt 3: Konfiguration & Deployment** *(In Arbeit)*  
| Befehl | Beschreibung |  
|--------|-------------|  
| `opensimcopy` | Kopiert OpenSim in alle Zielverzeichnisse. |  
| *(Geplant)* `opensimconfig` | Konfiguriert OpenSim-Einstellungen. |  
| `regionconfig` | Konfiguriert Automatisch OpenSim Regionen in eine Fibonacci-Folge. |

---

## **🧹 OpenSim-Grid bereinigen**  
⚠ **Warnung:** Einige Befehle erfordern eine **Neuinstallation** von OpenSim!  

| Befehl | Beschreibung |  
|--------|-------------|  
| `dataclean` | Entfernt alle Dateien (Neuinstallation erforderlich). |  
| `pathclean` | Löscht alle Verzeichnisse (Neuinstallation erforderlich). |  
| `cacheclean` | Bereinigt den Cache. |  
| `logclean` | Entfernt alle Log-Dateien. |  
| `mapclean` | Löscht alle Maptiles (Kartendaten). |  
| `autoallclean` | **Führt alle Cleaner aus** (sehr gefährlich, Neuinstallation nötig!). |  

Diese Cleaner entfernen nur überflüssige Daten, während Backups und Konfigurationen erhalten bleiben.

➜ **Das Grid läuft sofort nach einem Upgrade mit:**  
- Behaltenen Regionen
- Gleichen Benutzerkonten
- Intakten Einstellungen

⚠ **Warnung:** Dies ist eine gefährliche Aktion, bitte prüfen und vergleichen sie die alten Konfigurationen mit den neuen example Konfigurationen.
---

## **⚠️ Wichtige Hinweise**  
- **`autoallclean` ist irreversibel!** → OpenSim muss danach neu installiert werden.  
- **Backups erstellen**, bevor Bereinigungsbefehle ausgeführt werden.
- Auch wenn keine Konfigurationsdateien gelöscht werden würde ich empfehlen das sie eine Manuelle Sicherung vornehmen.
- Einige Funktionen sind noch in Arbeit (`opensimconfig`, `regionconfig`).  
---

## **🔄 OpenSimulator auto- start stop restart Beispiel**

### List crontabs:
     crontab -l

### Edit crontabs:
     crontab -e
```
# Minute Hour Day Month Year Command
#
# Restart at 5 AM, and on the 1st of each month, restart the entire server.
#

# Restart server on the first of each month to clear cache data debris.
40 4 1 * * bash /opt/osmtool.sh cacheclean
45 4 1 * * bash /opt/osmtool.sh reboot

# Restart the grid every morning at 5 AM.
55 4 * * * bash /opt/osmtool.sh logclean
0 5 * * * bash /opt/osmtool.sh autorestart

# If Robust or the Welcome region fails, restart the grid.
*/30 * * * * bash /opt/osmtool.sh check_screens
```
### Save crontabs
     ctrl O
     Enter
### Exit editor
     ctrl X
---

## **📜 Lizenz & Nutzung**  
- **Skriptname**: `osmtool.sh`  
- **Version**: *V25.3.26.46*  
- **Autor**: *Manfred Aabye*  
- **Lizenz**: *MIT*  
