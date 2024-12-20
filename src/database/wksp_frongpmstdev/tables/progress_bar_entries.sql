create table wksp_frongpmstdev.progress_bar_entries (
    id         number
        generated always as identity minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 start with 1 cache 20 noorder nocycle
        nokeep noscale
    not null enable,
    module     varchar2(100 byte),
    seq        number,
    message    varchar2(200 byte),
    percentage number
);

alter table wksp_frongpmstdev.progress_bar_entries
    add constraint progress_bar_entries_con unique ( seq,
                                                     module )
        using index enable;


-- sqlcl_snapshot {"hash":"30489d8a401c3418f7e0131e00e9c5eefe358e1f","type":"TABLE","name":"PROGRESS_BAR_ENTRIES","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<TABLE  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>PROGRESS_BAR_ENTRIES</NAME><RELATIONAL_TABLE><COL_LIST><COL_LIST_ITEM><NAME>ID</NAME><DATATYPE>NUMBER</DATATYPE><IDENTITY_COLUMN><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><GENERATION>ALWAYS</GENERATION><START_WITH>81</START_WITH><INCREMENT>1</INCREMENT><MINVALUE>1</MINVALUE><MAXVALUE>9999999999999999999999999999</MAXVALUE><CACHE>20</CACHE></IDENTITY_COLUMN><NOT_NULL></NOT_NULL></COL_LIST_ITEM><COL_LIST_ITEM><NAME>MODULE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>100</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>SEQ</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM><COL_LIST_ITEM><NAME>MESSAGE</NAME><DATATYPE>VARCHAR2</DATATYPE><LENGTH>200</LENGTH><COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>PERCENTAGE</NAME><DATATYPE>NUMBER</DATATYPE></COL_LIST_ITEM></COL_LIST><UNIQUE_KEY_CONSTRAINT_LIST><UNIQUE_KEY_CONSTRAINT_LIST_ITEM><NAME>PROGRESS_BAR_ENTRIES_CON</NAME><COL_LIST><COL_LIST_ITEM><NAME>SEQ</NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>MODULE</NAME></COL_LIST_ITEM></COL_LIST><USING_INDEX></USING_INDEX></UNIQUE_KEY_CONSTRAINT_LIST_ITEM></UNIQUE_KEY_CONSTRAINT_LIST><DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION><PHYSICAL_PROPERTIES><HEAP_TABLE></HEAP_TABLE></PHYSICAL_PROPERTIES></RELATIONAL_TABLE></TABLE>"}