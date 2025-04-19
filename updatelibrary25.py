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

import argparse
import logging
import re
import shutil
import stat
import sys
import traceback
import uuid
import xml.dom.minidom
from contextlib import contextmanager
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Iterator, Any

# Constants
OPENSIM_LIBRARY_ROOT_UUID = "00000112-000f-0000-0000-000100bba000"
DEFAULT_PERMISSIONS = "2147483647"  # 0x7FFFFFFF (full permissions)
FOLDER_TYPE_NO_ICON = -1

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stderr)]
)
logger = logging.getLogger(__name__)



class AssetExistsException(Exception):
    """Raised when an asset already exists"""
    def __init__(self, value: str):
        self.value = value
        super().__init__(value)

    def __str__(self) -> str:
        return repr(self.value)



class InventoryException(Exception):
    """Raised for inventory-related errors"""
    def __init__(self, value: str):
        self.value = value
        super().__init__(value)

    def __str__(self) -> str:
        return repr(self.value)



class NiniSection:
    """Represents a section in Nini XML file"""
    def __init__(self, sectionname: str, keyvalues: Dict[str, str]):
        self._sectionname = sectionname
        self._keyvalues = keyvalues

    @property
    def name(self) -> str:
        return self._sectionname

    @property
    def keyvalues(self) -> Dict[str, str]:
        return self._keyvalues.copy()

    def value(self, key: str) -> str:
        return self._keyvalues.get(key, "")

    def setvalue(self, key: str, value: str) -> None:
        self._keyvalues[key] = str(value)



class NiniException(Exception):
    """Custom exception for Nini-related errors"""
    def __init__(self, value: str):
        self.value = value
        super().__init__(value)

    def __str__(self) -> str:
        return repr(self.value)



class NiniThing:
    """Base class for Nini XML file handlers"""
    def __init__(self, keynames: List[str], ninitype: str):
        self.keynames = keynames
        self.ninitype = ninitype



    def readXML(self, filename: Path) -> List[NiniSection]:
        """Read and parse Nini XML file"""
        sections: List[NiniSection] = []

        if not filename.exists():
            logger.warning("%s file %s doesn't exist. Returning empty list.", 
                          self.ninitype, filename)
            return sections

        try:
            with filename.open('r', encoding='utf-8') as fh:
                xmlblob = xml.dom.minidom.parse(fh)
        except (xml.parsers.expat.ExpatError, OSError) as e:
            raise NiniException(f"Error parsing {filename}: {str(e)}")

        try:
            topelem = xmlblob.documentElement
            if topelem.tagName != "Nini":
                raise NiniException(f"Error not a Nini file: {filename}")

            for sec in topelem.childNodes:
                if sec.nodeType == xml.dom.Node.ELEMENT_NODE:
                    if sec.tagName != 'Section':
                        raise NiniException(
                            f"Error {self.ninitype} file: expecting 'Section', found '{sec.tagName}'"
                        )

                    item = NiniSection(sec.getAttribute("Name"), {})
                    for keyname in self.keynames:
                        item.setvalue(keyname, "")

                    for seckey in sec.childNodes:
                        if seckey.nodeType == xml.dom.Node.ELEMENT_NODE:
                            if seckey.tagName != "Key":
                                raise NiniException(
                                    f"Error reading {self.ninitype}: expecting 'Key', found '{seckey.tagName}'"
                                )
                            item.setvalue(
                                seckey.getAttribute("Name"),
                                seckey.getAttribute("Value")
                            )

                    sections.append(item)
        finally:
            xmlblob.unlink()

        return sections



    def writeXML(self, filename: Path, sections: List[NiniSection]) -> None:
        """Write data to Nini XML file"""
        try:
            with filename.open('w', encoding='utf-8') as ofh:
                ofh.write("<Nini>\n")
                for item in sections:
                    ofh.write(f'  <Section Name="{self._escape_xml(item.name)}">\n')
                    for keyname in self.keynames:
                        ofh.write(
                            f'    <Key Name="{self._escape_xml(keyname)}" '
                            f'Value="{self._escape_xml(item.value(keyname))}" />\n'
                        )
                    ofh.write("  </Section>\n\n")
                ofh.write("</Nini>\n")
        except OSError as e:
            raise NiniException(f"Error writing {filename}: {str(e)}")



    @staticmethod
    def _escape_xml(text: str) -> str:
        """Escape XML special characters"""
        return (text.replace("&", "&amp;")
                  .replace("<", "&lt;")
                  .replace(">", "&gt;")
                  .replace('"', "&quot;"))



class AssetSet(NiniThing):
    """Handles asset metadata"""
    def __init__(self):
        super().__init__(
            ["assetID", "name", "assetType", "inventoryType", "fileName"],
            "Asset Set"
        )
        self.assets: List[NiniSection] = []



    def __iter__(self) -> Iterator[NiniSection]:
        return iter(self.assets)



    def addasset(self, uuid_str: str, name: str, asstype: int, 
                invtype: int, filename: str) -> NiniSection:
        """Add a new asset to the collection"""
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
        """Find asset by filename"""
        return next(
            (ass for ass in self.assets if ass.value('fileName') == filename),
            None
        )



    def findbyuuid(self, uuid_str: str) -> Optional[NiniSection]:
        """Find asset by UUID"""
        return next(
            (ass for ass in self.assets if ass.value('assetID') == uuid_str),
            None
        )



class InvFolders(NiniThing):
    """Handles inventory folder structure"""
    def __init__(self):
        super().__init__(
            ["folderID", "parentFolderID", "name", "type"],
            "Inventory Folders"
        )
        self.folders: List[NiniSection] = []



    def __iter__(self) -> Iterator[NiniSection]:
        return iter(self.folders)



    def findbyuuid(self, uuid_str: str) -> Optional[NiniSection]:
        """Find folder by UUID"""
        return next(
            (f for f in self.folders if f.value('folderID') == uuid_str),
            None
        )



    def findbyname(self, name: str, parentid: str) -> Optional[NiniSection]:
        """Find folder by name under parent"""
        return next(
            (f for f in self.folders 
             if f.value('parentFolderID') == parentid and f.value('name') == name),
            None
        )



    def ensureexists(self, path: str, name: str, parentid: str) -> NiniSection:
        """Ensure folder exists or create it"""
        if (parentid != OPENSIM_LIBRARY_ROOT_UUID and 
            not self.findbyuuid(parentid)):
            raise InventoryException(f"No such parent folder exists: {parentid}")

        if (folder := self.findbyname(name, parentid)) is not None:
            return folder

        folder = NiniSection(
            path,
            {
                'folderID': str(uuid.uuid4()),
                'parentFolderID': parentid,
                'name': name,
                'type': str(FOLDER_TYPE_NO_ICON)
            }
        )
        self.folders.append(folder)
        return folder



class InvItems(NiniThing):
    """Handles inventory items"""
    def __init__(self, folders: InvFolders):
        super().__init__(
            [
                "inventoryID", "assetID", "folderID", "name", "description",
                "assetType", "inventoryType", "currentPermissions",
                "nextPermissions", "everyonePermissions", "basePermissions"
            ],
            "Inventory Items"
        )
        self.folders = folders
        self.items: List[NiniSection] = []



    def findbyinvid(self, uuid_str: str) -> Optional[NiniSection]:
        """Find item by inventory ID"""
        return next(
            (i for i in self.items if i.value('inventoryID') == uuid_str),
            None
        )



    def findbyname(self, name: str, folderid: str) -> Optional[NiniSection]:
        """Find item by name in folder"""
        return next(
            (i for i in self.items 
             if i.value('name') == name and i.value('folderID') == folderid),
            None
        )



    def ensureexists(self, path: str, name: str, assetid: str, 
                    assettype: int, invtype: int, folderid: str) -> NiniSection:
        """Ensure item exists or create it"""
        if (folderid != OPENSIM_LIBRARY_ROOT_UUID and 
            not self.folders.findbyuuid(folderid)):
            raise InventoryException(f"No such folder for item: {folderid}")

        existing = next(
            (i for i in self.items 
             if (i.value('assetID') == assetid and 
                 i.value('folderID') == folderid and 
                 i.value('name') == name)),
            None
        )
        if existing is not None:
            return existing

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
                'currentPermissions': DEFAULT_PERMISSIONS,
                'nextPermissions': DEFAULT_PERMISSIONS,
                'everyonePermissions': DEFAULT_PERMISSIONS,
                'basePermissions': DEFAULT_PERMISSIONS
            }
        )
        self.items.append(item)
        return item



class LibraryGenerator:
    """Main library generator class"""
    def __init__(self, libname: str, shortname: str):
        self.libname = libname
        self.shortname = shortname
        self.asset_dir = Path("assets") / f"{shortname}AssetSet"
        self.inv_dir = Path("inventory") / shortname
        self.asset_xmlfile = f"{shortname}AssetSet.xml"
        self.folders_xmlfile = f"{shortname}InvFolders.xml"
        self.items_xmlfile = f"{shortname}InvItems.xml"
        self.skips = [r'^\.hg$', r'^\.git$', r'^\.svn$']
        self.wipeinv = False

        # File type detection configuration
        self.file_types = {
            '.j2k': (0, 0),    # Texture
            '.txt': (7, 7),     # Notecard
            '.lsl': (10, 10)    # LSL script
        }

        # Compiled regex patterns
        self.endsinslash = re.compile(r'/$')
        self.commentline = re.compile(r'^\s*#')
        self.blankline = re.compile(r'^\s*$')
        self.assetlistline = re.compile(
            r'^\s*([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'
            r'\s*(\d+)\s*(\d+)\s*(.*\S)\s*$'
        )



    def set_skip_patterns(self, skips: List[str]) -> None:
        """Set patterns for files/directories to skip"""
        self.skips = skips



    def set_asset_dir(self, asset_dir: Path) -> None:
        """Set asset directory path"""
        self.asset_dir = Path(asset_dir)



    def set_inv_dir(self, inv_dir: Path) -> None:
        """Set inventory directory path"""
        self.inv_dir = Path(inv_dir)



    def wipe_inventory(self) -> None:
        """Flag to wipe existing inventory"""
        self.wipeinv = True



    @contextmanager
    def _backup_file(self, filepath: Path) -> Iterator[None]:
        """Context manager for creating backup files"""
        if filepath.exists():
            backup_path = filepath.with_name(f"{filepath.name}-old")
            try:
                shutil.copy2(filepath, backup_path)
                logger.info("Created backup: %s", backup_path)
            except OSError as e:
                logger.error("Failed to create backup for %s: %s", filepath, e)
                raise
        yield
        logger.info("Saved file: %s", filepath)



    def run(self) -> None:
        """Main execution method"""
        logger.info("Starting library generation for '%s'", self.libname)

        # Initialize data structures
        self.assets = AssetSet()
        self.folders = InvFolders()
        self.items = InvItems(self.folders)

        # Load existing data if not wiping inventory
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

        # Process directory structure
        self._process_directory(OPENSIM_LIBRARY_ROOT_UUID, "", "")

        # Save results with backups
        try:
            with self._backup_file(asset_xml_path):
                self.assets.writeXML(asset_xml_path)

            with self._backup_file(self.inv_dir / self.folders_xmlfile):
                self.folders.writeXML(self.inv_dir / self.folders_xmlfile)

            with self._backup_file(self.inv_dir / self.items_xmlfile):
                self.items.writeXML(self.inv_dir / self.items_xmlfile)

            logger.info("Library generation completed successfully")
        except Exception as e:
            logger.error("Failed to save library data: %s", e)
            raise



    def _should_skip(self, path: Path) -> bool:
        """Check if path should be skipped"""
        if any(re.search(pattern, path.name) for pattern in self.skips):
            return True
        if path.is_symlink():
            logger.warning("Skipping symlink: %s", path)
            return True
        return False



    def _detect_asset_type(self, filename: str) -> Optional[Tuple[int, int]]:
        """Determine asset type based on file extension"""
        ext = Path(filename).suffix.lower()
        return self.file_types.get(ext)



    def _process_directory(self, parent_uuid: str, dir_name: str, rel_path: str) -> None:
        """Recursively process a directory"""
        abs_path = self.asset_dir / rel_path if rel_path else self.asset_dir
        logger.info("Processing directory: %s", abs_path)

        try:
            # Ensure folder exists in inventory
            folder_name = dir_name if dir_name else self.libname
            folder_path = rel_path if rel_path else self.libname
            cur_folder = self.folders.ensureexists(
                folder_path, folder_name, parent_uuid
            )
            folder_uuid = cur_folder.value("folderID")

            # Process directory contents
            for entry in abs_path.iterdir():
                if self._should_skip(entry):
                    continue

                if entry.is_dir():
                    new_rel_path = str(Path(rel_path) / entry.name) if rel_path else entry.name
                    self._process_directory(folder_uuid, entry.name, new_rel_path)
                    continue

                self._process_file(entry, rel_path, folder_uuid)

            # Process additional assets list if present
            addassets_path = abs_path / "addassets.lis"
            if addassets_path.exists():
                self._process_addassets_file(addassets_path, rel_path, folder_uuid)

        except Exception as e:
            logger.error("Error processing %s: %s", abs_path, e)
            raise



    def _process_file(self, filepath: Path, rel_path: str, folder_uuid: str) -> None:
        """Process an individual file"""
        # Skip special files
        if filepath.name == self.asset_xmlfile:
            return
        if filepath.name == "addassets.lis":
            return

        # Determine file type
        file_type = self._detect_asset_type(filepath.name)
        if file_type is None:
            logger.warning("Skipping unrecognized file: %s", filepath.name)
            return

        asset_type, inv_type = file_type
        rel_filepath = str(Path(rel_path) / filepath.name) if rel_path else filepath.name

        # Strip extension (assumes 3-char extension like .j2k, .lsl)
        name = filepath.stem

        # Create or find asset entry
        asset = self.assets.findbyfilename(rel_filepath)
        if asset is None:
            asset = self.assets.addasset(
                str(uuid.uuid4()), name, asset_type, asset_type, rel_filepath
            )

        # Create inventory item
        self.items.ensureexists(
            str(Path(rel_path) / name) if rel_path else name,
            name,
            asset.value('assetID'),
            asset_type,
            inv_type,
            folder_uuid
        )



    def _process_addassets_file(self, filepath: Path, rel_path: str, folder_uuid: str) -> None:
        """Process addassets.lis file"""
        logger.info("Processing additional assets from: %s", filepath)
        
        try:
            with filepath.open('r', encoding='utf-8') as f:
                for line in f:
                    line = line.rstrip("\r\n")
                    if self.blankline.match(line) or self.commentline.match(line):
                        continue

                    match = self.assetlistline.match(line)
                    if not match:
                        logger.warning("Error parsing line in %s: %s", filepath, line)
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
            logger.error("Error reading %s: %s", filepath, e)
            raise



def main() -> int:
    """Command line entry point"""
    parser = argparse.ArgumentParser(
        description="OpenSim Library Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
Documentation: http://opensimulator.org/wiki/Custom_Libraries

After generation, you must manually:
1. Add your asset directory to AssetSets.xml
2. Add your inventory XML files to Libraries.xml
"""
    )

    parser.add_argument("-n", "--lib-name", required=True,
                       help="Display name of your library")
    parser.add_argument("-s", "--short-name", required=True,
                       help="Short name for files (no spaces)")
    parser.add_argument("-w", "--wipe-inventory", action="store_true",
                       help="Wipe existing inventory and start fresh")
    parser.add_argument("-a", "--asset-dir", type=Path,
                       help="Asset directory (default: assets/[shortname]AssetSet)")
    parser.add_argument("-i", "--inv-dir", type=Path,
                       help="Inventory directory (default: inventory/[shortname])")
    parser.add_argument("--skip", action="append",
                       help="Additional regex patterns for files/dirs to skip")
    parser.add_argument("--debug", action="store_true",
                       help="Enable debug logging")

    args = parser.parse_args()

    try:
        # Configure logging
        logging.basicConfig(
            level=logging.DEBUG if args.debug else logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            handlers=[logging.StreamHandler(sys.stderr)]
        )

        # Initialize generator
        generator = LibraryGenerator(args.lib_name, args.short_name)

        if args.wipe_inventory:
            generator.wipe_inventory()

        if args.asset_dir:
            generator.set_asset_dir(args.asset_dir)
        if args.inv_dir:
            generator.set_inv_dir(args.inv_dir)
        if args.skip:
            generator.set_skip_patterns(args.skip)

        # Run generation
        generator.run()
        return 0

    except Exception as e:
        logger.critical("Fatal error: %s", e, exc_info=args.debug)
        return 20

if __name__ == "__main__":
    sys.exit(main())