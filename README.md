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
| `ruthrothgit`     | Ruth/Roth IAR-Dateien aus Git.        | in Arbeit                |
| `avatarassetsgit` | Ruth/Roth Assets aus Git.             | in Arbeit                |
| `osslscriptsgit`  | OSSL Beispiel-Skripte herunterladen.  | Stabil                   |
| `pbrtexturesgit`  | PBR Texturen aus Git.                 | in Arbeit                |
| `downloadallgit`  | Alle Git-Repositories herunterladen.  | Voricht test             |
| `versionrevision` | Versionsrevision auf Expanded setzen. | Stabil                   |

---

## **⚙️ Konfiguration**

| Befehl                      | Beschreibung                           | Status              |
| --------------------------- | -------------------------------------- | ------------------- |
| `moneyserveriniconfig`      | Konfiguriert MoneyServer.ini.          | Optimierung fehlt.  |
| `opensiminiconfig`          | Konfiguriert OpenSim.ini.              | Optimierung fehlt.  |
| `robusthginiconfig`         | Konfiguriert Robust.HG.ini.            | Optimierung fehlt.  |
| `robustiniconfig`           | Konfiguriert Robust.ini.               | Optimierung fehlt.  |
| `gridcommoniniconfig`       | Erstellt GridCommon.ini.               | Optimierung fehlt.  |
| `standalonecommoniniconfig` | Erstellt StandaloneCommon.ini.         | Optimierung fehlt.  |
| `flotsaminiconfig`          | Erstellt FlotsamCache.ini.             | Optimierung fehlt.  |
| `osslenableiniconfig`       | Konfiguriert osslEnable.ini.           | Optimierung fehlt.  |
| `welcomeiniconfig`          | Konfiguriert Begrüßungsregion.         | Optimierung fehlt.  |
| `regionsiniconfig`          | Startet neue Regionen-Konfigurationen. | Optimierung fehlt.  |
| `iniconfig`                 | Startet ALLE Konfigurationen.          | Optimierung fehlt.  |

---

## **📜 INI Konfiguration Operationen**

| Befehl               | Beschreibung                | Status                   |
| -------------------- | --------------------------- | ------------------------ |
| `verify_ini_section` | INI-Abschnitt verifizieren. | Test                     |
| `verify_ini_key`     | INI-Schlüssel verifizieren. | Test                     |
| `add_ini_section`    | INI-Abschnitt hinzufügen.   | Stabil                   |
| `set_ini_key`        | INI-Schlüssel setzen.       | Stabil                   |
| `del_ini_section`    | INI-Abschnitt löschen.      | Stabil                   |

---

## **📄 XML Assets Operationen**

| Befehl               | Beschreibung                | Status                   |
| -------------------- | --------------------------- | ------------------------ |
| `verify_xml_section` | XML-Abschnitt verifizieren. | ungetestet               |
| `add_xml_section`    | XML-Abschnitt hinzufügen.   | ungetestet               |
| `del_xml_section`    | XML-Abschnitt löschen.      | ungetestet               |

---

## **🖥️ Standalone-Modus**

| Befehl                   | Beschreibung                          | Status |
| ------------------------ | ------------------------------------- | ------ |
| `standalonestart`        | Startet OpenSim im Standalone-Modus   | Stabil |
| `standalonestop`         | Stoppt OpenSim im Standalone-Modus    | Stabil |
| `standalonerestart`      | Startet OpenSim Standalone neu        | Stabil |
| `buildstandalone`        | Standalone erstellen                  | Test   |
| `opensimgitcopy`         | OpenSimulator aus Git kopieren        | Test   |
| `osslscriptsgit`         | Skripte aus Repository einfügen       | Test   |
| `versionrevision`        | OpenSimulator-Version festlegen       | Test   |
| `opensimbuild`           | OpenSimulator bauen                   | Test   |
| `standalonesetup`        | Standalone Setup durchführen          | Test   |
| `createstandaloneconfig` | OpenSimulator-Konfiguration erstellen | Test   |
| `createstandalonregion`  | Startregion konfigurieren             | Test   |
| `createstandaloneuser`   | Benutzer erstellen                    | Test   |

---

## **🧹 OpenSim Grid Bereinigen**

⚠ **Warnung:** Einige Befehle erfordern eine **Neuinstallation** von OpenSim!

| Befehl             | Beschreibung                                                 | Status                   |
| ------------------ | ------------------------------------------------------------ | ------------------------ |
| `dataclean`        | Alte Dateien löschen (⚡ Neuinstallation erforderlich!)       | Test                     |
| `pathclean`        | Alte Verzeichnisse löschen (⚡ Neuinstallation erforderlich!) | Test                     |
| `cacheclean`       | Cache bereinigen.                                            | Stabil                   |
| `logclean`         | Logs löschen.                                                | Stabil                   |
| `mapclean`         | Maptiles löschen.                                            | Stabil                   |
| `autoallclean`     | Komplettbereinigung (⚡ Neuinstallation erforderlich!)        | Test                     |
| `regionsclean`     | Alle Regionen löschen.                                       | Test                     |
| `cleanall`         | Alles bereinigen (⚡ Neuinstallation erforderlich!)           | Test                     |
| `renamefiles`      | Umbenennung aller \*.example Dateien.                        | Test                     |
| `clean_linux_logs` | Linux-Systemlogs bereinigen.                                 | Test                     |
| `delete_opensim`   | Entfernt OpenSimulator komplett inkl. Verzeichnissen.        | Test                     |

---

## **🛠️ Systembefehle**

| Befehl   | Beschreibung                               | Status                   |
| -------- | ------------------------------------------ | ------------------------ |
| `reboot` | Grid herunterfahren und Server neustarten. | Stabil                   |

---

## **📂 Backup**

| Befehl              | Beschreibung                                                                 | Status                   |
|---------------------|------------------------------------------------------------------------------|--------------------------|
| `loadiar`           | Lädt ein Inventar-Archiv (IAR) zu einem Avatar hoch                         | Test                     |
| `saveiar`           | Speichert das Inventar eines Avatars als IAR-Datei                          | Test                     |
| `loadoar`           | Lädt ein vollständiges Regionen-Backup (OAR) in eine Region                  | Test                     |
| `saveoar`           | Erstellt ein vollständiges Backup (OAR) einer Region                         | Test                     |
| `autoregionbackup`  | Führt automatisierte Backups aller Regionen aus                              | Test                  |


---

## **❓ Hilfen**

| Befehl    | Beschreibung                                                | Status                   |
| --------- | ----------------------------------------------------------- | ------------------------ |
| `help`    | Die Hilfeseite anzeigen.                                    | Stabil                   |
| `prohelp` | Erweiterte Hilfeseite mit allen Experten-Befehlen anzeigen. | Stabil                   |

➔ [📖 Wiki Dokumentation](https://github.com/ManfredAabye/opensimMULTITOOLS-II/wiki)

---

osmtool_backup.sh

* Ist dafür gemacht ein komplettes Grid so zu sichern das ein umzug auf einen neuen Server einfach und reibungslos ist.

osmtool_restart.sh

Das ist ein schmales Skript den Server neu zu starten und zu prüfen ob alles läuft.

* Wenn robustserver nicht läuft wird das Grid neu gestartet.
* Wenn moneyserver nicht läuft wird das Grid neu gestartet.
* Wenn sim1 also die Welcome Region nicht läuft wird das Grid neu gestartet.
* Wenn sim2 - sim99 nicht läuft wird die einzelne Region neu gestartet.

---

## **📜 Lizenz & Nutzung**

* **Skriptname**: `osmtool.sh`
* **Version**: *V25.5.109.442*
* **Autor**: *Manfred Aabye*
* **Lizenz**: *MIT*

---
