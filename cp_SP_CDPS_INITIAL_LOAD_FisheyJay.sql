CREATE OR REPLACE PROCEDURE sp_cdps_initial_load ( p_load_start      IN DATE,
                                                   p_load_end        IN DATE ) IS
												   
/******************************************************************************
   NAME:       sp_cdps_initial_load 
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        int. blank  John Fisher      Procedure to perform initial data
                                           population of CDPS MAIN table. 
******************************************************************************/
	  
   v_cat              VARCHAR2(6);
   v_icd9_code        VARCHAR2(7);
   v_cdps_score       NUMBER(9,5);
   v_member_maid      VARCHAR2(15);
   v_claim_id         VARCHAR2(12);
   r_error_msg        VARCHAR2(500);					       

   CURSOR DATA IS
      SELECT FC.CLAIM_ID, 
             FC.CLAIM_SEQUENCE_NO, 
             FC.MEMBER_ID,
             FC.PAID_DATE, 
             FC.SERVICE_FROM_DATE,
             FC.SERVICE_THROUGH_DATE,
             FC.SERVICE_PROVIDER_ID,
             FC.CLAIM_PCP,			  
             FC.DIAG1,FC.DIAG2,FC.DIAG3,FC.DIAG4,FC.DIAG5, 
             FC.DIAG6,FC.DIAG7,FC.DIAG8,FC.DIAG9, 
             FC.MEMBER_AGE
      FROM FISHEY_CLAIMS FC
      WHERE  ((FC.SERVICE_FROM_DATE between p_load_start and p_load_end		 
      AND FC.CLAIM_PAYMENT_STATUS='02')
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
      EXECUTE IMMEDIATE 'truncate table CDPS_SCORING_DIS_CLMS_MAIN drop storage';
	  
      PK_CDPS_SCORING.debug_log( SYSDATE, 'sp_cdps_initial_load', 
                          'Disease Claims Main Table has been Truncated.' );

/******************************************************************************/
      PK_CDPS_SCORING.debug_log( SYSDATE, 'sp_cdps_initial_load', 
	                      'Beginning Initial Load Disease Claims Main Table.' );

      v_claim_id := 'X';						  
      FOR REC IN DATA LOOP

         <<diag1>>
         BEGIN
            IF REC.DIAG1 IS NOT NULL THEN
               SELECT ICD9_CODE, CDPS_CATEGORY
               INTO v_icd9_code, v_cat
               FROM CDPS_SCORING_DIAG_CATEGORY DS
			   WHERE DS.ICD9_CODE = REC.DIAG1;
			   
               v_cdps_score := PK_CDPS_SCORING.fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);
			   
               IF v_claim_id <> REC.CLAIM_ID THEN
                  v_member_maid := NULL;
   		          v_member_maid := PK_CDPS_SCORING.fn_retrieve_member_maid(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;
			   
			   v_claim_id := REC.CLAIM_ID;
			   
 	           PK_CDPS_SCORING.load_data ( REC.CLAIM_ID,REC.CLAIM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_maid,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAIM_PCP,
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
			   
               v_cdps_score := PK_CDPS_SCORING.fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_claim_id <> REC.CLAIM_ID THEN
                  v_member_maid := NULL;
   		          v_member_maid := PK_CDPS_SCORING.fn_retrieve_member_maid(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;
			   
			   v_claim_id := REC.CLAIM_ID;

 	           PK_CDPS_SCORING.load_data ( REC.CLAIM_ID,REC.CLAIM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_maid,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAIM_PCP,
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
			   
               v_cdps_score := PK_CDPS_SCORING.fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_claim_id <> REC.CLAIM_ID THEN
                  v_member_maid := NULL;
   		          v_member_maid := PK_CDPS_SCORING.fn_retrieve_member_maid(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;

			   v_claim_id := REC.CLAIM_ID;
			   			   
 	           PK_CDPS_SCORING.load_data ( REC.CLAIM_ID,REC.CLAIM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_maid,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAIM_PCP,
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

               v_cdps_score := PK_CDPS_SCORING.fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_claim_id <> REC.CLAIM_ID THEN
                  v_member_maid := NULL;
   		          v_member_maid := PK_CDPS_SCORING.fn_retrieve_member_maid(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;

			   v_claim_id := REC.CLAIM_ID;
			   
 	           PK_CDPS_SCORING.load_data ( REC.CLAIM_ID,REC.CLAIM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_maid,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAIM_PCP,
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
			   
               v_cdps_score := PK_CDPS_SCORING.fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_claim_id <> REC.CLAIM_ID THEN
                  v_member_maid := NULL;
   		          v_member_maid := PK_CDPS_SCORING.fn_retrieve_member_maid(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;
			   
  			   v_claim_id := REC.CLAIM_ID;

 	           PK_CDPS_SCORING.load_data ( REC.CLAIM_ID,REC.CLAIM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_maid,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAIM_PCP,
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

               v_cdps_score := PK_CDPS_SCORING.fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_claim_id <> REC.CLAIM_ID THEN
                  v_member_maid := NULL;
   		          v_member_maid := PK_CDPS_SCORING.fn_retrieve_member_maid(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;
			   
			   v_claim_id := REC.CLAIM_ID;

 	           PK_CDPS_SCORING.load_data ( REC.CLAIM_ID,REC.CLAIM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_maid,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAIM_PCP,
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
			   
               v_cdps_score := PK_CDPS_SCORING.fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);

               IF v_claim_id <> REC.CLAIM_ID THEN
                  v_member_maid := NULL;
   		          v_member_maid := PK_CDPS_SCORING.fn_retrieve_member_maid(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;
			   
			   v_claim_id := REC.CLAIM_ID;

 	           PK_CDPS_SCORING.load_data ( REC.CLAIM_ID,REC.CLAIM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_maid,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAIM_PCP,
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
			   
               v_cdps_score := PK_CDPS_SCORING.fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);			   

               IF v_claim_id <> REC.CLAIM_ID THEN
                  v_member_maid := NULL;
   		          v_member_maid := PK_CDPS_SCORING.fn_retrieve_member_maid(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;

			   v_claim_id := REC.CLAIM_ID;

 	           PK_CDPS_SCORING.load_data ( REC.CLAIM_ID,REC.CLAIM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_maid,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAIM_PCP,
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
			   
               v_cdps_score := PK_CDPS_SCORING.fn_retrieve_cdps_score(REC.MEMBER_AGE, v_cat);			   

               IF v_claim_id <> REC.CLAIM_ID THEN
                  v_member_maid := NULL;
   		          v_member_maid := PK_CDPS_SCORING.fn_retrieve_member_maid(REC.MEMBER_ID,REC.SERVICE_FROM_DATE);			   		
			   END IF;

			   v_claim_id := REC.CLAIM_ID;

 	           PK_CDPS_SCORING.load_data ( REC.CLAIM_ID,REC.CLAIM_SEQUENCE_NO,REC.MEMBER_ID,
						   v_member_maid,REC.PAID_DATE,REC.SERVICE_FROM_DATE, 
						   REC.SERVICE_THROUGH_DATE,REC.SERVICE_PROVIDER_ID,REC.CLAIM_PCP,
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

      PK_CDPS_SCORING.debug_log( SYSDATE, 'sp_cdps_initial_load', 
	                      'Completed Initial Load of Disease Claims Main table.' );
						  
   EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      r_error_msg := 'Error Code = '
         || SQLCODE
         || ' and Error Message = '
         || SUBSTR (SQLERRM, 1, 125)
         || ' Error '
         || r_error_msg;
      PK_CDPS_SCORING.debug_log( SYSDATE, 'sp_cdps_initial_load', r_error_msg );
	  RAISE;
   END sp_cdps_initial_load;
/
