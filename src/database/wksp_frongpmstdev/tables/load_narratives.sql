create table wksp_frongpmstdev.load_narratives (
    id                    number
        generated by default on null as identity minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 start with 1 cache 20
        noorder nocycle nokeep noscale
    not null enable,
    expenditure_item_id   number,
    invoice_narrative     varchar2(255 byte),
    internal_comments     varchar2(32767 byte),
    expenditure_item_date date,
    person_name           varchar2(100 byte),
    title                 varchar2(100 byte),
    quantity              number,
    uom                   varchar2(50 byte),
    billable              varchar2(1 byte),
    standard_rate         number,
    standard_amount       number,
    agreement_rate        number,
    agreement_amount      number,
    real__rate            number,
    fee_allocation        number,
    billable_hold         varchar2(1 byte),
    currency              varchar2(50 byte),
    description           varchar2(32767 byte),
    inv_status            varchar2(1 byte),
    draft_status          varchar2(32767 byte),
    draft_invoice_number  varchar2(32767 byte)
);

alter table wksp_frongpmstdev.load_narratives add primary key ( id )
    using index enable;


-- sqlcl_snapshot {"hash":"b8990eb8e9bd207e510d049902db23dc653261b7","type":"TABLE","name":"LOAD_NARRATIVES","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<TABLE  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>LOAD_NARRATIVES</NAME><RELATIONAL_TABLE><COL_LIST><COL_LIST_ITEM><NAME>ID</NAME><DATATYPE>NUMBER</DATATYPE><IDENTITY_COLUMN><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><GENERATION>DEFAULT</GENERATION><ON_NULL></ON_NULL><START_WITH>2441</START_WITH><INCREMENT>1</INCREMENT><MINVALUE>1</MINVALUE><MAXVALUE>9999999999999999999999999999</MAXVALUE><CACHE>20</CACHE></IDENTITY_COLUMN><NOT_NULL></NOT_NULL></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_ITEM_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>INVOICE_NARRATIVE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>255</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>INTERNAL_COMMENTS</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>32767</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_ITEM_DATE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PERSON_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TITLE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>QUANTITY</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>UOM</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>50</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BILLABLE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>STANDARD_RATE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>STANDARD_AMOUNT</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>AGREEMENT_RATE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>AGREEMENT_AMOUNT</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>REAL__RATE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>FEE_ALLOCATION</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BILLABLE_HOLD</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CURRENCY</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>50</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>DESCRIPTION</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>32767</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>INV_STATUS</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>DRAFT_STATUS</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>32767</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>DRAFT_INVOICE_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>32767</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM></COL_LIST><PRIMARY_KEY_CONSTRAINT_LIST><PRIMARY_KEY_CONSTRAINT_LIST_ITEM><COL_LIST><COL_LIST_ITEM><NAME>ID</NAME></COL_LIST_ITEM></COL_LIST><USING_INDEX></USING_INDEX></PRIMARY_KEY_CONSTRAINT_LIST_ITEM></PRIMARY_KEY_CONSTRAINT_LIST><DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION><PHYSICAL_PROPERTIES><HEAP_TABLE></HEAP_TABLE></PHYSICAL_PROPERTIES></RELATIONAL_TABLE></TABLE>"}