create table wksp_frongpmstdev.xxgpms_project_contract (
    project_id               number(18, 0) not null enable,
    project_number           varchar2(25 byte),
    contract_number          varchar2(100 byte),
    bu_name                  varchar2(50 byte),
    currency_code            varchar2(50 byte),
    contract_type_name       varchar2(100 byte),
    session_id               number,
    organization_name        varchar2(100 byte),
    project_name             varchar2(100 byte),
    legal_entity_name        varchar2(150 byte),
    contract_id              number,
    customer_name            varchar2(1000 byte),
    retainer_balance         number,
    business_unit_id         number,
    user_transaction_source  varchar2(100 byte),
    transaction_source_id    number,
    trust_balance            number,
    creation_date            date,
    created_by               varchar2(100 byte),
    last_update_date         date,
    last_updated_by          varchar2(100 byte),
    contract_type_id         number,
    ebill_matter_id          varchar2(100 byte),
    tax_registration_type    varchar2(100 byte),
    tax_registration_number  varchar2(100 byte),
    tax_registration_country varchar2(500 byte),
    contract_office          varchar2(200 byte),
    bill_customer_name       varchar2(1000 byte),
    bill_customer_acct       varchar2(1000 byte),
    bill_customer_site       varchar2(1000 byte),
    client_number            varchar2(1000 byte)
);


-- sqlcl_snapshot {"hash":"10aa7610fd8a3de2d6f878ffbc6c7f9564d14d2b","type":"TABLE","name":"XXGPMS_PROJECT_CONTRACT","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<TABLE  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>XXGPMS_PROJECT_CONTRACT</NAME><RELATIONAL_TABLE><COL_LIST><COL_LIST_ITEM><NAME>PROJECT_ID</NAME><DATATYPE>NUMBER</DATATYPE><PRECISION>18</PRECISION><SCALE>0</SCALE><NOT_NULL></NOT_NULL></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJECT_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>25</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CONTRACT_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BU_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>50</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CURRENCY_CODE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>50</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CONTRACT_TYPE_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>SESSION_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ORGANIZATION_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJECT_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>LEGAL_ENTITY_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>150</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CONTRACT_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CUSTOMER_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>RETAINER_BALANCE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BUSINESS_UNIT_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>USER_TRANSACTION_SOURCE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TRANSACTION_SOURCE_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TRUST_BALANCE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CREATION_DATE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CREATED_BY</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>LAST_UPDATE_DATE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>LAST_UPDATED_BY</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CONTRACT_TYPE_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EBILL_MATTER_ID</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TAX_REGISTRATION_TYPE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TAX_REGISTRATION_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TAX_REGISTRATION_COUNTRY</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>500</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CONTRACT_OFFICE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>200</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BILL_CUSTOMER_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BILL_CUSTOMER_ACCT</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BILL_CUSTOMER_SITE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CLIENT_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM></COL_LIST><DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION><PHYSICAL_PROPERTIES><HEAP_TABLE></HEAP_TABLE></PHYSICAL_PROPERTIES></RELATIONAL_TABLE></TABLE>"}