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
        ##svn export https://github.com/chrisroederucdenver/ETL-Synthea/tags/v0.9.3cr > /dev/null
        git clone git@github.com:chrisroederucdenver/ETL-Synthea.git
        message $? "exporting ETL-Synthea failed" 3
        #mv v0.9.3cr ETL-Synthea
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

function synthea_etl {
    echo ""
    echo "** SYNTHEA ETL into $SYNTHEA_SCHEMA $DB_NAME $SYNTHEA_OUTPUT"

    echo "drop schema $SYNTHEA_SCHEMA cascade" | psql  -U ohdsi_admin_user  $DB_NAME
    cat $OMOP_DISTRO/setup_schema.sql | sed  s/XXX/$SYNTHEA_SCHEMA/g  | psql  -U ohdsi_admin_user  $DB_NAME
    message $? " schema setup failed" 5

    cd $GIT_BASE/ETL-Synthea
    sed -i .old1  s/DB_NAME/$DB_NAME/ local_load.R
    sed -i .old2  s/SYNTHEA_SCHEMA/$SYNTHEA_SCHEMA/ local_load.R
    sed -i .old3  s/CDM/$CDM_SCHEMA/ local_load.R
    sed -i .old4  s/VOCABULARY/$VOCABULARY_SCHEMA/ local_load.R
    sed -i .old5  "s|SYNTHEA_OUTPUT|$SYNTHEA_OUTPUT|" local_load.R
    if [ -d $SYNTHEA_OUTPUT ]; then    ## TODO
        mkdir -p $SYNTHEA_OUTPUT 
    fi

    Rscript local_load.R
    message $? " synthea etl failed" 5
    cd $GIT_BASE
}

export_git_repos

#drop_indexes

synthea
synthea_etl

#create_indexes
