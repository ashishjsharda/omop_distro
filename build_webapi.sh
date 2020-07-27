#!/bin/bash
set -euf
set -o pipefail

# This script setups tomcat and  WebAPI given a PostgreSQL connection.
#
# Depends on npm: https://nodejs.org/en/download/
#
# Chris Roeder
# July, 2020

. ./build_passwords.sh
. ./build_common.sh


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

function make_new_git {
    echo " A GIT BASE? $GIT_BASE"
    mkdir $DEPLOY_BASE
    mkdir $GIT_BASE
    echo " B GIT BASE? $GIT_BASE"
    cd $GIT_BASE
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
        svn export https://github.com/OHDSI/WebAPI/tags/v2.7.7 > /dev/null
        mv v2.7.7 WebAPI
        #git clone --depth 1 https://github.com/OHDSI/WebAPI.git
        message $? "exporting WebAPI failed" 3
    fi
}


function build_webapi {
    echo ""
    echo "** build WEBAPI"

    cd $GIT_BASE/WebAPI

    ##cp $OMOP_DISTRO/webapi_settings.xml .
    ##mkdir $GIT_BASE/WebAPI/WebAPIConfig
    ####cp webapi_settings.xml $GIT_BASE/WebAPI/WebAPIConfig/settings.xml

    # Set the db connection info in settings.xml and name the profile in the call to maven.
    mvn -P cloud_sql_by_proxy \
        -Dmaven.wagon.http.ssl.insecure=true \
        -Dmaven.wagon.http.ssl.allowall=true \
          clean package -D skipTests \
        -s $OMOP_DISTRO/webapi_settings.xml
    ###    -s $GIT_BASE/WebAPI/WebAPIConfig/webapi_settings.xml
    message $? " WebAPI build failed" 1
}

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

    echo "Installing WebAPI triggers flyway to create the webapi schema. Give it a few minutes."
    echo "check the logs under tomcat/apache-tomcat-9.0.37/logs/catalina.out"

    open $TOMCAT_URL/WebAPI/info
}

shutdown_and_delete_old
make_new_git
make_new_users
make_new_db
test_db_users
install_tomcat
export_git_repos
build_webapi

# echo "need to setup Achilles and the results schema that webapi uses too"
# get_results_ddl
install_webapi

open $TOMCAT_URL/manager/html
open $TOMCAT_URL/WebAPI/info



