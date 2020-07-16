#!/bin/bash

# download vocabulary from athena

# install postgres
edit build_passwords.sh*
either build_cdm or build_webapi will try to create the database and roles. The other will show warnings because they fail if its already been done.

# or configure Cloud SQL 
build_cloud_sql.sh
# connect ot google via a proxy making it local. proxy_run_sql.sh. We use a different port 
# number to differenitate it from a localy running postgresql that is on 5432 already.
# Can also connect via SSL and pem files, but I need to figure out how to tell the jdbc in Spring how to do that.

# or setup a Google Big Query
build_big_query.sh

# set up a db with a CDM and Results schemas
#  and load the vocabulary into the CDM
# WARNING: the vocabulary is big, takes a long time to load onto Cloud SQL, and might cost a few bucks.
# set database parameters in build_common.sh before hand
# WARNING: the script includes a function create_indexes that is called in order that
# later achilles stuff runs in a reasonable amount of time.
# Since this script just sets up the schema and doesn't do a complete ETL,
# you'll have to do the data load, and the indexes should be removed 
# before that step, or *they* won't run in a reasonable amount of time.
# Achilles (and others) need the indexes, ETL's data load needs them to be off.
edit build_common.sh*
build_cdm.sh



# install tomcat, build and install webapi, get the webapi schema for free
# WebAPI finds it's databases based on webapi_settings.xml. It's used to generate
# applications.properties that goes into the war, that gets installed in tomcat.
# WebAPI sets up its own schema when it is installed to tomcat. It uses flyway to do this.
build_webapi.sh


# results is a schema needed by Achilles as a place to populate the results of its analysis.
# Maybe webapi uses it that way as well. The original place for results schema ddl is webapi,
# but Ithink I've seen achilles add tables? Regardless, ATLAS isn't happy without it
# and wants it populated, so run achilles too.
build_achilles.sh*

# START WEBAPI
# I typically hit a button in the tomcat manager app, but I wonder if it can be scripted
# via curl or wget.
????

# install ATLAS and enter rows that direct it to the CDMl
# ATLAS finds it's WebAPI URL from config-local.js that gets built into 
# its war before it gets installed in tomcat
# The script adds rows to webapi.source and webapi.source_daimon so that it
# can find the CDMs you want to analyze.
build_atlas.sh


# add some synthetic data
build_synthea.sh


# still need to install Django and related code
# need to configure that stuff to use a schema to.
# import some BioLINCC studies into a different CDM.
**TODO**


# finally need to setup a google VM to run all this on instead of my mac.
# And don't forget to learn and do good security!!!
**TODO**

# HERE's the RUB:
# You can put a CDM onto a read/only database like BigQuery. Obviously it will have
# vocabulary. WebAPI's webapi schema can easily go onto a different database.
# --> Q: Does WebAPI assume that the results schema is on the same database as the CDM?
# If it does, that could be a problem. Is BigQuery read/write in a way that works?
# It it doesn't, there must be a vocabulary schema on the same db as the results schema
# because the results.ddl makes reference to it.
# clearly the CDM should be read-only and the resutls schema should be read/write.
# But it's not clear if results can be on a different database.
# In fact, there are signs that it goes 1:1 with a cdm. Most clearly, that the schema name
# is hard-coded in the ddl. 
# Q: I'm guessing the Achilles code hard codes the results schema name?
