#!/bin/bash
set -euf
set -o pipefail

# This script setups tomcat and  WebAPI given a PostgreSQL connection.
#
# Chris Roeder
# July, 2020


HOME=/Users/croeder/work
DB_USER=postgres
DB_NAME=test1
POSTGRESQL_PORT=5432
OMOP_DISTRO=$HOME/git/omop_distro
GIT_BASE=$HOME/git/test_install
DEPLOY_BASE=$HOME/test_deploy
WEBAPI_SCHEMA=webapi

TOMCAT_RELEASE=9.0.34
TOMCAT_ARCHIVE_URL="https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_RELEASE}/bin/apache-tomcat-${TOMCAT_RELEASE}.tar.gz"
TOMCAT_DIR=apache-tomcat-${TOMCAT_RELEASE}
TOMCAT_ARCHIVE="apache-tomcat-${TOMCAT_RELEASE}.tar.gz"
TOMCAT_HOME=$DEPLOY_BASE/tomcat/$TOMCAT_DIR
TOMCAT_PORT=8080
TOMCAT_URL=http://127.0.0.1:$TOMCAT_PORT/
PEM_DIR=/Users/croeder/play/git/google-cloud


function PSQL_u { 
    psql "sslmode=verify-ca sslrootcert=$PEM_DIR/server-ca.pem sslcert=$PEM_DIR/client-cert.pem sslkey=$PEM_DIR/client-key.pem hostaddr=34.71.79.17       port=5432 user=$DB_USER dbname=$DB_NAME password=Dear_God_Dont_Hack_this_long_pwd_79_79_88_96_08"
}

### PSQL_admin="psql \"sslmode=verify-ca sslrootcert=server-ca.pem       sslcert=client-cert.pem sslkey=client-key.pem       hostaddr=34.71.79.17       port=5432       user=ohdsi_admin_user dbname=$DB_NAME       password=Dear_God_Dont_Hack_this_long_pwd_79_79_88_96_08\" \" \" \" "

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

    $TOMCAT_HOME/bin/shutdown.sh
    #dropdb $DB_NAME
    cat $OMOP_DISTRO/drop_db.sql  \
      | sed  s/XXX/$DB_NAME/g  \
      | PSQL
    message $? "creating db $DB_NAME failed" 3
    rm -rf $GIT_BASE
    rm -rf $DEPLOY_BASE
}

function make_new {
# Sets up a new postgress database and deployment directories
    echo ""
    echo "** PostgreSQL Roles"
    cat $OMOP_DISTRO/setup_postgresql_roles.sql | \
       sed "s/XXXUSER/$DB_USER/g" | PSQL
    mkdir $DEPLOY_BASE
    cd $GIT_BASE

    echo "** PostgreSQL DB $OMOP_DISTRO"
    cat $OMOP_DISTRO/setup_db.sql  \
      | sed  s/XXX/$DB_NAME/g  \
      | PSQL
    message $? "creating db $DB_NAME failed" 3
}

function install_tomcat {
    echo ""
    echo "** TOMCAT"
    kill $(ps -aef | grep tomcat | awk '{print $2}')
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
        svn export https://github.com/OHDSI/WebAPI/tags/v2.7.6 > /dev/null
        message $? "exporting WebAPI failed" 3
        mv v2.7.6 WebAPI
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

    ## build WebAPI with profile using dbname
    cd $GIT_BASE/WebAPI
    cp $OMOP_DISTRO/webapi_settings.xml .
    sed -i s/POSTGRESQL_PORT/$POSTGRESQL_PORT/     webapi_settings.xml
    sed -i s/WEBAPI_SCHEMA/$WEBAPI_SCHEMA/ webapi_settings.xml
    sed -i s/DB_NAME/$DB_NAME/      webapi_settings.xml
    mkdir $GIT_BASE/WebAPI/WebAPIConfig
    cp webapi_settings.xml $GIT_BASE/WebAPI/WebAPIConfig/settings.xml
    mvn clean package -P $DB_NAME -D skipTests -s $GIT_BASE/WebAPI/WebAPIConfig/settings.xml
    message $? " WebAPI build failed" 1
}

function install_webapi {
    echo ""
    echo "** install WEBAPI"
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$WEBAPI_SCHEMA/g  \
      | PSQL_admin
    WARFILE=$GIT_BASE/WebAPI/target/WebAPI.war
    cp $WARFILE $TOMCAT_HOME/webapps
    message $? " copying war to Tomcat failed" 2
    # TODO: grep the log for action and success?
}

function insert_source_rows {
    echo ""
    echo " ** INSERT SOURCE ROWS "
    echo "delete from $WEBAPI_SCHEMA.source_daimon;" | $PSQL

    echo "insert into $WEBAPI_SCHEMA.source (source_id, source_name, source_key, source_connection, source_dialect, username, password) values (99, 'Synthea in OMOP', '$DB_NAME', 'jdbc:postgresql://localhost:$POSTGRESQL_PORT/$DB_NAME', 'postgresql', 'ohdsi_app_user', '');" | $PSQL_admin 
    echo ""
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 0, '$CDM_SCHEMA', 1);" | $PSQL_admin 
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 1, '$VOCABULARY_SCHEMA', 1);" | $PSQL_admin  
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 2, '$RESULTS_SCHEMA', 1);" | $PSQL_admin 

    echo "select * from $WEBAPI_SCHEMA.source_daimon;" | $PSQL 
    echo "select * from $WEBAPI_SCHEMA.source;" | $PSQL 
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

echo "select rolname from pg_roles;" | PSQL_u

#shutdown_and_delete_old
#make_new
#install_tomcat
#export_git_repos
#build_webapi
#install_webapi
#insert_source_rows
#test_webapi_sources
##atlas
#
#
