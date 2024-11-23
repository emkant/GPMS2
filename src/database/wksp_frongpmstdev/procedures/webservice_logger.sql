create or replace procedure wksp_frongpmstdev.webservice_logger (
    p_url           varchar2,
    p_request       clob,
    p_response      clob,
    p_response_code number
) is
    pragma autonomous_transaction;
begin
    insert into webservice_log (
        url,
        request,
        response,
        response_code
    ) values ( p_url,
               p_request,
               p_response,
               p_response_code );

    commit;
end;
/


-- sqlcl_snapshot {"hash":"45f9a7dc51801ed496148bafcc689069504a7c61","type":"PROCEDURE","name":"WEBSERVICE_LOGGER","schemaName":"WKSP_FRONGPMSTDEV"}