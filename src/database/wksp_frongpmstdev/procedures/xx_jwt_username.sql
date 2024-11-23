create or replace procedure wksp_frongpmstdev.xx_jwt_username is
    i number;
begin
    i := 0;
    delete from xxgpms_project_costs
    where
        session_id = v('APP_SESSION');

    delete from xxgpms_project_wip_category
    where
        session_id = v('APP_SESSION');

    delete from xxgpms_project_events
    where
        session_id = v('APP_SESSION');

    delete from xxgpms_project_contract
    where
        session_id = v('APP_SESSION');

    delete from xxgpms_project_rates
    where
        session_id = v('APP_SESSION');

    delete from xxgpms_project_invoices
    where
        session_id = v('APP_SESSION');

    delete from xxgpms_project_invoice_history
    where
        session_id = v('APP_SESSION');

        --  DELETE FROM XXGPMS_PROJECTS
        -- WHERE  SESSION_ID = V('APP_SESSION');

    delete from xxgpms_matter_credits
    where
        session_id = v('APP_SESSION');

    delete from xxgpms_interprojects
    where
        session_id = v('APP_SESSION');

    delete from axxml_tab;

    delete from spell_check;

    delete from xxgpms_exp_types; 
        -- DELETE FROM  XXGPMS_; 

    delete from spell_checker_dtl;

end;
/


-- sqlcl_snapshot {"hash":"16946052d507f8c28bfcdfca425085ab995f6bb5","type":"PROCEDURE","name":"XX_JWT_USERNAME","schemaName":"WKSP_FRONGPMSTDEV"}