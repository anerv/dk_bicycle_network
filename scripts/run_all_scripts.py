import subprocess

print("Running step 00...")
subprocess.run(["python", "00_create_db.py"], stdout=subprocess.DEVNULL)
print("Step 00 complete...")

print("Running step 1a...")
subprocess.run(["python", "01a_load_boundary_data.py"], stdout=subprocess.DEVNULL)
print("Step 1a complete...")

print("Running step 1b...")
subprocess.run(["python", "01b_load_geodk_vejmidte.py"], stdout=subprocess.DEVNULL)
print("Step 1b complete...")

print("Running step 1c...")
subprocess.run(["python", "01c_load_osm_data.py"], stdout=subprocess.DEVNULL)
print("Step 1c complete...")

print("Running step 00...")
subprocess.run(["python", "01d_load_urban_data.py"], stdout=subprocess.DEVNULL)
print("Step 00 complete...")

print("Running step 02...")
subprocess.run(
    ["python", "02_create_and_classify_osm_road_network.py"], stdout=subprocess.DEVNULL
)
print("Step 02 complete...")

print("Running step 03...")
print("This step can take a while to complete...")
subprocess.run(["python", "03_match_osm_geodk.py"], stdout=subprocess.DEVNULL)
print("Step 03 complete...")

print("Running step 04...")
subprocess.run(["python", "04_fill_cycling_columns.py"], stdout=subprocess.DEVNULL)
print("Step 04 complete...")

print("Running step 05...")
subprocess.run(["python", "05_create_vertices.py"], stdout=subprocess.DEVNULL)
print("Step 05 complete...")

print("Running step 06...")
subprocess.run(["python", "06_classify_intersections.py"], stdout=subprocess.DEVNULL)
print("Step 06 complete...")

print("Running step 07...")
subprocess.run(["python", "07_identify_bus_routes.py"], stdout=subprocess.DEVNULL)
print("Step 07 complete...")

print("Running step 08...")
subprocess.run(["python", "08_assign_muni_urban.py"], stdout=subprocess.DEVNULL)
print("Step 08 complete...")

print("Running step 09...")
subprocess.run(["python", "09_interpolate_missing_tags.py"], stdout=subprocess.DEVNULL)
print("Step 09 complete...")

print("Running step 10...")
subprocess.run(["python", "10_lts_classification.py"], stdout=subprocess.DEVNULL)
print("Step 10 complete...")

print("Running step 11...")
subprocess.run(["python", "11_clean_up_export.py"], stdout=subprocess.DEVNULL)
print("Step 11 complete...")
