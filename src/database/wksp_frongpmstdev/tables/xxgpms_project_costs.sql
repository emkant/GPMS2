create table wksp_frongpmstdev.xxgpms_project_costs (
    project_id                  number(18, 0),
    project_number              varchar2(25 byte),
    billable_flag               varchar2(20 byte),
    task_id                     number(18, 0),
    task_number                 varchar2(25 byte),
    project_status_code         varchar2(25 byte),
    project_name                varchar2(100 byte),
    expenditure_item_id         number(18, 0),
    expenditure_item_date       date,
    revenue_recognized_flag     varchar2(20 byte),
    bill_hold_flag              varchar2(20 byte),
    quantity                    number,
    projfunc_raw_cost           number,
    raw_cost_rate               number,
    projfunc_burdened_cost      number,
    burden_cost_rate            number,
    invoiced_flag               varchar2(10 byte),
    revenue_hold_flag           varchar2(10 byte),
    acct_currency_code          varchar2(10 byte),
    acct_raw_cost               number,
    acct_burdened_cost          number,
    task_billable_flag          varchar2(10 byte),
    task_start_date             date,
    task_completion_date        date,
    project_start_date          date,
    task_name                   varchar2(250 byte),
    session_id                  number,
    external_bill_rate          number,
    internal_comment            varchar2(1000 byte),
    narrative_billing_overflow  varchar2(1000 byte),
    total_amount                number(18, 2),
    expenditure_comment         varchar2(2000 byte),
    unit_of_measure             varchar2(30 byte),
    first_name                  varchar2(100 byte),
    last_name                   varchar2(100 byte),
    person_name                 varchar2(200 byte),
    expenditure_type_name       varchar2(240 byte),
    expenditure_category_name   varchar2(240 byte),
    project_bill_rate_attr      varchar2(24 byte),
    realized_bill_rate_attr     varchar2(100 byte),
    standard_bill_rate_attr     varchar2(24 byte),
    event_attr                  varchar2(100 byte),
    project_bill_rate_amt       number,
    realized_bill_rate_amt      number,
    standard_bill_rate_amt      number,
    bu_name                     varchar2(50 byte),
    bu_id                       number,
    job_name                    varchar2(50 byte),
    job_id                      number,
    system_linkage_function     varchar2(10 byte),
    cst_invoice_submitted_count number,
    orig_transaction_reference  varchar2(100 byte),
    document_name               varchar2(100 byte),
    doc_entry_name              varchar2(100 byte),
    creation_date               date,
    created_by                  varchar2(100 byte),
    last_update_date            date,
    last_updated_by             varchar2(100 byte),
    contract_number             varchar2(100 byte),
    line_number                 varchar2(500 byte),
    billing_instructions        varchar2(2000 byte),
    draft_invoice_number        number,
    invoice_status_code         varchar2(30 byte),
    transfer_status_code        varchar2(30 byte),
    nlr_org_id                  varchar2(1000 byte),
    wip_category                varchar2(1000 byte),
    non_labour_resource_name    varchar2(2000 byte),
    project_currency_code       varchar2(200 byte),
    write_up_down_value         varchar2(1000 byte),
    incurred_by_person_id       number,
    job_approval_id             number,
    top_task_number             varchar2(100 byte),
    description                 varchar2(4000 byte),
    bill_set_num                number,
    contract_line_num           varchar2(100 byte),
    exp_bu_id                   number,
    exp_org_id                  number,
    dept_name                   varchar2(1000 byte),
    transaction_source          varchar2(1000 byte),
    document_id                 number,
    transaction_source_id       number
);

alter table wksp_frongpmstdev.xxgpms_project_costs
    add constraint xxgpms_project_costs_con primary key ( expenditure_item_id,
                                                          session_id ) disable;


-- sqlcl_snapshot {"hash":"98519d1895ce7c24534b7ca931c8b0898c7f9824","type":"TABLE","name":"XXGPMS_PROJECT_COSTS","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<TABLE  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>XXGPMS_PROJECT_COSTS</NAME><RELATIONAL_TABLE><COL_LIST><COL_LIST_ITEM><NAME>PROJECT_ID</NAME><DATATYPE>NUMBER</DATATYPE><PRECISION>18</PRECISION><SCALE>0</SCALE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJECT_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>25</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BILLABLE_FLAG</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>20</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TASK_ID</NAME><DATATYPE>NUMBER</DATATYPE><PRECISION>18</PRECISION><SCALE>0</SCALE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TASK_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>25</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJECT_STATUS_CODE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>25</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJECT_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_ITEM_ID</NAME><DATATYPE>NUMBER</DATATYPE><PRECISION>18</PRECISION><SCALE>0</SCALE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_ITEM_DATE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>REVENUE_RECOGNIZED_FLAG</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>20</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BILL_HOLD_FLAG</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>20</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>QUANTITY</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJFUNC_RAW_COST</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>RAW_COST_RATE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJFUNC_BURDENED_COST</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BURDEN_COST_RATE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>INVOICED_FLAG</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>10</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>REVENUE_HOLD_FLAG</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>10</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ACCT_CURRENCY_CODE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>10</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ACCT_RAW_COST</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ACCT_BURDENED_COST</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TASK_BILLABLE_FLAG</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>10</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TASK_START_DATE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TASK_COMPLETION_DATE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJECT_START_DATE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TASK_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>250</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>SESSION_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXTERNAL_BILL_RATE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>INTERNAL_COMMENT</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>NARRATIVE_BILLING_OVERFLOW</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TOTAL_AMOUNT</NAME><DATATYPE>NUMBER</DATATYPE><PRECISION>18</PRECISION><SCALE>2</SCALE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_COMMENT</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>2000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>UNIT_OF_MEASURE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>30</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>FIRST_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>LAST_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PERSON_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>200</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_TYPE_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>240</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_CATEGORY_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>240</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJECT_BILL_RATE_ATTR</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>24</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>REALIZED_BILL_RATE_ATTR</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>STANDARD_BILL_RATE_ATTR</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>24</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EVENT_ATTR</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJECT_BILL_RATE_AMT</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>REALIZED_BILL_RATE_AMT</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>STANDARD_BILL_RATE_AMT</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BU_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>50</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BU_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>JOB_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>50</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>JOB_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>SYSTEM_LINKAGE_FUNCTION</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>10</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CST_INVOICE_SUBMITTED_COUNT</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ORIG_TRANSACTION_REFERENCE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>DOCUMENT_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>DOC_ENTRY_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CREATION_DATE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CREATED_BY</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>LAST_UPDATE_DATE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>LAST_UPDATED_BY</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CONTRACT_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>LINE_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>500</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BILLING_INSTRUCTIONS</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>2000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>DRAFT_INVOICE_NUMBER</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>INVOICE_STATUS_CODE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>30</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TRANSFER_STATUS_CODE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>30</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>NLR_ORG_ID</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>WIP_CATEGORY</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>NON_LABOUR_RESOURCE_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>2000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJECT_CURRENCY_CODE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>200</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>WRITE_UP_DOWN_VALUE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>INCURRED_BY_PERSON_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>JOB_APPROVAL_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TOP_TASK_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>DESCRIPTION</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>4000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>BILL_SET_NUM</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CONTRACT_LINE_NUM</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXP_BU_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXP_ORG_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>DEPT_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TRANSACTION_SOURCE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>DOCUMENT_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TRANSACTION_SOURCE_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM></COL_LIST><PRIMARY_KEY_CONSTRAINT_LIST><PRIMARY_KEY_CONSTRAINT_LIST_ITEM><NAME>XXGPMS_PROJECT_COSTS_CON</NAME><COL_LIST><COL_LIST_ITEM><NAME>EXPENDITURE_ITEM_ID</NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>SESSION_ID</NAME></COL_LIST_ITEM></COL_LIST><DISABLE></DISABLE><NOVALIDATE></NOVALIDATE></PRIMARY_KEY_CONSTRAINT_LIST_ITEM></PRIMARY_KEY_CONSTRAINT_LIST><DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION><PHYSICAL_PROPERTIES><HEAP_TABLE></HEAP_TABLE></PHYSICAL_PROPERTIES></RELATIONAL_TABLE></TABLE>"}