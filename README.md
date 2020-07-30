# README #

This project integrates the differnt parts of OMOP into a running setup. It references the OHDSI subprojects CommonDataModel, WebAPI, ATLAS, Achilles, ETL-Sythea, and the external project synthea. One of many goals here is to identify specfic versions, by tag, branch, release or commit hash, of each that are meant to work together. To that, the CDM ddl comes from the CommonDataModel project, not ETL-Synthea. Making direct reference to the ddl project rather than having the ETL include a copy avoids questions about which is the definitive and whether or how bugfixes will flow into production.


## Current Status
Moving from build.sh to build_uber.sh and component scripts.

## How do I get set up? ###
edit build_common with database locations, username and possword.
run build_uber.sh. 

## Issues


## Who do I talk to? ###

https://forums.ohdsi.org/t/ohdsi-tables-architecture-deploying-on-multiple-dbms-platforms/3481


* Chris Roeder, chris.roeder@cuanschutz.edu
* ohdsi.org of course
