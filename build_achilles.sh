#!/bin/bash
set -euf
set -o pipefail

# This creates a results schema and runs Achilles against it and a cdm schema.
# This must be on the same database as the cdm and vocabulary schemas.o
# The ddl that comes out of WebAPI for this purpose makes references to 
# a vocab schema. I haven't set one up, so I edit the file to replace
# "vocab." with "cdm." in get_results_ddl.

. build_passwords.sh
. build_common.sh

function export_git_repos {
    cd $GIT_BASE

# 2020-07-29 91f9a20
    if [ ! -e Achilles ]; then
        echo "cloning Achilles"
        git clone --depth 1 https://github.com/OHDSI/Achilles > /dev/null
        message $? "cloning Achilles failed" 3
    fi

# 2020-07-25 c255328
    if [ ! -e AchillesWeb ]; then
        echo "exporting AchillesWeb"
        git clone --depth 1 https://github.com/OHDSI/AchillesWeb
        message $? "exporting AchillesWeb failed" 3
    fi
}

function results_schema {
    echo ""
    echo "** RESULTS SCHEMA"
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$RESULTS_SCHEMA/g  \
      | PSQL_admin
    message $? " results schema failed" 7
}

function get_results_ddl {
    echo ""
    echo "** RESULTS DDL"
    # Achilles sets this up based on its config.
    # Here as a way of debugging.
    # https://forums.ohdsi.org/t/ddl-scripts-for-results-achilles-results-derived-etc/9618/6
    wget -O results.ddl "$TOMCAT_URL/WebAPI/ddl/results?dialect=postgresql" 
    message $? " get_results_ddl failed wget" 7
    echo "got results.ddl...."


    # results.ddl already specifies a results schema name.
    cat results.ddl | sed  s/results/$RESULTS_SCHEMA/g  \
      | sed  s/vocab\\./cdm\\./g  \
      | PSQL_admin
    message $? " get_results_ddl failed" 7
    echo "...must be  int he db now."
}

function achilles {
    echo ""
    echo "** ACHILLES"

    cd $GIT_BASE/Achilles
    cp $OMOP_DISTRO/run_achilles.R .
    sed -i .old1 s/DB_NAME/$DB_NAME/ run_achilles.R
    sed -i .old2 s/PORT/$DB_PORT/ run_achilles.R
    sed -i .old3 s/CDM_SCHEMA/$CDM_SCHEMA/ run_achilles.R
    sed -i .old4 s/VOCABULARY_SCHEMA/$VOCABULARY_SCHEMA/ run_achilles.R
    sed -i .old5 s/RESULTS_SCHEMA/$RESULTS_SCHEMA/ run_achilles.R
    Rscript run_achilles.R .
    message $? " achilles failed"  6
}


# UNFINISHED
function achilles_web {
    echo ""
    echo "** ACHILLES WEB "
    cp -r $GIT_BASE/AchillesWeb $TOMCAT_HOME/webapps
    mkdir $TOMCAT_HOME/webapps/AchillesWeb/data
    echo "{ \"datasources\":[ { \"name\":\"$DB_NAME\", \"folder\":\"SAMPLE\", \"cdmVersion\": 5 } ] } " > $TOMCAT_HOME/webapps/AchillesWeb/data/datasources.json
# that step of running an R script to extract achilles results into json files and make them available via tomcat in that data directory
}

export_git_repos
results_schema
get_results_ddl
achilles

