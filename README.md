# **opensimMULTITOOL II V25.4 – Skript-Dokumentation**  
Ein Bash-Skript zum Verwalten von OpenSim-Grids (Starten, Stoppen, Bereinigen, Installation).

**Benutzung ausschließlich auf eigene Gefahr**  
*Dieses Skript ist im Entwicklungsstadium und kann unbeabsichtigte Datenverluste verursachen.*

```diff
- WICHTIGE WARNUNGEN:

1.    ALPHA-STATUS
      Dies ist ein Alpha-Skript – Nutzung im Produktivbetrieb ausschließlich nach gründlichem Testen in einer sicheren Umgebung.

2.    BACKUPS SIND VERPFLICHTEND
      Vor jeder Ausführung müssen vollständige Backups aller betroffenen Systeme/Daten erstellt werden.

3.    HAFTUNGSAUSSCHLUSS
      Es wird keine Haftung für Datenverlust, Systemausfälle oder Folgeschäden übernommen. Nutzung auf eigenes Risiko.

4.    EINGESCHRÄNKTE ZUVERLÄSSIGKEIT
      Selbst als "sicher" markierte Funktionen können je nach Betriebssystem, Konfiguration oder Umgebung unerwartetes Verhalten zeigen.
      → Ausführliche Tests in Ihrer spezifischen Umgebung sind zwingend erforderlich.
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
3. [Diverse Git-Downloads](#-diverse-git-downloads)  
4. [Konfiguration](#-konfiguration)  
5. [INI-Operationen](#-ini-operationen)  
6. [XML-Operationen](#-xml-operationen)  
7. [Standalone-Modus](#-standalone-modus)  
8. [OpenSim bereinigen](#-opensim-grid-bereinigen)  
9. [Systembefehle](#-systembefehle)  
10. [Hilfen](#-hilfen)  

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
| Befehl | Beschreibung |  
|--------|-------------|  
| `servercheck` | Prüft, ob der Server für OpenSim bereit ist. |  
| `createdirectory` | Erstellt die benötigten Verzeichnisse. |  
| `opensimbuild` | OpenSim-Programm erstellen. |  
| `opensimcopy` | OpenSim kopieren/upgraden. |  
| `database_setup` | SQL-Datenbanken erstellen. |  
| `setcrontab` | Crontab Automatisierungen erstellen. |  
| `opensimupgrade` | OpenSim aktualisieren (_Experimentelle Funktion_) |

---

## **📂 Diverse Git-Downloads**  
| Befehl | Beschreibung |  
|--------|-------------|  
| `opensimgitcopy` | OpenSim aus Git herunterladen. |  
| `moneygitcopy` | MoneyServer aus Git herunterladen. |  
| `ruthrothgit` | Ruth/Roth IAR-Dateien aus Git (_Experimentelle Funktion_). |  
| `avatarassetsgit` | Ruth/Roth Assets aus Git (_Experimentelle Funktion_). |  
| `osslscriptsgit` | OSSL Beispiel-Skripte herunterladen. |  
| `pbrtexturesgit` | PBR Texturen aus Git (_Experimentelle Funktion_). |  
| `downloadallgit` | Alle Git-Repositories herunterladen (_Experimentelle Funktion_). |  
| `versionrevision` | Versionsrevision auf Expanded setzen. |  

---

## **⚙️ Konfiguration** 
| Befehl | Beschreibung |  
|--------|-------------|  
| `moneyserveriniconfig` | Konfiguriert MoneyServer.ini (_Experimentelle Funktion_). |  
| `opensiminiconfig` | Konfiguriert OpenSim.ini (_Experimentelle Funktion_). |  
| `robusthginiconfig` | Konfiguriert Robust.HG.ini (_Experimentelle Funktion_). |  
| `robustiniconfig` | Konfiguriert Robust.ini (_Experimentelle Funktion_). |  
| `gridcommoniniconfig` | Erstellt GridCommon.ini (_Experimentelle Funktion_). |  
| `standalonecommoniniconfig` | Erstellt StandaloneCommon.ini (_Experimentelle Funktion_). |  
| `flotsaminiconfig` | Erstellt FlotsamCache.ini (_Experimentelle Funktion_). |  
| `osslenableiniconfig` | Konfiguriert osslEnable.ini (_Experimentelle Funktion_). |  
| `welcomeiniconfig` | Konfiguriert Begrüßungsregion (_Experimentelle Funktion_). |  
| `regionsiniconfig` | Startet neue Regionen-Konfigurationen (_Experimentelle Funktion_). |  
| `iniconfig` | Startet ALLE Konfigurationen (_Experimentelle Funktion_). |  
| `generate_name` | Zufälligen Namen generieren (_Experimentelle Funktion_). |  
| `clean_config` | Konfigurationsdatei bereinigen (_Experimentelle Funktion_). | 
| `database_set_iniconfig` | Datenbanken einfügen (_Experimentelle Funktion_). | 
| `configure_pbr_textures` | PBR-Texturen (_Experimentelle Funktion_). | 

---

## **📜 INI-Operationen**  
| Befehl | Beschreibung |  
|--------|-------------|  
| `verify_ini_section` | INI-Abschnitt verifizieren (_Experimentelle Funktion_). |  
| `verify_ini_key` | INI-Schlüssel verifizieren (_Experimentelle Funktion_). |  
| `add_ini_section` | INI-Abschnitt hinzufügen (_Experimentelle Funktion_). |  
| `set_ini_key` | INI-Schlüssel setzen (_Experimentelle Funktion_). |  
| `del_ini_section` | INI-Abschnitt löschen (_Experimentelle Funktion_). |  
| `uncomment_ini_line` | INI-Zeile entkommentieren (_Experimentelle Funktion_). |  

---

## **📄 XML-Operationen**  
| Befehl | Beschreibung |  
|--------|-------------|  
| `verify_xml_section` | XML-Abschnitt verifizieren (_Experimentelle Funktion_). |  
| `add_xml_section` | XML-Abschnitt hinzufügen (_Experimentelle Funktion_). |  
| `del_xml_section` | XML-Abschnitt löschen (_Experimentelle Funktion_). |  

---

## **🖥️ Standalone-Modus**  
| Befehl | Beschreibung |  
|--------|-------------|  
| `standalone` | Standalone-Menü. |  
| `standalonestart` | Startet OpenSim im Standalone-Modus (_Experimentelle Funktion_). |  
| `standalonestop` | Stoppt OpenSim im Standalone-Modus (_Experimentelle Funktion_). |  
| `standalonerestart` | Startet OpenSim Standalone neu (_Experimentelle Funktion_). |  

---

## **🧹 OpenSim Grid Bereinigen**  
⚠ **Warnung:** Einige Befehle erfordern eine **Neuinstallation** von OpenSim!  

| Befehl            | Beschreibung |  
|------------------|-------------|  
| `dataclean`      | Alte Dateien löschen (⚡ Neuinstallation erforderlich!) (_Experimentelle Funktion_) |  
| `pathclean`      | Alte Verzeichnisse löschen (⚡ Neuinstallation erforderlich!) (_Experimentelle Funktion_) |  
| `cacheclean`     | Cache bereinigen. |  
| `logclean`       | Logs löschen. |  
| `mapclean`       | Maptiles löschen. |  
| `autoallclean`   | Komplettbereinigung (⚡ Neuinstallation erforderlich!) (_Experimentelle Funktion_) |  
| `regionsclean`   | Alle Regionen löschen. (_Experimentelle Funktion_) |  
| `cleanall`       | Alles bereinigen (⚡ Neuinstallation erforderlich!) (_Experimentelle Funktion_) |  
| `renamefiles`    | Umbenennung aller *.example Dateien. |  

---

## **🛠️ Systembefehle**  
| Befehl | Beschreibung |  
|--------|-------------|  
| `reboot` | Grid herunterfahren und Server neustarten. |  

---

## **❓ Hilfen**  
| Befehl | Beschreibung |  
|--------|-------------|  
| `help` | Die Hilfeseite anzeigen. |  
| `prohelp` | Die Pro Hilfeseite anzeigen. | 

➔ [📖 Wiki Dokumentation](https://github.com/ManfredAabye/opensimMULTITOOLS-II/wiki)

---

## **📜 Lizenz & Nutzung**  
- **Skriptname**: `osmtool.sh`  
- **Version**: *V25.4.63.181*  
- **Autor**: *Manfred Aabye*  
- **Lizenz**: *MIT*

---
