create or replace procedure wksp_frongpmstdev.test_rest (
    g_user_name in varchar2,
    g_password  in varchar2
) as
    l_clob       clob;
    l_url        varchar2(1000);
    instance_url varchar2(1000);
begin
    apex_web_service.g_request_headers(1).name := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/json';
    select
        base_url
    into instance_url
    from
        prt_environments
    where
        organization_id in (
            select
                organization_id
            from
                prt_organizations
            where
                upper(organization_name) = 'MAPLES'
        )
        and upper(environment_name) = 'DEV1';

    l_url := instance_url || '/fscmRestApi/resources/11.13.18.05/projectExpenditureItems';
    l_clob := apex_web_service.make_rest_request(
        p_url         => l_url,
        p_http_method => 'GET',
        p_username    => g_user_name,
        p_password    => g_password
    );

    dbms_output.put_line(apex_web_service.g_status_code);
exception
    when others then
        dbms_output.put_line(sqlerrm);
end test_rest;
/


-- sqlcl_snapshot {"hash":"80f5c850cd0faf2a9e55731570837db2e5114f9e","type":"PROCEDURE","name":"TEST_REST","schemaName":"WKSP_FRONGPMSTDEV"}