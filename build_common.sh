


# Set the db connection info in settings.xml and name the profile in the call to maven.
# Info is duplicated here for build related work. The settings.xml is for Spring.

# TODO, this involves MULTIPLE db connections, one for webapi and one for cdm...**TOOD**

# update these:
HOME=/Users/croeder/work
OMOP_DISTRO=$HOME/git/omop_distro
########################GIT_BASE=$HOME/git/test_install_20200729
########################DEPLOY_BASE=$HOME/test_deploy_20200729
ATHENA_VOCAB=$HOME/git/misc_external/athena_vocabulary
DO_CPT4=false  #DO_CPT4=true
GIT_BASE=$HOME/git/test_install
CDM=$GIT_BASE/CommonDataModel/PostgreSQL

DEPLOY_BASE=$HOME/test_deploy

TOMCAT_RELEASE=9.0.37
TOMCAT_ARCHIVE_URL="https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_RELEASE}/bin/apache-tomcat-${TOMCAT_RELEASE}.tar.gz"
TOMCAT_DIR=apache-tomcat-${TOMCAT_RELEASE}
TOMCAT_ARCHIVE="apache-tomcat-${TOMCAT_RELEASE}.tar.gz"
TOMCAT_HOME=$DEPLOY_BASE/tomcat/$TOMCAT_DIR
TOMCAT_PORT=8080
TOMCAT_URL=http://127.0.0.1:$TOMCAT_PORT


# pick a database location, edit.
# TODO: the PSQL functions below use these. Separating out WebAPI into its own database will require modification there.
# Local Postgresql for webapi
# DB_HOST=127.0.0.1
# DB_NAME=test1
# DB_PORT=5432
# PROFILE=local_postgresql
# DB_USER=postgres
# DB_USER=croeder
# DB_PASSWORD=""
#ADMIN_PASSWORD=

# Local Postgresql for cdm for google cloud work
 DB_HOST=127.0.0.1
 ######################DB_NAME=test_20200729
 DB_NAME=test_install_gc
 DB_PORT=5432
 DB_USER=ohdsi_admin_user
 DB_PASSWORD=""
 ADMIN_PASSWORD=""

# Cloud SQL via proxy
### DB_HOST=127.0.0.1
### DB_NAME=test1
### DB_PORT=5433
### PROFILE=cloud_sql_via_proxy
### DB_USER=postgres
### DB_PASSWORD=""
#DB_PASSWORD=
#ADMIN_PASSWORD=

##  Cloud SQL via SSL
## DB_HOST=34.71.79.17
## DB_NAME=test1
## DB_PORT=5432
## PROFILE=cloud_sql_via_ssl
## DB_USER=postgres
## DB_PASSWORD=""
#ADMIN_PASSWORD=
PEM_DIR=/Users/croeder/play/git/google-cloud

CDM_SCHEMA="cdm"
RESULTS_SCHEMA="results"
# The ddl in the CommonDataModel project doesn't isolate the vocabulary tables, # so I don't distinguish here.
VOCABULARY_SCHEMA="cdm"


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

# IF THE PROXY IS RUNNING, OR a local db - note the different port!
function PSQL_no_db {
    psql "sslmode=disable hostaddr=$DB_HOST  port=$DB_PORT user=$DB_USER password=$DB_PASSWORD"
    return $?
}

function PSQL {
    psql "sslmode=disable hostaddr=$DB_HOST  port=$DB_PORT user=ohdsi_app_user dbname=$DB_NAME password=$DB_PASSWORD"
    return $?
}

function PSQL_admin {
    psql "sslmode=disable hostaddr=$DB_HOST  port=$DB_PORT user=ohdsi_admin_user dbname=$DB_NAME password=$ADMIN_PASSWORD"
    return $?
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

function make_new_users {
# Sets up a new postgress database and deployment directories
    echo ""
    echo "** PostgreSQL Roles"
    cat $OMOP_DISTRO/setup_postgresql_roles.sql | \
       sed "s/XXXUSER/$DB_USER/g" | sed "s/XXX_PASSWORD_XXX/$ADMIN_PASSWORD/g" | PSQL_no_db
}
function make_new_db {
    echo "** PostgreSQL DB $OMOP_DISTRO $DB_NAME"
    cat $OMOP_DISTRO/setup_db.sql  \
      | sed  s/XXX/$DB_NAME/g  \
      | PSQL_no_db
    message $? "creating db $DB_NAME failed" 3
}
function pause {
    read -p "Press any key to resume. Do so after the migration completes."
}
function create_indexes {
    echo ""
    echo "** CREATE INDEXES"
    SET_SCHEMA="set search_path to $CDM_SCHEMA;"

    # INDEXES
    ##cp $CDM/OMOP\ CDM\ postgresql\ indexes.txt  $OMOP_DISTRO/OMOP\ CDM\ postgresql\ indexes_$CDM_SCHEMA.txt  
    cp $CDM/OMOP_CDM_postgresql_indexes_no_clusters.txt $OMOP_DISTRO/OMOP\ CDM\ postgresql\ indexes_$CDM_SCHEMA.txt  
    # add schema, tricky sed stuff to get newlines
    sed -i .bkup3  "39i\\
          $SET_SCHEMA\\
    " $OMOP_DISTRO/OMOP\ CDM\ postgresql\ indexes_$CDM_SCHEMA.txt  
    cat $OMOP_DISTRO/OMOP\ CDM\ postgresql\ indexes_$CDM_SCHEMA.txt | PSQL_admin
    message $? " indexes failed" 6

    # CONSTRAINTS
    cp $CDM/OMOP\ CDM\ postgresql\ constraints.txt  $OMOP_DISTRO/OMOP\ CDM\ postgresql\ constraints_$CDM_SCHEMA.txt  
    # add schema, tricky sed stuff to get newlines
    sed  -i .bkup2 "39i\\
          $SET_SCHEMA\\
    " $OMOP_DISTRO/OMOP\ CDM\ postgresql\ constraints_$CDM_SCHEMA.txt  

    cat $OMOP_DISTRO/OMOP\ CDM\ postgresql\ constraints_$CDM_SCHEMA.txt | PSQL_admin
    message $? " constraints failed" 7

}

function drop_indexes {
    echo ""
    echo "** DROP INDEXES"

    SET_SCHEMA="set search_path to $CDM_SCHEMA;"

    cp $OMOP_DISTRO/drop_postgresql_indexes.sql $OMOP_DISTRO/drop_postgresql_indexes_$CDM_SCHEMA.sql
    # add schema, tricky sed stuff to get newlines
    sed -i .bkup3  "2i\\
          $SET_SCHEMA\\
    " $OMOP_DISTRO/drop_postgresql_indexes_$CDM_SCHEMA.sql

    cat  $OMOP_DISTRO/drop_postgresql_indexes_$CDM_SCHEMA.sql | PSQL_admin
    message $? " drop constraints failed" 77

}

function truncate_cdm_tables {
    # does not truncate vocabulary or source_to_standard_vocab_map or source_to_source_vocab_map
    echo "truncate cdm.person cascade;" | PSQL_admin
    echo "truncate cdm.condition_era cascade;" | PSQL_admin
    echo "truncate cdm.condition_occurrence cascade;" | PSQL_admin
    echo "truncate cdm.drug_era cascade;" | PSQL_admin
    echo "truncate cdm.drug_exposure cascade;" | PSQL_admin
    echo "truncate cdm.measurement cascade;" | PSQL_admin
    echo "truncate cdm.observation cascade;" | PSQL_admin
    echo "truncate cdm.observation_period cascade;" | PSQL_admin
    echo "truncate cdm.procedure_occurrence cascade;" | PSQL_admin
    echo "truncate cdm.visit_occurrence cascade;" | PSQL_admin
    echo "truncate cdm.assign_all_visit_ids cascade;" | PSQL_admin
    echo "truncate cdm.all_visits cascade;" | PSQL_admin
    echo "truncate cdm.final_visit_ids cascade;" | PSQL_admin
}

function show_cdm_counts {
    echo "select count(*) from cdm.person;"
    echo "select count(*) from cdm.person;" | PSQL
    echo "select count(*) from cdm.condition_era;"
    echo "select count(*) from cdm.condition_era;" | PSQL
    echo "select count(*) from cdm.condition_occurrence;"
    echo "select count(*) from cdm.condition_occurrence;" | PSQL
    echo "select count(*) from cdm.drug_era;"
    echo "select count(*) from cdm.drug_era;" | PSQL
    echo "select count(*) from cdm.drug_exposure;"
    echo "select count(*) from cdm.drug_exposure;" | PSQL
    echo "select count(*) from cdm.measurement;"
    echo "select count(*) from cdm.measurement;" | PSQL
    echo "select count(*) from cdm.observation;"
    echo "select count(*) from cdm.observation;" | PSQL
    echo "select count(*) from cdm.observation_period;"
    echo "select count(*) from cdm.observation_period;" | PSQL
    echo "select count(*) from cdm.procedure_occurrence;"
    echo "select count(*) from cdm.procedure_occurrence;" | PSQL
    echo "select count(*) from cdm.visit_occurrence;"
    echo "select count(*) from cdm.visit_occurrence;" | PSQL
    echo "select count(*) from cdm.assign_all_visit_ids;"
    echo "select count(*) from cdm.assign_all_visit_ids;" | PSQL
    echo "select count(*) from cdm.all_visits;"
    echo "select count(*) from cdm.all_visits;" | PSQL
    echo "select count(*) from cdm.final_visit_ids;"
    echo "select count(*) from cdm.final_visit_ids;" | PSQL
}

