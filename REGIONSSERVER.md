# Handbuch: Regionsserver mit Hypergrid

Dieses Handbuch beschreibt einen separaten Regionsserver, der an einen zentralen Robust-Grid-Server angebunden ist.

## 1. Zweck und Rolle

Ein Regionsserver hostet nur Regionen (sim1, sim2, ...) und nutzt zentrale Dienste vom Grid-Server.

## 2. Voraussetzungen

- Grid-Server mit laufendem Robust vorhanden
- Ubuntu Server 18.04 bis 24.04 mit bash
- Root/Sudo-Rechte auf dem Server
- Projekt unter /opt/opensimMULTITOOLS-II

Wichtig:

- Die technische Server-Vorbereitung erfolgt ueber die Install-Aktionen (prepare-ubuntu, install-opensim-deps, install-dotnet8).
- Es wird keine vorinstallierte Firewall vorausgesetzt.

Manuelle Eingaben durch den Betreiber:

- DNS/FQDN bzw. oeffentliche Host/IP-Werte
- Endpunkte auf den zentralen Robust-Server

## 3. Installation auf dem Regionsserver

```bash
cd /opt/opensimMULTITOOLS-II
chmod +x osmtool_main.sh modular/*.sh

bash osmtool_main.sh --profile grid-sim --module install --action prepare-ubuntu --workdir /opt
bash osmtool_main.sh --profile grid-sim --module install --action install-opensim-deps --workdir /opt
bash osmtool_main.sh --profile grid-sim --module install --action install-dotnet8 --workdir /opt
bash osmtool_main.sh --profile grid-sim --module install --action server-check --workdir /opt
bash osmtool_main.sh --profile grid-sim --module install --action install-opensim --workdir /opt
bash osmtool_main.sh --profile grid-sim --module install --action configure-opensim --workdir /opt
```

## 4. Hypergrid- und Grid-Anbindung

Datei pruefen/anpassen:

- /opt/sim1/bin/OpenSim.ini (analog fuer weitere sim*)

Wichtige Punkte:

- Grid-/Robust-Endpunkte auf zentralen Robust-FQDN setzen
- Hypergrid/Gatekeeper-Abschnitte aktiv
- Keine lokalen Testwerte fuer externe URI

## 5. Betrieb nur fuer Regionen

### 5.1 Region starten

```bash
bash osmtool_main.sh --profile grid-sim --module startstop --target sim1 --action start --workdir /opt
```

### 5.2 Region neustarten/stoppen

```bash
bash osmtool_main.sh --profile grid-sim --module startstop --target sim1 --action restart --workdir /opt
bash osmtool_main.sh --profile grid-sim --module startstop --target sim1 --action stop --workdir /opt
```

### 5.3 Monitoring

```bash
bash osmtool_main.sh --profile grid-sim --module health --action run --workdir /opt
bash osmtool_main.sh --profile grid-sim --module report --action generate --workdir /opt
```

## 6. Typische Fehler

- "Target not allowed for this profile": Profil auf grid-sim stellen.
- Region startet, aber kein HG-Travel: FQDN/URI und NAT pruefen.
- Kein Login ins Grid: Robust-Endpunkte in OpenSim.ini verifizieren.

## 7. Abnahmecheckliste

- [ ] Region startet sauber
- [ ] Region verbindet sich mit zentralem Robust
- [ ] Hypergrid-Endpunkte extern erreichbar
- [ ] report/health ohne kritische Fehler
- [ ] HG-Reise in beide Richtungen getestet
