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
SYNTHEA_OUTPUT=$GIT_BASE/synthea_47d09bf/output/csv


function export_git_repos {
# Fetches code  from github into the GITBASE.
    echo ""
    echo "** EXPORT REPOS"
    cd $GIT_BASE

    if [ ! -e synthea ]; then
        echo "exporting synthea"
        # The commit 47d09bf was referenced by Anthony Sena in a commit of the create_synthea_tables.sql file.
        # But, the archive command doesn't work from github as a way of getting the repo at the state of a commit.:
        # git archive --remote=git@github.com:synthetichealth/synthea.git 47d09bf | (cd synthea_xxx; tar x)

        # So, use two steps instead:
        git clone git@github.com:synthetichealth/synthea.git
        mkdir  synthea_47d09bf
        cd synthea
        git archive 47d09bf | (cd  ../synthea_47d09bf; tar x)
        message $? "exporting synthea failed" 3
    fi

    if [ ! -e ETL-Synthea ]; then
        echo "exporting ETL-Synthea"
        git clone git@github.com:chrisroederucdenver/ETL-Synthea --branch v5.3.1-updates-combined
        #svn export https://github.com/OHDSI/ETL-Synthea/tags/v5.3.1 > /dev/null
        #mv v5.3.1 ETL-Synthea
        message $? "exporting ETL-Synthea failed" 3
    fi
}

function synthea {
    echo ""
    echo "** SYNTHEA $GIT_BASE/synthea"

    cd $GIT_BASE/synthea_47d09bf

    sed -i .old "s/exporter.csv.export = false/exporter.csv.export = true/" src/main/resources/synthea.properties
    ./run_synthea -s 12345 -p 100
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
    echo "** LOAD RAW SYNTHEA Data"

    echo "drop schema $SYNTHEA_SCHEMA cascade" | PSQL_admin
    cat $OMOP_DISTRO/setup_schema.sql | sed  s/XXX/$SYNTHEA_SCHEMA/g  | PSQL_admin
    message $? " schema setup failed" 5

    cd $GIT_BASE/ETL-Synthea
cd /Users/croeder/work/git/ETL-Synthea
    Rscript SyntheaLoader.R postgresql localhost test_install_gc ohdsi_admin_user "" $DB_PORT $SYNTHEA_SCHEMA  $SYNTHEA_OUTPUT
    message $? " synthea load failed" 5
}

function show_synthea_counts {
    echo "select count(*) from synthea.patient;"
    echo "select count(*) from synthea.patient;" | PSQL

    echo "select count(*) from synthea.encounters;"
    echo "select count(*) from synthea.encounters;" | PSQL

    echo "select count(*) from synthea.observations;"
    echo "select count(*) from synthea.observations;" | PSQL

    echo "select count(*) from synthea.procedures;"
    echo "select count(*) from synthea.procedures;" | PSQL

    echo "select count(*) from synthea.providers;"
    echo "select count(*) from synthea.providers;" | PSQL
}

function do_map_talbes  { # finish
    # This function can take a while...an hour?
    echo ""
    echo "** SYNTHEA map tables "

    cd $GIT_BASE/ETL-Synthea

    echo "CREATING Map tables (LONG)"
    sed_file local_map_tables.R
    Rscript local_map_tables.R
    message $? " synthea create maps failed" 5
}

function synthea_etl {
    echo ""
    echo "** SYNTHEA ETL into $SYNTHEA_SCHEMA $DB_NAME $SYNTHEA_OUTPUT"

    cd $GIT_BASE/ETL-Synthea
cd /Users/croeder/work/git/ETL-Synthea
    echo "DOING ETL from Synthea to OMOP $GIT_BASE/ETL-Synthea"

    Rscript  SyntheaETL.r postgresql $DB_HOST $DB_NAME $DB_USER "$DB_PASSWORD" $DB_PORT $SYNTHEA_SCHEMA $CDM_SCHEMA  $VOCABULARY_SCHEMA
    message $? " synthea etl failed" 5

    cd $GIT_BASE
}


#export_git_repos
#drop_indexes

#synthea
load_synthea
show_synthea_counts

truncate_cdm_tables
#do_map_tables
synthea_etl
show_cdm_counts

#create_indexes
