-------------------------------------------------------------------------
-- Author:    John Fisher
-- Date:      int. blank
-- Name:      ICN_FLAGGING_XREF
-------------------------------------------------------------------------

CREATE TABLE ICN_FLAGGING_XREF
(
MCO_CRN                     VARCHAR2(20)     NULL,
PROMISE_ICN                 VARCHAR2(13)     NULL
)
TABLESPACE JPF
PCTUSED    40
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          1M
            NEXT             1M
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

CREATE PUBLIC SYNONYM ICN_FLAGGING_XREF FOR JPF.ICN_FLAGGING_XREF;

GRANT DELETE, INSERT, SELECT, UPDATE ON ICN_FLAGGING_XREF TO FISHEY_MAIN;
GRANT SELECT ON ICN_FLAGGING_XREF TO FISHEY_READ;
GRANT DELETE, INSERT, SELECT, UPDATE ON ICN_FLAGGING_XREF TO FISHEY_OPER;

CREATE UNIQUE INDEX ICN_FLAGGING_XREF_PK ON ICN_FLAGGING_XREF
(MCO_CRN, PROMISE_ICN)
LOGGING
TABLESPACE JPF
PCTFREE    10
INITRANS   2
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
NOPARALLEL;