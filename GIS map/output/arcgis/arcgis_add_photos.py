"""Attach the tree photos to the trees feature class (run once in ArcGIS Pro).

ArcGIS Pro: Analysis > Python > Python Window, then:
    exec(open(r"<path to this folder>\\arcgis_add_photos.py").read())
or right-click the file in the Catalog pane > Open in Python window, and Run.
Uses only standard tools: Enable Attachments + Add Attachments.
"""
import os

import arcpy

HERE = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()
fc = os.path.join(HERE, "swecc004_field_map.gdb", "trees")
table = os.path.join(HERE, "photo_match_table.csv")
photos = os.path.join(HERE, "photos")
for p in (fc, table, photos):
    if not arcpy.Exists(p) and not os.path.exists(p):
        raise SystemExit("Not found: " + p + " (keep this script next to the .gdb, photos and csv)")
if arcpy.Exists(fc + "__ATTACH") and int(arcpy.management.GetCount(fc + "__ATTACH")[0]) > 0:
    raise SystemExit("Photos are already attached; nothing to do.")
arcpy.management.EnableAttachments(fc)
arcpy.management.AddAttachments(fc, "id", table, "id", "photo", photos)
n = int(arcpy.management.GetCount(fc + "__ATTACH")[0])
print("Attached", n, "photos to", fc)
