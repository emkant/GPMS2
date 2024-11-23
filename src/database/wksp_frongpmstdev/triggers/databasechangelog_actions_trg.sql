create or replace editionable trigger wksp_frongpmstdev.databasechangelog_actions_trg before
    insert on wksp_frongpmstdev.databasechangelog_actions
    for each row
declare
    new_seq number;
begin
    select
        nvl(
            max(sequence + 1),
            0
        )
    into new_seq
    from
        wksp_frongpmstdev.databasechangelog_actions
    where
            id = :new.id
        and author = :new.author
        and filename = :new.filename;

    :new.sequence := new_seq;
end;
/

alter trigger wksp_frongpmstdev.databasechangelog_actions_trg enable;


-- sqlcl_snapshot {"hash":"b82987638253e631fdcb6c26d4a6889274e20253","type":"TRIGGER","name":"DATABASECHANGELOG_ACTIONS_TRG","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<TRIGGER  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>DATABASECHANGELOG_ACTIONS_TRG</NAME><TRIGGER_TYPE>BEFORE</TRIGGER_TYPE><DML_EVENT><EVENT_LIST><EVENT_LIST_ITEM><EVENT>INSERT</EVENT></EVENT_LIST_ITEM></EVENT_LIST><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>DATABASECHANGELOG_ACTIONS</NAME><REFERENCING><FOR_EACH_ROW></FOR_EACH_ROW></REFERENCING></DML_EVENT><PLSQL_BLOCK>DECLARE  new_seq  NUMBER  ;BEGIN  SELECT  nvl  (MAX  (sequence  +1  ),0  )INTO  new_seq  FROM  WKSP_FRONGPMSTDEV  .DATABASECHANGELOG_ACTIONS  WHERE  id  =:new  .id  AND  author  =:new  .author  AND  filename  =:new  .filename  ;:new  .sequence  :=new_seq  ;END  ;</PLSQL_BLOCK></TRIGGER>"}