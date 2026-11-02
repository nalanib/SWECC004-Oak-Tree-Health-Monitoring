"""SWECC004 field map: one-step import into ArcGIS Pro.

In ArcGIS Pro (with a project open): View tab > Python window, paste this ONE
line (change the path to where you unzipped swecc004_arcgis) and press Enter:

    p = r"C:\\Users\\you\\Downloads\\swecc004_arcgis\\arcgis_import_all.py"; exec(open(p).read(), {"__file__": p})

It will:
  1. attach the tree photos to the trees layer (once; skipped if already done)
  2. add the 4 layers to the active map (or a new map) in RD New (EPSG:28992)
  3. colour and label them, add the Imagery basemap, zoom to the study area
Each styling step is wrapped so that, if your Pro version differs, the layers
are still added and the script tells you what it skipped. Save the project
yourself afterwards (Ctrl+S).
"""
import os

import arcpy

HERE = os.path.dirname(os.path.abspath(__file__))
GDB = os.path.join(HERE, "swecc004_field_map.gdb")
if not arcpy.Exists(GDB):
    raise SystemExit("Geodatabase not found: " + GDB + "  (run this file from the unzipped swecc004_arcgis folder)")
fc = lambda name: os.path.join(GDB, name)
skipped = []

# 1. photos as attachments ----------------------------------------------------
trees_fc = fc("trees")
table = os.path.join(HERE, "photo_match_table.csv")
photos = os.path.join(HERE, "photos")
try:
    if arcpy.Exists(trees_fc + "__ATTACH") and int(arcpy.management.GetCount(trees_fc + "__ATTACH")[0]) > 0:
        print("Photos already attached.")
    else:
        arcpy.management.EnableAttachments(trees_fc)
        arcpy.management.AddAttachments(trees_fc, "id", table, "id", "photo", photos)
        print("Attached", arcpy.management.GetCount(trees_fc + "__ATTACH")[0], "photos.")
except Exception as e:
    skipped.append("photo attachments (" + str(e).splitlines()[0] + ")")

# 2. map and layers -----------------------------------------------------------
aprx = arcpy.mp.ArcGISProject("CURRENT")
m = aprx.activeMap
if m is None:
    m = aprx.createMap("SWECC004 field map")
m.spatialReference = arcpy.SpatialReference(28992)
try:
    m.addBasemap("Imagery")
except Exception as e:
    skipped.append("Imagery basemap (" + str(e).splitlines()[0] + ")")

layers = {}
for name in ("study_area_extent", "habitat_polygons", "paths", "trees"):
    layers[name] = m.addDataFromPath(fc(name))
print("Added layers:", ", ".join(layers))

# 3. symbology and labels -----------------------------------------------------
COL = {"g01": (79, 155, 217), "g02": (185, 178, 165), "g03": (158, 208, 127), "g04": (227, 194, 107),
       "g05": (111, 174, 106), "g06": (201, 160, 214), "g07": (63, 127, 79)}
LABEL = {"g01": "pond", "g02": "gravel (outside planned area)", "g03": "mostly mowed", "g04": "Orion",
         "g05": "unmowed shrubs", "g06": "Atlas, unmowed", "g07": "unmowed trees/shrubs (outside planned area)"}


def style(name, fn):
    try:
        lyr = layers[name]
        sym = lyr.symbology
        fn(lyr, sym)
        lyr.symbology = sym
    except Exception as e:
        skipped.append(name + " symbology (" + str(e).splitlines()[0] + ")")


def polys(lyr, sym):
    sym.updateRenderer("UniqueValueRenderer")
    sym.renderer.fields = ["id"]
    for grp in sym.renderer.groups:
        for itm in grp.items:
            v = itm.values[0][0]
            r, g, b = COL.get(v, (200, 200, 200))
            itm.symbol.color = {"RGB": [r, g, b, 60]}
            itm.symbol.outlineColor = {"RGB": [32, 32, 32, 100]}
            itm.symbol.outlineWidth = 1
            itm.label = v + " " + LABEL.get(v, "")


def paths(lyr, sym):
    sym.updateRenderer("SimpleRenderer")
    sym.renderer.symbol.color = {"RGB": [192, 57, 43, 100]}
    sym.renderer.symbol.size = 2.5  # line width in points


def trees(lyr, sym):
    sym.updateRenderer("SimpleRenderer")
    sym.renderer.symbol.color = {"RGB": [20, 90, 50, 100]}
    sym.renderer.symbol.size = 9


def extent(lyr, sym):
    sym.updateRenderer("SimpleRenderer")
    sym.renderer.symbol.color = {"RGB": [0, 0, 0, 0]}
    sym.renderer.symbol.outlineColor = {"RGB": [255, 204, 0, 100]}
    sym.renderer.symbol.outlineWidth = 2


style("habitat_polygons", polys)
style("paths", paths)
style("trees", trees)
style("study_area_extent", extent)


def labels(name, arcade):
    try:
        lyr = layers[name]
        lc = lyr.listLabelClasses()[0]
        lc.expressionEngine = "Arcade"
        lc.expression = arcade
        lyr.showLabels = True
    except Exception as e:
        skipped.append(name + " labels (" + str(e).splitlines()[0] + ")")


labels("habitat_polygons", '$feature.id + TextFormatting.NewLine + $feature.label')
labels("paths", '$feature.id')
labels("trees", '$feature.id + " " + Replace(Split($feature.species, " (")[0], " unknown", "")')

# 4. zoom to the study area ---------------------------------------------------
try:
    view = aprx.activeView
    ext = arcpy.Describe(fc("study_area_extent")).extent
    view.camera.setExtent(ext)
except Exception as e:
    skipped.append("zoom (" + str(e).splitlines()[0] + "); right-click a layer > Zoom To Layer")

print("Done.")
if skipped:
    print("Skipped (do these by hand if needed):")
    for s in skipped:
        print("  -", s)
print("Save the project with Ctrl+S. Click a tree to see its photo and measurements.")
