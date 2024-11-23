create or replace procedure wksp_frongpmstdev.xx_jwt_username1 (
    l_str in varchar2
) is
    i number;
begin
    i := 0;
    insert into axxml_tab (
        session_id,
        id,
        vc2_data,
        xml_clob
    ) values ( v('APP_SESSION'),
               999,
               l_str,
               null );

end;
/


-- sqlcl_snapshot {"hash":"7aaeb8af3a440e28802ad64f820a17332c165c2b","type":"PROCEDURE","name":"XX_JWT_USERNAME1","schemaName":"WKSP_FRONGPMSTDEV"}