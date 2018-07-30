CREATE OR REPLACE PACKAGE PK_CDPS_SCORING AS
/******************************************************************************
   NAME:       PK_CDPS_SCORING

               CDPS - The Chronic Disability Scoring / Processing System for 
               Identifying members in need of Member Outreach due to some combination 
			   of: age (very old, very young), severity of diagnosis code and length 
			   of time since last provider visit / medical care event.

			   I feel that this is a technical process that positively and meaningfully helps 
			   those persons most in need of outreach / medical care. 
			   
			   I get no greater sense of accomplishment, pride or satisfaction as a developer 
			   than when my code helps people in a real and meaningful way. That said ...

			   If another technologist such as myself anywhere in the world can take this code 
			   and emulate it to server their needs and similarly have a positive effect on 
			   sick and/or very young or aging persons anywhere, if it helps just one person, 
			   then it is wonderful! ...and the time I spent posting this was time very well 
			   spent.

   PURPOSE:	   This is a Chronic Disability Scoring System that is designed to 
			   identify the sickest or most ill members of the health plan for 
			   Proactive Outreach purposes. A Senior Business Analyst in an 
			   Actuarial Department business-side (outside I.T.) had created a 
			   process like in MS Access which was terribly inefficient, painfully 
			   slow, taking two days to produce the information he needed.

			   I created this process in it's entirety in the Oracle Data Warehouse 
			   for him, having gathered his requirements over many sessions and 
			   weeks. I eliminated the onerous ODBC connection he had been connecting 
			   to Oracle with and eliminated that network traffic as well.

			   To say that his MS Access process was slow does a disservice to slow 
			   running processes eveywhere. I mean, this thing was a w f u l.

			   This process combines age, certain ICD9 Illness codes, and the 
			   length of time it has been since the member was last seen by a 
			   provider.

			   Sick & older health plan members having gone 2-3 months, for 
			   example, without being seen by the provider type required, would 
			   be placed in an Outreach Program.

			   The Outreach program began with mailings, and if that failed, a nurse 
			   making a phone call and if that failed as well, then a nurse would pay 
			   the member a visit at their home to get them the medical attention they 
			   desperately need.

   ENVIRON:	   The Oracle Data Warehouse contains claims data that is automatically 
               and regularly pushed to it from the online claims processing system. This 
			   is an ongoing process that runs at least nightly, actually many times per 
			   day via automated ETL jobs, etc.

			   Obviously there is absolutely no HIPPA related data anwhere in this 
			   solution that I am posting. This solution is in the form of an Oracle PL-SQL 
			   Package Specification and Package Body which I wrote in it's entirety for a 
			   large Health Insurance Provider. I have removed / replaced all names, variable 
			   names, server names, user names, table names, etc so as to ensure the data 
			   privacy of my former client.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        int. blank   John Fisher      
   
******************************************************************************/

   PROCEDURE sp_cdps_monthly_append;										  
  
   FUNCTION  fn_retrieve_cdps_score  (    p_member_age      IN     NUMBER, 
                                          p_cdps_category   IN     VARCHAR2 )
                                                            RETURN NUMBER;
															
   FUNCTION  fn_retrieve_member_medicaid_id (    p_member_id       IN     VARCHAR2,
                                          p_service_from_dt IN     DATE )
                                                            RETURN VARCHAR2;														
										
   PROCEDURE load_data(
      p_CLAM_id             IN   VARCHAR2
    , p_CLAM_seq_no         IN   VARCHAR2
    , p_member_id            IN   VARCHAR2
    , p_member_medicaid_id          IN   VARCHAR2
    , p_paid_date            IN   VARCHAR2
    , p_service_from_date    IN   VARCHAR2
	, p_service_thru_date    IN   VARCHAR2
	, p_service_prov_id      IN   VARCHAR2
	, p_CLAM_pcp            IN   VARCHAR2
	, p_diag                 IN   VARCHAR2
	, p_category             IN   VARCHAR2
	, p_icd9_code            IN   VARCHAR2
	, p_member_age           IN   VARCHAR2	
	, p_cdps_score           IN   NUMBER  );
	
   PROCEDURE sp_build_summary_data (c_start      IN DATE,
                                    c_end        IN DATE,
									h_start      IN DATE,
									h_end        IN DATE,
									p_score_diff IN NUMBER );
	
 
   PROCEDURE sp_load_cur_pd_scores (p_start_dt   IN DATE,
                                    p_end_dt     IN DATE );
   
   PROCEDURE sp_load_hist_scores   (p_hstart_dt  IN DATE,
                                    p_hend_dt    IN DATE );
									
   PROCEDURE sp_load_change_score_summary (p_score_diff IN NUMBER);   								  

   PROCEDURE debug_log (p_date IN DATE,   p_procedure_name  IN VARCHAR2, p_log_message IN VARCHAR2 );
   
   PROCEDURE sp_set_processing_flag ( p_yes_no   IN VARCHAR2,
                                      p_run_date IN DATE);

END PK_CDPS_SCORING;
/

CREATE OR REPLACE PACKAGE BODY PK_CDPS_SCORING AS
/******************************************************************************
   NAME:       PK_CDPS_SCORING
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        int. blank  John Fisher      See above.
   
******************************************************************************/

   unique_constraint             EXCEPTION;
   PRAGMA EXCEPTION_INIT (unique_constraint, -00001);

   r_error_msg                   VARCHAR2(500);
   v_score_diff                  NUMBER;

/******************************************************************************/

   PROCEDURE sp_cdps_monthly_append IS
	  
      v_cat              VARCHAR2(6);
      v_icd9_code        VARCHAR2(7);
	  v_cdps_score       NUMBER(9,5);
	  v_member_medicaid_id      VARCHAR2(15);
	  v_CLAM_id         VARCHAR2(12);

      CURSOR DATA IS
         SELECT FC.CLAM_ID, 
                FC.CLAM_SEQUENCE_NO, 
                FC.MEMBER_ID,
                FC.PAID_DATE, 
                FC.SERVICE_FROM_DATE, 
				FC.SERVICE_THROUGH_DATE,
				FC.SERVICE_PROVIDER_ID,
				FC.CLAM_PCP,
                FC.DIAG1,FC.DIAG2,FC.DIAG3,FC.DIAG4,FC.DIAG5, 
                FC.DIAG6,FC.DIAG7,FC.DIAG8,FC.DIAG9, 
                FC.MEMBER_AGE
         FROM FISHEY_CLAMS FC
         WHERE  ((FC.PAID_DATE BETWEEN TO_DATE(ADD_MONTHS(LAST_DAY(SYSDATE),-2) + 1,'DD_MON_YY')
		                       AND	   TO_DATE(ADD_MONTHS(LAST_DAY(SYSDATE),-1),'DD_MON_YY')	 
         AND FC.CLAM_PAYMENT_STATUS='02')
         AND ((FC.PAID_AMOUNT > 0) OR (FC.CAP_FFS_INDICATOR='Y' AND FC.PAID_AMOUNT=0)))
         AND NOT EXISTS (SELECT 'x'
                         FROM    CDPS_SCORING_NON_PROC_CDS CSNPC
                         WHERE   CSNPC.PROCEDURE_CODE = NVL(FC.PROCEDURE_CODE, '999'))
         AND NOT EXISTS (SELECT 'x'
                         FROM    CDPS_SCORING_NON_REV_CDS CSNRC
                         WHERE   CSNRC.REVENUE_CODE = NVL(FC.REVENUE_CODE, '00000'));

/******************************************************************************/

   BEGIN

      EXECUTE IMMEDIATE 'alter session set optimizer_index_cost_adj=1';

/******************************************************************************/

      debug_log( SYSDATE, 'sp_cdps_monthly_append', 
	                      'Beginning Monthly Append to Disease CLAMS Main Table.' );

      v_CLAM_id := 'X';						  
      FOR REC IN DATA LOOP

         <<diag1>>
         BEGIN
            IF REC.DIAG1 IS NOT NULL THEN
               SELECT ICD9_CODE, CDPS_CATEGORY
               INTO v_icd9_code, v_cat
               FROM CDPS_SCORING_DIAG_CATEGORY DS
			   WHERE DS.ICD9_CODE = REC.DIAG1;
			   
               v_cdps_score := fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);
			   
               IF v_CLAM_id <> REC.CLAM_ID THEN
                  v_member_medicaid_id := NULL;
   		          v_member_medicaid_id := fn_retrieve_member_medicaid_id(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;
			   
			   v_CLAM_id := REC.CLAM_ID;
			   
 	           load_data ( REC.CLAM_ID,REC.CLAM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_medicaid_id,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAM_PCP,						   
                           'Diag1',v_cat,v_icd9_code,REC.MEMBER_AGE, 
                           v_cdps_score );

            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END diag1;
/******************************************************************************/
         <<diag2>>
         BEGIN
            IF REC.DIAG2 IS NOT NULL THEN
               SELECT ICD9_CODE, CDPS_CATEGORY
               INTO v_icd9_code, v_cat
               FROM CDPS_SCORING_DIAG_CATEGORY DS
			   WHERE DS.ICD9_CODE = REC.DIAG2;
			   
               v_cdps_score := fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_CLAM_id <> REC.CLAM_ID THEN
                  v_member_medicaid_id := NULL;
   		          v_member_medicaid_id := fn_retrieve_member_medicaid_id(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;
			   
			   v_CLAM_id := REC.CLAM_ID;

 	           load_data ( REC.CLAM_ID,REC.CLAM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_medicaid_id,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAM_PCP,						   
                           'Diag2',v_cat,v_icd9_code,REC.MEMBER_AGE, 
                           v_cdps_score );
						   
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END diag2;
/******************************************************************************/		 
         <<diag3>>
         BEGIN
            IF REC.DIAG3 IS NOT NULL THEN
               SELECT ICD9_CODE, CDPS_CATEGORY
               INTO v_icd9_code, v_cat
               FROM CDPS_SCORING_DIAG_CATEGORY DS
			   WHERE DS.ICD9_CODE = REC.DIAG3;
			   
               v_cdps_score := fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_CLAM_id <> REC.CLAM_ID THEN
                  v_member_medicaid_id := NULL;
   		          v_member_medicaid_id := fn_retrieve_member_medicaid_id(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;

			   v_CLAM_id := REC.CLAM_ID;
			   			   
 	           load_data ( REC.CLAM_ID,REC.CLAM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_medicaid_id,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAM_PCP,
                           'Diag3',v_cat,v_icd9_code,REC.MEMBER_AGE, 
                           v_cdps_score );
						   
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END diag3;
/******************************************************************************/		 
         <<diag4>>
         BEGIN
            IF REC.DIAG4 IS NOT NULL THEN
               SELECT ICD9_CODE, CDPS_CATEGORY
               INTO v_icd9_code, v_cat
               FROM CDPS_SCORING_DIAG_CATEGORY DS
			   WHERE DS.ICD9_CODE = REC.DIAG3;

               v_cdps_score := fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_CLAM_id <> REC.CLAM_ID THEN
                  v_member_medicaid_id := NULL;
   		          v_member_medicaid_id := fn_retrieve_member_medicaid_id(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;

			   v_CLAM_id := REC.CLAM_ID;
			   
 	           load_data ( REC.CLAM_ID,REC.CLAM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_medicaid_id,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAM_PCP,
                           'Diag4',v_cat,v_icd9_code,REC.MEMBER_AGE, 
                           v_cdps_score );
						   
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END diag4;
/******************************************************************************/		 
         <<diag5>>
         BEGIN
            IF REC.DIAG5 IS NOT NULL THEN
               SELECT ICD9_CODE, CDPS_CATEGORY
               INTO v_icd9_code, v_cat
               FROM CDPS_SCORING_DIAG_CATEGORY DS
			   WHERE DS.ICD9_CODE = REC.DIAG5;
			   
               v_cdps_score := fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_CLAM_id <> REC.CLAM_ID THEN
                  v_member_medicaid_id := NULL;
   		          v_member_medicaid_id := fn_retrieve_member_medicaid_id(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;
			   
  			   v_CLAM_id := REC.CLAM_ID;

 	           load_data ( REC.CLAM_ID,REC.CLAM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_medicaid_id,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAM_PCP,
                           'Diag5',v_cat,v_icd9_code,REC.MEMBER_AGE, 
                           v_cdps_score );
						   
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END diag5;
/******************************************************************************/		 
         <<diag6>>
         BEGIN
            IF REC.DIAG6 IS NOT NULL THEN
               SELECT ICD9_CODE, CDPS_CATEGORY
               INTO v_icd9_code, v_cat
               FROM CDPS_SCORING_DIAG_CATEGORY DS
			   WHERE DS.ICD9_CODE = REC.DIAG6;

               v_cdps_score := fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_CLAM_id <> REC.CLAM_ID THEN
                  v_member_medicaid_id := NULL;
   		          v_member_medicaid_id := fn_retrieve_member_medicaid_id(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;
			   
			   v_CLAM_id := REC.CLAM_ID;

 	           load_data ( REC.CLAM_ID,REC.CLAM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_medicaid_id,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAM_PCP,
                           'Diag6',v_cat,v_icd9_code,REC.MEMBER_AGE, 
                           v_cdps_score );
						   
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END diag6;
/******************************************************************************/		 
         <<diag7>>
         BEGIN
            IF REC.DIAG7 IS NOT NULL THEN
               SELECT ICD9_CODE, CDPS_CATEGORY
               INTO v_icd9_code, v_cat
               FROM CDPS_SCORING_DIAG_CATEGORY DS
			   WHERE DS.ICD9_CODE = REC.DIAG7;
			   
               v_cdps_score := fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_CLAM_id <> REC.CLAM_ID THEN
                  v_member_medicaid_id := NULL;
   		          v_member_medicaid_id := fn_retrieve_member_medicaid_id(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;
			   
			   v_CLAM_id := REC.CLAM_ID;

 	           load_data ( REC.CLAM_ID,REC.CLAM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_medicaid_id,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAM_PCP,
                           'Diag7',v_cat,v_icd9_code,REC.MEMBER_AGE, 
                           v_cdps_score );
						   
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END diag7;
/******************************************************************************/		 
         <<diag8>>
         BEGIN
            IF REC.DIAG8 IS NOT NULL THEN
               SELECT ICD9_CODE, CDPS_CATEGORY
               INTO v_icd9_code, v_cat
               FROM CDPS_SCORING_DIAG_CATEGORY DS
			   WHERE DS.ICD9_CODE = REC.DIAG8;
			   
               v_cdps_score := fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);			   

               IF v_CLAM_id <> REC.CLAM_ID THEN
                  v_member_medicaid_id := NULL;
   		          v_member_medicaid_id := fn_retrieve_member_medicaid_id(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;

			   v_CLAM_id := REC.CLAM_ID;

 	           load_data ( REC.CLAM_ID,REC.CLAM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_medicaid_id,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAM_PCP,
                           'Diag8',v_cat,v_icd9_code,REC.MEMBER_AGE, 
                           v_cdps_score );
						   
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END diag8;
/******************************************************************************/		 
         <<diag9>>
         BEGIN
            IF REC.DIAG9 IS NOT NULL THEN
               SELECT ICD9_CODE, CDPS_CATEGORY
               INTO v_icd9_code, v_cat
               FROM CDPS_SCORING_DIAG_CATEGORY DS
			   WHERE DS.ICD9_CODE = REC.DIAG9;
			   
               v_cdps_score := fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);			   

               IF v_CLAM_id <> REC.CLAM_ID THEN
                  v_member_medicaid_id := NULL;
   		          v_member_medicaid_id := fn_retrieve_member_medicaid_id(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;

			   v_CLAM_id := REC.CLAM_ID;

 	           load_data ( REC.CLAM_ID,REC.CLAM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_medicaid_id,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAM_PCP,
                           'Diag9',v_cat,v_icd9_code,REC.MEMBER_AGE, 
                           v_cdps_score );
						   
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END diag9;
/******************************************************************************/		 
      END LOOP;

      COMMIT;

      debug_log( SYSDATE, 'sp_cdps_monthly_append', 
	                      'Completed Monthly Append to Disease CLAMS Main Table.' );
						  
   EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      r_error_msg := 'Error Code = '
         || SQLCODE
         || ' and Error Message = '
         || SUBSTR (SQLERRM, 1, 125)
         || ' Error '
         || r_error_msg;
      debug_log( SYSDATE, 'sp_cdps_monthly_append', r_error_msg );
	  RAISE;
   END sp_cdps_monthly_append;
   
/******************************************************************************/		 

   PROCEDURE load_data(
      p_CLAM_id             IN   VARCHAR2
    , p_CLAM_seq_no         IN   VARCHAR2
    , p_member_id            IN   VARCHAR2
	, p_member_medicaid_id          IN   VARCHAR2
    , p_paid_date            IN   VARCHAR2
    , p_service_from_date    IN   VARCHAR2
	, p_service_thru_date    IN   VARCHAR2
	, p_service_prov_id      IN   VARCHAR2
	, p_CLAM_pcp            IN   VARCHAR2
	, p_diag                 IN   VARCHAR2
	, p_category             IN   VARCHAR2
	, p_icd9_code            IN   VARCHAR2
	, p_member_age           IN   VARCHAR2	
	, p_cdps_score           IN   NUMBER  ) IS
	
   BEGIN
   
   INSERT INTO CDPS_SCORING_DIS_CLMS_MAIN 
              (CLAM_ID, CLAM_SEQUENCE_NO, MEMBER_ID, member_medicaid_id, PAID_DATE, SERVICE_FROM_DATE, 
			   SERVICE_THROUGH_DATE, SERVICE_PROVIDER_ID, CLAM_PCP,
	           ICD9_CODE, CDPS_CATEGORY, DIAG_CODE, MEMBER_AGE, CDPS_SCORE)
   VALUES     (p_CLAM_id, p_CLAM_seq_no, p_member_id, p_member_medicaid_id, p_paid_date, 
               p_service_from_date, p_service_thru_date, p_service_prov_id, 
			   p_CLAM_pcp, p_icd9_code, p_category, p_diag, p_member_age, p_cdps_score);
			   
      COMMIT;
   EXCEPTION
      WHEN unique_constraint THEN
         NULL;
	  WHEN OTHERS THEN
      ROLLBACK;
      r_error_msg := 'Error Code = '
         || SQLCODE
         || ' and Error Message = '
         || SUBSTR (SQLERRM, 1, 125)
         || ' Error '
         || r_error_msg;
      debug_log( SYSDATE, 'load_data', r_error_msg );
	  RAISE;
   END load_data;

/******************************************************************************/

   FUNCTION fn_retrieve_cdps_score ( p_member_age    IN NUMBER,
                                     p_cdps_category IN VARCHAR2 )
      RETURN NUMBER
   IS
      v_score  NUMBER;  
   BEGIN
      v_score := 0;

      IF p_member_age < 18 THEN
         SELECT DISABLED_UNDER_18
         INTO v_score
         FROM CDPS_SCORING_DISEASE_SCORE DS
         WHERE DS.CDPS_CATEGORY = p_cdps_category;
	  ELSE
         SELECT DISABLED_18_AND_OVER
		 INTO v_score
         FROM CDPS_SCORING_DISEASE_SCORE DS
         WHERE DS.CDPS_CATEGORY = p_cdps_category;
      END IF;

      RETURN v_score;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END fn_retrieve_cdps_score;

/******************************************************************************/

   FUNCTION fn_retrieve_member_medicaid_id ( p_member_id       IN  VARCHAR2,
                                      p_service_from_dt IN  DATE )
      RETURN      VARCHAR2
   IS
      v_maid      VARCHAR2(15);
	  v_term_date DATE;  
      BEGIN

		 <<member_info>>
		 BEGIN
		    SELECT DECODE (NVL (member_medicaid_id, 'ID-' || p_member_id)
                        , 'DUP', 'ID-' || p_member_id
                        , 'DUPLICATE', 'ID-' || p_member_id
                        , NVL (member_medicaid_id, 'ID-' || p_member_id))
            INTO v_maid
            FROM FISHEY_member fm
            WHERE fm.member_id = p_member_id
            AND p_service_from_dt BETWEEN fm.enrollment_date
                                       AND fm.disenroll_date;
									   
            RETURN v_maid;
         EXCEPTION
            WHEN OTHERS THEN
               v_maid := 'ID-' || p_member_id;
		       RETURN v_maid;
	     END member_info;
		 
         <<term_date>>
         BEGIN
            SELECT MAX (fm.disenroll_date)
            INTO v_term_date
            FROM FISHEY_member fm
            WHERE fm.member_id = p_member_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               debug_log ( SYSDATE,'fn_retrieve_member_medicaid_id','NO_DATA_FOUND : Error Message: '
                                || SQLCODE
                                || ' : '
                                || SQLERRM
                                || ' : '
                                || p_member_id);
               NULL;
            WHEN OTHERS THEN
               debug_log ( SYSDATE,'fn_retrieve_member_medicaid_id','OTHERS : Error Message: '
                                || SQLCODE
                                || ' : '
                                || SQLERRM
                                || ' : '
                                || p_member_id);
         END term_date;
		 
   END fn_retrieve_member_medicaid_id;

/******************************************************************************/

   PROCEDURE debug_log (p_date           IN DATE, 
                        p_procedure_name IN VARCHAR2, 
						p_log_message    IN VARCHAR2) IS
						
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
   
      INSERT INTO CDPS_SCORING_ERROR
                 (DATE_TIMESTAMP, PROCEDURE_NAME, ERROR_MESSAGE)
          VALUES (SYSDATE, p_procedure_name, p_log_message);
      COMMIT;
   END debug_log;

/******************************************************************************/   

   PROCEDURE sp_set_processing_flag (p_yes_no   IN VARCHAR2,
                                     p_run_date IN DATE) IS
						
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
   
      UPDATE CDPS_SCORING_RUN
	  SET PROCESSING_FLAG = p_yes_no, RUN_TIMESTAMP = p_run_date;
      COMMIT;
	  
      debug_log( SYSDATE, 'sp_set_processing_flag', 
                'Processing Flag has been set to :' || p_yes_no );	  

   END sp_set_processing_flag;

/******************************************************************************/   
   
   PROCEDURE sp_build_summary_data (c_start      IN DATE,
                                    c_end        IN DATE,
									h_start      IN DATE,
									h_end        IN DATE,
									p_score_diff IN NUMBER ) IS
									
   BEGIN									
   
      /* Set the processing flag to Y */
      sp_set_processing_flag('Y',SYSDATE);

      /************************************************************************/
      /* Create Current Period Scores and Historical Scores tables.           */
      /************************************************************************/
      sp_load_cur_pd_scores(c_start,c_end);
	  
      sp_load_hist_scores  (h_start,h_end);
	  
      /************************************************************************/
      /* Load the Change Score Summary Table.                                 */
      /************************************************************************/	  
      sp_load_change_score_summary (p_score_diff);
   
      /* Set the processing flag to N */
      sp_set_processing_flag('N',NULL);
	  
   END sp_build_summary_data;
   
/******************************************************************************/   

   PROCEDURE sp_load_cur_pd_scores (p_start_dt IN DATE,
                                    p_end_dt   IN DATE) IS
									
	  v_create_sql         VARCHAR2(4000);
      v_update_sql         VARCHAR2(4000);
      v_current_member     VARCHAR2(15);
	  v_cdps_base          VARCHAR2(3);
      v_mbr_tot_score      NUMBER(9,5) := 0;
	  v_current_base       VARCHAR2(3);
	  
      CURSOR DATA IS
         SELECT DISTINCT MEMBER_ID, 
		                 substr(CDPS_SCORING_DIS_CLMS_MAIN.CDPS_CATEGORY,1,3) AS CDPS_BASE,
					     member_medicaid_id, CDPS_SCORE, CLAM_ID, ICD9_CODE 
         FROM      CDPS_SCORING_DIS_CLMS_MAIN
		 WHERE    (SERVICE_FROM_DATE BETWEEN p_start_dt AND p_end_dt)
         ORDER BY  MEMBER_ID, CDPS_BASE, CDPS_SCORE DESC;
						 
/******************************************************************************/

   BEGIN

      EXECUTE IMMEDIATE 'truncate table CDPS_SCORING_CUR_PD_SCORES drop storage';
	  
      debug_log( SYSDATE, 'sp_load_cur_pd_scores', 
                          'Current Period Scores Table has been Truncated.' );

/******************************************************************************/

      debug_log( SYSDATE, 'sp_load_cur_pd_scores', 
	                      'Beginning to Load Current Period Scores Table.' );

      FOR REC IN DATA LOOP
  
         BEGIN
		    IF ((substr(REC.CDPS_BASE,1,2) = 'DD') OR (substr(REC.CDPS_BASE,1,2) = 'GI')) THEN
			   v_cdps_base := substr(REC.CDPS_BASE,1,2);
			ELSE
			   IF ((REC.CDPS_BASE = 'AID') OR (REC.CDPS_BASE = 'HIV')) THEN
			      v_cdps_base := 'INF';
			   ELSE
			      v_cdps_base := REC.CDPS_BASE;
			   END IF;
		    END IF;

            IF REC.MEMBER_ID = v_current_member THEN
			   IF v_cdps_base <> v_current_base THEN
                  -- Write a new record.
				  INSERT INTO CDPS_SCORING_CUR_PD_SCORES
				  VALUES(REC.MEMBER_ID,v_cdps_base,REC.member_medicaid_id,
				         REC.CDPS_SCORE,REC.CLAM_ID,REC.ICD9_CODE);
			   END IF;
            ELSE
               -- Write a new record.
		       INSERT INTO CDPS_SCORING_CUR_PD_SCORES
			   VALUES(REC.MEMBER_ID,v_cdps_base,REC.member_medicaid_id,
				      REC.CDPS_SCORE,REC.CLAM_ID,REC.ICD9_CODE);
            END IF;

		 END;
		 v_current_member := REC.MEMBER_ID;
		 v_current_base   := v_cdps_base; 
		 
      END LOOP;
      COMMIT;

      debug_log( SYSDATE, 'sp_load_cur_pd_scores', 
                'Completed Loading Current Period Scores table.' );	  
	  
   EXCEPTION
   WHEN unique_constraint THEN
      NULL;
   WHEN OTHERS THEN
      ROLLBACK;
      r_error_msg := 'Error Code = '
         || SQLCODE
         || ' and Error Message = '
         || SUBSTR (SQLERRM, 1, 125)
         || ' Error '
         || r_error_msg;
      debug_log( SYSDATE, 'sp_load_cur_pd_scores', r_error_msg );
	  sp_set_processing_flag('N',NULL);
	  RAISE;
   END sp_load_cur_pd_scores;
   
/******************************************************************************/   

   PROCEDURE sp_load_hist_scores (p_hstart_dt IN DATE,
                                  p_hend_dt   IN DATE) IS
									
	  v_hcreate_sql         VARCHAR2(4000);
      v_hupdate_sql         VARCHAR2(4000);
      v_hcurrent_member     VARCHAR2(15);
	  v_hcdps_base          VARCHAR2(3);
      v_hmbr_tot_score      NUMBER(9,5) := 0;
	  v_hcurrent_base       VARCHAR2(3);
	  
      CURSOR DATA IS
         SELECT DISTINCT MEMBER_ID, 
		                 substr(CDPS_SCORING_DIS_CLMS_MAIN.CDPS_CATEGORY,1,3) AS CDPS_BASE,
					     member_medicaid_id, CDPS_SCORE, CLAM_ID, ICD9_CODE 
         FROM      CDPS_SCORING_DIS_CLMS_MAIN
		 WHERE    (SERVICE_FROM_DATE BETWEEN p_hstart_dt AND p_hend_dt)
         ORDER BY  MEMBER_ID, CDPS_BASE, CDPS_SCORE DESC;
						 
/******************************************************************************/

   BEGIN

      EXECUTE IMMEDIATE 'truncate table CDPS_SCORING_HIST_SCORES drop storage';
	  
      debug_log( SYSDATE, 'sp_load_hist_scores', 
                          'Hist Scores Table has been Truncated.' );

/******************************************************************************/

      debug_log( SYSDATE, 'sp_load_hist_scores', 
	                      'Beginning to Load Hist Scores Table.' );

      FOR REC IN DATA LOOP
  
         BEGIN
		    IF ((substr(REC.CDPS_BASE,1,2) = 'DD') OR (substr(REC.CDPS_BASE,1,2) = 'GI')) THEN
			   v_hcdps_base := substr(REC.CDPS_BASE,1,2);
			ELSE
			   IF ((REC.CDPS_BASE = 'AID') OR (REC.CDPS_BASE = 'HIV')) THEN
			      v_hcdps_base := 'INF';
			   ELSE
			      v_hcdps_base := REC.CDPS_BASE;
			   END IF;
		    END IF;
			
            IF REC.MEMBER_ID = v_hcurrent_member THEN
			   IF v_hcdps_base <> v_hcurrent_base THEN
                  -- Write a new record.
				  INSERT INTO CDPS_SCORING_HIST_SCORES
				  VALUES(REC.MEMBER_ID,v_hcdps_base,REC.member_medicaid_id,
				         REC.CDPS_SCORE,REC.CLAM_ID,REC.ICD9_CODE);
			   END IF;
            ELSE
               -- Write a new record.
		       INSERT INTO CDPS_SCORING_HIST_SCORES
			   VALUES(REC.MEMBER_ID,v_hcdps_base,REC.member_medicaid_id,
				      REC.CDPS_SCORE,REC.CLAM_ID,REC.ICD9_CODE);
            END IF;

		 END;
		 v_hcurrent_member := REC.MEMBER_ID;
		 v_hcurrent_base   := v_hcdps_base; 
		 
      END LOOP;
      COMMIT;
	  
      debug_log( SYSDATE, 'sp_load_hist_scores', 
	                      'Completed Loading Historical Scores table.' );	  

   EXCEPTION
   WHEN unique_constraint THEN
      NULL;
   WHEN OTHERS THEN
      ROLLBACK;
      r_error_msg := 'Error Code = '
         || SQLCODE
         || ' and Error Message = '
         || SUBSTR (SQLERRM, 1, 125)
         || ' Error '
         || r_error_msg;
      debug_log( SYSDATE, 'sp_load_hist_scores', r_error_msg );
	  sp_set_processing_flag('N',NULL);
	  RAISE;
   END sp_load_hist_scores;
   
/******************************************************************************/ 

PROCEDURE sp_load_change_score_summary (p_score_diff IN NUMBER) IS
   
   BEGIN

      EXECUTE IMMEDIATE 'truncate table CDPS_SCORING_CHANGE_SUMMARY drop storage';
	  
      debug_log( SYSDATE, 'sp_load_change_score_summary', 
                          'Change Score Summary Table has been Truncated.' );

      debug_log( SYSDATE, 'sp_load_change_score_summary', 
	                      'Beginning to Load Change Score Summary Table.' );

      INSERT INTO CDPS_SCORING_CHANGE_SUMMARY (
         SELECT HS.MEMBER_ID, HS.member_medicaid_id, 
                NVL(sum(HS.BASE_MAX),0) AS HIST_TOTAL_SCORE,
	            NVL(sum(CS.BASE_MAX),0) AS CURR_TOTAL_SCORE,
				NVL(sum(HS.BASE_MAX),0) - NVL(sum(CS.BASE_MAX),0) AS SCORE_DIFF
         FROM CDPS_SCORING_CUR_PD_SCORES CS, CDPS_SCORING_HIST_SCORES HS
         WHERE HS.MEMBER_ID = CS.MEMBER_ID(+) 
         GROUP BY HS.MEMBER_ID,HS.member_medicaid_id 
		 HAVING NVL(sum(HS.BASE_MAX),0) - NVL(sum(CS.BASE_MAX),0) > p_score_diff);
      
	  COMMIT;
	  
	  debug_log( SYSDATE, 'sp_load_change_score_summary', 
	                      'Completed Loading Change Score Summary Table.' );
	  
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         r_error_msg := 'Error Code = '
            || SQLCODE
            || ' and Error Message = '
            || SUBSTR (SQLERRM, 1, 125)
            || ' Error '
            || r_error_msg;
         debug_log( SYSDATE, 'sp_load_change_score_summary', r_error_msg );
		 sp_set_processing_flag('N',NULL);
	     RAISE;
   END sp_load_change_score_summary;
         
/******************************************************************************/   

END PK_CDPS_SCORING;
/

