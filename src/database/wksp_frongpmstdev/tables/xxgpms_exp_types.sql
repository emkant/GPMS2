create table wksp_frongpmstdev.xxgpms_exp_types (
    id                    number
        generated always as identity minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 start with 1 cache 20 noorder nocycle
        nokeep noscale
    not null enable,
    expenditure_type_name varchar2(1000 char),
    expenditure_type_id   number,
    session_id            number
);

alter table wksp_frongpmstdev.xxgpms_exp_types
    add constraint xxgpms_exp_types_id_pk primary key ( id )
        using index enable;


-- sqlcl_snapshot {"hash":"c4f9ae657ebaf07776adee4ba02742fb3d92d9af","type":"TABLE","name":"XXGPMS_EXP_TYPES","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<TABLE  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>XXGPMS_EXP_TYPES</NAME><RELATIONAL_TABLE><COL_LIST><COL_LIST_ITEM><NAME>ID</NAME><DATATYPE>NUMBER</DATATYPE><IDENTITY_COLUMN><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><GENERATION>ALWAYS</GENERATION><START_WITH>33521</START_WITH><INCREMENT>1</INCREMENT><MINVALUE>1</MINVALUE><MAXVALUE>9999999999999999999999999999</MAXVALUE><CACHE>20</CACHE></IDENTITY_COLUMN><NOT_NULL></NOT_NULL></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_TYPE_NAME</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>1000</LENGTH><CHAR_SEMANTICS></CHAR_SEMANTICS><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>EXPENDITURE_TYPE_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>SESSION_ID</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM></COL_LIST><PRIMARY_KEY_CONSTRAINT_LIST><PRIMARY_KEY_CONSTRAINT_LIST_ITEM><NAME>XXGPMS_EXP_TYPES_ID_PK</NAME><COL_LIST><COL_LIST_ITEM><NAME>ID</NAME></COL_LIST_ITEM></COL_LIST><USING_INDEX></USING_INDEX></PRIMARY_KEY_CONSTRAINT_LIST_ITEM></PRIMARY_KEY_CONSTRAINT_LIST><DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION><PHYSICAL_PROPERTIES><HEAP_TABLE></HEAP_TABLE></PHYSICAL_PROPERTIES></RELATIONAL_TABLE></TABLE>"}