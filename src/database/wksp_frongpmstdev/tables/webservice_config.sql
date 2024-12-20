create table wksp_frongpmstdev.webservice_config (
    id       number
        generated by default on null as identity minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 start with 1 cache 20
        noorder nocycle nokeep noscale
    not null enable,
    name     varchar2(100 char),
    url      varchar2(1000 char),
    envelope varchar2(1000 char),
    action   varchar2(10 byte)
);

alter table wksp_frongpmstdev.webservice_config
    add constraint webservice_config_id_pk primary key ( id )
        using index enable;


-- sqlcl_snapshot {"hash":"6a1a96ac56dbd8a0167c9b09c546b9f1d508d42c","type":"TABLE","name":"WEBSERVICE_CONFIG","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<TABLE  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>WEBSERVICE_CONFIG</NAME><RELATIONAL_TABLE><COL_LIST><COL_LIST_ITEM><NAME>ID</NAME><DATATYPE>NUMBER</DATATYPE><IDENTITY_COLUMN><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><GENERATION>DEFAULT</GENERATION><ON_NULL></ON_NULL><START_WITH>41</START_WITH><INCREMENT>1</INCREMENT><MINVALUE>1</MINVALUE><MAXVALUE>9999999999999999999999999999</MAXVALUE><CACHE>20</CACHE></IDENTITY_COLUMN><NOT_NULL></NOT_NULL></COL_LIST_ITEM><COL_LIST_ITEM><NAME>NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><CHAR_SEMANTICS></CHAR_SEMANTICS><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>URL</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><CHAR_SEMANTICS></CHAR_SEMANTICS><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ENVELOPE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><CHAR_SEMANTICS></CHAR_SEMANTICS><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ACTION</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>10</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM></COL_LIST><PRIMARY_KEY_CONSTRAINT_LIST><PRIMARY_KEY_CONSTRAINT_LIST_ITEM><NAME>WEBSERVICE_CONFIG_ID_PK</NAME><COL_LIST><COL_LIST_ITEM><NAME>ID</NAME></COL_LIST_ITEM></COL_LIST><USING_INDEX></USING_INDEX></PRIMARY_KEY_CONSTRAINT_LIST_ITEM></PRIMARY_KEY_CONSTRAINT_LIST><DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION><PHYSICAL_PROPERTIES><HEAP_TABLE></HEAP_TABLE></PHYSICAL_PROPERTIES></RELATIONAL_TABLE></TABLE>"}