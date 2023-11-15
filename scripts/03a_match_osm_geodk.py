# %%

from sqlalchemy import create_engine
import os

os.environ["USE_PYGEOS"] = "0"
import geopandas as gpd
from datetime import datetime
import time
import yaml
import psycopg2
import math
from src import db_functions as dbf

with open(r"../config.yml") as file:
    parsed_yaml_file = yaml.load(file, Loader=yaml.FullLoader)

    muni_fp = parsed_yaml_file["muni_fp"]

    crs = parsed_yaml_file["CRS"]

    db_name = parsed_yaml_file["db_name"]
    db_user = parsed_yaml_file["db_user"]
    db_password = parsed_yaml_file["db_password"]
    db_host = parsed_yaml_file["db_host"]
    db_port = parsed_yaml_file["db_port"]


print("Settings loaded!")

print("Initializing...")
print("Start", time.ctime())

starttime = time.ctime()

# %%
# Connect to database
con = dbf.connect_pg(db_name, db_user, db_password, db_port, db_host)

con.autocommit = True

# %%
segment_length = 10  # The shorter the segments, the longer the matching process will take. For cities with a gridded street network with streets as straight lines, longer segments will usually work fine
buffer_dist = 10  # TODO use longer buffer distance!
buffer_dist_offset = 20
hausdorff_threshold = 10
hausdorff_threshold_offset = 25
angular_threshold = 30
offset_dist = 9

maxunionprocess = 100000  # Value used for prossecing

# skema1 = "geodk"
# skema2 = "osm"

# Kaldenavn
network1 = "geodk"
network2 = "osm"

skemacalc = "calc_" + network1 + "_" + network2
matches_table = network1 + "_" + network2 + "_match"
suggestions_table = network1 + "_" + network2 + "_networksuggestion"

# %%
# TABLE1
table1 = "geodk_bike"
idcolumn1 = "objectid"
geometrycolumn1 = "geometry"
groupbycolumns1 = "vejkode,vejkategori"
offsetcolumn1 = ""  # COLUMN THAT IS USED TO CHECK WETHER THERE IS GOING TO BE OFFSET
offsetcolumnvalues1 = ""
offsetsidecolumn1 = ""
offsetrightvalue1 = ""
offsetleftvalue1 = ""
vejkategori1 = "vejkategori"

# TABLE2
table2 = "osm_roads"
idcolumn2 = "osm_id"
geometrycolumn2 = "geometry"
groupbycolumns2 = "osm_id,highway"  # TODO: UPDATE
offsetcolumn2 = ""  # COLUMN THAT IS USED TO CHECK WETHER THERE IS GOING TO BE OFFSET
offsetcolumnvalues2 = ""
offsetsidecolumn2 = ""
offsetrightvalue2 = ""
offsetleftvalue2 = ""
offsetbothvalue2 = ""
vejkategori2 = "highway"  # TODO: update

# %%
# ** CREATING TABLES ***
# PRECOMMANDS
precommands = (
    "DROP SCHEMA IF EXISTS " + skemacalc + " CASCADE",
    "CREATE SCHEMA " + skemacalc + "",
    "DROP table  IF EXISTS " + suggestions_table + " cascade",
    "DROP table  IF EXISTS " + suggestions_table + "_inverse cascade",
    "DROP table  IF EXISTS " + matches_table + " cascade",
    "DROP table  IF EXISTS " + matches_table + "_inverse cascade",
    "CREATE TABLE " + suggestions_table + " (id bigint,table2id decimal,geom geometry)",
    "CREATE TABLE "
    + suggestions_table
    + "_inverse (id bigint,table1id decimal,geom geometry)",
    "CREATE TABLE "
    + matches_table
    + " (id bigint,table2id decimal,vk_"
    + network1
    + " character varying,vk_"
    + network2
    + " character varying,geom geometry)",
    "CREATE TABLE "
    + matches_table
    + "_inverse (id bigint,table1id decimal,vk_"
    + network1
    + " character varying,vk_"
    + network2
    + " character varying,geom geometry)",
)
# %%
cur = con.cursor()
for precommand in precommands:
    cur.execute(precommand)

print("precommands done!")

# %%
# COMMANDS

commands = []

sql = (
    "SELECT min("
    + idcolumn1
    + ") as id, (st_dump(ST_LineMerge(st_union(ST_Force2D("
    + geometrycolumn1
    + "))))).geom  as geom, '' as offsetside INTO "
    + skemacalc
    + "._extract1 FROM "
    # + skema1
    # + "."
    + table1
    + " group by "
    + groupbycolumns1
)
commands.append(sql)

sql = (
    "SELECT min("
    + idcolumn2
    + ") as id, (st_dump(ST_LineMerge(st_union(ST_Force2D("
    + geometrycolumn2
    + "))))).geom  as geom, '' as offsetside  INTO "
    + skemacalc
    + "._extract2 FROM "
    # + skema2
    # + "."
    + table2
    + " group by "
    + groupbycolumns2
)

commands.append(sql)
# %%

# intermediatecommands COMMANDS
intermediatecommands = (
    # Splitting into smaller lines for table 1
    "WITH data(id, geom) AS (SELECT id, geom, offsetside FROM "
    + skemacalc
    + "._extract1) "
    "SELECT ROW_NUMBER () OVER () as id, id as table1id, i,ST_LineSubstring( geom, startfrac, LEAST( endfrac, 1 ))  AS geom, offsetside "
    "into " + skemacalc + "._subparts1 "
    "FROM ( SELECT id, geom, ST_Length(geom) len, "
    + str(segment_length)
    + " sublen, offsetside FROM data ) AS d "
    "CROSS JOIN LATERAL ( SELECT i, (sublen * i) / len AS startfrac,  (sublen * (i+1)) / len AS endfrac "
    "FROM generate_series(0, floor( len / sublen )::integer ) AS t(i) "
    "WHERE (sublen * i) / len <> 1.0 ) AS d2",
    # Index
    "CREATE INDEX idx_subparts1_geometry  ON "
    + skemacalc
    + "._subparts1 USING gist(geom)",
    # Splitting into smaller lines for table 2
    "WITH data(id, geom) AS (SELECT id, geom, offsetside FROM "
    + skemacalc
    + "._extract2) "
    "SELECT ROW_NUMBER () OVER () as id, id as table2id, i, ST_LineSubstring( geom, startfrac, LEAST( endfrac, 1 ))  AS geom , offsetside "
    "into " + skemacalc + "._subparts2 "
    "FROM ( SELECT id, geom, ST_Length(geom) len, "
    + str(segment_length)
    + " sublen, offsetside FROM data ) AS d "
    "CROSS JOIN LATERAL ( SELECT i, (sublen * i) / len AS startfrac,  (sublen * (i+1)) / len AS endfrac "
    "FROM generate_series(0, floor( len / sublen )::integer ) AS t(i) "
    "WHERE (sublen * i) / len <> 1.0 ) AS d2",
    # Index
    "CREATE INDEX idx_subparts2_geometry  ON "
    + skemacalc
    + "._subparts2 USING gist(geom)",
    # Candidates
    "SELECT table1id, table2id, id1, id2,angle, CASE WHEN angle>270 THEN 360-angle WHEN angle>180 THEN angle-180 WHEN angle>90 THEN 180-angle ELSE angle END as angle_red, hausdorffdist, geom1, geom2, offsetside1, offsetside2 INTO "
    + skemacalc
    + "._candidates "
    "from (SELECT subparts1.table1id as table1id,  subparts2.table2id as table2id, subparts1.id as id1, subparts2.id as id2, degrees(ST_Angle(st_asText(subparts1.geom), st_asText(subparts2.geom))) AS angle, "
    "ST_HausdorffDistance(subparts1.geom,subparts2.geom) as hausdorffdist , subparts1.geom as geom1, subparts2.geom as geom2, subparts1.offsetside as offsetside1, subparts2.offsetside as offsetside2 "
    "FROM "
    + skemacalc
    + "._subparts1 as subparts1 join  "
    + skemacalc
    + "._subparts2 as subparts2 ON ST_Intersects(subparts1.geom, "
    "CASE WHEN  subparts2.offsetside='' THEN ST_Buffer(subparts2.geom,"
    + str(buffer_dist)
    + " )	WHEN  subparts2.offsetside='h' THEN ST_Buffer(subparts2.geom,"
    + str(buffer_dist_offset)
    + ", 'side=right' ) "
    "WHEN  subparts2.offsetside='v' THEN ST_Buffer(subparts2.geom,"
    + str(buffer_dist_offset)
    + ", 'side=left' )	END) ) as a",
    # MATCHES
    "SELECT _candidates.table1id, _candidates.table2id, _candidates.id1, _candidates.id2, _candidates.angle, _candidates.angle_red, _candidates.hausdorffdist, _candidates.geom2 as geom "
    "into " + skemacalc + "._matches "
    "FROM "
    + skemacalc
    + "._candidates as _candidates join (select id2, min(hausdorffdist) as mindist 	FROM "
    + skemacalc
    + "._candidates where angle_red <"
    + str(angular_threshold)
    + " AND "
    "CASE WHEN _candidates.offsetside2 in ('h','v') THEN  hausdorffdist<"
    + str(hausdorff_threshold_offset)
    + " ELSE  hausdorffdist<"
    + str(hausdorff_threshold)
    + " END group by id2) as a "
    "on a.id2=_candidates.id2 AND mindist=_candidates.hausdorffdist",
    # Index
    "CREATE INDEX idx_matches_geometry  ON " + skemacalc + "._matches USING gist(geom)",
    # MATCHES2
    "SELECT _candidates.table1id, _candidates.table2id, _candidates.id1, _candidates.id2, _candidates.angle, _candidates.angle_red, _candidates.hausdorffdist, _candidates.geom1 as geom "
    "into " + skemacalc + "._matches2 "
    "FROM "
    + skemacalc
    + "._candidates as _candidates join (select id1, min(hausdorffdist) as mindist 	FROM "
    + skemacalc
    + "._candidates where angle_red <"
    + str(angular_threshold)
    + " AND "
    "CASE WHEN _candidates.offsetside2 in ('h','v') THEN  hausdorffdist<"
    + str(hausdorff_threshold_offset)
    + " ELSE  hausdorffdist<"
    + str(hausdorff_threshold)
    + " END group by id1) as a "
    "on a.id1=_candidates.id1 AND mindist=_candidates.hausdorffdist",
    # Index
    "CREATE INDEX idx_matches2_geometry  ON "
    + skemacalc
    + "._matches2 USING gist(geom)",
)
for command in intermediatecommands:
    commands.append(command)


commandcounter = 0
cur = con.cursor()
for command in commands:
    commandcounter = commandcounter + 1
    print("Processing intermediatecommand SQL #" + str(commandcounter))
    # print("skipping")
    cur.execute(command)

# %%

# Finder antal records for subparts
subparts1 = 0
subparts2 = 0
cur = con.cursor()
cur.execute("select count(*) as antal from " + skemacalc + "._subparts1")
record = cur.fetchall()
for row in record:
    print("hej")
    subparts1 = int(row[0])

# %%
cur = con.cursor()
cur.execute("select count(*) as antal from " + skemacalc + "._subparts2")
record = cur.fetchall()
for row in record:
    subparts2 = int(row[0])

# %%

commands = []
sql = ""

iter1 = 0
iter1max = math.ceil(subparts1 / maxunionprocess)
# FNIAL COMMANDS (LOOPING )
while iter1 < iter1max:
    minvalue = iter1 * maxunionprocess
    iter1 = iter1 + 1
    maxvalue = iter1 * maxunionprocess
    subparts1commands = (
        # SUGGESTING PATHS FROM TABLE1
        "INSERT INTO " + suggestions_table + "_inverse (id,table1id,geom) "  # output.
        "select id, table1id::decimal, CASE WHEN offsetside = ''  or ST_IsClosed(geom)  THEN geom WHEN offsetside='h' THEN ST_OffsetCurve(ST_SimplifyPreserveTopology(geom,0.001),-"
        + str(offset_dist)
        + ")  WHEN offsetside='v' THEN ST_OffsetCurve(ST_SimplifyPreserveTopology(geom,0.001),"
        + str(offset_dist)
        + ") END as geom "
        "FROM (select min(id) as id, min(subparts1.table1id) as table1id, (st_dump(ST_LineMerge(st_union(ST_Force2D(subparts1.geom))))).geom as geom, subparts1.offsetside as offsetside "
        "from " + skemacalc + "._subparts1 as subparts1 "
        "left join "
        + skemacalc
        + "._matches2 as matches on subparts1.id=matches.id1 where subparts1.id>"
        + str(minvalue)
        + " AND subparts1.id<="
        + str(maxvalue)
        + " AND "
        "matches.id2 is null AND  st_length(ST_Force2D(subparts1.geom))>0.001  group by offsetside) as a",
        # MATCHES2 WITH INFO TO OUTPUT
        "INSERT into "  # output.
        + matches_table
        + "_inverse (id,table1id,vk_"
        + network1
        + ",vk_"
        + network2
        + ",geom) "
        "select id, table1id::decimal,vk_"
        + network1
        + ",vk_"
        + network2
        + ", CASE WHEN offsetside = ''  or ST_IsClosed(geom)  THEN geom WHEN offsetside='h' THEN ST_OffsetCurve(ST_SimplifyPreserveTopology(geom,0.001),-"
        + str(offset_dist)
        + ")  WHEN offsetside='v' THEN ST_OffsetCurve(ST_SimplifyPreserveTopology(geom,0.001),"
        + str(offset_dist)
        + ") END as geom "
        "FROM (select min(subparts1.id) as id, min(subparts1.table1id) as table1id, table1."
        + vejkategori1
        + " as vk_"
        + network1
        + ",  table2."
        + vejkategori2
        + " as vk_"
        + network2
        + ",(st_dump(ST_LineMerge(st_union(ST_Force2D(subparts1.geom))))).geom as geom, "
        "subparts1.offsetside as offsetside "
        "from " + skemacalc + "._subparts1 as subparts1 "
        "left join " + skemacalc + "._matches2 as matches on subparts1.id=matches.id1 "
        "LEFT JOIN "
        # + skema1
        # + "."
        + table1 + " as table1 on  matches.table1id = table1." + idcolumn1 + " "
        "LEFT JOIN "
        # + skema2
        # + "."
        + table2
        + " as table2 on matches.table2id = table2."
        + idcolumn2
        + "  where matches.id2 is not null and subparts1.id>"
        + str(minvalue)
        + " AND subparts1.id<="
        + str(maxvalue)
        + " "
        " group by offsetside,table1."
        + vejkategori1
        + " ,  table2."
        + vejkategori2
        + ") as a",
        # Index
    )
    for command in subparts1commands:
        commands.append(command)

commands.append(
    "CREATE INDEX idx_"
    + suggestions_table
    + "_inverse_geometry  ON "  # output.
    + suggestions_table
    + "_inverse USING gist(geom)"
)
commands.append(
    "CREATE INDEX idx_"
    + matches_table
    + "_inverse_geometry  ON "  # output.
    + matches_table
    + " USING gist(geom)"
)

iter2 = 0
iter2max = math.ceil(subparts2 / maxunionprocess)
# FNIAL COMMANDS (LOOPING )
while iter2 < iter2max:
    minvalue = iter2 * maxunionprocess
    iter2 = iter2 + 1
    maxvalue = iter2 * maxunionprocess
    subparts2commands = (
        # SUGGESTING PATHS FROM TABLE2
        "INSERT into " + suggestions_table + "  (id,table2id,geom) "  # output.
        "select id, table2id, CASE WHEN offsetside = ''  or ST_IsClosed(geom)  THEN geom WHEN offsetside='h' THEN ST_OffsetCurve(ST_SimplifyPreserveTopology(geom,0.001),-"
        + str(offset_dist)
        + ")  WHEN offsetside='v' THEN ST_OffsetCurve(ST_SimplifyPreserveTopology(geom,0.001),"
        + str(offset_dist)
        + ") END as geom "
        "FROM (select min(id) as id, min(subparts2.table2id) as table2id, (st_dump(ST_LineMerge(st_union(ST_Force2D(subparts2.geom))))).geom as geom, subparts2.offsetside as offsetside "
        "from " + skemacalc + "._subparts2 as subparts2 "
        "left join "
        + skemacalc
        + "._matches as matches on subparts2.id=matches.id2 where  subparts2.id>"
        + str(minvalue)
        + " AND subparts2.id<="
        + str(maxvalue)
        + " AND "
        "matches.id1 is null AND  st_length(ST_Force2D(subparts2.geom))>0.001  group by offsetside) as a",
        # MATCHES1 WITH INFO TO OUTPUT
        "INSERT into "  # output.
        + matches_table
        + " (id,table2id,vk_"
        + network1
        + ",vk_"
        + network2
        + ",geom) "
        "select id, table2id,vk_"
        + network1
        + ",vk_"
        + network2
        + ", CASE WHEN offsetside = ''  or ST_IsClosed(geom)  THEN geom WHEN offsetside='h' THEN ST_OffsetCurve(ST_SimplifyPreserveTopology(geom,0.001),-"
        + str(offset_dist)
        + ")  WHEN offsetside='v' THEN ST_OffsetCurve(ST_SimplifyPreserveTopology(geom,0.001),"
        + str(offset_dist)
        + ") END as geom "
        "FROM (select min(subparts2.id) as id, min(subparts2.table2id) as table2id, table1."
        + vejkategori1
        + " as vk_"
        + network1
        + ",  table2."
        + vejkategori2
        + " as vk_"
        + network2
        + ",(st_dump(ST_LineMerge(st_union(ST_Force2D(subparts2.geom))))).geom as geom, "
        "subparts2.offsetside as offsetside "
        "from " + skemacalc + "._subparts2 as subparts2 "
        "left join " + skemacalc + "._matches as matches on subparts2.id=matches.id2 "
        "LEFT JOIN "
        # + skema1
        # + "."
        + table1 + " as table1 on  matches.table1id = table1." + idcolumn1 + " "
        "LEFT JOIN "
        # + skema2
        # + "."
        + table2
        + " as table2 on matches.table2id = table2."
        + idcolumn2
        + "  where matches.id1 is not null and subparts2.id>"
        + str(minvalue)
        + " AND subparts2.id<="
        + str(maxvalue)
        + " "
        " group by offsetside,table1."
        + vejkategori1
        + " ,  table2."
        + vejkategori2
        + ") as a",
    )
    for command in subparts2commands:
        commands.append(command)

commands.append(
    "CREATE INDEX idx_"
    + suggestions_table
    + "_geometry  ON "  # output.
    + suggestions_table
    + " USING gist(geom)"
)
commands.append(
    "CREATE INDEX idx_"
    + matches_table
    + "_geometry  ON "  # output.
    + matches_table
    + " USING gist(geom)"
)

commandcounter = 0
cur = con.cursor()
for command in commands:
    commandcounter = commandcounter + 1
    print("Result sql #" + str(commandcounter))
    # if commandcounter == 118:
    #    print(command)
    cur.execute(command)


print("DONE!!!!")
print("Start", starttime)
print("Endtime", time.ctime())


# %%
