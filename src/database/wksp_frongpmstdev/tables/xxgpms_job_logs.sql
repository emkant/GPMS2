create table wksp_frongpmstdev.xxgpms_job_logs (
    job_name varchar2(100 char),
    start_ts timestamp(6) with local time zone,
    end_ts   timestamp(6) with local time zone,
    status   varchar2(100 char),
    error    clob
);


-- sqlcl_snapshot {"hash":"99e96cd863670b9b38a734a87698558a6ba6aa94","type":"TABLE","name":"XXGPMS_JOB_LOGS","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<TABLE  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>XXGPMS_JOB_LOGS</NAME><RELATIONAL_TABLE><COL_LIST><COL_LIST_ITEM><NAME>JOB_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><CHAR_SEMANTICS></CHAR_SEMANTICS><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>START_TS</NAME><DATATYPE>TIMESTAMP_WITH_LOCAL_TIMEZONE</DATATYPE><SCALE>6</SCALE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>END_TS</NAME><DATATYPE>TIMESTAMP_WITH_LOCAL_TIMEZONE</DATATYPE><SCALE>6</SCALE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>STATUS</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><CHAR_SEMANTICS></CHAR_SEMANTICS><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ERROR</NAME><DATATYPE>CLOB</DATATYPE><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM></COL_LIST><DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION><PHYSICAL_PROPERTIES><HEAP_TABLE></HEAP_TABLE></PHYSICAL_PROPERTIES></RELATIONAL_TABLE></TABLE>"}