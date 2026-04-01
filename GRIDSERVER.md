# Handbuch: Grid-Server mit Hypergrid

Dieses Handbuch beschreibt den Betrieb eines OpenSim Grid-Servers mit Robust-Diensten und Hypergrid-Funktion auf Basis von opensimMULTITOOLS-II.

## 1. Zweck und Rolle

Ein Grid-Server stellt zentral bereit:

- Robust-Dienste (Login, Grid, Inventory, Assets, Gatekeeper)
- optional lokale Regionen (sim1, sim2, ...)
- optional Janus fuer WebRTC

## 2. Voraussetzungen

- Linux Server

Wichtig:

- Die technische Server-Vorbereitung erfolgt ueber die Install-Aktionen (prepare-ubuntu, install-opensim-deps, install-dotnet8).
- Es wird keine vorinstallierte Firewall vorausgesetzt.
- Paketinstallation und Basis-Setup werden vom Tool ausgefuehrt.

Manuelle Eingaben durch den Betreiber:

- DNS/FQDN bzw. oeffentliche Host/IP-Werte fuer Hypergrid
- Datenbank-Zugangsdaten (z. B. --db-user, --db-pass)
- Oeffentliche Hostangabe fuer Janus/OpenSim (z. B. --public-host)

## 3. Grundinstallation

```bash
cd /opt/opensimMULTITOOLS-II
chmod +x osmtool_main.sh modular/*.sh

# Pflicht: Tool richtet den Server technisch ein
bash osmtool_main.sh server_install
# Betreiber gibt DB-Zugangsdaten vor
export OSM_DB_USER=opensim
export OSM_DB_PASS='DEIN_PASSWORT'
bash osmtool_main.sh dbsetup
```

## 4. Hypergrid-Konfiguration

Datei pruefen/anpassen:

- /opt/robust/bin/Robust.ini

Wichtige Punkte:

- Externe Endpunkte auf echten FQDN/IP setzen
- Keine localhost oder 127.0.0.1 fuer externe HG-URIs
- Gatekeeper/UserAgent-Endpunkte konsistent halten

Wenn lokale Regionen laufen, auch deren OpenSim.ini gegen Robust-FQDN pruefen.

## 5. Betrieb

### 5.1 Start/Stop/Restart

```bash
bash osmtool_main.sh opensimstart
bash osmtool_main.sh opensimrestart
bash osmtool_main.sh opensimstop
```

### 5.2 Monitoring

```bash
bash osmtool_main.sh healthcheck
bash osmtool_main.sh smoketest
bash osmtool_main.sh dailyreport
```

## 6. Cron fuer Stabilitaet

```bash
bash osmtool_main.sh croninstall
bash osmtool_main.sh cronlist
```

## 7. Janus (optional)

```bash
bash osmtool_main.sh janusinstall
bash osmtool_main.sh janusrestart
```

## 8. Abnahmecheckliste

- [ ] Robust startet fehlerfrei
- [ ] Regionen verbinden sich mit Robust
- [ ] Hypergrid-Endpunkte extern erreichbar
- [ ] smoke/report laufen erfolgreich
- [ ] HG-Reise von externem Grid erfolgreich
