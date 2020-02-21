#!/bin/bash


# This script setups up the gamut of OMOP schemata, runs DDL and loads data. For now,
# limited to PostgreSQL.
# It assumes PostgreSQL, and Tomcat have been installed and configured. 
#   and assumes the  PG environment variables are set to working defaults.
# It assumes Vocabulary has been selected, downloaded and placed ______________________
# It assumes CDM, Achilles, WebAPI, ATLAS and vocabulary are in parallel directories cloned 
#   from git or downloaded (vocabulary) as appropriate. And that that directory is in the 
#   variable GIT_BASE below.
# It assumes WebAPI has been configured with a profile whose name corresponds to the database name
# It and subsidiary scripts assume the following schema names: cdm, vocabulary, results, webapi
# It doesn't do much for error checking and so assumes the user can identify and resolve issues.
# 
# TODO: collect the scripts into a repo, not WebAPI
#DONE!  TODO: integrate/commit the split and use of schema names  in ddl between vocabulary and cdm
# TODO: parametrize schema names, esp cdm in cdm schema creation, ddl exec
# TOOD: call cdm creation from CDM project as a module/function with schema name as a parameter
#       instead of re-packaging the schema definition
# TODO: generalize to other dialects, not just PostgreSQL
#       This involves questions about delivering the CDM ddl in a form suitable to SQLRender 
#       vs delivering separate versions for each database platform. The reason to use SQLRender
#       is so the schema names can be parameterized.
#*TODO*: fetch ddl for results from a REST endoint, edit in the schema name
# TODO: come up with a way to distinguish the different senses of schema:
#  - the partition of a database schema: "database schema"
#  - the ddl and data associated with a schema: "ddl"
#  - the design of the data put into a database : "schema design"
# TODO pass the DB name into the run_achilles.R script
# TODO: implement read-only on voccabulary schema

# Chris Roeder
# February, 2020

# immediate TODO
# - database name parameterization
#   setup_postgres_db.sql


OMOP_DISTRO=/Users/christopherroeder/work/git/omop_distro
UBER_DB_USER=christopherroeder

GIT_BASE=/Users/christopherroeder/work/git/test_install
DEPLOY_BASE=/Users/christopherroeder/work/test_deploy
DB_NAME=test_install
VOCABULARY_SCHEMA=vocabulary
CDM_SCHEMA=cdm
RESULTS_SCHEMA=results
WEBAPI_SCHEMA=webapi
SYNTHEA_SCHEMA=synthea
SYNTHEA_OUTPUT=$DEPLOY_BASE/synthea_output

ATHENA_VOCAB=$GIT_BASE/OHDSI_Vocabulary_local

TOMCAT_ARCHIVE_URL="https://downloads.apache.org/tomcat/tomcat-9/v9.0.31/bin/apache-tomcat-9.0.31.tar.gz"
TOMCAT_DIR=apache-tomcat-9.0.31
TOMCAT_ARCHIVE="apache-tomcat-9.0.31.tar.gz"
TOMCAT_HOME=$DEPLOY_BASE/tomcat/$TOMCAT_DIR
TOMCAT_URL=http://127.0.0.1:8080/
TOMCAT_PORT=8081


mkdir $GIT_BASE
mkdir $DEPLOY_BASE
cd $GIT_BASE


function message  {
    status=$1
    msg=$2
    exitval=$3

    if [[ "$status" != "0" ]] ; then 
        echo "********************"
        echo "\"$status\" $msg"
        exit $exitval 
    fi
}

echo "** PostgreSQL Roles"
cat $OMOP_DISTRO/setup_postgres_roles.sql | psql 

function db_prep {
    # Drop Database, create new
    echo "** DATABASE, $DB_NAME"

    # for dev
    dropdb $DB_NAME

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
    # CommonDataModel tags are last from 2018-10-11, v6.0.0
    # WebAPI has tag v2.7.6 from 2020-01-22, still used current
    # Atlas has v.2.7.6 from 2020-01-23, used current
    
    mkdir  "$GIT_BASE"
    cd $GIT_BASE
    OHDSI_BASE="https://github.com/OHDSI"
    repo=(
      "CommonDataModel.git"
      "Achilles.git"  
      "WebAPI.git"
      "AchillesWeb.git"
      "Atlas.git" )

    for rep in ${repo[*]}; do
        dirname=$(echo $rep | sed s/.git//)
        echo $rep $dirname
        if [ ! -e $dirname ]; then
            git clone $OHDSI_BASE/$rep
        else
            echo "..already have $rep"
        fi
    done

    if [ ! -e synthea ]; then
        git clone "https://github.com/synthetichealth/synthea.git"
    fi

    if [ ! -e ETL-Synthea ]; then
        git clone https://github.com/chrisroederucdenver/ETL-Synthea.git
    fi
}


function vocabulary {
# This ddl is adapted from CommonDataModel
    echo "** VOCABULARY"
    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/$VOCABULAR_SCHEMA/$DB_NAME/g  \
      | psql  -U ohdsi_admin_user  $DB_NAME
# vocabulary*.ddl needs schema templating
    cat $OMOP_DISTOR/ddl/vocabulary.ddl | psql -U ohdsi_admin_user $DB_NAME

    $ this is an unzipped package of vocabulary from athena
    cd $ATHENA_VOCAB
    cat load_copy.sql | psql -U ohdsi_admin_user $DB_NAME
    cat $OMOP_DISTRO/ddl/vocabulary_indexes.ddl | psql -U ohdsi_admin_user $DB_NAME
    cat $OMOP_DISTRO/ddl/vocabulary_constraints.ddl | psql -U ohdsi_admin_user $DB_NAME
    cd $GIT_BASE
}


function cdm {
# This ddl is adapted from CommonDataModel
    echo "** CDM"
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
    SYNTHEA_OUTPUT=$GIT_BASE/synthea/output/csv  # unused: TODO: use it, pass the location into R as a parameter
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
    sed -i .old  s/OUTPUT/$SYNTHEA_OUTPUT/ local_load.R
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
    cat $GIT_BASE/WebAPI/setup_results_schema.sql \
      | sed  s/XXX/$RESULTS_SCHEMA/g  \
      | psql  -U ohdsi_admin_user  $DB_NAME
}

function results {
    # requires WebAPI and Tomcat to be up and running, is rumored to be run as part of 
    # running achilles: 
    # https://forums.ohdsi.org/t/ddl-scripts-for-results-achilles-results-derived-etc/9618/6
    cat $GIT_BASE/Achilles/results.ddl 
    wget -o - http://127.0.0.1:$TOMCAT_PORT/WebAPI/ddl/results?dialect=postgresql \
      | sed  s/results/$RESULTS_SCHEMA/g  \
      | psql -U ohdsi_admin_user $DB_NAME
}


function achilles {
    echo "** ACHILLES"
# hard-coded with server/database, user (connection details), and schema names
    Rscript $GIT_BASE/Achilles/run_achilles_synthea_omop.R
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
# The settings needs customized
    mvn clean package -P $DB_NAME -D skipTests -s $GIT_BASE/WebAPI/WebAPIConfig/settings.xml
    message $? " WebAPI build failed" 1
}

function install_postgres {
    echo "install_postgres? LOL HAHAHAHAHAH" 
}

function install_tomcat {
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
    # for testing...
    netstat -na | grep 8005
    if [[ "$status" == "0" ]] ; then 
        # there's another server here already, move out of the way
        echo "existing server detected, deploying this one to tomcat ports 8006 and 8010"
        sed -i .old s/8005/8006/g conf/server.xml
        sed -i .old s/8009/8010/g conf/server.xml
    fi
    grep 8081 conf/server.xml
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
    open $TOMCAT_URL/WebAPI
}

function insert_source_rows {
    echo "insert into webapi.source (source_id, source_name, source_key, source_connection, source_dialect, username, password) values (99, 'Synthea in OMOP', 'synthea_omop', 'jdbc:'jdbc:postgresql://localhost:5432/$DB_NAME, 'postgresql', 'ohsi_app_user', '');" | psql -U ohdsi_admin_user $DB_NAME
    echo "" 
    echo "insert into webapi.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 0, 'cdm', 1);" | psql -U ohdsi_admin_user $DB_NAME
    echo "insert into webapi.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 1, 'vocabulary', 1);" | psql -U ohdsi_admin_user $DB_NAME
    echo "insert into webapi.source_daimon (source_id, daimon_type, table_qualifier, priority) values (99, 2, 'results', 1);" | psql -U ohdsi_admin_user $DB_NAME
}



function atlas {
    echo "**ATLAS"
    ##cp -r $GIT_BASE/Atlas $TOMCAT_HOME/webapps
# create $TOMCAT_HOME/webapps/Atlas/js/config-local.js TODO
    open $TOMCAT_URL/WebAPI/Atlas
}

install_postgres
get_git_repos 
db_prep
#vocabulary
#cdm
synthea
#synthea_etl
#results_schema
    #results
#achilles
#install_tomcat
###achilles_web
#build_webapi
#install_webapi
#insert_source_rows
#atlas
