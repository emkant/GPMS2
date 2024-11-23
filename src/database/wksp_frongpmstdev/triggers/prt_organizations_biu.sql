create or replace editionable trigger wksp_frongpmstdev.prt_organizations_biu before
    insert or update on wksp_frongpmstdev.prt_organizations
    for each row
begin
    if inserting then
        :new.created_by := nvl(
            v('APP_USER'),
            user
        );
        :new.creation_date := systimestamp;
    end if;

    :new.last_updated_by := nvl(
        v('APP_USER'),
        user
    );
    :new.last_update_date := systimestamp;
end;
/

alter trigger wksp_frongpmstdev.prt_organizations_biu enable;


-- sqlcl_snapshot {"hash":"0855309fe48fa382895e1f7e6dfd6126e6ce4727","type":"TRIGGER","name":"PRT_ORGANIZATIONS_BIU","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<TRIGGER  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>PRT_ORGANIZATIONS_BIU</NAME><TRIGGER_TYPE>BEFORE</TRIGGER_TYPE><DML_EVENT><EVENT_LIST><EVENT_LIST_ITEM><EVENT>INSERT</EVENT></EVENT_LIST_ITEM><EVENT_LIST_ITEM><EVENT>UPDATE</EVENT></EVENT_LIST_ITEM></EVENT_LIST><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>PRT_ORGANIZATIONS</NAME><REFERENCING><FOR_EACH_ROW></FOR_EACH_ROW></REFERENCING></DML_EVENT><PLSQL_BLOCK>BEGIN  IF  INSERTING  THEN  :new  .created_by  :=nvl  (v  ('APP_USER'  ),USER  );:new  .creation_date  :=SYSTIMESTAMP  ;END  IF  ;:new  .last_updated_by  :=nvl  (v  ('APP_USER'  ),USER  );:new  .last_update_date  :=SYSTIMESTAMP  ;END  ;</PLSQL_BLOCK></TRIGGER>"}