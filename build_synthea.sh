#!/bin/bash
set -euf
set -o pipefail

# build_atlash.sh :  depends on build_webapi.sh 
# 
# This script finishes setting up WebAPI and then installs ATLAS.
# The build_webapi.sh script triggers the flyway migration to
# create the webapi schema which needs to complete before running
# this script.
#
# Install npm if you haven't: https://nodejs.org/en/download/
#
# Chris Roeder
# July, 2020

. ./build_passwords.sh
. ./build_common.sh


SYNTHEA_SCHEMA=synthea
SYNTHEA_OUTPUT=$GIT_BASE/synthea/output/csv

function export_git_repos {
# Fetches code for WebAPI and ATLAS from github into the GITBASE.
    echo ""
    echo "** EXPORT REPOS"
    cd $GIT_BASE

    if [ ! -e synthea ]; then
        echo "exporting synthea"
        svn export https://github.com/synthetichealth/synthea/tag/v2.5.0
        mv v2.5.0 synthea
        #svn export https://github.com/synthetichealth/synthea/trunk > /dev/null
        message $? "exporting synthea failed" 3
        mv trunk synthea
    fi

    if [ ! -e ETL-Synthea ]; then
        echo "exporting ETL-Synthea"
        svn export https://github.com/chrisroederucdenver/ETL-Synthea/tags/v0.9.3cr > /dev/null
        mv v0.9.3cr ETL-Synthea
        ##git clone git@github.com:chrisroederucdenver/ETL-Synthea.git # head is for CMD v6
        message $? "exporting ETL-Synthea failed" 3
    fi
}

function synthea {
    echo ""
    echo "** SYNTHEA $GIT_BASE/synthea"
    cd $GIT_BASE/synthea
    sed -i .old "s/exporter.csv.export = false/exporter.csv.export = true/" src/main/resources/synthea.properties
    ./run_synthea
    message $? " synthea failed" 4
    cd $GIT_BASE
}

function sed_file {
    echo " * editting $1"
    sed -i .old1  "s/DB_NAME/$DB_NAME/" $1
    sed -i .old2  "s/SYNTHEA_SCHEMA/$SYNTHEA_SCHEMA/" $1
    sed -i .old3  "s/CDM/$CDM_SCHEMA/" $1
    sed -i .old4  "s/VOCABULARY/$VOCABULARY_SCHEMA/" $1
    sed -i .old5  "s|SYNTHEA_OUTPUT|$SYNTHEA_OUTPUT|" $1
}

function load_synthea {
    echo ""
    echo "** LOAD RAW SYNTHEA ETL"

    echo "drop schema $SYNTHEA_SCHEMA cascade" | psql  -U ohdsi_admin_user  $DB_NAME
    cat $OMOP_DISTRO/setup_schema.sql | sed  s/XXX/$SYNTHEA_SCHEMA/g  | psql  -U ohdsi_admin_user  $DB_NAME
    message $? " schema setup failed" 5

    cd $GIT_BASE/ETL-Synthea
    sed_file local_synthea_tables.R

    echo "LOADING Synthea data"
    Rscript local_synthea_tables.R
    message $? " synthea load failed" 5
}

function synthea_etl {
    echo ""
    echo "** SYNTHEA ETL into $SYNTHEA_SCHEMA $DB_NAME $SYNTHEA_OUTPUT"

    cd $GIT_BASE/ETL-Synthea
    sed_file local_load_events.R
    sed_file local_map_tables.R
    if [ -d $SYNTHEA_OUTPUT ]; then    ## TODO
        mkdir -p $SYNTHEA_OUTPUT 
    fi

     echo "CREATING Map tables (LONG)"
     Rscript local_map_tables.R
     message $? " synthea create maps failed" 5

    echo "DOING ETL from Synthea to OMOP $GIT_BASE/ETL-Synthea"
    Rscript local_load_events.R
    message $? " synthea etl failed" 5

    cd $GIT_BASE
}


export_git_repos


#drop_indexes

synthea
load_synthea
truncate_cdm_tables
synthea_etl
show_cdm_counts

#create_indexes
