CREATE OR REPLACE PACKAGE PKG_ENC_CASUALTY_RESPONSE
AS

/******************************************************************************
   NAME:       PKG_ENC_CASUALTY_RESPONSE
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        int. blank  John Fisher      See above.
   
******************************************************************************/
   PROCEDURE SP_CREATE_ENC_CASLTY_RESP(
      r_error_flag       OUT      VARCHAR2,
      r_error_msg        OUT      VARCHAR2
   );

   PROCEDURE SP_CHECK_EA_CLAMS(
      r_error_flag       OUT      VARCHAR2,
      r_error_msg        OUT      VARCHAR2,
      p_member_id        IN       VARCHAR2,
	  p_member_medicaid_id      IN       VARCHAR2,
	  p_svc_from         IN       DATE,
	  p_svc_thru         IN       DATE
   );

   PROCEDURE SP_CREATE_GEN_FILE(
      p_out_error_flag   OUT      VARCHAR2,
      p_out_error_msg    OUT      VARCHAR2,
      p_passed_query              VARCHAR2 DEFAULT NULL,
      p_filename                  VARCHAR2 DEFAULT NULL,
      p_stamp                     NUMBER   DEFAULT NULL,
      p_delim                     VARCHAR2 DEFAULT NULL,
      p_column_names              NUMBER   DEFAULT 0
   );

   PROCEDURE SP_DEBUG_PROC (
      p_date             IN       DATE,
	  p_procedure_name   IN       VARCHAR2,
	  p_log_message      IN       VARCHAR2
   );

END;
/

CREATE OR REPLACE PACKAGE BODY JPF.PKG_ENC_CASUALTY_RESPONSE
AS
   gv_debug                    NUMBER         := 1;
   gv_build_id                 NUMBER;
------------------------------------------------------------------------------------------
   PROCEDURE SP_CREATE_ENC_CASLTY_RESP(
      r_error_flag    OUT      VARCHAR2,
      r_error_msg     OUT      VARCHAR2)
   IS
      v_member_id              VARCHAR2(15);
      v_member_medicaid_id            VARCHAR2(15);
      v_mem_medicaid_id               VARCHAR2(15);
      v_response_cnt           NUMBER(10) := 0;
      v_resp_rec_cnt           NUMBER(10) := 0;
      v_sql                    VARCHAR2(8000);
      v_fm_cnt                 NUMBER(10) := 0;
      v_filename               VARCHAR2(50);

         CURSOR C_MEMBER_REQUEST
      IS
         SELECT member_medicaid_id, INCIDENT_DATE, SERVICE_FROM_DATE, SERVICE_THROUGH_DATE
         FROM   ENC_CASLTY_REQUEST;

      C_REC        C_MEMBER_REQUEST%ROWTYPE;

         CURSOR C_CHECK_RESPONSES
      IS
         SELECT DISTINCT SUBSTR(member_medicaid_id,1,9) AS MEM_medicaid_id
         FROM   ENC_CASLTY_REQUEST;

      C_CHK        C_CHECK_RESPONSES%ROWTYPE;

   BEGIN
      
      EXECUTE IMMEDIATE 'TRUNCATE TABLE ENC_CASLTY_ERROR';
      SP_DEBUG_PROC(SYSDATE, 'SPCR', 'TRUNCATED TABLE ENC_CASLTY_ERROR');
      
      EXECUTE IMMEDIATE 'TRUNCATE TABLE ENC_CASLTY_RESPONSE';
      SP_DEBUG_PROC(SYSDATE, 'SPCR', 'TRUNCATED TABLE ENC_CASLTY_RESPONSE');

      -- Update MEMBER_ID field in request table by joining member_medicaid_id to FISHEY_MEMBER.
      OPEN C_MEMBER_REQUEST;
      LOOP
      FETCH C_MEMBER_REQUEST INTO C_REC;
      EXIT WHEN C_MEMBER_REQUEST%NOTFOUND;

         v_member_medicaid_id := C_REC.member_medicaid_id;

         SELECT COUNT(1) INTO v_fm_cnt
         FROM   FISHEY_MEMBER FM
         WHERE  C_REC.member_medicaid_id = FM.member_medicaid_id;

         IF v_fm_cnt > 0 THEN

            SELECT DISTINCT FM.MEMBER_ID INTO v_member_id
            FROM   FISHEY_MEMBER FM
            WHERE  C_REC.member_medicaid_id = FM.member_medicaid_id;

            UPDATE ENC_CASLTY_REQUEST ECR SET MEMBER_ID = v_member_id
            WHERE ECR.member_medicaid_id = C_REC.member_medicaid_id;

            -- Check for CLAMS ...
            SP_CHECK_EA_CLAMS(r_error_flag,r_error_msg,v_member_id, C_REC.member_medicaid_id,
                               C_REC.SERVICE_FROM_DATE, C_REC.SERVICE_THROUGH_DATE);
         ELSE
            r_error_flag := 'N';
            r_error_msg  := 'NO MEMBER_ID FOUND FOR member_medicaid_id: ' || C_REC.member_medicaid_id;
            SP_DEBUG_PROC(SYSDATE, 'SPCR', r_error_msg);
         END IF;
      END LOOP;
      CLOSE C_MEMBER_REQUEST;
      COMMIT;

      ------------------------------------------------------------------------------------
      -- After check CLAMS processing is performed, loop through response table to ensure
      -- that each member has a response record written. If none are present, then a 
      -- default record must be written.		      
      ------------------------------------------------------------------------------------
      OPEN C_CHECK_RESPONSES;
      LOOP
      FETCH C_CHECK_RESPONSES INTO C_CHK;
      EXIT WHEN C_CHECK_RESPONSES%NOTFOUND;

         v_mem_medicaid_id := C_CHK.MEM_medicaid_id;
         
         SELECT COUNT(1) INTO v_response_cnt
         FROM   ENC_CASLTY_RESPONSE ECR
         WHERE  v_mem_medicaid_id = ECR.member_medicaid_id;
         
         IF v_response_cnt = 0 THEN
            r_error_flag := 'N';
            r_error_msg  := 'WRITE DEFAULT RESPONSE RECORD FOR member_medicaid_id: ' || v_mem_medicaid_id;
            SP_DEBUG_PROC(SYSDATE, 'SPCR', r_error_msg);
         
            -- Write default response record for no CLAM or CIS number unknown.
            INSERT  INTO ENC_CASLTY_RESPONSE
            VALUES ('0',
                    '        ',
                    '00000000000000000000',
                    ' ',
                    v_mem_medicaid_id,
                    '             ',
                    '        ',
                    '        ',
                    '      ',
                    '  ',
                    '           ',
                    '       ',
                    '       ',
                    '          ',
                    '          ',
                    ' ');
         END IF;         
      END LOOP;
      CLOSE C_CHECK_RESPONSES;
      COMMIT;
         
      ------------------------------------------------------------------------------------
      
      r_error_flag := 'N';
      r_error_msg  := 'BEFORE CALL TO SP_CREATE_GEN_FILE';

      -- Logic to avoid creating empty output files.
      SELECT COUNT (1)
      INTO   v_resp_rec_cnt
      FROM   ENC_CASLTY_RESPONSE;

      IF v_resp_rec_cnt > 0
      THEN

         v_filename := 'yourfileprefix.47.' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.txt';
         v_sql := 'select * from enc_caslty_response order by orig_crn desc, orig_crn_line_no asc';

         SP_CREATE_GEN_FILE (r_error_flag,
                             r_error_msg,
                             v_sql,
                             v_filename);

         INSERT INTO ENC_CASLTY_FILE_TRACKING VALUES (v_filename,SYSDATE,NULL,NULL,NULL);
         COMMIT;

      END IF;

      INSERT INTO ENC_CASLTY_REQUEST_HIST  (SELECT * FROM ENC_CASLTY_REQUEST);
      INSERT INTO ENC_CASLTY_RESPONSE_HIST (SELECT * FROM ENC_CASLTY_RESPONSE);
      COMMIT;

      --------------------------------------

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         r_error_flag := 'N';
         r_error_msg  := 'NO_DATA_FOUND ' || 'member_medicaid_id: ' || v_member_medicaid_id;
         SP_DEBUG_PROC(SYSDATE, 'SPCR', r_error_msg);
         RAISE;
      WHEN OTHERS
      THEN
         ROLLBACK;
         r_error_msg :=
            'Error Code = '
            || SQLCODE
            || ' and Error Message = '
            || SUBSTR (SQLERRM, 1, 125)
            || ' Error '
            || r_error_msg;

            SP_DEBUG_PROC(SYSDATE, 'SPCR', r_error_msg);
         RAISE;
   END SP_CREATE_ENC_CASLTY_RESP;

------------------------------------------------------------------------------------------

   PROCEDURE SP_CHECK_EA_CLAMS(
      r_error_flag    OUT VARCHAR2,
      r_error_msg     OUT VARCHAR2,
      p_member_id      IN VARCHAR2,
      p_member_medicaid_id    IN VARCHAR2,
      p_svc_from       IN DATE,
      p_svc_thru       IN DATE)
   IS
      v_CLAM_id          VARCHAR2(12);
      v_CLAM_seq_no      NUMBER(9);

        CURSOR C_CLAMS
      IS
         SELECT
         CASE WHEN FCU.BILL_TYPE = '77'
                 THEN 4
              WHEN FCU.BILL_TYPE = '88' OR FCU.BILL_TYPE = '99'
                 THEN 3
         ELSE 1
         END
         BILL_TYPE,
         FC.CLAM_ID,
         FC.CLAM_SEQUENCE_NO,
         FC.PAID_DATE,
         CASE WHEN FP.PPID_NO IS NULL
                 THEN CASE WHEN FP.PAR_NON_STATUS = 'NP'
                              THEN CASE WHEN FC.SERVICE_FROM_DATE >= '01-JUL-69' -- changed for data privacy , put your's here
                                           THEN '9999999999999' -- changed for data privacy , put your's here
                                   ELSE '9999999999999' -- changed for data privacy , put your's here
                                   END       
                      ELSE FP.PPID_NO
                      END
         ELSE FP.PPID_NO                     
         END
         PPID_NO,
         FC.SERVICE_FROM_DATE,
         FC.SERVICE_THROUGH_DATE,
         FC.PROCEDURE_CODE,
         FC.HCPCS_MODIFIERS,
         FC.NDC,
		 FC.DIAG1,
 		 FC.DIAG2,
         FC.PAID_AMOUNT,
         FC.BILL_AMOUNT,
         FC.CAP_FFS_INDICATOR,
         FC.LOB,
         FC.STAMP_DATE
         FROM FISHEY_CLAMS FC,
              FISHEY_CLAMS_UB92 FCU,
              FISHEY_PROVIDER FP
         WHERE MEMBER_ID = p_member_id AND
         FC.CLAM_ID = FCU.CLAM_ID(+) AND
         FC.SERVICE_PROVIDER_ID = FP.PROVIDER_ID(+) AND
         (PAID_DATE BETWEEN p_svc_from AND p_svc_thru) AND
         (PAID_AMOUNT > 0 OR CAP_FFS_INDICATOR = 'Y') AND CLAM_SEQUENCE_NO = 1;

      C_CLAMS_VAL        C_CLAMS%ROWTYPE;
      v_rec_count         NUMBER(9) := 0;
      v_ea_count          NUMBER(9) := 0;

   BEGIN

      OPEN C_CLAMS;
      LOOP
      FETCH C_CLAMS INTO C_CLAMS_VAL;
         IF C_CLAMS%ROWCOUNT > 0 THEN
            v_rec_count := C_CLAMS%ROWCOUNT;
         ELSE
            v_rec_count := 0;
         END IF;
      EXIT WHEN C_CLAMS%NOTFOUND;

         r_error_msg := 'MBR ' || p_member_id || ' FSHY CLM ' || C_CLAMS_VAL.CLAM_ID
                               || ' SEQNO ' || TO_CHAR(C_CLAMS_VAL.CLAM_SEQUENCE_NO);
         SP_DEBUG_PROC(SYSDATE, 'SPCC', r_error_msg);

         -- For each CLAM found, if any, check ENCOUNTER_AUDIT to see if previously submitted.
         -- If not previously submitted, then populate ENC_CASLTY_RESPONSE table.

         SELECT  COUNT(1) INTO v_ea_count
         FROM    ENCOUNTER_AUDIT EA
         WHERE  (EA.CLAM_ID =  C_CLAMS_VAL.CLAM_ID OR
                 EA.CLAM_ID_BASE = SUBSTR(C_CLAMS_VAL.CLAM_ID,1,10)) AND
                 EA.CLAM_SEQUENCE_NUMBER = C_CLAMS_VAL.CLAM_SEQUENCE_NO;

         IF v_ea_count > 0 THEN

            IF v_ea_count > 1 THEN
               r_error_msg := 'MBR ' || p_member_id || ' MORE THAN ONE CLAM FOUND FOR CLAM_ID_BASE.';
               SP_DEBUG_PROC(SYSDATE, 'SPCC', r_error_msg);
            ELSE
               SELECT  CLAM_ID, CLAM_SEQUENCE_NUMBER INTO v_CLAM_id, v_CLAM_seq_no
               FROM    ENCOUNTER_AUDIT EA
               WHERE  (EA.CLAM_ID =  C_CLAMS_VAL.CLAM_ID OR
                       EA.CLAM_ID_BASE = SUBSTR(C_CLAMS_VAL.CLAM_ID,
                                                 1,LENGTH(C_CLAMS_VAL.CLAM_ID) - 2 )) AND
                       EA.CLAM_SEQUENCE_NUMBER = C_CLAMS_VAL.CLAM_SEQUENCE_NO;

               r_error_msg := 'MBR ' || p_member_id || ' EA CLM ' || v_CLAM_id
                                     || ' SEQNO ' || TO_CHAR(v_CLAM_seq_no);
               SP_DEBUG_PROC(SYSDATE, 'SPCC', r_error_msg);

               r_error_msg := 'MBR ' || p_member_id || ' FC AND EA PRESENT, DISREGARD.';
               SP_DEBUG_PROC(SYSDATE, 'SPCC', r_error_msg);
            END IF;

         ELSE

            r_error_msg := 'MBR ' || p_member_id || ' FC PRESENT, NO EA - WRITE RESPONSE.';
            SP_DEBUG_PROC(SYSDATE, 'SPCC', r_error_msg);

            -- Obtain detail and write response record for CLAM present.
            INSERT  INTO ENC_CASLTY_RESPONSE
            VALUES (TO_CHAR(C_CLAMS_VAL.BILL_TYPE),
                    NVL(TO_CHAR(C_CLAMS_VAL.PAID_DATE,'YYYYMMDD'), '        '),
                    RPAD(C_CLAMS_VAL.CLAM_ID || LPAD(C_CLAMS_VAL.CLAM_SEQUENCE_NO,3,0),20,' '),
                    '3',
                    SUBSTR(p_member_medicaid_id,1,9),
                    C_CLAMS_VAL.PPID_NO,
                    NVL(TO_CHAR(C_CLAMS_VAL.SERVICE_FROM_DATE,'YYYYMMDD'), '        '),
                    NVL(TO_CHAR(C_CLAMS_VAL.SERVICE_THROUGH_DATE,'YYYYMMDD'), '        '),
                    NVL(RPAD(SUBSTR(C_CLAMS_VAL.PROCEDURE_CODE,1,6),6,' '), '      '),
                    NVL(RPAD(C_CLAMS_VAL.HCPCS_MODIFIERS,2,' '), '  '),
                    NVL(RPAD(C_CLAMS_VAL.NDC,11,' '), '           '),
					NVL(RPAD(C_CLAMS_VAL.DIAG1,7,' '), '0000000'),
					NVL(RPAD(C_CLAMS_VAL.DIAG2,7,' '), '0000000'),
                    REPLACE(LTRIM(TO_CHAR(C_CLAMS_VAL.PAID_AMOUNT, '00000000D00')), '.', ''),
                    REPLACE(LTRIM(TO_CHAR(C_CLAMS_VAL.BILL_AMOUNT, '00000000D00')), '.', ''),
                    NVL(RPAD(C_CLAMS_VAL.CAP_FFS_INDICATOR,1,' '), ' '));

         END IF;

      END LOOP;
      CLOSE C_CLAMS;

      IF v_rec_count = 0 THEN
         r_error_msg := 'MBR ' || p_member_id || ' NO FC, NO EA - WRITE RESPONSE.';
         SP_DEBUG_PROC(SYSDATE, 'SPCC', r_error_msg);

         -- Write response record for no CLAM and CIS number unknown.
         INSERT  INTO ENC_CASLTY_RESPONSE
         VALUES ('0',
                 '        ',
                 '00000000000000000000',
                 ' ',
                 SUBSTR(p_member_medicaid_id,1,9),
                 '             ',
                 '        ',
                 '        ',
                 '      ',
                 '  ',
                 '           ',
                 '       ',
                 '       ',
                 '          ',
                 '          ',
                 ' ');
      END IF;
      COMMIT;

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         r_error_flag := 'N';
         r_error_msg  := 'NO_DATA_FOUND ' || 'MBR: ' || p_member_id;
         SP_DEBUG_PROC(SYSDATE, 'SPCC', r_error_msg);
      WHEN OTHERS
      THEN
         ROLLBACK;
         r_error_msg :=
            'Error Code = '
            || SQLCODE
            || ' and Error Message = '
            || SUBSTR (SQLERRM, 1, 125)
            || ' Error '
            || r_error_msg;

            SP_DEBUG_PROC(SYSDATE, 'SPCR', r_error_msg);

   END SP_CHECK_EA_CLAMS;

------------------------------------------------------------------------------------------

   PROCEDURE SP_DEBUG_PROC (
      p_date           IN DATE,
      p_procedure_name IN VARCHAR2,
      p_log_message    IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN

      INSERT INTO ENC_CASLTY_ERROR
                 (DATE_TIMESTAMP, PROCEDURE_NAME, ERROR_MESSAGE)
          VALUES (p_date, p_procedure_name, p_log_message);
      COMMIT;

   END SP_DEBUG_PROC;

------------------------------------------------------------------------------------------

   PROCEDURE debug_log(
      p_log_message IN VARCHAR2)
   IS
      tmp_build_id   NUMBER := -1;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      IF (gv_debug = 1)
      THEN
         IF (gv_build_id IS NOT NULL)
         THEN
            tmp_build_id := gv_build_id;
         END IF;

         INSERT INTO ENCOUNTER_DEBUG_LOG
                     (build_id, status_date, MESSAGE)
              VALUES (tmp_build_id, SYSDATE, p_log_message);
         COMMIT;
      END IF;
   END debug_log;

------------------------------------------------------------------------------------------

   PROCEDURE SP_CREATE_GEN_FILE(
      p_out_error_flag   OUT   VARCHAR2,
      p_out_error_msg    OUT   VARCHAR2,
      p_passed_query           VARCHAR2 DEFAULT NULL,
      p_filename               VARCHAR2 DEFAULT NULL,
      p_stamp                  NUMBER   DEFAULT NULL,
      p_delim                  VARCHAR2 DEFAULT NULL,
      p_column_names           NUMBER   DEFAULT 0)
   IS
      /*******************************************************************************
      ' PROCEDURE: SP_CREATE_GEN_FILE
      ' ------------------------------------------------------------------------------
      ' PURPOSE..: Creates '|' delimited sequential file containing from the passed query.
      ' DESCRIPT.: Used to create the encounters EDI files. Can take a valid query or
      '         valid table_name in first parameter. A table name will deliver a "select *"
      '         on that table.
      ' .........:
      ' ------------------------------------------------------------------------------
      ' INPUT....: p_passed_query   Valid output SQL statement
      '            p_filename       Output filename
      '            p_stamp          Flag to datestamp output filename (non null means stamp)
      '            p_delim          Passed delimiter character (defaults to |)
      '            p_column_names   Flag for placing column names in first row of file
      '                             (0 means no column names)
      ' OUTPUT...: p_out_error_flag
      '            p_out_error_msg
      *******************************************************************************/
      v_sql_error_code   NUMBER;
      v_sql_error_msg    VARCHAR2 (4000)    := NULL;
      v_output_dir       VARCHAR2 (255);
      v_output_ext       VARCHAR2 (4)       := '.dat';
      v_open_type        VARCHAR2 (1)       := 'W';
      v_column_names     NUMBER;
      v_delim            VARCHAR2 (1)       := '';
      v_table_name       VARCHAR2 (80)      := 'dual';
      v_file_name        VARCHAR2 (80)      := 'file';
      v_file_path        VARCHAR2 (80);
      v_file             UTL_FILE.FILE_TYPE;
      v_data_flag        NUMBER             := 0;
      v_select           VARCHAR2 (8)       := 'select ';
      v_hint             VARCHAR2 (1000)    := '';
      v_distinct         VARCHAR2 (9)       := '';
      v_from             VARCHAR2 (8000)    := '';
      v_first_data_row   NUMBER             := 1;
      v_counter          NUMBER;
      v_report_stamp     DATE;
      v_report_start     DATE;
      v_report_end       DATE;
      v_cursor           INTEGER            DEFAULT DBMS_SQL.OPEN_CURSOR;
      v_desc             DBMS_SQL.DESC_TAB;
      v_desc2            DBMS_SQL.DESC_TAB;
      v_column_value     VARCHAR2 (32767);
      v_status           INTEGER;
      v_col_cnt          NUMBER             DEFAULT 0;
      v_col_cnt2         NUMBER             DEFAULT 0;
      v_separator        VARCHAR2 (10)      DEFAULT '';
      v_query            VARCHAR2 (32767)   := 'select * from ';
   BEGIN
      --debug_log (p_filename);

      -- Full Query or Table Query and determine output filename
      IF TRIM (p_passed_query) IS NOT NULL
      THEN
         IF INSTR (TRIM (p_passed_query), ' ') > 0
         THEN
            v_query := p_passed_query;

            IF TRIM (p_filename) IS NOT NULL
            THEN
               IF p_stamp IS NOT NULL
               THEN
                  v_file_name :=
                        p_filename
                     || TO_CHAR (SYSDATE, '_MMDDYYYY_HH24MISS')
                     || v_output_ext;
               ELSE
                  IF INSTR (p_filename, '.') = 0
                  THEN
                     v_file_name := p_filename || v_output_ext;
                  ELSE
                     v_file_name := p_filename;
                  END IF;
               END IF;
            ELSE
               IF p_stamp IS NOT NULL
               THEN
                  v_file_name :=
                        v_file_name
                     || TO_CHAR (SYSDATE, '_MMDDYYYY_HH24MISS')
                     || v_output_ext;
               ELSE
                  v_file_name := v_file_name || v_output_ext;
               END IF;
            END IF;
         ELSE
            v_query := v_query || p_passed_query;

            IF TRIM (p_filename) IS NOT NULL
            THEN
               IF p_stamp IS NOT NULL
               THEN
                  v_file_name :=
                        p_filename
                     || TO_CHAR (SYSDATE, '_MMDDYYYY_HH24MISS')
                     || v_output_ext;
               ELSE
                  IF INSTR (p_filename, '.') = 0
                  THEN
                     v_file_name := p_filename || v_output_ext;
                  ELSE
                     v_file_name := p_filename;
                  END IF;
               END IF;
            ELSE
               IF p_stamp IS NOT NULL
               THEN
                  v_file_name :=
                        v_file_name
                     || '_'
                     || p_passed_query
                     || TO_CHAR (SYSDATE, '_MMDDYYYY_HH24MISS')
                     || v_output_ext;
               ELSE
                  v_file_name :=
                         v_file_name || '_' || p_passed_query || v_output_ext;
               END IF;
            END IF;
         END IF;
      END IF;

      IF LENGTH (p_delim) = 1
      THEN
         v_delim := p_delim;
      END IF;

      v_column_names := p_column_names;
      v_hint :=
         SUBSTR (v_query,
                 INSTR (v_query, '/*'),
                 INSTR (v_query, '*/', -1) - INSTR (v_query, '/*')
                );

      IF LENGTH (v_hint) > 0
      THEN
         v_hint := v_hint || '*/';
      END IF;

      IF (INSTR (UPPER (v_query), 'DISTINCT') > 0)
      THEN
         v_distinct := 'distinct ';
      END IF;

      v_from := SUBSTR (v_query, INSTR (v_query, 'from'));
      DBMS_SQL.PARSE (v_cursor, v_query, DBMS_SQL.native);
      DBMS_SQL.DESCRIBE_COLUMNS (v_cursor, v_col_cnt, v_desc);
      v_query := v_select || v_hint || v_distinct;
      v_separator := '';

      FOR i IN 1 .. v_col_cnt
      LOOP
         v_query := v_query || v_separator || v_desc (i).col_name;
         v_separator := '||''' || v_delim || '''||';
      END LOOP;

      v_query := v_query || ' as output_line ' || v_from;
      DBMS_SQL.PARSE (v_cursor, v_query, DBMS_SQL.native);
      DBMS_SQL.DESCRIBE_COLUMNS (v_cursor, v_col_cnt2, v_desc2);

      FOR i IN 1 .. v_col_cnt2
      LOOP
         DBMS_SQL.DEFINE_COLUMN (v_cursor, i, v_column_value, 32767);
      END LOOP;

      v_status := DBMS_SQL.EXECUTE (v_cursor);

      -- Open the file
      SELECT directory_path
        INTO v_file_path
        FROM all_directories
       WHERE directory_name = 'DATA_DIR';

      v_file := UTL_FILE.FOPEN (v_file_path, v_file_name, v_open_type, 32767);

      -- Write column names in the first row
      IF v_column_names <> 0
      THEN
         v_separator := '';
         v_query := '';

         FOR i IN 1 .. v_col_cnt
         LOOP
            v_query := v_query || v_separator || v_desc (i).col_name;
            v_separator := v_delim;
         END LOOP;

         UTL_FILE.PUT_LINE (v_file, v_query);
      END IF;

      -- Write the table data to the file
      LOOP
         EXIT WHEN (DBMS_SQL.FETCH_ROWS (v_cursor) <= 0);
         v_data_flag := 1;

         FOR i IN 1 .. v_col_cnt2
         LOOP
            DBMS_SQL.COLUMN_VALUE (v_cursor, i, v_column_value);
            UTL_FILE.PUT_LINE (v_file, v_column_value);
         END LOOP;
      END LOOP;

      DBMS_SQL.CLOSE_CURSOR (v_cursor);
      UTL_FILE.FCLOSE (v_file);
   EXCEPTION
      WHEN UTL_FILE.INTERNAL_ERROR
      THEN
         ROLLBACK;
         p_out_error_flag := 'Y';
         p_out_error_msg :=
               'UTL_FILE INTERNAL ERROR in Procedure SP_CREATE_GEN_FILE '
            || ' where Error Code = '
            || SQLCODE
            || ' and Error Message = '
            || SQLERRM;

         INSERT INTO ENCOUNTER_BUILD_ERROR
                     (procedure_name, date_timestamp, error_message
                     )
              VALUES ('SP_CREATE_GEN_FILE', SYSDATE, p_out_error_msg
                     );

         COMMIT;
      WHEN UTL_FILE.INVALID_FILEHANDLE
      THEN
         p_out_error_flag := 'Y';
         p_out_error_msg :=
               'UTL_FILE INVALID FILEHANDLE in Procedure SP_CREATE_GEN_FILE '
            || ' where Error Code = '
            || SQLCODE
            || ' and Error Message = '
            || SQLERRM;
         RAISE;
      WHEN UTL_FILE.INVALID_MODE
      THEN
         p_out_error_flag := 'Y';
         p_out_error_msg :=
               'UTL_FILE INVALID MODE in Procedure SP_CREATE_GEN_FILE '
            || ' where Error Code = '
            || SQLCODE
            || ' and Error Message = '
            || SQLERRM;

         INSERT INTO ENCOUNTER_BUILD_ERROR
                     (procedure_name, date_timestamp, error_message
                     )
              VALUES ('SP_CREATE_GEN_FILE', SYSDATE, p_out_error_msg
                     );

         COMMIT;
      WHEN UTL_FILE.INVALID_OPERATION
      THEN
         p_out_error_flag := 'Y';
         p_out_error_msg :=
               'UTL_FILE INVALID OPERATION in Procedure SP_CREATE_GEN_FILE '
            || ' where Error Code = '
            || SQLCODE
            || ' and Error Message = '
            || SQLERRM;

         INSERT INTO ENCOUNTER_BUILD_ERROR
                     (procedure_name, date_timestamp, error_message
                     )
              VALUES ('SP_CREATE_GEN_FILE', SYSDATE, p_out_error_msg
                     );

         COMMIT;
      WHEN UTL_FILE.INVALID_PATH
      THEN
         p_out_error_flag := 'Y';
         p_out_error_msg :=
               'UTL_FILE INVALID PATH Error in Procedure SP_CREATE_GEN_FILE '
            || ' where Error Code = '
            || SQLCODE
            || ' and Error Message = '
            || SQLERRM;

         INSERT INTO ENCOUNTER_BUILD_ERROR
                     (procedure_name, date_timestamp, error_message
                     )
              VALUES ('SP_CREATE_GEN_FILE', SYSDATE, p_out_error_msg
                     );

         COMMIT;
      WHEN UTL_FILE.WRITE_ERROR
      THEN
         p_out_error_flag := 'Y';
         p_out_error_msg :=
               'UTL_FILE WRITE ERROR Error in Procedure SP_CREATE_GEN_FILE '
            || ' where Error Code = '
            || SQLCODE
            || ' and Error Message = '
            || SQLERRM;

         INSERT INTO ENCOUNTER_BUILD_ERROR
                     (procedure_name, date_timestamp, error_message
                     )
              VALUES ('SP_CREATE_GEN_FILE', SYSDATE, p_out_error_msg
                     );

         COMMIT;
      WHEN OTHERS
      THEN
         UTL_FILE.FCLOSE (v_file);
         p_out_error_flag := 'Y';
         p_out_error_msg :=
               ' Error in Procedure SP_CREATE_GEN_FILE '
            || ' where Error Code = '
            || SQLCODE
            || ' and Error Message = '
            || SQLERRM;

         INSERT INTO ENCOUNTER_BUILD_ERROR
                     (procedure_name, date_timestamp, error_message
                     )
              VALUES ('SP_CREATE_GEN_FILE', SYSDATE, p_out_error_msg
                     );

         COMMIT;
   END SP_CREATE_GEN_FILE;

------------------------------------------------------------------------------------------

END;
/