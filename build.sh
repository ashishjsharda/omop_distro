#!/bin/bash


# This script setups up the gamut of OMOP schemata, runs DDL and loads data. For now,
# limited to PostgreSQL.
#
# To run: 
#   download vocabulary from ATHENA
#   install postgresql
#   clone git@github.com:chrisroederucdenver/omop_distro.git
#   edit locations in variables below: GIT_BASE, DEPLOY_BASE, DB_NAME, ATHENA_VOCAB
#   run build.sh
# It will bring up an ATLAS web page.
#
# ASSUMPTIONS:
# (perhaps obviously) BASH is available
# R is installed
# It assumes PostgreSQL has been installed and configured. 
#   and assumes the  PG environment variables are set to working defaults.
# It doesn't do much for error checking and so assumes the user can identify and resolve issues.
# 
#DONE! TODO: collect the scripts into a repo
#DONE! TODO: integrate/commit the split and use of schema names  in ddl between vocabulary and cdm
# TODO: parametrize schema names, esp cdm in cdm schema creation, ddl exec
#       done in the schema creation scripts, not in ddl
# TOOD: call cdm creation from CDM project as a module/function with schema name as a parameter
#       instead of re-packaging the schema definition
# TODO: generalize to other dialects, not just PostgreSQL
#       This involves questions about delivering the CDM ddl in a form suitable to SQLRender 
#       vs delivering separate versions for each database platform. The reason to use SQLRender
#       is so the schema names can be parameterized.
#DONE! TODO: fetch ddl for results from a REST endoint, edit in the schema name
#DONE! TODO pass the DB name into the run_achilles.R script
# TODO: implement read-only on voccabulary schema

# Chris Roeder
# February, 2020


OMOP_DISTRO=/Users/christopherroeder/work/git/omop_distro
UBER_DB_USER=christopherroeder

GIT_BASE=/Users/christopherroeder/work/git/test_install
DEPLOY_BASE=/Users/christopherroeder/work/test_deploy
DB_NAME=test_install
VOCABULARY_SCHEMA=vocabulary # all that works for the moment is vocabulary
CDM_SCHEMA=cdm # all that works for the moment is cdm
RESULTS_SCHEMA=results_x
WEBAPI_SCHEMA=webapi_x
SYNTHEA_SCHEMA=synthea_x
SYNTHEA_OUTPUT=$GIT_BASE/synthea/output/csv

ATHENA_VOCAB=/Users/christopherroeder/work/git/misc_external/OHDSI_Vocabulary_local

TOMCAT_ARCHIVE_URL="https://downloads.apache.org/tomcat/tomcat-9/v9.0.31/bin/apache-tomcat-9.0.31.tar.gz"
TOMCAT_DIR=apache-tomcat-9.0.31
TOMCAT_ARCHIVE="apache-tomcat-9.0.31.tar.gz"
TOMCAT_HOME=$DEPLOY_BASE/tomcat/$TOMCAT_DIR
TOMCAT_PORT=8080
TOMCAT_URL=http://127.0.0.1:$TOMCAT_PORT/

POSTGRESQL_PORT=5432




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
    $TOMCAT_HOME/bin/shutdown.sh
    dropdb $DB_NAME
    rm -rf $GIT_BASE
    rm -rf $DEPLOY_BASE
}

function make_new {
    echo "** PostgreSQL Roles"
    cat $OMOP_DISTRO/setup_postgres_roles.sql | psql 

    mkdir $GIT_BASE
    mkdir $DEPLOY_BASE
    cd $GIT_BASE

    echo "** PostgreSQL DB"
    cat $OMOP_DISTRO/setup_db.sql  \
      | sed  s/XXX/$DB_NAME/g  \
      | psql  -U $UBER_DB_USER
    message $? "creating db $DB_NAME failed" 3
}

function get_git_repos {
    # tags are old:
    # achilles tags are from 2018-10, used current
    # ETL-Synthea has tag v5.3.1 from 2019-05-22, used current
    # AchillesWeb has a v1.0.0 tag from 2014, changes from 2017, used current

    # should use tags here: TODO
    # CommonDataModel tags are last from 2018-10-11, v5.3.1
    # WebAPI has tag v2.7.6 from 2020-01-22, still used current
    # Atlas has v.2.7.6 from 2020-01-23, used current
    
    cd $GIT_BASE

    if [ ! -e Achilles ]; then
        #svn export https://github.com/OHDSI/Achilles/trunk/
        #mv trunk Achilles
        git clone --depth 1 https://github.com/OHDSI/Achilles
    fi

    if [ ! -e CommonDataModel ]; then
        svn export https://github.com/OHDSI/CommonDataModel/tags/v5.3.1
        mv v5.3.1 CommonDataModel
    fi

    if [ ! -e WebAPI ]; then
        svn export https://github.com/OHDSI/WebAPI/tags/v2.7.6
        mv v2.7.6 WebAPI
    fi

    if [ ! -e ATLAS ]; then
        svn export https://github.com/OHDSI/Atlas/tags/v2.7.6
        mv v2.7.6 Atlas
    fi

    if [ ! -e synthea ]; then
        #svn export https://github.com/synthetichealth/synthea/tag/v2.5.0
        #mv v2.5.0 synthea
        svn export https://github.com/synthetichealth/synthea/trunk
        mv trunk synthea
    fi

    if [ ! -e ETL-Synthea ]; then
        svn export https://github.com/chrisroederucdenver/ETL-Synthea/tags/v0.9.3cr
        mv v0.9.3cr ETL-Synthea
    fi

    if [ ! -e AchillesWeb ]; then
        svn export https://github.com/OHDSI/AchillesWeb/trunk
        mv trunk AchillesWeb
    fi
}


function vocabulary {
# This ddl is adapted from CommonDataModel
    echo "** VOCABULARY"
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$VOCABULARY_SCHEMA/g  \
      | psql  -U ohdsi_admin_user  $DB_NAME
# vocabulary*.ddl needs schema templating
    cat $OMOP_DISTRO/ddl/vocabulary.ddl | psql -U ohdsi_admin_user $DB_NAME

    # this is an unzipped package of vocabulary from athena
    cd $ATHENA_VOCAB
    cat load_copy.sql | psql -U ohdsi_admin_user $DB_NAME
    cat $OMOP_DISTRO/ddl/vocabulary_indexes.ddl | psql -U ohdsi_admin_user $DB_NAME
    cat $OMOP_DISTRO/ddl/vocabulary_constraints.ddl | psql -U ohdsi_admin_user $DB_NAME
    cd $GIT_BASE
}


function cdm {
# This ddl is adapted from CommonDataModel
    echo "** CDM $DB_NAME"
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$CDM_SCHEMA/g  \
      | psql  -U ohdsi_admin_user  $DB_NAME
# cdm*.ddl needs schema templating
    cat $OMOP_DISTRO/ddl/cdm.ddl | psql -U ohdsi_admin_user $DB_NAME
}

function synthea {
    echo "** SYNTHEA"
    cd $GIT_BASE/synthea
    if [ ! -e output ] ; then
        ./run_synthea
        message $? " synthea failed" 4
    else
        echo "...using previous run of synthea"
    fi
    cd $GIT_BASE
}


function synthea_etl {
    echo "** SYNTHEA ETL"
    # *****
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$SYNTHEA_SCHEMA/g  \
      | psql  -U ohdsi_admin_user  $DB_NAME
    # TODO commit tweaks to synthea and run just load.R instead
    #   assumes data in SYNTHEA_OUT as above, but hard-coded for the moment
    #   assumes vocabulary in $GIT_BASE/CommonDataModel/vocabulary
    #   does not do DDL, 
    #   assumes this script has connection details...
    # ** TODO reconcile ETL here into its own CDM schema with CDM schema setup above!! **
    cd $GIT_BASE/ETL-Synthea
    sed -i .old1 s/DB_NAME/$DB_NAME/ local_load.R
    sed -i .old  s/SYNTHEA/$SYNTHEA_SCHEMA/ local_load.R
    sed -i .old  s/CDM/$CDM_SCHEMA/ local_load.R
    sed -i .old  s/VOCABULARY/$VOCABULARY_SCHEMA/ local_load.R
    sed -i .old  "s|OUTPUT|$SYNTHEA_OUTPUT|" local_load.R
    mkdir $SYNTHEA_OUTPUT

    Rscript local_load.R
    message $? " synthea etl failed" 5
    cd $GIT_BASE
    
    # when done, set indexes on cdm
    cat $OMOP_DISTRO/ddl/cdm_indexes.ddl \
      | sed  s/XXX/$CDM_SCHEMA/g  \
      | psql -U ohdsi_admin_user $DB_NAME
    cat $OMOP_DISTRO/ddl/cdm_constraints.ddl \
      | sed  s/XXX/$CDM_SCHEMA/g  \
      | psql -U ohdsi_admin_user $DB_NAME
}


function results_schema {
    # requires WebAPI and Tomcat to be up and running
    echo "** RESULTS SCHEMA"
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$RESULTS_SCHEMA/g  \
      | psql  -U ohdsi_admin_user  $DB_NAME
}

function get_results_ddl {
    # Achilles sets this up based on its config.
    # Here as a way of debugging.
    # https://forums.ohdsi.org/t/ddl-scripts-for-results-achilles-results-derived-etc/9618/6
    wget -o - http://127.0.0.1:$TOMCAT_PORT/WebAPI/ddl/results?dialect=postgresql \
      | sed  s/results/$RESULTS_SCHEMA/g  \
      | psql -U ohdsi_admin_user $DB_NAME
}


function achilles {
    echo "** ACHILLES"
   
    cd $GIT_BASE/Achilles
    cp $OMOP_DISTRO/run_achilles.R . 
    sed -i .old s/DB_NAME/$DB_NAME/ run_achilles.R
    sed -i .old s/PORT/$POSTGRESQL_PORT/ run_achilles.R
    sed -i .old s/CDM_SCHEMA/$CDM_SCHEMA/ run_achilles.R
    sed -i .old s/VOCABULARY_SCHEMA/$VOCABULARY_SCHEMA/ run_achilles.R
    sed -i .old s/RESULTS_SCHEMA/$RESULTS_SCHEMA/ run_achilles.R
  cat run_achilles.R . 
    Rscript run_achilles.R . 
    message $? " achilles failed"  6
} 


function achilles_web {
    echo "** achilles web "
    cp -r $GIT_BASE/AchillesWeb $TOMCAT_HOME/webapps
    mkdir $TOMCAT_HOME/webapps/AchillesWeb/data
    echo "{ \"datasources\":[ { \"name\":\"$DB_NAME\", \"folder\":\"SAMPLE\", \"cdmVersion\": 5 } ] } " > $TOMCAT_HOME/webapps/AchillesWeb/data/datasources.json
# UNFINISHED
# that ugly step of running an R script to extract achilles results into json files and make them available via tomcat in that data directory
}

function build_webapi {
    echo "** build WEBAPI"

    ## build WebAPI with profile using dbname
    cd $GIT_BASE/WebAPI
    cp $OMOP_DISTRO/webapi_settings.xml .
    sed -i .old1 s/POSTGRESQL_PORT/$POSTGRESQL_PORT/     webapi_settings.xml
    sed -i .old  s/WEBAPI_SCHEMA/$WEBAPI_SCHEMA/ webapi_settings.xml
    sed -i .old  s/DB_NAME/$DB_NAME/      webapi_settings.xml
    mkdir $GIT_BASE/WebAPI/WebAPIConfig
    cp webapi_settings.xml $GIT_BASE/WebAPI/WebAPIConfig/settings.xml
    mvn clean package -P $DB_NAME -D skipTests -s $GIT_BASE/WebAPI/WebAPIConfig/settings.xml
    message $? " WebAPI build failed" 1
}

function install_postgres {
    echo "install_postgres? ...not yet" 
}

function install_tomcat {
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

    # for testing...
    netstat -na | grep 8005
###    if [[ "$status" == "0" ]] ; then 
###        # there's another server here already, move out of the way
###        echo "existing server detected, deploying this one to tomcat ports 8006 and 8010"
###        sed -i .old s/8005/8006/g conf/server.xml
###        sed -i .old s/8009/8010/g conf/server.xml
###    fi
    bin/startup.sh
    sleep 10
    wget http://127.0.0.1:$TOMCAT_PORT
    message $? " cant' hit tomcat" 1

    echo "tomcat seems to be up, $TOMCAT_HOME"
    rm index.html
}

function install_webapi {
    echo "** install WEBAPI"
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$WEBAPI_SCHEMA/g  \
      | psql  -U ohdsi_admin_user  $DB_NAME
    WARFILE=$GIT_BASE/WebAPI/target/WebAPI.war
    cp $WARFILE $TOMCAT_HOME/webapps
    message $? " copying war to Tomcat failed" 2
    # TODO: grep the log for action and success?
}

function insert_source_rows {
    echo "delete from $WEBAPI_SCHEMA.source_daimon;" | psql $DB_NAME

    echo "insert into $WEBAPI_SCHEMA.source (source_id, source_name, source_key, source_connection, source_dialect, username, password) values (99, 'Synthea in OMOP', '$DB_NAME', 'jdbc:postgresql://localhost:$POSTGRESQL_PORT/$DB_NAME', 'postgresql', 'ohdsi_app_user', '');" | psql -U ohdsi_admin_user $DB_NAME
    echo "" 
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 0, '$CDM_SCHEMA', 1);" | psql -U ohdsi_admin_user $DB_NAME
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 1, '$VOCABULARY_SCHEMA', 1);" | psql -U ohdsi_admin_user $DB_NAME
    echo "insert into $WEBAPI_SCHEMA.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 2, '$RESULTS_SCHEMA', 1);" | psql -U ohdsi_admin_user $DB_NAME
    
    echo "select * from $WEBAPI_SCHEMA.source_daimon;" | psql $DB_NAME
    echo "select * from $WEBAPI_SCHEMA.source;" | psql $DB_NAME
}

function atlas {
    echo "**ATLAS"
    cp -r $GIT_BASE/Atlas $TOMCAT_HOME/webapps
    cp $OMOP_DISTRO/config-local.js $TOMCAT_HOME/webapps/Atlas/js/
    sed -i .old1  s/APP_NAME/WebAPI/            $TOMCAT_HOME/webapps/Atlas/js/config-local.js
    sed -i .old2  s/TOMCAT_PORT/$TOMCAT_PORT/  $TOMCAT_HOME/webapps/Atlas/js/config-local.js
    open $TOMCAT_URL/Atlas/#/home
}

function test_webapi_sources {
    wget http://127.0.0.1:$TOMCAT_PORT/WebAPI/source/sources
    CONTENTS=$(cat sources)
    rm sources
    if [[ $CONTENTS == '[]' ]] ;then
        echo "ERROR, no data sources: \"$CONTENTS\" $WEBAPI_SCHEMA $DB_NAME"
        # this means WebAPI isn't reading the source and source_daimon tables it should be.
    else
        echo "cool! data sources: \"$CONTENTS\" "
    fi
}

##install_postgres
shutdown_and_delete_old
make_new
get_git_repos 
vocabulary
cdm
synthea
synthea_etl
results_schema
##get_results_ddl
achilles
install_tomcat
######achilles_web
build_webapi
install_webapi
sleep 30
insert_source_rows
test_webapi_sources
atlas

