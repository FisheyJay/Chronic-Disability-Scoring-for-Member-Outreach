-------------------------------------------------------------------------
-- Author:    John Fisher
-- Name:      ENC_CASLTY_FILE_TRACKING
-- Date:      int. blank
-- Purpose:   Create table to store data pertaining to file tracking
-------------------------------------------------------------------------

CREATE TABLE ENC_CASLTY_FILE_TRACKING
(
  SEND_FILE_NAME        VARCHAR2(50)      NULL,
  DATE_SENT             DATE              NULL,
  ACK_FILE_NAME         VARCHAR2(50)      NULL,
  DATE_RECEIVED         DATE              NULL,
  STATUS                CHAR(1)           NULL  
)
TABLESPACE JPF
PCTUSED    40
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          1M
            NEXT             512K
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            FREELISTS        1
            FREELIST GROUPS  1
            BUFFER_POOL      DEFAULT
           )
NOLOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
NOMONITORING;