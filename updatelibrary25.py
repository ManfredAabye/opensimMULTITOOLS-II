#!/usr/bin/env python3
"""
OpenSim Library Generator - Modernized Version

Features:
- Type hints throughout
- pathlib for path handling
- argparse instead of optparse
- Secure path traversal protection
- Context managers for file operations
- Configurable file type mappings
- Proper logging system
- XML security improvements
"""

"""
### **OpenSim Library Generator - Modernisierte Version**  
**Was dieses Skript macht:**  
Erstellt eine Bibliothek für OpenSim (eine virtuelle Welt) mit Dateien und Ordnern.  
👉 *Für absolute Anfänger: Stell dir vor, du baust einen Katalog für digitale Objekte wie Bilder, Notizen und Skripte.*

---

### **Wichtige Funktionen (einfach erklärt)**  
| Funktion | Erklärung |  
|----------|-----------|  
| **Type hints** | Sagt dem Code, welche Art von Daten (Zahlen, Text etc.) erwartet wird → weniger Fehler |  
| **pathlib** | Moderner Weg, mit Dateipfaden umzugehen (besser als `os.path`) |  
| **argparse** | Verarbeitet Eingaben von der Kommandozeile (z. B. `--name MeineBibliothek`) |  
| **Sicherheit** | Schützt vor Hackern, die bösartige Dateipfade eingeben könnten |  
| **Context Manager** | Macht Dateioperationen (Öffnen/Schließen) sicherer → keine vergessenen offenen Dateien |  
| **Logging** | Schreibt Protokolle, was passiert (gut für Fehlersuche!) |  

---

### **Wie die Haupt-Klassen arbeiten**  
#### **1. `AssetSet` – Verwaltet digitale Objekte**  
- **Aufgabe**: Speichert Infos über Dateien (z. B. Texturen, Skripte).  
- **Wichtige Methoden**:  
  - `addasset()`: Fügt neue Datei hinzu (mit Name, Typ, UUID).  
  - `findbyfilename()`: Sucht Datei nach ihrem Namen.  

#### **2. `InvFolders` – Verwaltet Ordner**  
- **Aufgabe**: Erstellt die Ordner-Struktur in der Bibliothek.  
- **Wichtige Methoden**:  
  - `ensureexists()`: Erstellt Ordner, falls noch nicht da.  

#### **3. `InvItems` – Verwaltet Objekte in Ordnern**  
- **Aufgabe**: Verknüpft Dateien (`AssetSet`) mit Ordnern (`InvFolders`).  
- **Wichtige Methoden**:  
  - `ensureexists()`: Legt ein Objekt im richtigen Ordner ab.  

---

### **Wie man das Skript benutzt**  
**Beispiel-Befehl**:  
```bash
python library_generator.py --lib-name "Meine Bibliothek" --short-name meine_bib
```  

**Optionen**:  
- `--wipe-inventory`: Lösche alte Bibliothek und starte neu.  
- `--asset-dir`: Pfad zu den Dateien (z. B. Bilder/Skripte).  
- `--skip`: Überspringe bestimmte Dateien (z. B. `.git`).  

---

### **Für Neulinge: Wichtige Konzepte**  
| Begriff | Erklärung |  
|---------|-----------|  
| **UUID** | Eindeutige ID für jedes Objekt (wie ein Barcode) |  
| **Asset** | Digitale Datei (z. B. `.j2k` = Bild, `.lsl` = Skript) |  
| **Inventory** | "Bibliotheks-Katalog" mit Ordnern und Objekten |  
| **Nini XML** | Dateiformat für OpenSim-Bibliotheken |  

---

### **Fehlerbehandlung**  
- Das Skript **meldet Fehler** sofort (z. B. ungültige Dateien).  
- **Automatische Backups**: Bevor etwas überschrieben wird, gibt es eine Sicherungskopie.  

---

### **Beispiel: So wird eine Datei hinzugefügt**  
1. Benutzer gibt ein:  
   ```bash
   python library_generator.py --lib-name "Meine Bilder" --short-name bilder
   ```  
2. Skript:  
   - Sucht alle `.j2k`-Dateien im Ordner `assets/bilderAssetSet`.  
   - Erstellt einen Eintrag im "Katalog" (`AssetSet`).  
   - Legt die Datei in den richtigen Ordner (`InvFolders` + `InvItems`).  
"""

import argparse         # Für das Lesen von Befehlszeilen-Argumenten (z.B. --input datei.txt)
import logging          # Zum Schreiben von Log-Dateien (Fehlerprotokollierung)
import re               # Für reguläre Ausdrücke (Mustererkennung in Texten)
import shutil           # Für Dateioperationen (Kopieren, Verschieben von Dateien/Ordnern)
import stat             # Für Dateiberechtigungen (Lesen/Schreiben/Execute-Rechte)
import sys              # Für Systemfunktionen (z.B. Programm beenden)
import traceback        # Für detaillierte Fehlermeldungen
import uuid             # Zum Erzeugen einzigartiger IDs (z.B. für Objekte)
import xml.dom.minidom  # Zum Lesen/Schreiben von XML-Dateien

from contextlib import contextmanager  # Für sichere Ressourcenverwaltung (z.B. automatisches Schließen von Dateien)
from pathlib import Path              # Moderner Weg mit Dateipfaden zu arbeiten
from typing import (                 # Für Typ-Hinweise (macht Code lesbarer, aber optional):
    Dict,    # Für Wörterbücher {key: value}
    List,    # Für Listen [item1, item2]
    Optional, # Für Variablen die None sein können
    Tuple,   # Für Tupel (unveränderliche Listen)
    Iterator, # Für wiederholbare Objekte
    Any      # Für beliebige Datentypen
)

# Konstanten
# Eindeutige ID für den Wurzelordner der OpenSim-Bibliothek
OPENSIM_LIBRARY_ROOT_UUID = "00000112-000f-0000-0000-000100bba000"
# Standard-Berechtigungen (Vollzugriff in Hex: 0x7FFFFFFF)
DEFAULT_PERMISSIONS = "2147483647"  
# Kennzeichnet Ordner ohne Icon
FOLDER_TYPE_NO_ICON = -1

# Logging einrichten:
# - Level: INFO (zeigt wichtige Meldungen)
# - Format: "Zeit - Level - Nachricht"
# - Ausgabe: Fehlerausgabe (sys.stderr)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stderr)]
)

# Logger-Objekt für dieses Modul erstellen
logger = logging.getLogger(__name__)



class AssetExistsException(Exception):
    """Wird geworfen, wenn ein Asset bereits existiert"""
    def __init__(self, value: str):
        self.value = value  # Speichert die Fehlermeldung
        super().__init__(value)  # Ruft Basisklassen-Konstruktor auf

    def __str__(self) -> str:
        return repr(self.value)  # Gibt Fehlermeldung formatiert zurück


class InventoryException(Exception):
    """Wird bei Inventar-Fehlern geworfen"""
    # (Aufbau identisch zu AssetExistsException)
    def __init__(self, value: str):
        self.value = value
        super().__init__(value)

    def __str__(self) -> str:
        return repr(self.value)



class NiniSection:
    """Repräsentiert einen Abschnitt in einer Nini-XML-Datei"""
    
    def __init__(self, sectionname: str, keyvalues: Dict[str, str]):
        # Initialisiert mit:
        self._sectionname = sectionname  # Abschnittsname
        self._keyvalues = keyvalues     # Schlüssel-Wert-Paare als Dictionary

    # Eigenschaften (Properties):
    @property
    def name(self) -> str:
        return self._sectionname  # Gibt Abschnittsnamen zurück

    @property
    def keyvalues(self) -> Dict[str, str]:
        return self._keyvalues.copy()  # Kopie der Schlüssel-Wert-Paare

    # Methoden:
    def value(self, key: str) -> str:
        """Gibt Wert für einen Schlüssel zurück (oder leeren String)"""
        return self._keyvalues.get(key, "")

    def setvalue(self, key: str, value: str) -> None:
        """Setzt einen neuen Wert für einen Schlüssel"""
        self._keyvalues[key] = str(value)  # Wert wird immer als String gespeichert



class NiniException(Exception):
    """Spezialfehler für Nini-XML-Probleme"""
    # (Aufbau identisch zu AssetExistsException)
    def __init__(self, value: str):
        self.value = value
        super().__init__(value)

    def __str__(self) -> str:
        return repr(self.value)



class NiniThing:
    """Basisklasse zum Lesen/Schreiben von Nini-XML-Dateien"""
    
    def __init__(self, keynames: List[str], ninitype: str):
        # Schlüsselnamen, die in der XML-Datei erwartet werden
        self.keynames = keynames  
        # Typbeschreibung (für Fehlermeldungen)
        self.ninitype = ninitype  



    def readXML(self, filename: Path) -> List[NiniSection]:
        """Liest eine Nini-XML-Datei und gibt Abschnitte zurück"""
        sections = []  # Hier kommen die geparsten Daten rein

        # Datei existiert nicht? → Warnung + leere Liste
        if not filename.exists():
            logger.warning("%s-Datei %s existiert nicht!", self.ninitype, filename)
            return sections

        try:
            # Datei öffnen und parsen
            with filename.open('r', encoding='utf-8') as fh:
                xmlblob = xml.dom.minidom.parse(fh)  # XML in Speicher laden
                
                # Prüfe Root-Element
                topelem = xmlblob.documentElement
                if topelem.tagName != "Nini":
                    raise NiniException(f"{filename} ist keine Nini-Datei!")

                # Alle Abschnitte durchgehen
                for sec in topelem.childNodes:
                    if sec.nodeType == xml.dom.Node.ELEMENT_NODE:
                        if sec.tagName != 'Section':
                            raise NiniException(f"Abschnitt '{sec.tagName}' ungültig!")

                        # Neuen Abschnitt erstellen
                        item = NiniSection(sec.getAttribute("Name"), {})
                        
                        # Schlüssel mit Leerwerten vorbelegen
                        for keyname in self.keynames:
                            item.setvalue(keyname, "")

                        # Schlüssel-Werte-Paare extrahieren
                        for seckey in sec.childNodes:
                            if seckey.nodeType == xml.dom.Node.ELEMENT_NODE:
                                if seckey.tagName != "Key":
                                    raise NiniException(f"Schlüssel '{seckey.tagName}' ungültig!")
                                
                                item.setvalue(
                                    seckey.getAttribute("Name"),
                                    seckey.getAttribute("Value")
                                )

                        sections.append(item)
        except Exception as e:
            raise NiniException(f"Fehler beim Lesen von {filename}: {str(e)}")
        finally:
            xmlblob.unlink()  # Speicher freigeben

        return sections



    def writeXML(self, filename: Path, sections: List[NiniSection]) -> None:
        """Schreibt Daten in Nini-XML-Datei"""
        try:
            with filename.open('w', encoding='utf-8') as ofh:
                ofh.write("<Nini>\n")
                for item in sections:
                    # Abschnitt-Header
                    ofh.write(f'  <Section Name="{self._escape_xml(item.name)}">\n')
                    
                    # Alle Schlüssel-Werte-Paare
                    for keyname in self.keynames:
                        ofh.write(
                            f'    <Key Name="{self._escape_xml(keyname)}" '
                            f'Value="{self._escape_xml(item.value(keyname))}" />\n'
                        )
                    
                    ofh.write("  </Section>\n\n")
                ofh.write("</Nini>\n")
        except OSError as e:
            raise NiniException(f"Fehler beim Schreiben von {filename}: {str(e)}")



    @staticmethod
    def _escape_xml(text: str) -> str:
        """Ersetzt Sonderzeichen durch XML-Entities"""
        return (text.replace("&", "&amp;")
                  .replace("<", "&lt;")
                  .replace(">", "&gt;")
                  .replace('"', "&quot;"))



class AssetSet(NiniThing):
    """Verwaltet Asset-Metadaten (Dateien/Objekte)"""
    
    def __init__(self):
        # Initialisiert mit Standard-Schlüsseln für Assets
        super().__init__(
            ["assetID", "name", "assetType", "inventoryType", "fileName"],
            "Asset Set"
        )
        self.assets = []  # Liste aller Assets

    def __iter__(self):
        return iter(self.assets)  # Ermöglicht for-Schleifen über Assets

    def addasset(self, uuid_str: str, name: str, asstype: int, 
                invtype: int, filename: str) -> NiniSection:
        """Fügt ein neues Asset hinzu"""
        ass = NiniSection(
            filename,
            {
                'assetID': uuid_str,
                'name': name,
                'assetType': str(asstype),
                'inventoryType': str(invtype),
                'fileName': filename
            }
        )
        self.assets.append(ass)
        return ass

    def findbyfilename(self, filename: str) -> Optional[NiniSection]:
        """Sucht Asset nach Dateiname"""
        return next((a for a in self.assets if a.value('fileName') == filename), None)

    def findbyuuid(self, uuid_str: str) -> Optional[NiniSection]:
        """Sucht Asset nach UUID"""
        return next((a for a in self.assets if a.value('assetID') == uuid_str), None)



class InvFolders(NiniThing):
    """Verwaltet die Ordnerstruktur im Inventar"""
    
    def __init__(self):
        # Initialisiert mit Standard-Schlüsseln für Ordner
        super().__init__(
            ["folderID", "parentFolderID", "name", "type"],  # XML-Schlüssel
            "Inventory Folders"  # Typbezeichnung
        )
        self.folders = []  # Liste aller Ordner

    def __iter__(self):
        return iter(self.folders)  # Ermöglicht for-Schleifen über Ordner

    def findbyuuid(self, uuid_str: str) -> Optional[NiniSection]:
        """Findet Ordner anhand seiner UUID"""
        return next((f for f in self.folders if f.value('folderID') == uuid_str), None)

    def findbyname(self, name: str, parentid: str) -> Optional[NiniSection]:
        """Findet Ordner anhand von Name und Eltern-Ordner"""
        return next(
            (f for f in self.folders 
             if f.value('parentFolderID') == parentid and f.value('name') == name),
            None
        )

    def ensureexists(self, path: str, name: str, parentid: str) -> NiniSection:
        """Erstellt Ordner falls nicht vorhanden"""
        # Prüfe ob Eltern-Ordner existiert (außer Root)
        if parentid != OPENSIM_LIBRARY_ROOT_UUID and not self.findbyuuid(parentid):
            raise InventoryException(f"Eltern-Ordner existiert nicht: {parentid}")

        # Falls Ordner existiert: gib zurück
        if (folder := self.findbyname(name, parentid)) is not None:
            return folder

        # Neuen Ordner erstellen
        folder = NiniSection(
            path,
            {
                'folderID': str(uuid.uuid4()),  # Neue UUID generieren
                'parentFolderID': parentid,
                'name': name,
                'type': str(FOLDER_TYPE_NO_ICON)  # Ohne spezielles Icon
            }
        )
        self.folders.append(folder)
        return folder



class InvItems(NiniThing):
    """Verwaltet Objekte in Inventar-Ordnern"""
    
    def __init__(self, folders: InvFolders):
        # Initialisiert mit Standard-Schlüsseln für Objekte
        super().__init__(
            [
                "inventoryID", "assetID", "folderID", "name", "description",
                "assetType", "inventoryType", "currentPermissions",
                "nextPermissions", "everyonePermissions", "basePermissions"
            ],
            "Inventory Items"
        )
        self.folders = folders  # Referenz zur Ordnerstruktur
        self.items = []  # Liste aller Objekte

    def findbyinvid(self, uuid_str: str) -> Optional[NiniSection]:
        """Findet Objekt anhand Inventar-ID"""
        return next((i for i in self.items if i.value('inventoryID') == uuid_str), None)

    def findbyname(self, name: str, folderid: str) -> Optional[NiniSection]:
        """Findet Objekt anhand Namen im Ordner"""
        return next(
            (i for i in self.items 
             if i.value('name') == name and i.value('folderID') == folderid),
            None
        )

    def ensureexists(self, path: str, name: str, assetid: str, 
                    assettype: int, invtype: int, folderid: str) -> NiniSection:
        """Erstellt Objekt falls nicht vorhanden"""
        # Prüfe ob Zielordner existiert
        if folderid != OPENSIM_LIBRARY_ROOT_UUID and not self.folders.findbyuuid(folderid):
            raise InventoryException(f"Zielordner existiert nicht: {folderid}")

        # Falls Objekt existiert: gib zurück
        existing = next(
            (i for i in self.items 
             if (i.value('assetID') == assetid and 
                 i.value('folderID') == folderid and 
                 i.value('name') == name)),
            None
        )
        if existing:
            return existing

        # Neues Objekt erstellen
        item = NiniSection(
            path,
            {
                'inventoryID': str(uuid.uuid4()),
                'assetID': assetid,
                'folderID': folderid,
                'name': name,
                'description': "",
                'assetType': str(assettype),
                'inventoryType': str(invtype),
                'currentPermissions': DEFAULT_PERMISSIONS,  # Vollzugriff
                'nextPermissions': DEFAULT_PERMISSIONS,
                'everyonePermissions': DEFAULT_PERMISSIONS,
                'basePermissions': DEFAULT_PERMISSIONS
            }
        )
        self.items.append(item)
        return item


class LibraryGenerator:
    """
    Hauptklasse zur Generierung von OpenSim-Bibliotheken.
    Verarbeitet Dateiverzeichnisse und erstellt die benötigten XML-Dateien:
    - AssetSet.xml: Enthält alle Dateimetadaten
    - InvFolders.xml: Definiert die Ordnerstruktur
    - InvItems.xml: Verknüpft Assets mit Inventarordnern
    """

    def __init__(self, libname: str, shortname: str):
        """
        Initialisiert den Bibliotheks-Generator.
        
        Args:
            libname: Anzeigename der Bibliothek (z.B. "Meine Texturen")
            shortname: Kurzname für Dateien (ohne Leerzeichen/Sonderzeichen)
        """
        # Grundkonfiguration
        self.libname = libname    # Anzeigename der Bibliothek
        self.shortname = shortname  # Basis für Dateinamen
        
        # Pfadkonfiguration
        self.asset_dir = Path("assets") / f"{shortname}AssetSet"  # Quelle: Hier liegen die Asset-Dateien
        self.inv_dir = Path("inventory") / shortname  # Ziel: Hier werden XML-Dateien gespeichert
        
        # Dateinamen der Output-XMLs
        self.asset_xmlfile = f"{shortname}AssetSet.xml"  # Asset-Metadaten
        self.folders_xmlfile = f"{shortname}InvFolders.xml"  # Ordnerhierarchie
        self.items_xmlfile = f"{shortname}InvItems.xml"  # Inventareinträge
        
        # Systemkonfiguration
        self.skips = [r'^\.hg$', r'^\.git$', r'^\.svn$']  # Zu ignorierende Ordner (Regex)
        self.wipeinv = False  # True = Existierendes Inventar löschen vor Neuerstellung

        # Dateityp-Mapping (Erweiterung -> (assetType, inventoryType))
        self.file_types = {
            '.j2k': (0, 0),    # 0 = Texture, 0 = Texture
            '.txt': (7, 7),     # 7 = Notecard, 7 = Notecard
            '.lsl': (10, 10)    # 10 = LSL Text, 10 = Script
        }

        # RegEx-Patterns für die Verarbeitung
        self.endsinslash = re.compile(r'/$')  # Erkennung von Pfaden mit Endslash
        self.commentline = re.compile(r'^\s*#')  # Erkennung von Kommentarzeilen
        self.blankline = re.compile(r'^\s*$')  # Erkennung von Leerzeilen
        self.assetlistline = re.compile(
            r'^\s*([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'
            r'\s*(\d+)\s*(\d+)\s*(.*\S)\s*$'
        )  # Pattern für addassets.lis-Zeilen (UUID, AssetType, InvType, Name)

    def set_skip_patterns(self, skips: List[str]) -> None:
        """
        Setzt zusätzliche Ignorier-Muster für Dateien/Ordner.
        
        Args:
            skips: Liste von Regex-Patterns (z.B. [r'^temp_', r'\.bak$'])
        """
        self.skips = skips

    def set_asset_dir(self, asset_dir: Path) -> None:
        """
        Setzt ein benutzerdefiniertes Asset-Quellverzeichnis.
        
        Args:
            asset_dir: Pfad zum Verzeichnis mit den Asset-Dateien
        """
        self.asset_dir = Path(asset_dir)

    def set_inv_dir(self, inv_dir: Path) -> None:
        """
        Setzt ein benutzerdefiniertes Zielverzeichnis für die XML-Dateien.
        
        Args:
            inv_dir: Pfad zum Output-Verzeichnis
        """
        self.inv_dir = Path(inv_dir)

    def wipe_inventory(self) -> None:
        """Aktiviert den Wipe-Modus (löscht bestehende Inventardaten vor Neuerstellung)."""
        self.wipeinv = True

    @contextmanager
    def _backup_file(self, filepath: Path) -> Iterator[None]:
        """
        Context Manager für sichere Dateioperationen mit Backup.
        
        Erstellt vor Änderungen eine Kopie mit '-old' Suffix.
        
        Args:
            filepath: Zu sichernde Datei
        """
        if filepath.exists():
            backup_path = filepath.with_name(f"{filepath.name}-old")
            try:
                shutil.copy2(filepath, backup_path)
                logger.info("Backup erstellt: %s", backup_path)
            except OSError as e:
                logger.error("Backup fehlgeschlagen für %s: %s", filepath, e)
                raise
        yield
        logger.info("Datei gespeichert: %s", filepath)

    def run(self) -> None:
        """
        Hauptmethode zur Bibliotheksgenerierung.
        Durchläuft den kompletten Workflow:
        1. Initialisierung
        2. Laden existierender Daten (falls nicht im Wipe-Modus)
        3. Verarbeitung der Verzeichnisstruktur
        4. Speicherung der Ergebnisse
        """
        logger.info("Starte Generierung für Bibliothek '%s'", self.libname)

        # Datenstrukturen initialisieren
        self.assets = AssetSet()
        self.folders = InvFolders()
        self.items = InvItems(self.folders)

        # Existierende Daten laden (falls gewünscht)
        asset_xml_path = self.asset_dir / self.asset_xmlfile
        if asset_xml_path.exists():
            self.assets.readXML(asset_xml_path)

        if not self.wipeinv:
            folders_xml_path = self.inv_dir / self.folders_xmlfile
            items_xml_path = self.inv_dir / self.items_xmlfile
            
            if folders_xml_path.exists():
                self.folders.readXML(folders_xml_path)
            if items_xml_path.exists():
                self.items.readXML(items_xml_path)

        # Verzeichnisstruktur verarbeiten
        self._process_directory(OPENSIM_LIBRARY_ROOT_UUID, "", "")

        # Ergebnisse mit Backup-Mechanismus speichern
        try:
            with self._backup_file(asset_xml_path):
                self.assets.writeXML(asset_xml_path)

            with self._backup_file(self.inv_dir / self.folders_xmlfile):
                self.folders.writeXML(self.inv_dir / self.folders_xmlfile)

            with self._backup_file(self.inv_dir / self.items_xmlfile):
                self.items.writeXML(self.inv_dir / self.items_xmlfile)

            logger.info("Bibliotheksgenerierung erfolgreich abgeschlossen")
        except Exception as e:
            logger.error("Fehler beim Speichern: %s", e)
            raise

    def _should_skip(self, path: Path) -> bool:
        """
        Prüft, ob ein Datei/Ordner ignoriert werden soll.
        
        Args:
            path: Zu prüfender Pfad
            
        Returns:
            True wenn übersprungen werden soll
        """
        if any(re.search(pattern, path.name) for pattern in self.skips):
            return True
        if path.is_symlink():
            logger.warning("Symlink wird übersprungen: %s", path)
            return True
        return False

    def _detect_asset_type(self, filename: str) -> Optional[Tuple[int, int]]:
        """
        Ermittelt den Asset-Typ anhand der Dateiendung.
        
        Args:
            filename: Dateiname
            
        Returns:
            Tuple (assetType, inventoryType) oder None wenn unbekannt
        """
        ext = Path(filename).suffix.lower()
        return self.file_types.get(ext)

    def _process_directory(self, parent_uuid: str, dir_name: str, rel_path: str) -> None:
        """
        Verarbeitet ein Verzeichnis rekursiv.
        
        Args:
            parent_uuid: UUID des Elternordners
            dir_name: Name des aktuellen Verzeichnisses
            rel_path: Relativer Pfad vom Wurzelverzeichnis
        """
        abs_path = self.asset_dir / rel_path if rel_path else self.asset_dir
        logger.info("Verarbeite Verzeichnis: %s", abs_path)

        try:
            # Ordner im Inventar anlegen/abrufen
            folder_name = dir_name if dir_name else self.libname
            folder_path = rel_path if rel_path else self.libname
            cur_folder = self.folders.ensureexists(
                folder_path, folder_name, parent_uuid
            )
            folder_uuid = cur_folder.value("folderID")

            # Verzeichnisinhalt verarbeiten
            for entry in abs_path.iterdir():
                if self._should_skip(entry):
                    continue

                if entry.is_dir():
                    new_rel_path = str(Path(rel_path) / entry.name) if rel_path else entry.name
                    self._process_directory(folder_uuid, entry.name, new_rel_path)
                    continue

                self._process_file(entry, rel_path, folder_uuid)

            # Zusätzliche Assets aus addassets.lis verarbeiten
            addassets_path = abs_path / "addassets.lis"
            if addassets_path.exists():
                self._process_addassets_file(addassets_path, rel_path, folder_uuid)

        except Exception as e:
            logger.error("Fehler bei %s: %s", abs_path, e)
            raise

    def _process_file(self, filepath: Path, rel_path: str, folder_uuid: str) -> None:
        """
        Verarbeitet eine einzelne Datei.
        
        Args:
            filepath: Vollständiger Dateipfad
            rel_path: Relativer Pfad vom Asset-Root
            folder_uuid: Zielordner-UUID
        """
        # Systemdateien überspringen
        if filepath.name == self.asset_xmlfile or filepath.name == "addassets.lis":
            return

        # Dateityp ermitteln
        file_type = self._detect_asset_type(filepath.name)
        if file_type is None:
            logger.warning("Unbekannter Dateityp: %s", filepath.name)
            return

        asset_type, inv_type = file_type
        rel_filepath = str(Path(rel_path) / filepath.name) if rel_path else filepath.name

        # Asset erstellen/abrufen
        name = filepath.stem  # Dateiname ohne Erweiterung
        asset = self.assets.findbyfilename(rel_filepath)
        if asset is None:
            asset = self.assets.addasset(
                str(uuid.uuid4()), name, asset_type, asset_type, rel_filepath
            )

        # Inventareintrag erstellen
        self.items.ensureexists(
            str(Path(rel_path) / name) if rel_path else name,
            name,
            asset.value('assetID'),
            asset_type,
            inv_type,
            folder_uuid
        )

    def _process_addassets_file(self, filepath: Path, rel_path: str, folder_uuid: str) -> None:
        """
        Verarbeitet eine addassets.lis-Datei mit manuellen Asset-Definitionen.
        
        Args:
            filepath: Pfad zur addassets.lis
            rel_path: Relativer Pfad vom Asset-Root
            folder_uuid: Zielordner-UUID
        """
        logger.info("Verarbeite zusätzliche Assets aus: %s", filepath)
        
        try:
            with filepath.open('r', encoding='utf-8') as f:
                for line in f:
                    line = line.rstrip("\r\n")
                    if self.blankline.match(line) or self.commentline.match(line):
                        continue

                    match = self.assetlistline.match(line)
                    if not match:
                        logger.warning("Ungültige Zeile in %s: %s", filepath, line)
                        continue

                    uuid_str, asset_type, inv_type, name = match.groups()
                    self.items.ensureexists(
                        str(Path(rel_path) / name) if rel_path else name,
                        name,
                        uuid_str,
                        int(asset_type),
                        int(inv_type),
                        folder_uuid
                    )
        except OSError as e:
            logger.error("Lesefehler bei %s: %s", filepath, e)
            raise



def main() -> int:
    """
    Haupt-Einstiegspunkt für die Kommandozeile.
    Verarbeitet Argumente und startet die Bibliotheksgenerierung.
    
    Returns:
        int: Exit-Code (0 bei Erfolg, 20 bei Fehlern)
    """
    # Argumentparser initialisieren
    parser = argparse.ArgumentParser(
        description="OpenSim Bibliotheks-Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
Dokumentation: http://opensimulator.org/wiki/Custom_Libraries

Nach der Generierung müssen manuell folgende Schritte durchgeführt werden:
1. Asset-Verzeichnis in AssetSets.xml eintragen
2. Inventar-XMLs in Libraries.xml verlinken
"""
    )

    # Pflichtargumente
    parser.add_argument("-n", "--lib-name", required=True,
                      help="Anzeigename der Bibliothek (z.B. 'Meine Texturen')")
    parser.add_argument("-s", "--short-name", required=True,
                      help="Kurzname für Dateien (ohne Leerzeichen, z.B. 'texturen')")

    # Optionale Argumente
    parser.add_argument("-w", "--wipe-inventory", action="store_true",
                      help="Existierendes Inventar vor Generierung löschen")
    parser.add_argument("-a", "--asset-dir", type=Path,
                      help="Alternatives Asset-Verzeichnis (Standard: assets/[Kurzname]AssetSet)")
    parser.add_argument("-i", "--inv-dir", type=Path,
                      help="Alternatives Zielverzeichnis für XMLs (Standard: inventory/[Kurzname])")
    parser.add_argument("--skip", action="append",
                      help="Zusätzliche Regex-Muster für zu ignorierende Dateien/Ordner")
    parser.add_argument("--debug", action="store_true",
                      help="Debug-Logging aktivieren (detaillierte Ausgaben)")

    args = parser.parse_args()

    try:
        # Logging konfigurieren
        logging.basicConfig(
            level=logging.DEBUG if args.debug else logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            handlers=[logging.StreamHandler(sys.stderr)]  # Ausgabe auf stderr
        )

        # Generator initialisieren
        generator = LibraryGenerator(args.lib_name, args.short_name)

        # Optionen setzen
        if args.wipe_inventory:
            generator.wipe_inventory()  # Löschmodus aktivieren

        if args.asset_dir:
            generator.set_asset_dir(args.asset_dir)  # Custom Asset-Pfad
        if args.inv_dir:
            generator.set_inv_dir(args.inv_dir)  # Custom Output-Pfad
        if args.skip:
            generator.set_skip_patterns(args.skip)  # Ignorier-Muster hinzufügen

        # Generierung starten
        generator.run()
        return 0  # Erfolg

    except Exception as e:
        logger.critical(
            "Schwerer Fehler: %s%s",
            e,
            traceback.format_exc() if args.debug else ""
        )
        return 20  # Fehlercode

if __name__ == "__main__":
    sys.exit(main())  # Exit-Code an Shell zurückgeben