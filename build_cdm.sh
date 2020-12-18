#!/bin/bash

#  build_cdm.sh
#
# For version 5.3, gets the ddl, adds schema search path and loads it.
# Requires athena to have been downloaded. This is data downloaded from
# the OHDSI Athena website, not the Athena git repo.
# https://athena.ohdsi.org/search-terms/terms
#  ATHENA_VOCAB=$HOME/git/misc_external/athena_vocabulary
#   ATHENA_VOCAB=$WK_HOME/athena_vocabulary
# I have a copy on Google cloud storage and copied it over.
#
# Be careful when running against multiple schema names. This code fetches
# a fresh copy of the ddl and modifies it with the schema name, so there's
# a chance that taking some shortcuts could have you using previously editted files.
#
# Optinally adds CPT4 based on the DO_CPT4 variable set in build_common.sh
# This step requires a umls username and password.
#
set -euf
set -o pipefail

. build_passwords.sh
. build_common.sh

function export_git_repos {
    echo ""
    echo "** EXPORT REPOS"

    cd $GIT_BASE

    if [ ! -e CommonDataModel ]; then
        echo "exporting CDM"
        svn export https://github.com/chrisroederucdenver/CommonDataModel/branches/v5.3.1_fixes-ddl_patch > /dev/null
        message $? "exporting CDM failed" 3
        mv v5.3.1_fixes-ddl_patch CommonDataModel
    fi
}


function cdm {
    echo ""
    echo "** CDM setup schema $CDM_SCHEMA $DB_NAME"
    SET_SCHEMA="set search_path to $CDM_SCHEMA;"

    # add schema, tricky sed stuff to get newlines
    cp $CDM/OMOP\ CDM\ postgresql\ ddl.txt $OMOP_DISTRO/OMOP\ CDM\ postgresql\ ddl_$CDM_SCHEMA.txt
    #sed -i .bkup  "39i\\
    sed -ibkup  "39i\\
          $SET_SCHEMA\\
    " $OMOP_DISTRO/OMOP\ CDM\ postgresql\ ddl_$CDM_SCHEMA.txt

    cat $OMOP_DISTRO/setup_schema.sql \
      | sed  s/XXX/$CDM_SCHEMA/g  \
      | PSQL_admin
    status=$?
    message $status "creating schema $CDM_SCHEMA in  $DB_NAME failed" 1
    if (( $status )); then exit; fi

    echo "** CDM run ddl $CDM_SCHEMA $DB_NAME"
    cat $OMOP_DISTRO/OMOP\ CDM\ postgresql\ ddl_$CDM_SCHEMA.txt  \
      | PSQL_admin
    message $? "running cdm dll $CDM_SCHEMA $DB_NAME failed" 1
}

function athena {
    echo ""
    echo "** LOAD ATHENA VOCABULARIES"
    # this is an unzipped package of vocabulary from athena
    echo "** CDM load vocab $CDM_SCHEMA $DB_NAME"
    cd $ATHENA_VOCAB

    ## message $? "loading vocabulary $ATHENA_VOCAB $DB_NAME failed" 1

    # need to prepare CONCEPT.csv with CPT4, if its included
    # (might be nice if there was a way to tell this had been done:grep CPT4??) TODO
    if $DO_CPT4 ; then
        chmod 755 cpt.sh
        ./cpt.sh $UMLS_USER $UMLS_PASSWORD
    fi

    # my release has a VOCABULARY.csv with consecutive tabs for the 4th column and its not-null.
    # The vocabularies are generatedy on the Odysseus Athena site. 
    #cp VOCABULARY.csv VOCABULARY.csv.org
    #cat VOCABULARY.csv | sed "s/          /               /g" > /tmp/vocab.csv
    #mv /tmp/vocab.csv VOCABULARY.csv

    cat $OMOP_DISTRO/load_athena.sql | sed "s/SCHEMA/$CDM_SCHEMA/g" \
        | PSQL_admin

     message $? "loading vocabulary $ATHENA_VOCAB $DB_NAME failed" 1

    cd $GIT_BASE
}

make_new_db
make_new_users
export_git_repos
cdm
athena

