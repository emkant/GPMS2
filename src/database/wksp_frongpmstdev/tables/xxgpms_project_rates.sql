create table wksp_frongpmstdev.xxgpms_project_rates (
    project_id                   varchar2(1000 byte),
    project_number               varchar2(1000 byte),
    task_id                      number,
    proj_element_id              number,
    carrying_out_organization_id number,
    attribute_number1            number,
    attribute_number2            number,
    attribute_number3            number,
    person_id                    number,
    start_date_active            date,
    incurred_by_person_id        number,
    end_date_active              date,
    rate_unit                    varchar2(1000 byte),
    rate                         number,
    rate_schedule_id             number,
    expenditure_type_id          number,
    person_job_id                number,
    raw_cost_rate                number,
    expenditure_item_date        date,
    markup_percentage            number,
    job_id                       number,
    standard_rate                number,
    agreement_rate               number,
    expenditure_item_id          number,
    session_id                   number,
    user_email                   varchar2(1000 byte),
    created_date                 timestamp(6)
);


-- sqlcl_snapshot {"hash":"96f6fb529400e1d80613dfb91a459239026e3044","type":"TABLE","name":"XXGPMS_PROJECT_RATES","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<TABLE  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>XXGPMS_PROJECT_RATES</NAME><RELATIONAL_TABLE><COL_LIST><COL_LIST_ITEM><NAME>PROJECT_ID</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJECT_NUMBER</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>TASK_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PROJ_ELEMENT_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CARRYING_OUT_ORGANIZATION_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ATTRIBUTE_NUMBER1</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ATTRIBUTE_NUMBER2</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ATTRIBUTE_NUMBER3</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PERSON_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>START_DATE_ACTIVE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>INCURRED_BY_PERSON_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>END_DATE_ACTIVE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>RATE_UNIT</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>RATE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>RATE_SCHEDULE_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_TYPE_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PERSON_JOB_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>RAW_COST_RATE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_ITEM_DATE</NAME><DATATYPE>DATE</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>MARKUP_PERCENTAGE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>JOB_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>STANDARD_RATE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>AGREEMENT_RATE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_ITEM_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>SESSION_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>USER_EMAIL</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>CREATED_DATE</NAME><DATATYPE>TIMESTAMP</DATATYPE><SCALE>6</SCALE></COL_LIST_ITEM></COL_LIST><DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION><PHYSICAL_PROPERTIES><HEAP_TABLE></HEAP_TABLE></PHYSICAL_PROPERTIES></RELATIONAL_TABLE></TABLE>"}