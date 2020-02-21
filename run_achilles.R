
if (!require("devtools")) install.packages("devtools")

if (!require("Achilles")) devtools::install_github("OHDSI/Achilles")
# I had better luck installing from a download. TODO

library(Achilles)
connectionDetails <- createConnectionDetails(
    dbms="postgresql",
    server="localhost/DB_NAME",
    user="ohdsi_admin_user",
    password="",
    port="PORT")

achilles(connectionDetails,
    cdmDatabaseSchema="CDM_SCHEMA",
    resultsDatabaseSchema="RESULTS_SCHEMA",
    vocabDatabaseSchema="VOCABULARY_SCHEMA",
    numThreads=1,
    sourceName="My Source Name",
    cdmVersion="5.3.0",
    runHeel = TRUE,
    runCostAnalysis=TRUE)

