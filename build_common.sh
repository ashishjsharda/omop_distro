
HOME=/Users/croeder/work


# Set the db connection info in settings.xml and name the profile in the call to maven.
# Info is duplicated here for build related work. The settings.xml is for Spring.

# Local Postgresql
 WEBAPI_SCHEMA=webapi
 DB_HOST=127.0.0.1
 DB_NAME=test1
 DB_PORT=5432
 PROFILE=local_postgresql
 DB_USER=postgres
## DB_USER=croeder

# Cloud SQL via proxy
### WEBAPI_SCHEMA=webapi
### DB_HOST=127.0.0.1
### DB_NAME=test1
### DB_PORT=5433
### PROFILE=cloud_sql_via_proxy
### DB_USER=postgres
#DB_PASSWORD=
#ADMIN_PASSWORD=

##  Cloud SQL via SSL
## WEBAPI_SCHEMA=webapi
## DB_HOST=34.71.79.17
## DB_NAME=test1
## DB_PORT=5432
## PROFILE=cloud_sql_via_ssl
## DB_USER=postgres
PEM_DIR=/Users/croeder/play/git/google-cloud

CDM_SCHEMA="cdm"
RESULTS_SCHEMA="results"
# The ddl in the CommonDataModel project doesn't isolate the vocabulary tables,
# so I don't distinguish here.
##VOCABULARY_SCHEMA="vocabulary"
VOCABULARY_SCHEMA="cdm"

OMOP_DISTRO=$HOME/git/omop_distro
GIT_BASE=$HOME/git/test_install
DEPLOY_BASE=$HOME/test_deploy
ATHENA_VOCAB=$HOME/git/misc_external/athena_vocabulary
#DO_CPT4=true
DO_CPT4=false
CDM=$GIT_BASE/CommonDataModel/PostgreSQL


TOMCAT_RELEASE=9.0.37
TOMCAT_ARCHIVE_URL="https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_RELEASE}/bin/apache-tomcat-${TOMCAT_RELEASE}.tar.gz"
TOMCAT_DIR=apache-tomcat-${TOMCAT_RELEASE}
TOMCAT_ARCHIVE="apache-tomcat-${TOMCAT_RELEASE}.tar.gz"
TOMCAT_HOME=$DEPLOY_BASE/tomcat/$TOMCAT_DIR
TOMCAT_PORT=8080
TOMCAT_URL=http://127.0.0.1:$TOMCAT_PORT



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
    psql "sslmode=disable hostaddr=$DB_HOST  port=$DB_PORT user=$DB_USER dbname=$DB_NAME password=$DB_PASSWORD"
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

