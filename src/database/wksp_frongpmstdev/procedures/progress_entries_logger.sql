create or replace procedure wksp_frongpmstdev.progress_entries_logger (
    p_percentage in number,
    p_message    in varchar2
) is
    pragma autonomous_transaction;
begin
    insert into progress_entries (
        percentage,
        message,
        created_date
    ) values ( p_percentage,
               p_message,
               systimestamp );

    commit;
end;
/


-- sqlcl_snapshot {"hash":"0a12b831687bd9458e3d71b0358520db52bfcc44","type":"PROCEDURE","name":"PROGRESS_ENTRIES_LOGGER","schemaName":"WKSP_FRONGPMSTDEV"}