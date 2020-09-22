
if (!require("devtools")) install.packages("devtools")
if (!require("Achilles")) devtools::install_github("OHDSI/Achilles")
# I had better luck installing from a download. TODO
# note here that 2.6 is the way to go, not root from the git tree
# https://forums.ohdsi.org/t/atlas-setup-failing/5858/2
# this is about it not finding bootstrap

