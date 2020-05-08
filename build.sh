#!/bin/bash
set -euf
set -o pipefail

# This script setups up the gamut of OMOP schemata, runs DDL and loads data. For now,
# limited to PostgreSQL.
#
# To run: 
#   download vocabulary from ATHENA
#   install postgresql
#   clone git@github.com:chrisroederucdenver/omop_distro.git (this repository)
#   edit locations in variables below: GIT_BASE, DEPLOY_BASE, DB_NAME, ATHENA_VOCAB
#   run build.sh (this script)
# It will bring up an ATLAS web page.
#
# ASSUMPTIONS:
# (perhaps obviously) BASH is available
# R is installed
# It assumes PostgreSQL has been installed and configured. 
#   and assumes the  PG environment variables are set to working defaults, and the
#   current user has permissions 
# It doesn't do much for error checking and so assumes the user can identify and resolve issues.
# 
# TODO: parametrize schema names, esp cdm in cdm schema creation, ddl exec
#       done in the schema creation scripts, not in ddl
# TOOD: call cdm creation from CDM project as a module/function with schema name as a parameter
#       instead of re-packaging the schema definition
# TODO: generalize to other dialects, not just PostgreSQL
#       This involves questions about delivering the CDM ddl in a form suitable to SQLRender 
#       vs delivering separate versions for each database platform. The reason to use SQLRender
#       is so the schema names can be parameterized.
# TODO: implement read-only on voccabulary schema

# Chris Roeder
# February, 2020

# get this from the environment.
## ATHENA_USER=
## ATHENA_PASSWORD=


#ME=/Users/christopherroeder/work/
ME=/Users/croeder/work
#DB_USER=christopherroeder
DB_USER=croeder

OMOP_DISTRO=$ME/git/omop_distro


GIT_BASE=$ME/git/test_install_2
DEPLOY_BASE=$ME/test_deploy_2
DB_NAME=test_install_2

VOCABULARY_SCHEMA=cdm
CDM_SCHEMA=cdm
RESULTS_SCHEMA=results_x
WEBAPI_SCHEMA=webapi_x
SYNTHEA_SCHEMA=synthea_x
SYNTHEA_OUTPUT=$GIT_BASE/synthea/output/csv

ATHENA_VOCAB=$ME/git//misc_external/athena_vocabulary

CDM=$GIT_BASE/CommonDataModel/PostgreSQL

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
#    $TOMCAT_HOME/bin/shutdown.sh
    dropdb $DB_NAME
    rm -rf $GIT_BASE
    rm -rf $DEPLOY_BASE
}

function make_new {
    echo ""
    echo "** PostgreSQL Roles"
    cat $OMOP_DISTRO/setup_postgresql_roles.sql | \
       sed "s/XXXUSER/$DB_USER/g" | psql 

    mkdir $GIT_BASE
    mkdir $DEPLOY_BASE
    cd $GIT_BASE

    echo "** PostgreSQL DB $OMOP_DISTRO"
    cat $OMOP_DISTRO/setup_db.sql  \
      | sed  s/XXX/$DB_NAME/g  \
      | psql  -U $DB_USER
    message $? "creating db $DB_NAME failed" 3
}

function export_git_repos {
    echo ""
    echo "** EXPORT REPOS"
    # tags are old:
    # achilles tags are from 2018-10, used current
    # ETL-Synthea has tag v5.3.1 from 2019-05-22, used current
    # AchillesWeb has a v1.0.0 tag from 2014, changes from 2017, used current

    # should use tags here: TODO
    # CommonDataModel tags are last from 2018-10-11, v5.3.1
    # WebAPI has tag v2.7.6 from 2020-01-22, still used current
    # Atlas has v.2.7.6 from 2020-01-23, used current
    #   ...I've seen 2.6 recommended https://forums.ohdsi.org/t/atlas-setup-failing/5858/2 
    
    cd $GIT_BASE

    if [ ! -e Achilles ]; then
        echo "cloning Achilles"
        #svn export https://github.com/OHDSI/Achilles/trunk/
        #mv trunk Achilles
        git clone --depth 1 https://github.com/OHDSI/Achilles > /dev/null
        message $? "cloning Achilles failed" 3
    fi

    if [ ! -e CommonDataModel ]; then
        echo "exporting CDM"
        svn export https://github.com/OHDSI/CommonDataModel/tags/v5.3.1 > /dev/null
        message $? "exporting CDM failed" 3
        mv v5.3.1 CommonDataModel
    fi

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

    if [ ! -e synthea ]; then
        echo "exporting synthea"
        #svn export https://github.com/synthetichealth/synthea/tag/v2.5.0
        #mv v2.5.0 synthea
        svn export https://github.com/synthetichealth/synthea/trunk > /dev/null
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

    if [ ! -e AchillesWeb ]; then
        echo "exporting AchillesWeb"
        svn export https://github.com/OHDSI/AchillesWeb/trunk > /dev/null
        message $? "exporting AchillesWeb failed" 3
        mv trunk AchillesWeb
    fi
}


function  add_schema_to_ddl {
    echo ""
    echo "** ADD SCHEMA"
    # also fix DATETIME2

    cd $OMOP_DISTRO
    rm -rf new_ddl
    mkdir new_ddl
    cd new_ddl
    mkdir PostgreSQL
    cd PostgreSQL
    cp $CDM/OMOP\ CDM\ postgresql\ constraints.txt .
    cp $CDM/OMOP\ CDM\ postgresql\ ddl.txt .
    cp $CDM/OMOP\ CDM\ postgresql\ indexes.txt .
    
    SET_SCHEMA="set search_path to $CDM_SCHEMA;"

    # DDL
    sed  "39i\\
          $SET_SCHEMA\\
    " $CDM/OMOP\ CDM\ postgresql\ ddl.txt  > /tmp/ddl.txt
    mv /tmp/ddl.txt $CDM/OMOP\ CDM\ postgresql\ ddl.txt

    # CONSTRAINTS 
    sed  "39i\\
          $SET_SCHEMA\\
    " $CDM/OMOP\ CDM\ postgresql\ constraints.txt  > /tmp/constraints.txt
    mv /tmp/constraints.txt $CDM/OMOP\ CDM\ postgresql\ constraints.txt

    # INDEXES 
    sed  "39i\\
          $SET_SCHEMA\\
    " $CDM/OMOP\ CDM\ postgresql\ indexes.txt  > /tmp/indexes.txt
    mv /tmp/indexes.txt $CDM/OMOP\ CDM\ postgresql\ indexes.txt
}

function cdm {
    echo ""
    echo "** CDM setup schema $CDM_SCHEMA $DB_NAME"
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$CDM_SCHEMA/g  \
      | psql  -U ohdsi_admin_user  $DB_NAME
    message $? "creating schema $CDM_SCHEMA in  $DB_NAME failed" 1

    echo "** CDM run ddl $CDM_SCHEMA $DB_NAME"
    cat $CDM/OMOP\ CDM\ postgresql\ ddl.txt  | psql -U ohdsi_admin_user $DB_NAME
    STATUS=$?
    message $STATUS "running cdm dll $CDM_SCHEMA $DB_NAME failed" 1
    echo "****************** $STATUS"
}

function athena {
    echo ""
    echo "** LOAD ATHENA VOCABULARIES"
    # this is an unzipped package of vocabulary from athena
    echo "** CDM load vocab $CDM_SCHEMA $DB_NAME"
    cd $ATHENA_VOCAB

    # need to prepare CONCEPT.csv with CPT4, if its included
    # (might be nice if there was a way to tell this had been done:grep CTP4??) TODO
 #   chmod 755 cpt.sh
 #   ./cpt.sh $UMLS_USER $UMLS_PASSWORD

    # my release has a VOCABULARY.csv with consecutive tabs for the 4th column and it's not-null.
    cp VOCABULARY.csv VOCABULARY.csv.org 
    cat VOCABULARY.csv | sed "s/          /               /g" > /tmp/vocab.csv
    mv /tmp/vocab.csv VOCABULARY.csv

    cat $OMOP_DISTRO/load_athena.sql | sed "s/SCHEMA/$CDM_SCHEMA/g" | psql -U ohdsi_admin_user $DB_NAME
    message $? "loading vocabulary $ATHENA_VOCAB $DB_NAME failed" 1
    cd $GIT_BASE
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
    echo "** SYNTHEA ETL into $SYNTHEA_SCHEMA $DB_NAME"
    ### NB. synthea_etl is built to do a lot of what happens here
    ### Need to identify the overlap and separate it. Consider the role of synthea in this project...
    ### ...or the existence of this project as anything more than a learning exercise.

    # *****
    cat $OMOP_DISTRO/setup_schema.sql | sed  s/XXX/$SYNTHEA_SCHEMA/g  | psql  -U ohdsi_admin_user  $DB_NAME
    message $? " schema setup failed" 5

    # TODO commit tweaks to synthea and run just load.R instead
    #   assumes data in SYNTHEA_OUT as above, but hard-coded for the moment
    #   assumes vocabulary in $GIT_BASE/CommonDataModel/vocabulary
    #   does not do DDL, 
    #   assumes this script has connection details...
    # ** TODO reconcile ETL here into its own CDM schema with CDM schema setup above!! **
    cd $GIT_BASE/ETL-Synthea
    sed -i .old1 s/DB_NAME/$DB_NAME/ local_load.R
    message $? " synthea sed 1 failed" 5
    sed -i .old  s/SYNTHEA_SCHEMA/$SYNTHEA_SCHEMA/ local_load.R
    message $? " synthea sed 2 failed" 5
    sed -i .old  s/CDM/$CDM_SCHEMA/ local_load.R
    message $? " synthea sed 3 failed" 5
    sed -i .old  s/VOCABULARY/$VOCABULARY_SCHEMA/ local_load.R
    message $? " synthea sed 4 failed" 5
    sed -i .old  "s|SYNTHEA_OUTPUT|$SYNTHEA_OUTPUT|" local_load.R
    message $? " synthea sed 5 failed" 5
    if [[! -d $SYNTHEA_OUTPUT ]]; then
        mkdir -f $SYNTHEA_OUTPUT
    fi

    Rscript local_load.R
    message $? " synthea etl failed" 5
    cd $GIT_BASE
   
}
 
function indexes {
    echo ""
    echo "** INDEXES"
    # when done, set indexes on cdm
      ## | sed  s/XXX/$CDM_SCHEMA/g  \
 #   cat $CDM/OMOP\ CDM\ postgresql\ indexes.txt | psql -U ohdsi_admin_user $DB_NAME
 #   message $? " indexes failed" 6 

      ## | sed  s/XXX/$CDM_SCHEMA/g  \
    cat $CDM/OMOP\ CDM\ postgresql\ constraints.txt | psql -U ohdsi_admin_user $DB_NAME
    message $? " constraints failed" 7
}


function results_schema {
    echo ""
    echo "** RESULTS SCHEMA"
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$RESULTS_SCHEMA/g  \
      | psql  -U ohdsi_admin_user  $DB_NAME
    message $? " results schema failed" 7
}

function get_results_ddl {
    echo ""
    echo "** RESULTS SCHEMA"
    # Achilles sets this up based on its config.
    # Here as a way of debugging.
    # https://forums.ohdsi.org/t/ddl-scripts-for-results-achilles-results-derived-etc/9618/6
    wget -o - http://127.0.0.1:$TOMCAT_PORT/WebAPI/ddl/results?dialect=postgresql \
      | sed  s/results/$RESULTS_SCHEMA/g  \
      | psql -U ohdsi_admin_user $DB_NAME
    message $? " get_results_ddl failed" 7
}


function achilles {
    echo ""
    echo "** ACHILLES"
   
    cd $GIT_BASE/Achilles
    cp $OMOP_DISTRO/run_achilles.R . 
    sed -i .old s/DB_NAME/$DB_NAME/ run_achilles.R
    sed -i .old s/PORT/$POSTGRESQL_PORT/ run_achilles.R
    sed -i .old s/CDM_SCHEMA/$CDM_SCHEMA/ run_achilles.R
    sed -i .old s/VOCABULARY_SCHEMA/$VOCABULARY_SCHEMA/ run_achilles.R
    sed -i .old s/RESULTS_SCHEMA/$RESULTS_SCHEMA/ run_achilles.R
    Rscript run_achilles.R . 
    message $? " achilles failed"  6
} 


function achilles_web {
    echo ""
    echo "** ACHILLES WEB "
    cp -r $GIT_BASE/AchillesWeb $TOMCAT_HOME/webapps
    mkdir $TOMCAT_HOME/webapps/AchillesWeb/data
    echo "{ \"datasources\":[ { \"name\":\"$DB_NAME\", \"folder\":\"SAMPLE\", \"cdmVersion\": 5 } ] } " > $TOMCAT_HOME/webapps/AchillesWeb/data/datasources.json
# UNFINISHED
# that ugly step of running an R script to extract achilles results into json files and make them available via tomcat in that data directory
}

function build_webapi {
    echo ""
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
    echo ""
    echo "install_postgres? ...not yet" 
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

function install_webapi {
    echo ""
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
    echo ""
    echo " ** INSERT SOURCE ROWS "
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
    echo ""
    echo "**ATLAS"
    cp -r $GIT_BASE/Atlas $TOMCAT_HOME/webapps
    cp $OMOP_DISTRO/config-local.js $TOMCAT_HOME/webapps/Atlas/js/
    sed -i .old1  s/APP_NAME/WebAPI/            $TOMCAT_HOME/webapps/Atlas/js/config-local.js
    sed -i .old2  s/TOMCAT_PORT/$TOMCAT_PORT/  $TOMCAT_HOME/webapps/Atlas/js/config-local.js
    open $TOMCAT_URL/Atlas/#/home
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

##install_postgres
##shutdown_and_delete_old
##make_new
##export_git_repos 
##add_schema_to_ddl 
#cdm

#athena
#synthea
#synthea_etl
indexes
#results_schema
#####get_results_ddl
#achilles
######achilles_web

if false
then
    install_tomcat
    build_webapi
    install_webapi
    sleep 60
    insert_source_rows
    test_webapi_sources
    atlas
fi


