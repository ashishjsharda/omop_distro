
# oo { "datasources":[ { "name":"My Sample Database", "folder":"SAMPLE", "cdmVersion": 5 } ] } 
##exportToJson(connectionDetails,"CDM_SCHEMA", "RESULTS_SCHEMA", "C:/AchillesWeb/data/SAMPLE", cdmVersion = "cdm version")


library(Achilles)
connectionDetails <- createConnectionDetails(
  dbms="postgresql", 
  server="localhost/synthea_omop", 
  #user="ohdsi_admin_user", 
  user="christopherroeder", 
  password='', 
  port="5432")

#exportToJson(connectionDetails,"cdm", "results", "/Users/christopherroeder/output", cdmVersion = "5")
exportToJson(connectionDetails,"cdm", "results", "/Users/christopherroeder/output", vocabDatabaseSchema="vocabulary")

