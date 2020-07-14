
CREATE ROLE ohdsi_admin
  CREATEDB  --  REPLICATION
   VALID UNTIL 'infinity';
COMMENT ON ROLE ohdsi_admin
  IS 'Administration group for OHDSI applications';

CREATE ROLE ohdsi_app
   VALID UNTIL 'infinity';
COMMENT ON ROLE ohdsi_app
  IS 'Application groupfor OHDSI applications';

CREATE ROLE ohdsi_admin_user LOGIN PASSWORD 'XXX_PASSWORD_XXX'
   VALID UNTIL 'infinity';
GRANT ohdsi_admin TO ohdsi_admin_user;
GRANT ohdsi_admin TO XXXUSER;


COMMENT ON ROLE ohdsi_admin_user
  IS 'Admin user account for OHDSI applications';

CREATE ROLE ohdsi_app_user LOGIN PASSWORD 'XXX_PASSWORD_XXX'
   VALID UNTIL 'infinity';
GRANT ohdsi_app TO ohdsi_app_user;
COMMENT ON ROLE ohdsi_app_user
  IS 'Application user account for OHDSI applications';


