create or replace procedure wksp_frongpmstdev.wip_logger_proc (
    p_message_vc   in varchar2 default null,
    p_message_clob in varchar2 default null
) is
    pragma autonomous_transaction;
begin
    insert into wip_logger (
        message_vc,
        message_clob
    ) values ( p_message_vc,
               p_message_clob );

    commit;
end;
/


-- sqlcl_snapshot {"hash":"1618a825ccbe6f57ae30dcfab99863b7253d1028","type":"PROCEDURE","name":"WIP_LOGGER_PROC","schemaName":"WKSP_FRONGPMSTDEV"}