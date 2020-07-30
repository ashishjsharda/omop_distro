#!/bin/bash
set -euf
set -o pipefail

# This script setups tomcat and  WebAPI given a PostgreSQL connection.
# The db connection for webapi is not in variables in these scripts, rather in webapi_settings.xml in the omop_distro project.
# Note the reference to profiles within the maven call below, like "postgres_local".
#
# Depends on npm: https://nodejs.org/en/download/
#
# Chris Roeder
# July, 2020

. ./build_passwords.sh
. ./tomcat_common.sh

DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=test_webapi
WEBAPI_SCHEMA=webapi

function PSQL_admin {
    psql "sslmode=disable hostaddr=$DB_HOST  port=$DB_PORT user=ohdsi_admin_user dbname=$DB_NAME password=$ADMIN_PASSWORD"
    return $?
}

function PSQL_no_db {
    psql "sslmode=disable hostaddr=$DB_HOST  port=$DB_PORT user=$DB_USER password=$DB_PASSWORD"
    return $?
}

function make_new_db {
    echo "** PostgreSQL DB $DB_NAME"
    cat $OMOP_DISTRO/setup_db.sql  \
      | sed  s/XXX/$DB_NAME/g  \
      | PSQL_no_db
    message $? "creating db $DB_NAME failed" 3
}

function make_new_users {
# Sets up a new postgress database and deployment directories
    echo ""
    echo "** PostgreSQL Roles"
    cat $OMOP_DISTRO/setup_postgresql_roles.sql | \
       sed "s/XXXUSER/$DB_USER/g" | sed "s/XXX_PASSWORD_XXX/$ADMIN_PASSWORD/g" | PSQL_no_db
}

function create_schema {
    echo ""
    echo "** create schema: $WEBAPI_SCHEMA in $DB_NAME"

    # create schema 
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$WEBAPI_SCHEMA/g  \
      | PSQL_admin
    message $? " create schema for webapi failed" 2
}

function show_db_connection {
    echo " \conninfo" | PSQL_admin
}

function shutdown_tomcat {
    set +e
    set +o pipefail
    $TOMCAT_HOME/bin/shutdown.sh
    set -o pipefail
    set -e
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
    if [ ! -d tomcat ]; then
        mkdir tomcat
        cd tomcat
        if [ ! -e $TOMCAT_ARCHIVE ]; then
            wget $TOMCAT_ARCHIVE_URL
            message $? " tomcat download failed" 1
        fi

        tar xzf $TOMCAT_ARCHIVE
        message $? " tomcat extract failed" 1
    else
        # remove old WebAPI install if we already had a tomcat, so we start fresh
        # and so flyway doesn't kick back in when we restart below
        echo "removing old WebAPI application"
        cd tomcat/apache-tomcat-$TOMCAT_RELEASE
        rm -rf webapps/WebAPI
        rm -rf webapps/WebAPI.war
        pwd
        ls webapps
    fi

    cd $TOMCAT_HOME
    sed -i .old s/8080/$TOMCAT_PORT/g conf/server.xml
    cat conf/tomcat-users.xml      \
        | awk 'NR==44 {print " <role rolename=\"manager-gui\"/>  " } {print}' \
        > conf/tomcat-users.xml.new1
    cat conf/tomcat-users.xml.new1 \
        | awk 'NR==45 {print " <role rolename=\"tomcat\"/>  " } {print}' \
        > conf/tomcat-users.xml.new2
    cat conf/tomcat-users.xml.new2 \
        | awk 'NR==46 {print "<user username=\"tomcat\" password=\"Harmonization\" roles=\"tomcat,manager-gui\"/>" } {print}' \
        > conf/tomcat-users.xml.new
    mv conf/tomcat-users.xml conf/tomcat-users.xml.old
    mv conf/tomcat-users.xml.new conf/tomcat-users.xml
    rm conf/tomcat-users.xml.new1
    rm conf/tomcat-users.xml.new2

    echo "Starting Tomcat"
    bin/startup.sh
    sleep 10
    wget http://127.0.0.1:$TOMCAT_PORT
    message $? " cant' hit tomcat" 1
    echo "tomcat seems to be up, $TOMCAT_HOME"
    rm index.html

    #  check logs/catalina.out for flyway errors
    #  check webapps/WEB-INF/classes/application.properties for correct db connection info
}

function export_git_repos {
# Fetches code for WebAPI and ATLAS from github into the GITBASE.
    echo ""
    echo "** EXPORT REPOS"

    cd $GIT_BASE

    if [ ! -e WebAPI ]; then
        echo "exporting WebAPI"
        svn export https://github.com/OHDSI/WebAPI/tags/v2.7.7 > /dev/null
        mv v2.7.7 WebAPI
        message $? "exporting WebAPI failed" 3
    fi
}


function build_webapi {
    echo ""
    echo "** build WEBAPI"

    cd $GIT_BASE/WebAPI

    # Set the db connection info in settings.xml and name the profile in the call to maven.
    # mvn -P cloud_sql_by_proxy 
    mvn -P local_postgres \
        -Dmaven.wagon.http.ssl.insecure=true \
        -Dmaven.wagon.http.ssl.allowall=true \
          clean package -D skipTests \
        -s $OMOP_DISTRO/webapi_settings.xml
    message $? " WebAPI build failed" 1
}

function install_webapi {
    echo ""
    echo "** install WEBAPI schema: $WEBAPI_SCHEMA"

    # copy war
    WARFILE=$GIT_BASE/WebAPI/target/WebAPI.war
    cp $WARFILE $TOMCAT_HOME/webapps
    message $? " install webapi failed" 2

    echo "Installing WebAPI triggers flyway to create the webapi schema. Give it a few minutes."
    echo "hit https://127.0.0.1:8080 for tomcat in general"
    echo "hit https://127.0.0.1:8080/manager/html with tomcat password in this scrpt for the tomcat manager app. Check for WebAPI and start it."
    echo "start a psql session and look for the webapi schema"
    echo "tail -f  tomcat/apache-tomcat-9.0.37/logs/catalina.out, and watch flyway:"

    open $TOMCAT_URL/WebAPI/info
}

make_new_db
make_new_users
shutdown_tomcat
install_tomcat
export_git_repos
show_db_connection
create_schema
build_webapi
install_webapi

#open $TOMCAT_URL/manager/html
#open $TOMCAT_URL/WebAPI/info



