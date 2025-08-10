#!/usr/bin/env python3

import os
import xml.etree.ElementTree as ET
from urllib.parse import unquote, quote

home = os.path.expanduser("~")
gtk_bookmarks_file = os.path.join(home, ".config/gtk-3.0/bookmarks")
dolphin_bookmarks_file = os.path.join(home, ".local/share/user-places.xbel")

try:
    with open(gtk_bookmarks_file, "r") as f:
        gtk_bookmarks = [line.strip() for line in f if line.strip()]
except FileNotFoundError:
    print("GTK bookmarks file not found. Exiting.")
    exit()

try:
    tree = ET.parse(dolphin_bookmarks_file)
    root = tree.getroot()
except (FileNotFoundError, ET.ParseError):
    # If Dolphin's file doesn't exist or is empty, create a basic structure
    root = ET.Element("xbel", version="1.0")
    tree = ET.ElementTree(root)

# Get a set of existing Dolphin bookmark URLs for easy lookup
existing_dolphin_hrefs = {bm.get("href") for bm in root.findall("bookmark")}

print("Syncing GTK bookmarks to Dolphin...")
added_count = 0
for bookmark in gtk_bookmarks:
    parts = bookmark.split(maxsplit=1)
    uri = parts[0]

    if not uri.startswith("file://"):
        continue  # Skip non-file bookmarks

    # Check if this bookmark already exists in Dolphin
    if uri in existing_dolphin_hrefs:
        print(f"Skipping existing bookmark: {uri}")
        continue

    # If not, add it
    path = unquote(uri.replace("file://", ""))
    # Use the provided name or fallback to the folder/file name
    name = parts[1] if len(parts) > 1 else os.path.basename(path.rstrip("/"))

    print(f"Adding '{name}' to Dolphin.")

    # Create new bookmark element
    new_bookmark = ET.Element("bookmark", href=uri)
    title = ET.SubElement(new_bookmark, "title")
    title.text = name
    root.append(new_bookmark)
    added_count += 1

if added_count > 0:
    # The 'indent' argument pretty-prints the XML
    tree.write(
        dolphin_bookmarks_file,
        encoding="UTF-8",
        xml_declaration=True,
        short_empty_elements=False,
    )
    print(f"\nSync complete. Added {added_count} new bookmark(s) to Dolphin.")
else:
    print("\nEverything is already in sync.")
