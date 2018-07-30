-------------------------------------------------------------------------
-- Name:      SP_PERFORM_ICN_CONVERSION
-- Author:    John Fisher
-- Date:      int. blank
-- Purpose:   Recovery Process - Perform ICN conversion.
--
-------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE SP_PERFORM_ICN_CONVERSION IS

   r_error_msg      VARCHAR2(255) := '';
   v_update_count   SMALLINT := 0;
   v_total_updated  SMALLINT := 0;

   CURSOR DATA IS
      SELECT I.ICN, X.PROMISE_ICN, X.MCO_CRN
	  FROM ICN_FLAGGING_CONTROL I,ICN_FLAGGING_XREF_100 X
      WHERE I.ICN = X.MCO_CRN;

   BEGIN
      FOR REC IN DATA LOOP
         BEGIN
            IF REC.PROMISE_ICN IS NOT NULL THEN
 
               UPDATE ICN_FLAGGING_CONTROL SET
                      ICN = REC.PROMISE_ICN
					  WHERE ICN = REC.MCO_CRN;

			   v_update_count := v_update_count + 1;

			   IF MOD(v_update_count,100) = 0 THEN
			      v_total_updated := v_total_updated + 100;
				  v_update_count := 0;
				  r_error_msg := 'Number of ICN Records Updated:  ' || TO_CHAR(v_total_updated);
			      INSERT INTO ICN_FLAGGING_ERROR (date_timestamp, procedure_name, error_message)
                  VALUES ( SYSDATE, 'SP_PERFORM_ICN_CONVERSION', r_error_msg);
                  COMMIT;
			   END IF;

            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END;
      END LOOP;
	  r_error_msg := 'Total Number of ICN Records Updated:  ' || TO_CHAR(v_total_updated + v_update_count);
	  INSERT INTO ICN_FLAGGING_ERROR (date_timestamp, procedure_name, error_message)
                  VALUES ( SYSDATE, 'SP_PERFORM_ICN_CONVERSION', r_error_msg);
                  COMMIT;

      COMMIT;
   EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
         r_error_msg := 'Error Code = '
         || SQLCODE
         || ' and Error Message = '
         || SUBSTR (SQLERRM, 1, 125)
         || ' Error '
         || r_error_msg;
         INSERT INTO ICN_FLAGGING_ERROR (date_timestamp, procedure_name, error_message)
         VALUES ( SYSDATE, 'SP_PERFORM_ICN_CONVERSION', r_error_msg);
         COMMIT;
	  RAISE;
   END SP_PERFORM_ICN_CONVERSION;
/

