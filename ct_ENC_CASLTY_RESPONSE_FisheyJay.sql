-------------------------------------------------------------------------
-- Author:    John Fisher
-- Date:      int. blank
-- Purpose:   Create table to store responses and response history
-------------------------------------------------------------------------

CREATE TABLE ENC_CASLTY_RESPONSE
(
  REC_TYPE                    CHAR(1 BYTE),
  PAID_DATE                   CHAR(8 BYTE),
  ORIG_CRN                    CHAR(20 BYTE),
  ORIG_CRN_LINE_NO            CHAR(1 BYTE),
  MEMBER_MAID                 CHAR(9 BYTE),
  PPID_NO                     CHAR(13 BYTE),
  SERVICE_FROM_DATE           CHAR(8 BYTE),
  SERVICE_THROUGH_DATE        CHAR(8 BYTE),
  PROCEDURE_CODE              CHAR(6 BYTE),
  HCPCS_MODIFIERS             CHAR(2 BYTE),
  NDC                         CHAR(11 BYTE),
  PRINCIPLE_SURG_PROC_CODE    CHAR(7 BYTE),
  DIAG1                       CHAR(7 BYTE),
  PAID_AMOUNT                 CHAR(10 BYTE),
  BILL_AMOUNT                 CHAR(10 BYTE),
  CAP_FFS_INDICATOR           CHAR(1 BYTE)
)
TABLESPACE JPF
PCTUSED    40
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          512K
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

---------------------------------------

CREATE TABLE ENC_CASLTY_RESPONSE_HIST
(
  REC_TYPE                    CHAR(1 BYTE),
  PAID_DATE                   CHAR(8 BYTE),
  ORIG_CRN                    CHAR(20 BYTE),
  ORIG_CRN_LINE_NO            CHAR(1 BYTE),
  MEMBER_MAID                 CHAR(9 BYTE),
  PPID_NO                     CHAR(13 BYTE),
  SERVICE_FROM_DATE           CHAR(8 BYTE),
  SERVICE_THROUGH_DATE        CHAR(8 BYTE),
  PROCEDURE_CODE              CHAR(6 BYTE),
  HCPCS_MODIFIERS             CHAR(2 BYTE),
  NDC                         CHAR(11 BYTE),
  PRINCIPLE_SURG_PROC_CODE    CHAR(7 BYTE),
  DIAG1                       CHAR(7 BYTE),
  PAID_AMOUNT                 CHAR(10 BYTE),
  BILL_AMOUNT                 CHAR(10 BYTE),
  CAP_FFS_INDICATOR           CHAR(1 BYTE)
)
TABLESPACE JPF
PCTUSED    40
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          512K
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