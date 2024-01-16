import subprocess

all_scripts = [
    "00_create_db.py",
    "01a_load_boundary_data.py",
    "01b_load_geodk_vejmidte.py",
    "01c_load_osm_data.py",
    "01d_load_urban_data.py",
    "02_create_and_classify_osm_road_network.py",
    "03_match_osm_geodk.py",
    "04_fill_cycling_columns.py",
    "05_create_vertices.py",
    "06_classify_intersections.py",
    "07_assign_muni_urban.py",
    "08_interpolate_missing_tags.py",
    "09_lts_classification.py",
    "10_clean_up_export.py",
]

for s in all_scripts:
    subprocess.run(["python", s])
