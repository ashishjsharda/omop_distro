#!/bin/bash
set -euf
set -o pipefail

# This script setups tomcat and  WebAPI given a PostgreSQL connection.
#
# Chris Roeder
# July, 2020

. ./build_passwords.sh

HOME=/Users/croeder/work

# Set the db connection info in settings.xml and name the profile in the call to maven.
# Info is duplicated here for build related work. The settings.xml is for Spring.

# local Postgresql
## WEBAPI_SCHEMA=webapi
## DB_HOST=127.0.0.1
## DB_NAME=test1
## POSTGRESQL_PORT=5432
## PROFILE=local_postgresql
## DB_USER=croeder

# Cloud SQL via proxy
WEBAPI_SCHEMA=webapi
DB_HOST=127.0.0.1
DB_NAME=test1
POSTGRESQL_PORT=5433
PROFILE=cloud_sql_via_proxy
DB_USER=postgres
#DB_PASSWORD=
#ADMIN_PASSWORD=

##  Cloud SQL via SSL
## WEBAPI_SCHEMA=webapi
## DB_HOST=34.71.79.17
## DB_NAME=test1
## POSTGRESQL_PORT=5432
## PROFILE=cloud_sql_via_ssl
## DB_USER=postgres
PEM_DIR=/Users/croeder/play/git/google-cloud

CDM_SCHEMA="cdm"
VOCABULARY_SCHEMA="vocabulary"
RESULTS_SCHEMA="results"


OMOP_DISTRO=$HOME/git/omop_distro
GIT_BASE=$HOME/git/test_install
DEPLOY_BASE=$HOME/test_deploy



TOMCAT_RELEASE=9.0.37
TOMCAT_ARCHIVE_URL="https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_RELEASE}/bin/apache-tomcat-${TOMCAT_RELEASE}.tar.gz"
TOMCAT_DIR=apache-tomcat-${TOMCAT_RELEASE}
TOMCAT_ARCHIVE="apache-tomcat-${TOMCAT_RELEASE}.tar.gz"
TOMCAT_HOME=$DEPLOY_BASE/tomcat/$TOMCAT_DIR
TOMCAT_PORT=8080
TOMCAT_URL=http://127.0.0.1:$TOMCAT_PORT/



# USING SSL
## function PSQL_no_db {
##     psql "sslmode=verify-ca sslrootcert=$PEM_DIR/server-ca.pem sslcert=$PEM_DIR/client-cert.pem sslkey=$PEM_DIR/client-key.pem hostaddr=$DB_HOST port=5432 user=$DB_USER password=$DB_PASSWORD"
##
##
## function PSQL {
##     psql "sslmode=verify-ca sslrootcert=$PEM_DIR/server-ca.pem sslcert=$PEM_DIR/client-cert.pem sslkey=$PEM_DIR/client-key.pem hostaddr=$DB_HOST     port=5432 user=$DB_USER dbname=$DB_NAME password=$DB_PASSWORD"
## }
##
## function PSQL_admin {
##     psql "sslmode=verify-ca sslrootcert=$PEM_DIR/server-ca.pem sslcert=$PEM_DIR/client-cert.pem sslkey=$PEM_DIR/client-key.pem hostaddr=$DB_HOST       port=5432 user=ohdsi_admin_user dbname=$DB_NAME password=$ADMIN_PASSWORD"
## }

# IF THE PROXY IS RUNNING - note the different port!
function PSQL_no_db {
    psql "sslmode=disable hostaddr=$DB_HOST  port=5433 user=$DB_USER password=$DB_PASSWORD"
}

function PSQL {
    psql "sslmode=disable hostaddr=$DB_HOST  port=5433 user=$DB_USER dbname=$DB_NAME password=$DB_PASSWORD"
}

function PSQL_admin {
    psql "sslmode=disable hostaddr=$DB_HOST  port=5433 user=ohdsi_admin_user dbname=$DB_NAME password=$ADMIN_PASSWORD"
}

function message  {
    # check status, output message and exit with exitval, if the status is not 0
    # Ex. call:  message $? "creating db $DB_NAME failed" 3
    status=$1
    msg=$2
    exitval=$3

    if [[ "$status" != "0" ]] ; then
        echo "********************"
        echo "\"$status\" $msg"
        exit $exitval
    fi
}


function shutdown_and_delete_old {
# Here to support iterative development of the install scripts,
# this script shuts down tomcat, and cleans out deployment directories.

    set +e
    set +o pipefail
    $TOMCAT_HOME/bin/shutdown.sh
    set -o pipefail
    set -e
    cat $OMOP_DISTRO/drop_db.sql  \
      | sed  s/XXX/$DB_NAME/g  \
      | PSQL_no_db
    message $? "creating db $DB_NAME failed" 3
    rm -rf $GIT_BASE
    rm -rf $DEPLOY_BASE

    cat $OMOP_DISTRO/drop_postgres_roles.sql | PSQL_no_db
}

function make_new {
# Sets up a new postgress database and deployment directories
    echo ""
    echo "** PostgreSQL Roles"
    cat $OMOP_DISTRO/setup_postgresql_roles.sql | \
       sed "s/XXXUSER/$DB_USER/g" | sed "s/XXX_PASSWORD_XXX/$ADMIN_PASSWORD/g" | PSQL_no_db
    echo " A GIT BASE? $GIT_BASE"
    mkdir $DEPLOY_BASE
    mkdir $GIT_BASE
    echo " B GIT BASE? $GIT_BASE"
    cd $GIT_BASE

    echo "** PostgreSQL DB $OMOP_DISTRO"
    cat $OMOP_DISTRO/setup_db.sql  \
      | sed  s/XXX/$DB_NAME/g  \
      | PSQL_no_db
    message $? "creating db $DB_NAME failed" 3
}

function test_db_users {
    echo "select rolname from pg_roles; \q" | PSQL
    message $? "couldn't get into PSQL" 99
    echo "select rolname from pg_roles ; \q" | PSQL_admin
    message $? "couldn't get into PSQL_admin" 98
}

function install_tomcat {
    echo ""
    echo "** TOMCAT"
    set +e
    set +o pipefail
    kill $(ps -aef | grep tomcat | awk '{print $2}')
    set -o pipefail
    set -e
    cd $DEPLOY_BASE
    mkdir tomcat
    cd tomcat
    if [ ! -e $TOMCAT_ARCHIVE ]; then
        wget $TOMCAT_ARCHIVE_URL
        message $? " tomcat download failed" 1
    fi

    tar xzf $TOMCAT_ARCHIVE
    message $? " tomcat extract failed" 1

    cd $TOMCAT_HOME
    sed -i .old s/8080/$TOMCAT_PORT/g conf/server.xml
    cat conf/tomcat-users.xml      | awk 'NR==44 {print " <role rolename=\"manager-gui\"/>  " } {print}' > conf/tomcat-users.xml.new1
    cat conf/tomcat-users.xml.new1 | awk 'NR==45 {print " <role rolename=\"tomcat\"/>  " } {print}' > conf/tomcat-users.xml.new4
    cat conf/tomcat-users.xml.new4 | awk 'NR==46 {print "<user username=\"tomcat\" password=\"Harmonization\" roles=\"tomcat,manager-gui\"/>" } {print}' > conf/tomcat-users.xml.new
    mv conf/tomcat-users.xml conf/tomcat-users.xml.old
    mv conf/tomcat-users.xml.new conf/tomcat-users.xml
    rm conf/tomcat-users.xml.new1
    rm conf/tomcat-users.xml.new4

    bin/startup.sh
    sleep 10
    wget http://127.0.0.1:$TOMCAT_PORT
    message $? " cant' hit tomcat" 1

    echo "tomcat seems to be up, $TOMCAT_HOME"
    rm index.html
}

function export_git_repos {
# Fetches code for WebAPI and ATLAS from github into the GITBASE.
    echo ""
    echo "** EXPORT REPOS"
    # should use tags here: TODO
    # WebAPI has tag v2.7.6 from 2020-01-22, still used current
    # Atlas has v.2.7.6 from 2020-01-23, used current
    #   ...I've seen 2.6 recommended https://forums.ohdsi.org/t/atlas-setup-failing/5858/2

    cd $GIT_BASE

    if [ ! -e WebAPI ]; then
        echo "exporting WebAPI"
        #svn export https://github.com/OHDSI/WebAPI/tags/v2.7.6 > /dev/null
        #mv v2.7.6 WebAPI
        git clone https://github.com/OHDSI/WebAPI.git
        message $? "exporting WebAPI failed" 3
    fi

    if [ ! -e ATLAS ]; then
        echo "exporting ATLAS"
        svn export https://github.com/OHDSI/Atlas/tags/v2.7.6 > /dev/null
        message $? "exporting ATLAS failed" 3
        mv v2.7.6 Atlas
    fi

}


function build_webapi {
    echo ""
    echo "** build WEBAPI"

    cd $GIT_BASE/WebAPI
    cp $OMOP_DISTRO/webapi_settings.xml .
    mkdir $GIT_BASE/WebAPI/WebAPIConfig
    # Set the db connection info in settings.xml and name the profile in the call to maven.
    ####cp webapi_settings.xml $GIT_BASE/WebAPI/WebAPIConfig/settings.xml
    mvn -P cloud_sql_by_proxy \
        -Dmaven.wagon.http.ssl.insecure=true \
        -Dmaven.wagon.http.ssl.allowall=true \
          clean package -D skipTests \
        -s $OMOP_DISTRO/webapi_settings.xml
    ###    -s $GIT_BASE/WebAPI/WebAPIConfig/webapi_settings.xml
    message $? " WebAPI build failed" 1
}

## function get_results_ddl {
##     echo ""
##     echo "** RESULTS DDL"
##     # Achilles sets this up based on its config.
##     # Here as a way of debugging.
##     # https://forums.ohdsi.org/t/ddl-scripts-for-results-achilles-results-derived-etc/9618/6
##     wget -o - http://127.0.0.1:$TOMCAT_PORT/WebAPI/ddl/results?dialect=postgresql > results.ddl
##     message $? " get_results_ddl failed wget" 7
##     echo "got results.ddl...."
## 
##     cat results.ddl | sed  s/results/$RESULTS_SCHEMA/g  \
##       | psql -U ohdsi_admin_user $DB_NAME
##     message $? " get_results_ddl failed" 7
##     echo "...must be  int he db now."
## }

function install_webapi {
    echo ""
    echo "** install WEBAPI schema: $WEBAPI_SCHEMA"
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$WEBAPI_SCHEMA/g  \
      | PSQL_admin
    message $? " create schema for webapi failed" 2
    WARFILE=$GIT_BASE/WebAPI/target/WebAPI.war
    cp $WARFILE $TOMCAT_HOME/webapps
    message $? " install webapi failed" 2
}

function insert_source_rows {
    echo ""
    echo " ** INSERT SOURCE ROWS "
    echo "delete from $WEBAPI_SCHEMA.source_daimon;" | PSQL

    echo "insert into $WEBAPI_SCHEMA.source (source_id, source_name, source_key, source_connection, source_dialect, username, password) values (99, 'Synthea in OMOP', '$DB_NAME', 'jdbc:postgresql://localhost:$POSTGRESQL_PORT/$DB_NAME', 'postgresql', 'ohdsi_app_user', '');" | PSQL_admin
    echo ""
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 0, '$CDM_SCHEMA', 1);" | PSQL_admin
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 1, '$VOCABULARY_SCHEMA', 1);" | PSQL_admin
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 2, '$RESULTS_SCHEMA', 1);" | PSQL_admin

    echo "select * from $WEBAPI_SCHEMA.source_daimon;" | PSQL
    echo "select * from $WEBAPI_SCHEMA.source;" | PSQL
}


function test_webapi_sources {
    echo ""
    echo "** TEST WEBAPI SOURCES"
    wget http://127.0.0.1:$TOMCAT_PORT/WebAPI/source/sources
    message $? " wgetting WebAPI sources failed" 1
    CONTENTS=$(cat sources)
    rm sources
    if [[ $CONTENTS == '[]' ]] ;then
        echo "ERROR, no data sources: \"$CONTENTS\" $WEBAPI_SCHEMA $DB_NAME"
        # this means WebAPI isn't reading the source and source_daimon tables it should be.
    else
        echo "cool! data sources: \"$CONTENTS\" "
    fi
}


shutdown_and_delete_old
make_new
test_db_users
install_tomcat
export_git_repos
build_webapi

## echo "need to setup Achilles and the results schema that webapi uses too"
## get_results_ddl
install_webapi

echo "need to start WebAPI in the tomcat manager app to create the source and source_daimon tables before populating"
echo "check the logs under tomcat/apache-tomcat-9.0.37/logs/catalina.out"
open $TOMCAT_URL/manager/html
exit 0;

#echo "need to start WebAPI to create the source and source_daimon tables before populating"
#open $TOMCAT_URL/Atlas/#/home
#exit 0;

insert_source_rows
#test_webapi_sources
##atlas


