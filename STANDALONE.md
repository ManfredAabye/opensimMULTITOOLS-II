# Handbuch: OpenSim Standalone mit Hypergrid

Dieses Handbuch beschreibt den Betrieb einer OpenSim-Standalone-Instanz mit aktivierter Hypergrid-Funktion.

## 1. Zweck und Rolle

Standalone bedeutet: Alle Dienste auf einem Host, geeignet fuer Test, Entwicklung oder kleine produktive Setups.

## 2. Voraussetzungen

- Ubuntu Server 18.04 bis 24.04 mit bash
- Root/Sudo-Rechte auf dem Server
- Projekt unter /opt/opensimMULTITOOLS-II

Wichtig:

- Die technische Server-Vorbereitung erfolgt ueber die Install-Aktionen (prepare-ubuntu, install-opensim-deps, install-dotnet8).
- Es wird keine vorinstallierte Firewall vorausgesetzt.
- Paketinstallation und Basis-Setup werden vom Tool ausgefuehrt.

Manuelle Eingaben durch den Betreiber:

- Oeffentlicher FQDN/IP fuer Hypergrid
- Datenbank-Zugangsdaten (falls verwendet)

## 3. Installation

```bash
cd /opt/opensimMULTITOOLS-II
chmod +x osmtool_main.sh modular/*.sh

bash osmtool_main.sh --profile standalone --module install --action prepare-ubuntu --workdir /opt
bash osmtool_main.sh --profile standalone --module install --action install-opensim-deps --workdir /opt
bash osmtool_main.sh --profile standalone --module install --action install-dotnet8 --workdir /opt
bash osmtool_main.sh --profile standalone --module install --action server-check --workdir /opt
bash osmtool_main.sh --profile standalone --module install --action install-opensim --workdir /opt
bash osmtool_main.sh --profile standalone --module install --action configure-opensim --workdir /opt
```

Optional Datenbanksetup:

```bash
bash osmtool_main.sh --profile standalone --module install --action configure-database --workdir /opt --db-user opensim --db-pass 'DEIN_PASSWORT'
```

## 4. Hypergrid-Konfiguration

Datei pruefen/anpassen:

- /opt/standalone/bin/OpenSim.ini

Wichtige Punkte:

- Hypergrid-Abschnitte aktivieren
- Externe URI/FQDN korrekt setzen
- Keine localhost/127.0.0.1 in extern relevanten URI

## 5. Betrieb

### 5.1 Start/Stop/Restart

```bash
bash osmtool_main.sh --profile standalone --module startstop --action start --workdir /opt
bash osmtool_main.sh --profile standalone --module startstop --action restart --workdir /opt
bash osmtool_main.sh --profile standalone --module startstop --action stop --workdir /opt
```

### 5.2 Monitoring

```bash
bash osmtool_main.sh --profile standalone --module smoke --action run --workdir /opt
bash osmtool_main.sh --profile standalone --module health --action run --workdir /opt
bash osmtool_main.sh --profile standalone --module report --action generate --workdir /opt
```

## 6. Cron-Einrichtung

```bash
bash osmtool_main.sh --profile standalone --module cron --action install --workdir /opt --db-user opensim --db-pass 'DEIN_PASSWORT' --db-name opensim --region sim1 --session sim1
bash osmtool_main.sh --profile standalone --module cron --action list --workdir /opt
```

## 7. Typische Fehler

- Instanz laeuft lokal, aber kein HG-Travel: externe URI und NAT fehlen.
- Startfehler nach Update: mit report/health und Logs pruefen.
- Unstabiler Betrieb: smoke/report cron aktivieren.

## 8. Abnahmecheckliste

- [ ] Standalone startet sauber
- [ ] Hypergrid-Endpunkte extern erreichbar
- [ ] smoke/health/report erfolgreich
- [ ] HG-Reise zu externem Grid erfolgreich
