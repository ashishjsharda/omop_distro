#!/bin/bash


# 1. download vocabulary from athena
# 2. install postgres, or configure Cloud SQL,  or setup a Google Big Query
# 3. edit build_common.sh, build_passwords.sh

# set up a db with a CDM and Results schemas
./build_cdm.sh

# add some synthetic data
./build_synthea.sh

# Install WebAPI
# installs tomcat, builds and installs webapi which then creates the webapi schema and it's tables, etc.
# WebAPI finds it's databases based on webapi_settings.xml, here in omop_distro.
# Achilles, below, needs WebAPI as a source for its schema, so this has to come before that.
./build_webapi.sh

# results is a schema needed by Achilles, and others as a place to populate the results of its analysis.
# Maybe webapi uses it that way as well. The original place for results schema ddl is webapi,
# but Ithink I've seen achilles add tables? Regardless, ATLAS isn't happy without it
# and wants it populated, so run achilles too.
./build_achilles.sh*

# Start webapi
# I typically hit a button in the tomcat manager app, but I wonder if it can be scripted
# via curl or wget.
????

# Install ATLAS
# ATLAS finds it's WebAPI URL from config-local.js that gets built into 
# its war before it gets installed in tomcat
# The script adds rows to webapi.source and webapi.source_daimon so that it
# can find the CDMs you want to analyze.
./build_atlas.sh



