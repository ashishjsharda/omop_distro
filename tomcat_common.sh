

# update these:
HOME=/Users/croeder/work

OMOP_DISTRO=$HOME/git/omop_distro
GIT_BASE=$HOME/git/test_install
DEPLOY_BASE=$HOME/test_deploy

TOMCAT_RELEASE=9.0.37
TOMCAT_ARCHIVE_URL="https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_RELEASE}/bin/apache-tomcat-${TOMCAT_RELEASE}.tar.gz"
TOMCAT_DIR=apache-tomcat-${TOMCAT_RELEASE}
TOMCAT_ARCHIVE="apache-tomcat-${TOMCAT_RELEASE}.tar.gz"
TOMCAT_HOME=$DEPLOY_BASE/tomcat/$TOMCAT_DIR
TOMCAT_PORT=8080
TOMCAT_URL=http://127.0.0.1:$TOMCAT_PORT


# Local Postgresql for webapi
 DB_HOST=127.0.0.1
 DB_NAME=test1
 DB_PORT=5432
 PROFILE=local_postgresql
 DB_USER=postgres
# DB_USER=croeder
 DB_PASSWORD=""
ADMIN_PASSWORD=

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


