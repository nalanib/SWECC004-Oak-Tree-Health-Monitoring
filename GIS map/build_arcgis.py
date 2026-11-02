"""Export the cleaned field map for ArcGIS (Pro / Online).

Run after build_gis_map.py:   python3 build_arcgis.py
Writes output/arcgis/:
  swecc004_field_map.gdb      file geodatabase, EPSG:28992 (RD New):
                              habitat_polygons, paths, trees, study_area_extent
  swecc004_field_map_gdb.zip  the same .gdb zipped (upload to ArcGIS Online)
  photos/ + photo_match_table.csv + arcgis_add_photos.py
                              attach each tree photo in ArcGIS Pro
  README_ArcGIS.txt
"""
import os
import shutil
import zipfile

import geopandas as gpd
import pyogrio

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "output")
GPKG = os.path.join(OUT, "swecc004_field_map.gpkg")
DST = os.path.join(OUT, "arcgis")
GDB = os.path.join(DST, "swecc004_field_map.gdb")

if os.path.exists(DST):
    shutil.rmtree(DST)
os.makedirs(DST)

layers = ["habitat_polygons", "paths", "trees", "study_area_extent"]
src = {}
for name in layers:
    df = gpd.read_file(GPKG, layer=name)
    assert df.crs.to_epsg() == 28992
    for c in df.columns:  # FGDB has no boolean type: write yes/no text
        if df[c].dtype == bool:
            df[c] = df[c].map({True: "yes", False: "no"})
        elif str(df[c].dtype) == "int64":
            df[c] = df[c].astype("int32")
    src[name] = df
    df.to_file(GDB, layer=name, driver="OpenFileGDB")

# read back and compare
for name, df in src.items():
    back = gpd.read_file(GDB, layer=name)
    assert len(back) == len(df), name
    assert back.crs.to_epsg() == 28992, name
    # FGDB snaps vertices to a 0.1 mm grid; allow 1 mm
    assert max(a.hausdorff_distance(b) for a, b in zip(df.geometry, back.geometry)) < 0.001, name
    assert list(back["id"]) == list(df["id"]) if "id" in df else True
print("gdb layers:", pyogrio.list_layers(GDB).tolist())

# zipped gdb for ArcGIS Online (zip must contain the .gdb folder)
with zipfile.ZipFile(os.path.join(DST, "swecc004_field_map_gdb.zip"), "w", zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk(GDB):
        for f in files:
            p = os.path.join(root, f)
            z.write(p, os.path.relpath(p, DST))

# photos + match table for the Add Attachments tool
trees = src["trees"]
os.makedirs(os.path.join(DST, "photos"))
with open(os.path.join(DST, "photo_match_table.csv"), "w") as f:
    f.write("id,photo\n")
    for _, r in trees.iterrows():
        shutil.copy2(os.path.join(OUT, r.photo), os.path.join(DST, r.photo))
        f.write(f"{r.id},{os.path.basename(r.photo)}\n")

with open(os.path.join(DST, "arcgis_add_photos.py"), "w") as f:
    f.write('''"""Attach the tree photos to the trees feature class (run once in ArcGIS Pro).

ArcGIS Pro: Analysis > Python > Python Window, then:
    exec(open(r"<path to this folder>\\\\arcgis_add_photos.py").read())
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
''')

with open(os.path.join(DST, "README_ArcGIS.txt"), "w") as f:
    f.write("""SWECC004 field map - ArcGIS
==========================
All layers are in Amersfoort / RD New (EPSG:28992).

ArcGIS Pro
1. Unzip this folder somewhere local (not inside the zip).
2. Catalog pane > Add Folder Connection > this folder.
   Expand swecc004_field_map.gdb and drag the 4 feature classes onto a map.
3. Basemap: Map tab > Basemap > Imagery (or add the Dutch aerial photo:
   Add Data > Data From Path >
   https://service.pdok.nl/hwh/luchtfotorgb/wmts/v1_0/WMTSCapabilities.xml ).
4. Tree photos (once): open arcgis_add_photos.py in the Python window and run it.
   It enables attachments on 'trees' and adds the photo for each tree (match on id).
   Click a tree to see its photo in the pop-up.
5. Suggested symbology: habitat_polygons > Unique Values on 'id' (or 'label');
   label trees with  $feature.id + " " + $feature.species

ArcGIS Online
- Content > New item > upload swecc004_field_map_gdb.zip (File Geodatabase)
  > create a hosted feature layer. For photos, first do step 4 in Pro and then
  Share > Web Layer from Pro instead.

Fields on 'trees': species, height_m, dbh_cm, breast_height_m, inclination_deg,
arboreal_time_local, arboreal_accuracy_m, arboreal_lat/lon, offset_arboreal_m,
photo, qa_note (see README.md for the checks and QA notes).
""")
print("wrote", DST)
