SWECC004 field map - ArcGIS
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
