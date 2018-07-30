-------------------------------------------------------------------------
-- Author:    Another developer wrote this piece here.
-------------------------------------------------------------------------

CREATE TABLE ENC_CASLTY_REQUEST
(
  MEMBER_MAID           VARCHAR2(15 BYTE)       NOT NULL,
  INCIDENT_DATE         DATE,
  SERVICE_FROM_DATE     DATE,
  SERVICE_THROUGH_DATE  DATE,
  REQUEST_TYPE          VARCHAR2(2 BYTE),
  SENT_COUNT            NUMBER(9),
  MEMBER_ID             VARCHAR2(15 BYTE)
)
TABLESPACE MHP
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

CREATE UNIQUE INDEX ENC_CASLTY_REQUEST_PK ON ENC_CASLTY_REQUEST
(MEMBER_MAID)
LOGGING
TABLESPACE MHP
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          512K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       2147483645
            PCTINCREASE      0
            FREELISTS        1
            FREELIST GROUPS  1
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

ALTER TABLE ENC_CASLTY_REQUEST ADD (
  CONSTRAINT ENC_CASLTY_REQUEST_PK
 PRIMARY KEY
 (MEMBER_MAID)
    USING INDEX 
    TABLESPACE MHP
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          512K
                NEXT             1M
                MINEXTENTS       1
                MAXEXTENTS       2147483645
                PCTINCREASE      0
                FREELISTS        1
                FREELIST GROUPS  1
               ));
               
-------------------------------------------

CREATE TABLE ENC_CASLTY_REQUEST_HIST
(
  MEMBER_MAID           VARCHAR2(15 BYTE)       NOT NULL,
  INCIDENT_DATE         DATE,
  SERVICE_FROM_DATE     DATE,
  SERVICE_THROUGH_DATE  DATE,
  REQUEST_TYPE          VARCHAR2(2 BYTE),
  SENT_COUNT            NUMBER(9),
  MEMBER_ID             VARCHAR2(15 BYTE)
)
TABLESPACE MHP
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