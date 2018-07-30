-------------------------------------------------------------------------
-- Author:    John Fisher
-- Date:      int. blank
--
-- Purpose:   Create CDPS Modeling Process in Data Warehouse
--            Grant object permissions script.
--               Roles: USER_MAIN, USER_READ
--               QA User: ops_user
--            Tables:
--               CDPS_SCORING_DIAG_CATEGORY
--               CDPS_SCORING_DISEASE_SCORE
--               CDPS_SCORING_NON_PROC_CDS
--               CDPS_SCORING_NON_REV_CDS
--               CDPS_SCORING_DIS_CLMS_MAIN
--               CDPS_SCORING_CUR_PD_SCORES
--               CDPS_SCORING_HIST_SCORES
--               CDPS_SCORING_CHANGE_SUMMARY
--               CDPS_SCORING_ERROR
--               CDPS_SCORING_RUN
--            Objects:
--               PK_CDPS_SCORING TO USER_MAIN;
--               sp_cdps_initial_load
-------------------------------------------------------------------------

GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_DIAG_CATEGORY TO USER_MAIN;
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_DIAG_CATEGORY TO ops_user;
GRANT SELECT ON CDPS_SCORING_DIAG_CATEGORY TO USER_READ;
-------------------------------------------------------------------------
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_DISEASE_SCORE TO USER_MAIN;
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_DISEASE_SCORE TO ops_user;
GRANT SELECT ON CDPS_SCORING_DISEASE_SCORE TO USER_READ;
-------------------------------------------------------------------------
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_NON_PROC_CDS TO USER_MAIN;
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_NON_PROC_CDS TO ops_user;
GRANT SELECT ON CDPS_SCORING_NON_PROC_CDS TO USER_READ;
-------------------------------------------------------------------------
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_NON_REV_CDS TO USER_MAIN;
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_NON_REV_CDS TO ops_user;
GRANT SELECT ON CDPS_SCORING_NON_REV_CDS TO USER_READ;
-------------------------------------------------------------------------
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_DIS_CLMS_MAIN TO USER_MAIN;
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_DIS_CLMS_MAIN TO ops_user;
GRANT SELECT ON CDPS_SCORING_DIS_CLMS_MAIN TO USER_READ;
-------------------------------------------------------------------------
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_CUR_PD_SCORES TO USER_MAIN;
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_CUR_PD_SCORES TO ops_user;
GRANT SELECT ON CDPS_SCORING_CUR_PD_SCORES TO USER_READ;
-------------------------------------------------------------------------
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_HIST_SCORES TO USER_MAIN;
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_HIST_SCORES TO ops_user;
GRANT SELECT ON CDPS_SCORING_HIST_SCORES TO USER_READ;
-------------------------------------------------------------------------
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_CHANGE_SUMMARY TO USER_MAIN;
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_CHANGE_SUMMARY TO ops_user;
GRANT SELECT ON CDPS_SCORING_CHANGE_SUMMARY TO USER_READ;
-------------------------------------------------------------------------
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_ERROR TO USER_MAIN;
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_ERROR TO ops_user;
GRANT SELECT ON CDPS_SCORING_ERROR TO USER_READ;
-------------------------------------------------------------------------
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_RUN TO USER_MAIN;
GRANT DELETE, INSERT, SELECT, UPDATE ON CDPS_SCORING_RUN TO ops_user;
GRANT SELECT ON CDPS_SCORING_RUN TO USER_READ;
-------------------------------------------------------------------------
GRANT EXECUTE ON PK_CDPS_SCORING TO USER_MAIN;
GRANT EXECUTE ON PK_CDPS_SCORING TO ops_user;
-------------------------------------------------------------------------
GRANT EXECUTE ON sp_cdps_initial_load TO USER_MAIN;
GRANT EXECUTE ON sp_cdps_initial_load TO ops_user;
