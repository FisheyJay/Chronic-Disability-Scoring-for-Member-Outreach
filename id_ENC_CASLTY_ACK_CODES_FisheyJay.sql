-------------------------------------------------------------------------
-- Author:    John Fisher
-- Date:      int. blank
-- Purpose:   Load the codes
-------------------------------------------------------------------------

INSERT INTO ENC_CASLTY_ACK_CODES ( ERROR_CODE,
ERROR_CODE_DESC ) VALUES ( 
'I', 'File Name Length was Incorrect.');

INSERT INTO ENC_CASLTY_ACK_CODES ( ERROR_CODE,
ERROR_CODE_DESC ) VALUES ( 
'Z', 'File Size was Zero Bytes.'); 

INSERT INTO ENC_CASLTY_ACK_CODES ( ERROR_CODE,
ERROR_CODE_DESC ) VALUES ( 
'F', 'File Name had a Future Date.'); 

INSERT INTO ENC_CASLTY_ACK_CODES ( ERROR_CODE,
ERROR_CODE_DESC ) VALUES ( 
'L', 'Record Length was Incorrect in one or more Records.'); 

INSERT INTO ENC_CASLTY_ACK_CODES ( ERROR_CODE,
ERROR_CODE_DESC ) VALUES ( 
'W', 'Some of the Records in the File were Written to the Error Table.'); 

INSERT INTO ENC_CASLTY_ACK_CODES ( ERROR_CODE,
ERROR_CODE_DESC ) VALUES ( 
'A', 'The Entire File has been Accepted.');  

COMMIT;