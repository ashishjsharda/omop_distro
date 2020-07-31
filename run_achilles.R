
if (!require("devtools")) install.packages("devtools")

if (!require("Achilles")) devtools::install_github("OHDSI/Achilles")
# I had better luck installing from a download. TODO
# note here that 2.6 is the way to go, not root from the git tree
# https://forums.ohdsi.org/t/atlas-setup-failing/5858/2
# this is about it not finding bootstrap

library(Achilles)
connectionDetails <- createConnectionDetails(
    dbms="postgresql",
    server="DB_HOST/DB_NAME",
    user="DB_USER",
    password="DB_PASSWORD",
    port="DB_PORT")

achilles(connectionDetails,
    cdmDatabaseSchema="CDM_SCHEMA",
    resultsDatabaseSchema="RESULTS_SCHEMA",
    vocabDatabaseSchema="VOCABULARY_SCHEMA",
    numThreads=1,
    sourceName="My Source Name",
    cdmVersion="5.3.0",
    runHeel = TRUE,
    runCostAnalysis=TRUE)

