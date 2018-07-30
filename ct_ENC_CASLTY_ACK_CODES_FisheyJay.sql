-------------------------------------------------------------------------
-- Author:    John Fisher
-- Name:      ENC_CASLTY_ACK_CODES
-- Date:      int. blank
-- Purpose:   Create table to store Acknowledgement codes
-------------------------------------------------------------------------

CREATE TABLE ENC_CASLTY_ACK_CODES
(
  ERROR_CODE       VARCHAR2(1 BYTE)            NOT NULL,
  ERROR_CODE_DESC  VARCHAR2(125 BYTE)              NULL
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
NOCACHE
NOPARALLEL;