create or replace package wksp_frongpmstdev.ma_util as
    procedure fetch_invoices;

    procedure webservice_call (
        p_web_service_type varchar2,
        p_request          clob,
        p_response_code    out number,
        p_response         out clob
    );

    procedure mass_approve_invoices (
        p_task_numbers varchar2,
        p_response     clob
    );

    procedure mass_reject_invoices (
        p_task_numbers  varchar2,
        p_justification varchar2,
        p_response      clob
    );

end ma_util;
/


-- sqlcl_snapshot {"hash":"dafd44c5ca7405325f220240d64eaa8f72d99472","type":"PACKAGE_SPEC","name":"MA_UTIL","schemaName":"WKSP_FRONGPMSTDEV"}