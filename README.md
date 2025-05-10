# **opensimMULTITOOL II V25.5**

Ein Bash-Skript zum Verwalten von OpenSim-Grids (Starten, Stoppen, Bereinigen, Installation).

**Benutzung ausschließlich auf eigene Gefahr**
*Dieses Skript ist im Entwicklungsstadium und kann unbeabsichtigte Datenverluste verursachen.*

```diff
- WICHTIGE WARNUNGEN:

1.    ALPHA-STATUS
      Dies ist ein Alpha-Skript – Nutzung im Produktivbetrieb ausschließlich
      nach gründlichem Testen in einer sicheren Umgebung.

2.    BACKUPS SIND VERPFLICHTEND
      Vor jeder Ausführung müssen
      vollständige Backups aller betroffenen Systeme/Daten erstellt werden.

3.    HAFTUNGSAUSSCHLUSS
      Es wird keine Haftung für Datenverlust,
      Systemausfälle oder Folgeschäden übernommen.
      Nutzung auf eigenes Risiko.

4.    EINGESCHRÄNKTE ZUVERLÄSSIGKEIT
      Selbst als "sicher" markierte Funktionen können je nach Betriebssystem,
      Konfiguration oder Umgebung unerwartetes Verhalten zeigen.

      → Ausführliche Tests in Ihrer spezifischen Umgebung sind zwingend erforderlich.
```

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

| Befehl                   | Beschreibung                                                        |
| ------------------------ | ------------------------------------------------------------------- |
| `opensimstart`           | Startet den OpenSim-Server.                                         |
| `opensimstop`            | Stoppt den OpenSim-Server.                                          |
| `opensimrestart`         | Startet OpenSim neu.                                                |
| `opensimstartParallel`   | Startet alle Regionen parallel.                                     |
| `opensimstopParallel`    | Stoppt alle Regionen parallel.                                      |
| `opensimrestartParallel` | Startet alle Regionen neu (parallel).                               |
| `check_screens`          | Überprüft laufende OpenSim-Prozesse und startet sie bei Bedarf neu. |

---

## **🛠️ OpenSim-Grid erstellen oder aktualisieren**

| Befehl                                | Beschreibung                                    |
| ------------------------------------- | ----------------------------------------------- |
| `servercheck`                         | Prüft, ob der Server für OpenSim bereit ist.    |
| `createdirectory`                     | Erstellt die benötigten Verzeichnisse.          |
| `opensimbuild`                        | OpenSim-Programm erstellen.                     |
| `opensimcopy`                         | OpenSim kopieren/upgraden.                      |
| `database_setup`                      | SQL-Datenbanken erstellen.                      |
| `opensimupgrade`                      | OpenSim aktualisieren.                          |
| `autoupgrade`                         | Führt automatisches Upgrade durch.              |
| `autoupgradefast`                     | Führt automatisches paralleles Upgrade durch.   |
| `regionbackup`                        | Backup aller Regionsdaten.                      |
| `robustbackup`                        | Backup der Robust-Datenbank mit Zeitraumfilter. |
| `robustrestore <user> <pass> [teil]`  | Wiederherstellung aus Backup.                   |
| `robustrepair <user> <pass> [aktion]` | Reparatur oder Bereinigung.                     |
| `setcrontab`                          | Crontab Automatisierungen erstellen.            |

---

## **📂 Diverse Git-Downloads**

| Befehl            | Beschreibung                          |
| ----------------- | ------------------------------------- |
| `opensimgitcopy`  | OpenSim aus Git herunterladen.        |
| `moneygitcopy`    | MoneyServer aus Git herunterladen.    |
| `ruthrothgit`     | Ruth/Roth IAR-Dateien aus Git.        |
| `avatarassetsgit` | Ruth/Roth Assets aus Git.             |
| `osslscriptsgit`  | OSSL Beispiel-Skripte herunterladen.  |
| `pbrtexturesgit`  | PBR Texturen aus Git.                 |
| `downloadallgit`  | Alle Git-Repositories herunterladen.  |
| `versionrevision` | Versionsrevision auf Expanded setzen. |

---

## **⚙️ Konfiguration**

| Befehl                      | Beschreibung                           |
| --------------------------- | -------------------------------------- |
| `moneyserveriniconfig`      | Konfiguriert MoneyServer.ini.          |
| `opensiminiconfig`          | Konfiguriert OpenSim.ini.              |
| `robusthginiconfig`         | Konfiguriert Robust.HG.ini.            |
| `robustiniconfig`           | Konfiguriert Robust.ini.               |
| `gridcommoniniconfig`       | Erstellt GridCommon.ini.               |
| `standalonecommoniniconfig` | Erstellt StandaloneCommon.ini.         |
| `flotsaminiconfig`          | Erstellt FlotsamCache.ini.             |
| `osslenableiniconfig`       | Konfiguriert osslEnable.ini.           |
| `welcomeiniconfig`          | Konfiguriert Begrüßungsregion.         |
| `regionsiniconfig`          | Startet neue Regionen-Konfigurationen. |
| `iniconfig`                 | Startet ALLE Konfigurationen.          |

---

## **📜 INI-Operationen**

| Befehl               | Beschreibung                |
| -------------------- | --------------------------- |
| `verify_ini_section` | INI-Abschnitt verifizieren. |
| `verify_ini_key`     | INI-Schlüssel verifizieren. |
| `add_ini_section`    | INI-Abschnitt hinzufügen.   |
| `set_ini_key`        | INI-Schlüssel setzen.       |
| `del_ini_section`    | INI-Abschnitt löschen.      |

---

## **📄 XML-Operationen**

| Befehl               | Beschreibung                |
| -------------------- | --------------------------- |
| `verify_xml_section` | XML-Abschnitt verifizieren. |
| `add_xml_section`    | XML-Abschnitt hinzufügen.   |
| `del_xml_section`    | XML-Abschnitt löschen.      |

---

## **🖥️ Standalone-Modus**

| Befehl              | Beschreibung                         |
| ------------------- | ------------------------------------ |
| `standalone`        | Standalone-Menü.                     |
| `standalonestart`   | Startet OpenSim im Standalone-Modus. |
| `standalonestop`    | Stoppt OpenSim im Standalone-Modus.  |
| `standalonerestart` | Startet OpenSim Standalone neu.      |

---

## **🧹 OpenSim Grid Bereinigen**

⚠ **Warnung:** Einige Befehle erfordern eine **Neuinstallation** von OpenSim!

| Befehl             | Beschreibung                                                 |
| ------------------ | ------------------------------------------------------------ |
| `dataclean`        | Alte Dateien löschen (⚡ Neuinstallation erforderlich!)       |
| `pathclean`        | Alte Verzeichnisse löschen (⚡ Neuinstallation erforderlich!) |
| `cacheclean`       | Cache bereinigen.                                            |
| `logclean`         | Logs löschen.                                                |
| `mapclean`         | Maptiles löschen.                                            |
| `autoallclean`     | Komplettbereinigung (⚡ Neuinstallation erforderlich!)        |
| `regionsclean`     | Alle Regionen löschen.                                       |
| `cleanall`         | Alles bereinigen (⚡ Neuinstallation erforderlich!)           |
| `renamefiles`      | Umbenennung aller \*.example Dateien.                        |
| `clean_linux_logs` | Linux-Systemlogs bereinigen.                                 |
| `delete_opensim`   | Entfernt OpenSimulator komplett inkl. Verzeichnissen.        |

---

## **🛠️ Systembefehle**

| Befehl   | Beschreibung                               |
| -------- | ------------------------------------------ |
| `reboot` | Grid herunterfahren und Server neustarten. |

---

## **❓ Hilfen**

| Befehl    | Beschreibung                                                |
| --------- | ----------------------------------------------------------- |
| `help`    | Die Hilfeseite anzeigen.                                    |
| `prohelp` | Erweiterte Hilfeseite mit allen Experten-Befehlen anzeigen. |

➔ [📖 Wiki Dokumentation](https://github.com/ManfredAabye/opensimMULTITOOLS-II/wiki)

---

## **📜 Lizenz & Nutzung**

* **Skriptname**: `osmtool.sh`
* **Version**: *V25.5.101.412*
* **Autor**: *Manfred Aabye*
* **Lizenz**: *MIT*

---
