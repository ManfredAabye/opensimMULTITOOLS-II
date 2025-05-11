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

| Befehl                   | Beschreibung                                                        | Status                   |
| ------------------------ | ------------------------------------------------------------------- | ------------------------ |
| `opensimstart`           | Startet den OpenSim-Server.                                         | Stabil                   |
| `opensimstop`            | Stoppt den OpenSim-Server.                                          | Stabil                   |
| `opensimrestart`         | Startet OpenSim neu.                                                | Stabil                   |
| `opensimstartParallel`   | Startet alle Regionen parallel.                                     | Stabil                   |
| `opensimstopParallel`    | Stoppt alle Regionen parallel.                                      | Stabil                   |
| `opensimrestartParallel` | Startet alle Regionen neu (parallel).                               | Stabil                   |
| `check_screens`          | Überprüft laufende OpenSim-Prozesse und startet sie bei Bedarf neu. | Stabil                   |

---

## **🛠️ OpenSim-Grid erstellen oder aktualisieren**

| Befehl                                | Beschreibung                                    | Status                   |
| ------------------------------------- | ----------------------------------------------- | ------------------------ |
| `servercheck`                         | Prüft, ob der Server für OpenSim bereit ist.    | Test                     |
| `createdirectory`                     | Erstellt die benötigten Verzeichnisse.          | Stabil                   |
| `opensimbuild`                        | OpenSim-Programm erstellen.                     | Stabil                   |
| `opensimcopy`                         | OpenSim kopieren/upgraden.                      | Stabil                   |
| `database_setup`                      | SQL-Datenbanken erstellen.                      | Test                     |
| `opensimupgrade`                      | OpenSim aktualisieren.                          | Test                     |
| `autoupgrade`                         | Führt automatisches Upgrade durch.              | Test                     |
| `autoupgradefast`                     | Führt automatisches paralleles Upgrade durch.   | Test                     |
| `regionbackup`                        | Backup aller Regionsdaten.                      | Test                     |
| `robustbackup`                        | Backup der Robust-Datenbank mit Zeitraumfilter. | Test                     |
| `robustrestore <user> <pass> [teil]`  | Wiederherstellung aus Backup.                   | Test                     |
| `robustrepair <user> <pass> [aktion]` | Reparatur oder Bereinigung.                     | Test                     |
| `setcrontab`                          | Crontab Automatisierungen erstellen.            | Stabil                   |

---

## **📂 Diverse Git-Downloads**

| Befehl            | Beschreibung                          | Status                   |
| ----------------- | ------------------------------------- | ------------------------ |
| `opensimgitcopy`  | OpenSim aus Git herunterladen.        | Stabil                   |
| `moneygitcopy`    | MoneyServer aus Git herunterladen.    | Stabil                   |
| `ruthrothgit`     | Ruth/Roth IAR-Dateien aus Git.        |
| `avatarassetsgit` | Ruth/Roth Assets aus Git.             |
| `osslscriptsgit`  | OSSL Beispiel-Skripte herunterladen.  | Stabil                   |
| `pbrtexturesgit`  | PBR Texturen aus Git.                 |
| `downloadallgit`  | Alle Git-Repositories herunterladen.  |
| `versionrevision` | Versionsrevision auf Expanded setzen. | Stabil                   |

---

## **⚙️ Konfiguration**

| Befehl                      | Beschreibung                           | Status                   |
| --------------------------- | -------------------------------------- | ------------------------ |
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

| Befehl               | Beschreibung                | Status                   |
| -------------------- | --------------------------- | ------------------------ |
| `verify_ini_section` | INI-Abschnitt verifizieren. |
| `verify_ini_key`     | INI-Schlüssel verifizieren. |
| `add_ini_section`    | INI-Abschnitt hinzufügen.   |
| `set_ini_key`        | INI-Schlüssel setzen.       | Stabil                   |
| `del_ini_section`    | INI-Abschnitt löschen.      | Stabil                   |

---

## **📄 XML-Operationen**

| Befehl               | Beschreibung                | Status                   |
| -------------------- | --------------------------- | ------------------------ |
| `verify_xml_section` | XML-Abschnitt verifizieren. |
| `add_xml_section`    | XML-Abschnitt hinzufügen.   |
| `del_xml_section`    | XML-Abschnitt löschen.      |

---

## **🖥️ Standalone-Modus**

| Befehl              | Beschreibung                         | Status                   |
| ------------------- | ------------------------------------ | ------------------------ |
| `standalone`        | Standalone-Menü.                     |
| `standalonestart`   | Startet OpenSim im Standalone-Modus. |
| `standalonestop`    | Stoppt OpenSim im Standalone-Modus.  |
| `standalonerestart` | Startet OpenSim Standalone neu.      |

---

## **🧹 OpenSim Grid Bereinigen**

⚠ **Warnung:** Einige Befehle erfordern eine **Neuinstallation** von OpenSim!

| Befehl             | Beschreibung                                                 | Status                   |
| ------------------ | ------------------------------------------------------------ | ------------------------ |
| `dataclean`        | Alte Dateien löschen (⚡ Neuinstallation erforderlich!)       |
| `pathclean`        | Alte Verzeichnisse löschen (⚡ Neuinstallation erforderlich!) |
| `cacheclean`       | Cache bereinigen.                                            | Stabil                   |
| `logclean`         | Logs löschen.                                                | Stabil                   |
| `mapclean`         | Maptiles löschen.                                            | Stabil                   |
| `autoallclean`     | Komplettbereinigung (⚡ Neuinstallation erforderlich!)        |
| `regionsclean`     | Alle Regionen löschen.                                       |
| `cleanall`         | Alles bereinigen (⚡ Neuinstallation erforderlich!)           |
| `renamefiles`      | Umbenennung aller \*.example Dateien.                        |
| `clean_linux_logs` | Linux-Systemlogs bereinigen.                                 |
| `delete_opensim`   | Entfernt OpenSimulator komplett inkl. Verzeichnissen.        |

---

## **🛠️ Systembefehle**

| Befehl   | Beschreibung                               | Status                   |
| -------- | ------------------------------------------ | ------------------------ |
| `reboot` | Grid herunterfahren und Server neustarten. | Stabil                   |

---

## **❓ Hilfen**

| Befehl    | Beschreibung                                                | Status                   |
| --------- | ----------------------------------------------------------- | ------------------------ |
| `help`    | Die Hilfeseite anzeigen.                                    | Stabil                   |
| `prohelp` | Erweiterte Hilfeseite mit allen Experten-Befehlen anzeigen. | Stabil                   |

➔ [📖 Wiki Dokumentation](https://github.com/ManfredAabye/opensimMULTITOOLS-II/wiki)

---

## **📜 Lizenz & Nutzung**

* **Skriptname**: `osmtool.sh`
* **Version**: *V25.5.101.412*
* **Autor**: *Manfred Aabye*
* **Lizenz**: *MIT*

---
