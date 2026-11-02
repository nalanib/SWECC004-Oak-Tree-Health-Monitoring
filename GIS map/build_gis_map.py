"""Build the SWECC004 field GIS map from the 29 Oct 2026 GPX recordings.

Run:  python3 build_gis_map.py            (from inside the "GIS map" folder)
Needs: geopandas, shapely, pyproj, pyogrio, matplotlib

Cleaning steps (each one is asserted, so the script stops if the data
does not look exactly as expected):
  1. g01 (pond): drop the 2 track points stamped 13:39:57Z (GPS jump of
     33.5 m and 20.5 m next to waypoint "g01_v10 - glitch").
  2. trees: keep only waypoints (Type = WPT) t01-t16; the 147 track points
     in the same file are discarded.
  3. g03: drop the stray waypoint named "2:56:04 PM" (accidental tap,
     far south of the lawn). The g03 polygon is built from the track only.
  4. Feature IDs follow the file names: g01-g07, path1-path4, t01-t16.
  5. Study-area extent is computed from ALL features, so g02, g07 and
     path4 (south-west, outside the planned area) are included.
"""
import json
import os
import xml.etree.ElementTree as ET

import geopandas as gpd
import matplotlib

matplotlib.use("Agg")
import matplotlib.patheffects as pe
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.patches import Patch
from shapely.geometry import LineString, Point, Polygon, box

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "raw_gpx")
OUT = os.path.join(HERE, "output")
os.makedirs(OUT, exist_ok=True)
NS = {"g": "http://www.topografix.com/GPX/1/1"}
RD = "EPSG:28992"  # Amersfoort / RD New

POLYGONS = {  # id: (file, label taken from the file name)
    "g01": ("g01_-_pond_.gpx", "pond"),
    "g02": ("g02_-_gravel.gpx", "gravel"),
    "g03": ("g03_-_mostly_mowed.gpx", "mostly mowed"),
    "g04": ("g04_-_Orion_.gpx", "Orion"),
    "g05": ("g05_-_unmowed_shrubs.gpx", "unmowed shrubs"),
    "g06": ("g06_-_atlas__unmowed.gpx", "Atlas, unmowed"),
    "g07": ("g07_-_unmowed_trees_shrubs.gpx", "unmowed trees/shrubs"),
}
PATHS = {f"path{i}": f"29-okt-2026-path{i}.gpx" for i in range(1, 5)}
TREES = "trees_-_points.gpx"
OUTSIDE_PLANNED = {"g02", "g07", "path4"}

removed = []  # audit log of everything deleted


def parse(fname):
    root = ET.parse(os.path.join(RAW, fname)).getroot()
    wpts = [
        dict(name=w.findtext("g:name", namespaces=NS), lat=float(w.get("lat")),
             lon=float(w.get("lon")), time=w.findtext("g:time", namespaces=NS),
             ele=w.findtext("g:ele", namespaces=NS))
        for w in root.findall("g:wpt", NS)
    ]
    segs = [
        [dict(lat=float(p.get("lat")), lon=float(p.get("lon")),
              time=p.findtext("g:time", namespaces=NS)) for p in s.findall("g:trkpt", NS)]
        for s in root.findall(".//g:trkseg", NS)
    ]
    return wpts, segs


# ---------------------------------------------------------------- polygons
poly_rows = []
for gid, (fname, label) in POLYGONS.items():
    wpts, segs = parse(fname)
    assert len(segs) == 1, f"{gid}: expected 1 track segment"
    pts = segs[0]

    if gid == "g01":  # FIX 1
        bad = [p for p in pts if p["time"] == "2026-10-29T13:39:57Z"]
        assert len(bad) == 2, f"g01: expected 2 glitch points, found {len(bad)}"
        for p in bad:
            removed.append(dict(layer="g01 track", what="track point", time=p["time"],
                                lat=p["lat"], lon=p["lon"], reason="GPS jump next to 'g01_v10 - glitch'"))
        pts = [p for p in pts if p["time"] != "2026-10-29T13:39:57Z"]
        assert not Polygon([(p["lon"], p["lat"]) for p in pts]).is_valid
        # FIX 1b: with the 2 jumps gone, the ~1 m back-step at 13:39:59 makes the
        # edge 13:39:26->13:39:58 cross 13:39:59->13:40:01 (a bow-tie). Drop it too.
        back = [p for p in pts if p["time"] == "2026-10-29T13:39:59Z"]
        assert len(back) == 1
        removed.append(dict(layer="g01 track", what="track point", time=back[0]["time"],
                            lat=back[0]["lat"], lon=back[0]["lon"],
                            reason="~1 m GPS back-step; caused self-intersection after glitch removal"))
        pts = [p for p in pts if p["time"] != "2026-10-29T13:39:59Z"]
        # FIX 1c: remove the pond-outline vertices where the walk detoured onto the
        # bridge (path1 crosses the pond). West abutment 13:38:34-13:39:07 (6 pts,
        # around waypoints v06-v08), east abutment 13:42:01-13:43:28 (12 pts,
        # around v12-v15). All lie within 5 m of path1 (asserted further down).
        BRIDGE = [("2026-10-29T13:38:34Z", "2026-10-29T13:39:07Z", 6),
                  ("2026-10-29T13:42:01Z", "2026-10-29T13:43:28Z", 12)]
        bridge_pts = []
        for t0, t1, n in BRIDGE:
            sel = [p for p in pts if t0 <= p["time"] <= t1]
            assert len(sel) == n, f"g01 bridge {t0}-{t1}: expected {n}, found {len(sel)}"
            bridge_pts += sel
        for p in bridge_pts:
            removed.append(dict(layer="g01 track", what="track point", time=p["time"],
                                lat=p["lat"], lon=p["lon"], reason="pond outline detour onto the bridge (path1)"))
        pts = [p for p in pts if p not in bridge_pts]
        # FIX 1d: remove the south-east lobe at the start of the walk (v01 -> v02 ->
        # v03 -> v04, 13:35:36-13:36:41, 28 pts incl. the start point, which left a
        # 1.5 m hook) that bulges east of the pond's straight east edge; the outline
        # now runs straight from the finish point (v16) down to v04.
        lobe = [p for p in pts if "2026-10-29T13:35:36Z" <= p["time"] <= "2026-10-29T13:36:41Z"]
        assert len(lobe) == 28, f"g01 lobe: expected 28, found {len(lobe)}"
        for p in lobe:
            removed.append(dict(layer="g01 track", what="track point", time=p["time"],
                                lat=p["lat"], lon=p["lon"], reason="south-east lobe (v01-v04) outside pond edge"))
        pts = [p for p in pts if p not in lobe]
        # FIX 1e: leftover tooth at the SE corner: v04 and the ~4 m dip south
        # (13:36:43-13:37:00, 4 pts). Dropping them makes the east edge run
        # straight from the finish point (13:44:40) to v05 (13:37:02).
        tooth = [p for p in pts if "2026-10-29T13:36:43Z" <= p["time"] <= "2026-10-29T13:37:00Z"]
        assert len(tooth) == 4, f"g01 tooth: expected 4, found {len(tooth)}"
        assert tooth[-1]["time"] == "2026-10-29T13:37:00Z"
        for p in tooth:
            removed.append(dict(layer="g01 track", what="track point", time=p["time"],
                                lat=p["lat"], lon=p["lon"], reason="SE corner tooth left after lobe removal"))
        pts = [p for p in pts if p not in tooth]

    if gid == "g03":  # FIX 3
        # iOS writes a narrow no-break space (U+202F) before "PM"; normalise it
        stray = [w for w in wpts if " ".join(w["name"].replace(" ", " ").split()) == "2:56:04 PM"]
        assert len(stray) == 1 and len(wpts) == 1, "g03: expected exactly 1 stray waypoint"
        removed.append(dict(layer="g03 waypoints", what="waypoint '2:56:04 PM'", time=stray[0]["time"],
                            lat=stray[0]["lat"], lon=stray[0]["lon"], reason="accidental tap, far south of lawn"))
    elif gid != "g01":
        assert not wpts, f"{gid}: unexpected waypoints"

    poly_rows.append(dict(id=gid, label=label, source_file=fname, n_vertices=len(pts),
                          t_start=pts[0]["time"], t_end=pts[-1]["time"],
                          outside_planned_area=gid in OUTSIDE_PLANNED,
                          geometry=Polygon([(p["lon"], p["lat"]) for p in pts])))

polys = gpd.GeoDataFrame(poly_rows, crs="EPSG:4326").to_crs(RD)
for _, r in polys.iterrows():
    assert r.geometry.is_valid, f"{r.id}: polygon is not valid"
polys["area_m2"] = polys.area.round(0)
polys["perimeter_m"] = polys.length.round(1)

# ------------------------------------------------------------------- paths
path_rows = []
for pid, fname in PATHS.items():
    wpts, segs = parse(fname)
    assert len(segs) == 1 and not wpts, f"{pid}: unexpected structure"
    pts = segs[0]
    path_rows.append(dict(id=pid, source_file=fname, n_vertices=len(pts),
                          t_start=pts[0]["time"], t_end=pts[-1]["time"],
                          outside_planned_area=pid in OUTSIDE_PLANNED,
                          geometry=LineString([(p["lon"], p["lat"]) for p in pts])))
paths = gpd.GeoDataFrame(path_rows, crs="EPSG:4326").to_crs(RD)
paths["length_m"] = paths.length.round(1)
_p1 = paths.set_index("id").geometry["path1"]
_br = gpd.GeoSeries([Point(p["lon"], p["lat"]) for p in bridge_pts], crs="EPSG:4326").to_crs(RD)
assert (_br.distance(_p1) < 5).all(), "a removed bridge vertex is not within 5 m of path1"

# ------------------------------------------------------------------- trees
wpts, segs = parse(TREES)  # FIX 2: keep Type = WPT only
n_trk = sum(len(s) for s in segs)
assert n_trk == 147, f"trees: expected 147 track points, found {n_trk}"
names = [w["name"] for w in wpts]
assert names == [f"t{i:02d}" for i in range(1, 17)], f"trees: unexpected waypoint names {names}"
removed.append(dict(layer="trees", what=f"{n_trk} track points ({len(segs)} segments)", time="",
                    lat="", lon="", reason="track not needed; keep waypoints t01-t16 only"))
trees = gpd.GeoDataFrame(
    [dict(id=w["name"], time=w["time"], ele_gps_m=round(float(w["ele"]), 1),
          geometry=Point(w["lon"], w["lat"])) for w in wpts], crs="EPSG:4326").to_crs(RD)
trees["x_rd"] = trees.geometry.x.round(2)
trees["y_rd"] = trees.geometry.y.round(2)
# Which mapped polygon (if any) each tree falls in
joined = gpd.sjoin(trees, polys[["id", "geometry"]].rename(columns={"id": "in_polygon"}),
                   how="left", predicate="within")
assert len(joined) == len(trees), "a tree falls in more than one polygon"
trees["in_polygon"] = joined["in_polygon"].fillna("").values

# ------------------------------------------- Arboreal measurements (trees)
# raw_measurements/Measurements Arboreal.csv: one row per tree, Name T01-T16,
# times in local time (CET = UTC+1), photo per tree. Joined on ID (T01 -> t01);
# the match is checked on time and position. The GPX point stays the position.
import shutil

import pandas as pd

MEAS = os.path.join(HERE, "raw_measurements")
arb = pd.read_csv(os.path.join(MEAS, "Measurements Arboreal.csv"), skipinitialspace=True)
arb.columns = [c.strip() for c in arb.columns]
# strip padding and normalise iOS narrow no-break spaces (U+202F) in "2:31 PM"
arb = arb.apply(lambda s: s.map(lambda v: " ".join(v.replace("\u202f", " ").split()) if isinstance(v, str) else v)
                if not pd.api.types.is_numeric_dtype(s) else s)
arb["id"] = arb["Name"].str.lower()
assert sorted(arb["id"]) == list(trees["id"]), "Arboreal names do not match t01-t16"
arb = arb.set_index("id").loc[trees["id"]]
# time check: Arboreal local time (UTC+1) within 3 min of the GPX waypoint (UTC)
for tid, r in arb.iterrows():
    t_loc = pd.to_datetime(f"2026-10-29 {r['Time']}", format="%Y-%m-%d %I:%M %p")
    t_gpx = pd.to_datetime(trees.set_index("id").loc[tid, "time"]).tz_localize(None) + pd.Timedelta(hours=1)
    assert abs((t_loc - t_gpx).total_seconds()) <= 180, f"{tid}: time mismatch {t_loc} vs {t_gpx}"
centre = gpd.GeoSeries(gpd.points_from_xy(arb["Tree center longitude"], arb["Tree center latitude"]),
                       crs="EPSG:4326").to_crs(RD).values
offset = [c.distance(g) for c, g in zip(centre, trees.geometry)]
for tid, d, acc in zip(trees["id"], offset, arb["Accuracy (m)"]):
    others = trees[trees["id"] != tid].geometry.distance(centre[list(trees["id"]).index(tid)]).min()
    assert d < others, f"{tid}: Arboreal position is closer to another tree"
    assert d <= max(6.0, acc), f"{tid}: offset {d:.1f} m exceeds GPS accuracy {acc:.1f} m"

SPECIES_FIX = {"Lach unknown (larix spec.)": "Larch unknown (Larix spec.)"}  # typo in export
trees["species"] = [SPECIES_FIX.get(s, s) for s in arb["Tree species"]]
trees["height_m"] = arb["Perpendicular height (m)"].astype(float).values
trees["dbh_cm"] = arb["Diameter (cm)"].astype(float).values
trees["breast_height_m"] = arb["Breast height (m)"].astype(float).values
trees["inclination_deg"] = arb["Inclination°"].str.rstrip("°").astype(float).values
trees["arboreal_time_local"] = arb["Time"].values
trees["arboreal_accuracy_m"] = arb["Accuracy (m)"].round(1).values
trees["arboreal_lat"] = arb["Tree center latitude"].values
trees["arboreal_lon"] = arb["Tree center longitude"].values
trees["offset_arboreal_m"] = [round(d, 1) for d in offset]
trees["photo"] = ["photos/" + f for f in arb["Imagename"]]
QA = {"t05": "Arboreal GPS accuracy 20.8 m; position offset 18 m - GPX position kept",
      "t07": "Height 38.1 m is implausible for a silver birch with 30.7 cm DBH - re-measure"}
trees["qa_note"] = [QA.get(t, "") for t in trees["id"]]
assert trees["photo"].map(lambda p: os.path.exists(os.path.join(MEAS, p[7:]))).all(), "missing photo"
os.makedirs(os.path.join(OUT, "photos"), exist_ok=True)
for p in trees["photo"]:
    shutil.copy2(os.path.join(MEAS, p[7:]), os.path.join(OUT, p))

# -------------------------------------------------------------- study area
everything = list(polys.geometry) + list(paths.geometry) + list(trees.geometry)
minx, miny, maxx, maxy = gpd.GeoSeries(everything, crs=RD).total_bounds
study = gpd.GeoDataFrame(
    [dict(name="SWECC004 field survey extent (all features + 10 m)",
          geometry=box(minx - 10, miny - 10, maxx + 10, maxy + 10))], crs=RD)
for g in polys[polys.outside_planned_area].geometry.tolist() + paths[paths.outside_planned_area].geometry.tolist():
    assert study.geometry.iloc[0].contains(g)

# ---------------------------------------------------------------- QA notes
overlaps = []
for i, a in polys.iterrows():
    for j, b in polys.iterrows():
        if i < j and a.geometry.intersects(b.geometry):
            ov = a.geometry.intersection(b.geometry).area
            if ov > 0.5:
                overlaps.append((a.id, b.id, round(ov, 0)))

# ------------------------------------------------------------------ export
gpkg = os.path.join(OUT, "swecc004_field_map.gpkg")
if os.path.exists(gpkg):
    os.remove(gpkg)
polys.to_file(gpkg, layer="habitat_polygons", driver="GPKG")
paths.to_file(gpkg, layer="paths", driver="GPKG")
trees.to_file(gpkg, layer="trees", driver="GPKG")
study.to_file(gpkg, layer="study_area_extent", driver="GPKG")
gpd.GeoDataFrame(removed).to_csv(os.path.join(OUT, "removed_points_log.csv"), index=False)

# Attribute-join template: fill in from the printed form, keyed on `id`
with open(os.path.join(OUT, "form_attributes_template.csv"), "w") as f:
    f.write("id,feature_type,source_file,form_id_on_paper,notes\n")
    for _, r in polys.iterrows():
        f.write(f"{r.id},polygon,{r.source_file},,\n")
    for _, r in paths.iterrows():
        f.write(f"{r.id},path,{r.source_file},,\n")
    for _, r in trees.iterrows():
        f.write(f"{r.id},tree,{TREES},,\n")

wgs = {k: json.loads(v.to_crs(4326).to_json()) for k, v in
       dict(polygons=polys, paths=paths, trees=trees, study=study).items()}

# ------------------------------------------------------------- static map
COL = {"g01": "#4f9bd9", "g02": "#b9b2a5", "g03": "#9ed07f", "g04": "#e3c26b",
       "g05": "#6fae6a", "g06": "#c9a0d6", "g07": "#3f7f4f"}
fig, ax = plt.subplots(figsize=(11.7, 11.0), dpi=200)
study.boundary.plot(ax=ax, color="#555", lw=0.8, linestyle=":")
for _, r in polys.iterrows():
    gpd.GeoSeries([r.geometry]).plot(ax=ax, color=COL[r.id], alpha=0.55, edgecolor="#222",
                                     lw=1.6 if r.outside_planned_area else 0.8,
                                     ls="--" if r.outside_planned_area else "-")
    c = r.geometry.representative_point()
    ax.text(c.x, c.y, f"{r.id}\n{r.label}", ha="center", va="center", fontsize=7.5, weight="bold",
            path_effects=[pe.withStroke(linewidth=2.5, foreground="white")])
for _, r in paths.iterrows():
    gpd.GeoSeries([r.geometry]).plot(ax=ax, color="#c0392b", lw=1.8,
                                     ls="--" if r.outside_planned_area else "-")
    m = r.geometry.interpolate(0.5, normalized=True)
    ax.text(m.x, m.y, r.id, fontsize=7, color="#c0392b", weight="bold",
            path_effects=[pe.withStroke(linewidth=2.5, foreground="white")])
trees.plot(ax=ax, color="#145a32", markersize=38, edgecolor="white", lw=0.8, zorder=5)
for _, r in trees.iterrows():
    sp = r.species.split(" (")[0].replace(" unknown", "")
    ax.annotate(f"{r.id} {sp}", (r.geometry.x, r.geometry.y), xytext=(4, 4), textcoords="offset points",
                fontsize=6.5, color="#145a32", weight="bold", zorder=6,
                path_effects=[pe.withStroke(linewidth=2.5, foreground="white")])
ax.set_aspect("equal")
ax.set_xlim(minx - 25, maxx + 25)
ax.set_ylim(miny - 25, maxy + 25)
ax.ticklabel_format(useOffset=False, style="plain")
ax.tick_params(labelsize=7)
ax.set_xlabel("RD x (m)", fontsize=8)
ax.set_ylabel("RD y (m)", fontsize=8)
ax.grid(color="#ddd", lw=0.5)
ax.set_title("SWECC004 oak monitoring – field survey 29 Oct 2026 (Wageningen Campus)", fontsize=12, weight="bold")
# scale bar (50 m) and north arrow; RD grid north ~ true north here
sx, sy = minx - 15, miny - 18
ax.plot([sx, sx + 50], [sy, sy], color="k", lw=3)
ax.text(sx + 25, sy + 3, "50 m", ha="center", fontsize=8)
ax.annotate("N", xy=(maxx + 15, maxy + 15), xytext=(maxx + 15, maxy - 10), ha="center", fontsize=11,
            weight="bold", arrowprops=dict(arrowstyle="-|>", color="k", lw=1.5))
handles = [Patch(facecolor=COL[g], alpha=0.55, edgecolor="#222", label=f"{g} {POLYGONS[g][1]}") for g in COL]
handles += [Line2D([], [], color="#c0392b", lw=1.8, label="Paths (path1–path4)"),
            Line2D([], [], marker="o", color="w", markerfacecolor="#145a32", markersize=7, label="Trees t01–t16 (Arboreal: species, height, DBH)"),
            Line2D([], [], color="#222", ls="--", lw=1.4, label="Dashed = outside planned area (g02, g07, path4)"),
            Line2D([], [], color="#555", ls=":", lw=0.8, label="Survey extent (all features + 10 m)")]
ax.legend(handles=handles, loc="upper left", fontsize=7.5, framealpha=0.92)
# Site basemap: PDOK aerial photo, falling back to OpenStreetMap. Needs network
# access to service.pdok.nl / tile.openstreetmap.org; without it the map is drawn
# without a background and the footnote says so.
BASEMAP_NOTE = "\nNo basemap: tile servers unreachable when this map was built"
try:
    import contextily as cx
    from xyzservices import TileProvider
    pdok = TileProvider(name="PDOK aerial", attribution="Luchtfoto © PDOK (CC BY 4.0)", max_zoom=19,
                        url="https://service.pdok.nl/hwh/luchtfotorgb/wmts/v1_0/Actueel_orthoHR/EPSG:3857/{z}/{x}/{y}.jpeg")
    for prov in (pdok, cx.providers.OpenStreetMap.Mapnik):
        try:
            cx.add_basemap(ax, crs=RD, source=prov, zoom=18, attribution=False)
            BASEMAP_NOTE = f"\nBasemap: {prov.attribution}"
            break
        except Exception as e:  # tile host blocked/offline -> try the next one
            print(f"basemap {prov.name} unavailable: {type(e).__name__}")
except ImportError:
    pass
ax.set_xlim(minx - 25, maxx + 25)
ax.set_ylim(miny - 25, maxy + 25)
ax.text(0.99, 0.01, "CRS: Amersfoort / RD New (EPSG:28992) · GPS: Open GPX Tracker (iOS), accuracy ≈ 3–5 m\n"
        "Cleaned: g01 glitch (3 pts), bridge detours (18 pts) and SE lobe + corner (32 pts) removed · g03 stray waypoint removed · trees = waypoints only"
        + BASEMAP_NOTE,
        transform=ax.transAxes, ha="right", va="bottom", fontsize=6.5, color="#444")
fig.tight_layout()
fig.savefig(os.path.join(OUT, "swecc004_field_map.png"))
fig.savefig(os.path.join(OUT, "swecc004_field_map.pdf"))

# ------------------------------------------------------- interactive map
import base64
import io

from PIL import Image

thumbs = {}  # small embedded tree photos for the popups
for _, r in trees.iterrows():
    im = Image.open(os.path.join(OUT, r.photo))
    im.thumbnail((440, 440))
    buf = io.BytesIO()
    im.convert("RGB").save(buf, "JPEG", quality=80)
    thumbs[r.id] = "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()
LEAF = os.environ.get("LEAFLET_DIR")  # folder holding leaflet.js / leaflet.css (inlined if given)
if LEAF:
    js = open(os.path.join(LEAF, "leaflet.js")).read()
    css = open(os.path.join(LEAF, "leaflet.css")).read()
    head = f"<style>{css}</style><script>{js}</script>"
else:
    head = ('<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">'
            '<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>')
html = f"""<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SWECC004 field map</title>{head}
<style>html,body,#map{{height:100%;margin:0}} .lbl{{font:bold 11px sans-serif;color:#145a32;text-shadow:0 0 3px #fff,0 0 3px #fff}}</style>
</head><body><div id="map"></div><script>
const D={json.dumps(wgs)};
const COL={json.dumps(COL)};
const map=L.map('map');
const osm=L.tileLayer('https://tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png',{{maxZoom:20,maxNativeZoom:19,attribution:'© OpenStreetMap contributors'}}).addTo(map);
const air=L.tileLayer('https://service.pdok.nl/hwh/luchtfotorgb/wmts/v1_0/Actueel_orthoHR/EPSG:3857/{{z}}/{{x}}/{{y}}.jpeg',{{maxZoom:21,maxNativeZoom:19,attribution:'Luchtfoto © PDOK'}});
const THUMB={json.dumps(thumbs)};
const pop=p=>(THUMB[p.id]?`<img src="${{THUMB[p.id]}}" style="width:220px;display:block;margin-bottom:4px">`:'')+Object.entries(p).filter(([k,v])=>v!==''&&v!==null).map(([k,v])=>`<b>${{k}}</b>: ${{v}}`).join('<br>');
const study=L.geoJSON(D.study,{{style:{{color:'#555',weight:1,dashArray:'6 4',fill:false}}}}).addTo(map);
const polys=L.geoJSON(D.polygons,{{style:f=>({{color:'#222',weight:f.properties.outside_planned_area?2:1,dashArray:f.properties.outside_planned_area?'5 4':null,fillColor:COL[f.properties.id],fillOpacity:.45}}),
  onEachFeature:(f,l)=>{{l.bindPopup(pop(f.properties));l.bindTooltip(f.properties.id+' '+f.properties.label);}}}}).addTo(map);
const paths=L.geoJSON(D.paths,{{style:f=>({{color:'#c0392b',weight:3,dashArray:f.properties.outside_planned_area?'6 5':null}}),
  onEachFeature:(f,l)=>{{l.bindPopup(pop(f.properties));l.bindTooltip(f.properties.id);}}}}).addTo(map);
const trees=L.geoJSON(D.trees,{{pointToLayer:(f,ll)=>L.circleMarker(ll,{{radius:6,color:'#fff',weight:1,fillColor:'#145a32',fillOpacity:1}}),
  onEachFeature:(f,l)=>{{l.bindPopup(pop(f.properties));l.bindTooltip(f.properties.id+' '+f.properties.species.split(' (')[0].replace(' unknown',''),{{permanent:true,direction:'right',className:'lbl'}});}}}}).addTo(map);
L.control.layers({{'OpenStreetMap':osm,'Aerial photo (PDOK)':air}},{{'Survey extent':study,'Habitat polygons g01–g07':polys,'Paths path1–path4':paths,'Trees t01–t16':trees}}).addTo(map);
L.control.scale({{imperial:false}}).addTo(map);
map.fitBounds(study.getBounds());
</script></body></html>"""
with open(os.path.join(OUT, "swecc004_field_map.html"), "w") as f:
    f.write(html)

# ----------------------------------------------------------------- report
print(polys.drop(columns="geometry").to_string(index=False))
print(paths.drop(columns="geometry").to_string(index=False))
print(trees.drop(columns="geometry").to_string(index=False))
print("Removed:", *removed, sep="\n  ")
print("Polygon overlaps (m2):", overlaps)
b = study.to_crs(4326).total_bounds
print(f"Survey extent RD: x {minx:.0f}-{maxx:.0f}, y {miny:.0f}-{maxy:.0f} "
      f"({maxx - minx:.0f} x {maxy - miny:.0f} m); WGS84 lon {b[0]:.5f}-{b[2]:.5f}, lat {b[1]:.5f}-{b[3]:.5f}")
