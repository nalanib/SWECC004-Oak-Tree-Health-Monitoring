"""Export the cleaned field map to KMZ (Google Earth: phone app, web, desktop).

Run after build_gis_map.py:   python3 build_kmz.py
Writes output/swecc004_field_map.kmz. Opens in Google Earth over satellite
imagery, and imports into QGIS / ArcGIS (KML is WGS84 lon/lat).
"""
import os
import zipfile
from xml.sax.saxutils import escape

import geopandas as gpd

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "output")
GPKG = os.path.join(OUT, "swecc004_field_map.gpkg")

COL = {"g01": "#4f9bd9", "g02": "#b9b2a5", "g03": "#9ed07f", "g04": "#e3c26b",
       "g05": "#6fae6a", "g06": "#c9a0d6", "g07": "#3f7f4f"}


def kml_color(hex_rgb, alpha):  # KML uses aabbggrr
    r, g, b = hex_rgb[1:3], hex_rgb[3:5], hex_rgb[5:7]
    return f"{alpha:02x}{b}{g}{r}"


def coords(seq):
    return " ".join(f"{x:.8f},{y:.8f},0" for x, y in seq)


def desc(row, skip=("geometry",)):
    return "<![CDATA[" + "<br>".join(f"<b>{k}</b>: {escape(str(v))}" for k, v in row.items() if k not in skip) + "]]>"


load = lambda layer: gpd.read_file(GPKG, layer=layer).to_crs(4326)
polys, paths, trees, study = (load(n) for n in ("habitat_polygons", "paths", "trees", "study_area_extent"))
assert (len(polys), len(paths), len(trees)) == (7, 4, 16)

styles, folders = [], []
# polygons
pm = []
for _, r in polys.iterrows():
    sid = f"s_{r.id}"
    styles.append(f'<Style id="{sid}"><LineStyle><color>ff202020</color><width>{3 if r.outside_planned_area else 1.5}</width></LineStyle>'
                  f'<PolyStyle><color>{kml_color(COL[r.id], 0x99)}</color></PolyStyle>'
                  f'<LabelStyle><scale>0.9</scale></LabelStyle></Style>')
    g = r.geometry
    assert g.geom_type == "Polygon" and not g.interiors
    c = g.representative_point()
    name = f"{r.id} {r.label}" + (" (outside planned area)" if r.outside_planned_area else "")
    pm.append(f'<Placemark><name>{escape(name)}</name><description>{desc(r)}</description><styleUrl>#{sid}</styleUrl>'
              f'<MultiGeometry><Point><coordinates>{c.x:.8f},{c.y:.8f},0</coordinates></Point>'
              f'<Polygon><tessellate>1</tessellate><outerBoundaryIs><LinearRing><coordinates>{coords(g.exterior.coords)}'
              f'</coordinates></LinearRing></outerBoundaryIs></Polygon></MultiGeometry></Placemark>')
folders.append(("Habitat polygons g01–g07", pm))

# paths
styles.append('<Style id="s_path"><LineStyle><color>ff2b39c0</color><width>3</width></LineStyle></Style>')
pm = [f'<Placemark><name>{r.id}</name><description>{desc(r)}</description><styleUrl>#s_path</styleUrl>'
      f'<LineString><tessellate>1</tessellate><coordinates>{coords(r.geometry.coords)}</coordinates></LineString></Placemark>'
      for _, r in paths.iterrows()]
folders.append(("Paths path1–path4", pm))

# trees
styles.append('<Style id="s_tree"><IconStyle><color>ff325a14</color><scale>0.9</scale><Icon>'
              '<href>http://maps.google.com/mapfiles/kml/shapes/parks.png</href></Icon></IconStyle>'
              '<LabelStyle><color>ffffffff</color><scale>0.9</scale></LabelStyle></Style>')
pm = [f'<Placemark><name>{r.id}</name><description>{desc(r)}</description><styleUrl>#s_tree</styleUrl>'
      f'<Point><coordinates>{r.geometry.x:.8f},{r.geometry.y:.8f},0</coordinates></Point></Placemark>'
      for _, r in trees.iterrows()]
folders.append(("Oak trees t01–t16", pm))

# survey extent
styles.append('<Style id="s_ext"><LineStyle><color>ff00ccff</color><width>2</width></LineStyle><PolyStyle><fill>0</fill></PolyStyle></Style>')
g = study.geometry.iloc[0]
folders.append(("Survey extent", [f'<Placemark><name>Survey extent</name><styleUrl>#s_ext</styleUrl><Polygon><outerBoundaryIs><LinearRing>'
                                   f'<coordinates>{coords(g.exterior.coords)}</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>']))

minx, miny, maxx, maxy = study.total_bounds
look = (f'<LookAt><longitude>{(minx + maxx) / 2:.6f}</longitude><latitude>{(miny + maxy) / 2:.6f}</latitude>'
        f'<altitude>0</altitude><range>650</range><tilt>0</tilt><heading>0</heading><altitudeMode>relativeToGround</altitudeMode></LookAt>')
kml = ('<?xml version="1.0" encoding="UTF-8"?>\n<kml xmlns="http://www.opengis.net/kml/2.2"><Document>'
       '<name>SWECC004 field survey 29 Oct 2026</name><open>1</open>'
       '<description>Cleaned GPS data, Wageningen Campus. See README / removed_points_log.csv.</description>'
       + look + "".join(styles)
       + "".join(f"<Folder><name>{escape(n)}</name><open>1</open>{''.join(p)}</Folder>" for n, p in folders)
       + "</Document></kml>")
kmz = os.path.join(OUT, "swecc004_field_map.kmz")
with zipfile.ZipFile(kmz, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("doc.kml", kml)
print("wrote", kmz)
