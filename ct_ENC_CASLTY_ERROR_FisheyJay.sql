-------------------------------------------------------------------------
-- Author:    John Fisher
-- Name:      ENC_CASLTY_ERROR
-- Date:      int. blank
-- Purpose:   Create table to store Errors
-------------------------------------------------------------------------

CREATE TABLE ENC_CASLTY_ERROR
(
  DATE_TIMESTAMP             DATE              NULL,
  PROCEDURE_NAME             VARCHAR2(150)     NULL,
  ERROR_MESSAGE              VARCHAR2(2000)    NULL
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