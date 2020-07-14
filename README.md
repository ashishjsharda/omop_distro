# README #

This project integrates the differnt parts of OMOP into a running setup.  

It's probably largely a re-implementation of what happens inside ETl projects like Synthea-ETL. The goal isn't to be prescriptive or to be make-work. It's an attempt to figure out how this works, how to do ETL in my own project, and to document it.

## Current Status
I have the first parts running and updated. Setting up the CDM and populating vocabulary. The scripting for pulling the results schema out of the WebAPI app isn't working.

### stand alone WebAPI setup, July 2020
I've separated out WebAPI. The all-in-one build script build.sh still stands. This adds build_webapi.sh. It takes a simpler approach to setting up the database connection properties. This project, omop_distro, has a webapi_settings.xml file that has different profiles for databases I use. When building WebAPI, I refer maven to that file directly and use a trimed-down profile within the pom. It does mean the connection info is duplicated between build_webapi.sh and webapi_settings.xml, but the path from settings files, poms, etc into the application.properties in the WebAPI build process is a step shorter. The values are in this webapi_settings.xml file explicityly, not as variables, and they don't appear in the pom profile I use.

## How do I get set up? ###

* run build.sh

## Issues

* DDL comes in different forms, uses different methods for naming the schema of a sub-project.
* see also TODO tags in the scripts.

## Who do I talk to? ###

https://forums.ohdsi.org/t/ohdsi-tables-architecture-deploying-on-multiple-dbms-platforms/3481


* Chris Roeder, chris.roeder@cuanschutz.edu
* ohdsi.org of course
#shutdown_and_delete_old
#make_new
#export_git_repos
#add_schema_to_ddl
#cdm
#athena

#synthea
#synthea_etl

#indexes

#achilles
######achilles_web

# if false
if true
then
#    install_tomcat
#    build_webapi
#    install_webapi
#    sleep 60
#    results_schema
    get_results_ddl
    insert_source_rows
    test_webapi_sources
    #atlas
fi


