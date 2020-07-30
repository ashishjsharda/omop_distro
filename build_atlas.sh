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

CDM_DB_NAME=test_install_gc
WEBAPI_DB_NAME=test_webapi
WEBAPI_DB_PORT=5432
WEBAPI_SCHEMA=webapi

function PSQL_admin {
    psql "sslmode=disable hostaddr=$DB_HOST  port=$DB_PORT user=ohdsi_admin_user dbname=$WEBAPI_DB_NAME password=$ADMIN_PASSWORD"
    return $?
}

function PSQL_no_db {
    psql "sslmode=disable hostaddr=$DB_HOST  port=$DB_PORT user=$DB_USER password=$DB_PASSWORD"
    return $?
}


function export_git_repos {
# Fetches code for ATLAS from github into the GITBASE.
    echo ""
    echo "** EXPORT REPOS"
    # should use tags here: TODO
    # Atlas has v.2.7.6 from 2020-01-23, used current
    #   ...I've seen 2.6 recommended https://forums.ohdsi.org/t/atlas-setup-failing/5858/2

    cd $GIT_BASE

    if [ ! -e ATLAS ]; then
        echo "exporting ATLAS"
        #git clone --depth 1 https://github.com/OHDSI/Atlas.git
        svn export https://github.com/OHDSI/Atlas/tags/v2.7.7 > /dev/null
        mv v2.7.7 Atlas 
        message $? "exporting ATLAS failed" 3
    fi

}

function insert_source_rows {
    echo ""
    echo " ** INSERT SOURCE ROWS into $WEBAPI_DB_NAME about $CDM_DB_NAME"
    echo "delete from $WEBAPI_SCHEMA.source_daimon where source_id in (99, 98, 97);" | PSQL_admin
    echo "delete from  $WEBAPI_SCHEMA.source where source_id in (99, 98, 97);" | PSQL_admin
    message $? "failed to delete" 3

    # SOURCES
    echo "insert into $WEBAPI_SCHEMA.source \
         (source_id, source_name, source_key, source_connection, source_dialect, username, password) \
        values (99, 'Synthea on localhost', '$CDM_DB_NAME', 'jdbc:postgresql://localhost:$DB_PORT/$CDM_DB_NAME', \
                'postgresql', 'ohdsi_app_user', '');" \
        | PSQL_admin

    #echo "insert into $WEBAPI_SCHEMA.source \
    #    (source_id, source_name, source_key, source_connection, source_dialect, username, password) \
    #    values (98, 'Synthea on Cloud SQL via proxy', '$CDM_DB_NAME', 'jdbc:postgresql://localhost:$DB_PORT/$CDM_DB_NAME', \
    #            'postgresql', 'ohdsi_app_user', '');" \
    #    | PSQL_admin

    #echo "insert into $WEBAPI_SCHEMA.source \
    #    (source_id, source_name, source_key, source_connection, source_dialect, username, password) \
    #    values (97, 'Synthea in BQ', '$CDM_DB_NAME', 'jdbc:postgresql://localhost:$DB_PORT/$CDM_DB_NAME', \
    #            'postgresql', 'ohdsi_app_user', '');" \
    #    | PSQL_admin

    echo ""

    # LOCAL
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) \
        values (1, 99, 0, '$CDM_SCHEMA', 1);" \
        | PSQL_admin
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) \
        values (2, 99, 1, '$VOCABULARY_SCHEMA', 1);" \
        | PSQL_admin
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) \
        values (3, 99, 2, '$RESULTS_SCHEMA', 1);" \
        | PSQL_admin

#    # Cloud SQL
#    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) \
#        values (1, 98, 0, '$CDM_SCHEMA', 1);" \
#        | PSQL_admin
#    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) \
#        values (1, 98, 1, '$VOCABULARY_SCHEMA', 1);" \
#        | PSQL_admin
#    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) \
#        values (1, 98, 2, '$RESULTS_SCHEMA', 1);" \
#        | PSQL_admin
#
#    # Big Query
#    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) \
#        values (1, 97, 0, '$CDM_SCHEMA', 1);" \
#        | PSQL_admin
#    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) \
#        values (1, 97, 1, '$VOCABULARY_SCHEMA', 1);" \
#        | PSQL_admin
#    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) \
#        values (1, 97, 2, '$RESULTS_SCHEMA', 1);" \
#        | PSQL_admin
#
}


function select_webapi_sources {
    echo "source"
    echo "select * from $WEBAPI_SCHEMA.source;" | PSQL_admin
    echo "source daimon"
    echo "select * from $WEBAPI_SCHEMA.source_daimon;" | PSQL_admin
}

function test_webapi_sources {
    echo ""
    echo "** TEST WEBAPI SOURCES $WEBAPI_SCHEMA $WEBAPI_DB_NAME"
    wget $TOMCAT_URL/WebAPI/source/sources
    message $? " wgetting WebAPI sources failed" 1
    CONTENTS=$(cat sources)
    rm sources
    if [[ $CONTENTS == '[]' ]] ;then
        echo "ERROR, no data sources: \"$CONTENTS\" $WEBAPI_SCHEMA $WEBAPI_DB_NAME"
        echo "check for webapi.source and webapi.source_daimon tables, and entries like those this script's insert_source_rows is inserting."
        echo "also, do we have to have the real schemas behind what they refer to, like vocabulary?"
        open $TOMCAT_URL/WebAPI/source/sources
        echo "exiting"
        exit 1
    else
        echo "cool! data sources: \"$CONTENTS\" "
        echo "proceed."
    fi
}


function build_and_install_atlas {
    echo ""
    echo "**ATLAS"

    which npm
    message $? "Couldn't find npm, please install it" 3

    cd $GIT_BASE/Atlas
    npm run build
    message $? "npm build of Atlas failed." 3

    cp -r $GIT_BASE/Atlas $TOMCAT_HOME/webapps
    cp $OMOP_DISTRO/config-local.js $TOMCAT_HOME/webapps/Atlas/js/

    sed -i .old1  s/APP_NAME/WebAPI/            $TOMCAT_HOME/webapps/Atlas/js/config-local.js
    sed -i .old2  s/TOMCAT_PORT/$TOMCAT_PORT/  $TOMCAT_HOME/webapps/Atlas/js/config-local.js
    open $TOMCAT_URL/Atlas/#/home
}


export_git_repos
insert_source_rows
select_webapi_sources
test_webapi_sources
build_and_install_atlas


