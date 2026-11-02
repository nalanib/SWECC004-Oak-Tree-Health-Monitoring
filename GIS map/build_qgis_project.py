"""Build a ready-to-open QGIS project for the SWECC004 field map.

Run (after build_gis_map.py), with the QGIS Python:
    QT_QPA_PLATFORM=offscreen python3 build_qgis_project.py

Creates output/swecc004_field_map.qgz, which opens:
  * the cleaned layers from output/swecc004_field_map.gpkg (relative path),
    styled and labelled
  * PDOK aerial photo (Luchtfoto, NL) and OpenStreetMap basemaps, fetched by
    QGIS when the project is opened online
  * a print layout "SWECC004 field map" (A3 landscape) with legend, scale
    bar, north arrow and credits: Project > Layouts > Export as PDF/image.
The layer styles are also saved as defaults inside the GeoPackage, so
dragging the .gpkg alone into QGIS gives the same symbology.
"""
import os

from qgis.core import (
    QgsApplication, QgsCategorizedSymbolRenderer, QgsCoordinateReferenceSystem,
    QgsFillSymbol, QgsLayerTreeLayer, QgsLayoutItemLabel, QgsLayoutItemLegend,
    QgsLayoutItemMap, QgsLayoutItemPicture, QgsLayoutItemScaleBar, QgsLayoutPoint,
    QgsLayoutSize, QgsLineSymbol, QgsMarkerSymbol, QgsPalLayerSettings,
    QgsPrintLayout, QgsProject, QgsRasterLayer, QgsReferencedRectangle, QgsRendererCategory,
    QgsRuleBasedRenderer, QgsSingleSymbolRenderer, QgsTextBufferSettings, QgsTextFormat, QgsUnitTypes,
    QgsVectorLayer, QgsVectorLayerSimpleLabeling, QgsLayoutExporter,
)
from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtGui import QColor, QFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "output")
GPKG = os.path.join(OUT, "swecc004_field_map.gpkg")
QGZ = os.path.join(OUT, "swecc004_field_map.qgz")
assert os.path.exists(GPKG), "run build_gis_map.py first"

app = QgsApplication([], False)
app.initQgis()
proj = QgsProject.instance()
proj.setTitle("SWECC004 oak monitoring – field survey 29 Oct 2026")
proj.setCrs(QgsCoordinateReferenceSystem("EPSG:28992"))
proj.writeEntryBool("Paths", "/Absolute", False)  # relative paths -> portable folder

COL = {"g01": "#4f9bd9", "g02": "#b9b2a5", "g03": "#9ed07f", "g04": "#e3c26b",
       "g05": "#6fae6a", "g06": "#c9a0d6", "g07": "#3f7f4f"}


def vlayer(layer, name):
    lyr = QgsVectorLayer(f"{GPKG}|layername={layer}", name, "ogr")
    assert lyr.isValid() and lyr.featureCount() > 0, f"could not load {layer}"
    return lyr


def label(lyr, expr, size=8, color="#000000", placement=None):
    s = QgsPalLayerSettings()
    s.fieldName = expr
    s.isExpression = True
    fmt = QgsTextFormat()
    f = QFont("Sans Serif")
    f.setBold(True)
    fmt.setFont(f)
    fmt.setSize(size)
    fmt.setColor(QColor(color))
    buf = QgsTextBufferSettings()
    buf.setEnabled(True)
    buf.setSize(1)
    buf.setColor(QColor("white"))
    fmt.setBuffer(buf)
    s.setFormat(fmt)
    if placement is not None:
        s.placement = placement
    lyr.setLabeling(QgsVectorLayerSimpleLabeling(s))
    lyr.setLabelsEnabled(True)


# ---------------------------------------------------------------- basemaps
def xyz(name, url, zmax):
    uri = f"type=xyz&url={url}&zmin=0&zmax={zmax}"
    lyr = QgsRasterLayer(uri, name, "wms")
    assert lyr.isValid(), f"basemap {name} invalid"
    return lyr


aerial = xyz("Luchtfoto PDOK (aerial)",
             "https://service.pdok.nl/hwh/luchtfotorgb/wmts/v1_0/Actueel_orthoHR/EPSG:3857/{z}/{x}/{y}.jpeg", 19)
aerial.setAttribution("Luchtfoto © PDOK / Beeldmateriaal Nederland (CC BY 4.0)")
osm = xyz("OpenStreetMap", "https://tile.openstreetmap.org/{z}/{x}/{y}.png", 19)
osm.setAttribution("© OpenStreetMap contributors")

# ------------------------------------------------------------------ layers
study = vlayer("study_area_extent", "Survey extent")
study_sym = QgsFillSymbol.createSimple({"color": "0,0,0,0", "outline_color": "#ffcc00",
                                        "outline_style": "dash", "outline_width": "0.6"})
study.setRenderer(QgsSingleSymbolRenderer(study_sym))

polys = vlayer("habitat_polygons", "Habitat polygons g01–g07")
cats = []
labels = {}
for f in polys.getFeatures():
    labels[f["id"]] = f["label"]
for gid, col in COL.items():
    outside = gid in ("g02", "g07")
    sym = QgsFillSymbol.createSimple({
        "outline_color": "#202020", "outline_width": "0.6" if outside else "0.35",
        "outline_style": "dash" if outside else "solid"})
    c = QColor(col)  # ~55 % opacity fill
    c.setAlpha(140)
    sym.setColor(c)
    cats.append(QgsRendererCategory(gid, sym, f"{gid} {labels[gid]}" + (" (outside planned area)" if outside else "")))
polys.setRenderer(QgsCategorizedSymbolRenderer("id", cats))
label(polys, "\"id\" || '\\n' || \"label\"", 8)

paths = vlayer("paths", "Paths path1–path4")
root_rule = QgsRuleBasedRenderer.Rule(None)
for name, expr, style in [("path1–path3", 'NOT "outside_planned_area"', "solid"),
                          ("path4 (outside planned area)", '"outside_planned_area"', "dash")]:
    s = QgsLineSymbol.createSimple({"line_color": "#c0392b", "line_width": "0.8", "line_style": style})
    root_rule.appendChild(QgsRuleBasedRenderer.Rule(s, 0, 0, expr, name))
paths.setRenderer(QgsRuleBasedRenderer(root_rule))
for expr, n in (('NOT "outside_planned_area"', 3), ('"outside_planned_area"', 1)):
    from qgis.core import QgsFeatureRequest
    assert sum(1 for _ in paths.getFeatures(QgsFeatureRequest().setFilterExpression(expr))) == n, expr
label(paths, "\"id\"", 8, "#c0392b", QgsPalLayerSettings.Curved)

trees = vlayer("trees", "Oak trees t01–t16")
tsym = QgsMarkerSymbol.createSimple({"name": "circle", "color": "#145a32", "outline_color": "#ffffff",
                                     "outline_width": "0.4", "size": "3"})
trees.setRenderer(QgsSingleSymbolRenderer(tsym))
label(trees, "\"id\"", 8, "#145a32")

# Save the styles as default inside the GeoPackage as well
for lyr in (study, polys, paths, trees):
    lyr.saveStyleToDatabase("default", "SWECC004 style", True, "")

for lyr in (osm, aerial, study, polys, paths, trees):
    proj.addMapLayer(lyr, False)
root = proj.layerTreeRoot()
for lyr in (trees, paths, polys, study, aerial, osm):  # top -> bottom
    root.addLayer(lyr)
root.findLayer(osm.id()).setItemVisibilityChecked(False)  # aerial on by default

# Project extent = survey extent
ext = study.extent()
ext.grow(25)
proj.viewSettings().setDefaultViewExtent(QgsReferencedRectangle(ext, proj.crs()))

# ------------------------------------------------------------ print layout
lay = QgsPrintLayout(proj)
lay.initializeDefaults()  # A4 landscape
lay.setName("SWECC004 field map")
lay.pageCollection().page(0).setPageSize("A3", lay.pageCollection().page(0).Landscape)
mm = QgsUnitTypes.LayoutMillimeters

m = QgsLayoutItemMap(lay)
m.attemptMove(QgsLayoutPoint(10, 22, mm))
m.attemptResize(QgsLayoutSize(285, 265, mm))
m.setCrs(proj.crs())
m.setLayers([trees, paths, polys, study, aerial])
m.setExtent(ext)
m.setFrameEnabled(True)
lay.addLayoutItem(m)

title = QgsLayoutItemLabel(lay)
title.setText("SWECC004 oak monitoring – field survey 29 Oct 2026 (Wageningen Campus)")
tf = QgsTextFormat()
tf.setFont(QFont("Sans Serif", 18, QFont.Bold))
tf.setSize(18)
title.setTextFormat(tf)
title.attemptMove(QgsLayoutPoint(10, 6, mm))
title.attemptResize(QgsLayoutSize(400, 12, mm))
lay.addLayoutItem(title)

leg = QgsLayoutItemLegend(lay)
leg.setLinkedMap(m)
leg.setLegendFilterByMapEnabled(False)
leg.setAutoUpdateModel(False)
leg.model().rootGroup().clear()
for lyr in (polys, paths, trees, study):
    leg.model().rootGroup().addLayer(lyr)
leg.setTitle("Legend")
leg.attemptMove(QgsLayoutPoint(300, 22, mm))
lay.addLayoutItem(leg)

sb = QgsLayoutItemScaleBar(lay)
sb.setLinkedMap(m)
sb.setStyle("Single Box")
sb.setUnits(QgsUnitTypes.DistanceMeters)
sb.setUnitLabel("m")
sb.setNumberOfSegments(4)
sb.setNumberOfSegmentsLeft(0)
sb.setUnitsPerSegment(25)
sb.attemptMove(QgsLayoutPoint(300, 230, mm))
lay.addLayoutItem(sb)

north = QgsLayoutItemPicture(lay)
north.setPicturePath(os.path.join(QgsApplication.svgPaths()[0], "arrows", "NorthArrow_02.svg")
                     if QgsApplication.svgPaths() else "")
north.setLinkedMap(m)
north.setNorthMode(QgsLayoutItemPicture.GridNorth)
north.attemptMove(QgsLayoutPoint(395, 205, mm))
north.attemptResize(QgsLayoutSize(15, 20, mm))
lay.addLayoutItem(north)

cred = QgsLayoutItemLabel(lay)
cred.setText("CRS: Amersfoort / RD New (EPSG:28992) · GPS: Open GPX Tracker (iOS), accuracy ≈ 3–5 m\n"
             "Basemap: Luchtfoto © PDOK (CC BY 4.0) · © OpenStreetMap contributors\n"
             "Cleaned data: see removed_points_log.csv")
cf = QgsTextFormat()
cf.setFont(QFont("Sans Serif", 7))
cf.setSize(7)
cred.setTextFormat(cf)
cred.attemptMove(QgsLayoutPoint(300, 255, mm))
cred.attemptResize(QgsLayoutSize(115, 30, mm))
lay.addLayoutItem(cred)
proj.layoutManager().addLayout(lay)

assert proj.write(QGZ), "could not write project"
print("wrote", QGZ)

# Test export of the layout (basemap tiles may be unreachable from here)
res = QgsLayoutExporter(lay).exportToImage(os.path.join(OUT, "_layout_test.png"),
                                           QgsLayoutExporter.ImageExportSettings())
print("layout export:", res)
app.exitQgis()
