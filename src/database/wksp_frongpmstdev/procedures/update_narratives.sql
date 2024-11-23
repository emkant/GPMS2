create or replace procedure wksp_frongpmstdev.update_narratives as

    l_url           varchar2(4000);
    instance_url    varchar2(200);
    l_version       varchar2(10);
    l_response_clob clob;
    l_envelope      varchar2(32000);
    v_statuscode    number;
begin
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
                upper(organization_name) = 'DEV'
        )
        and upper(environment_name) = 'DEV';

    for i in (
        select
            *
        from
            load_narratives-- WHERE EXPENDITURE_ITEM_ID = 527257
    ) loop
        l_url := instance_url
                 || '/fscmRestApi/resources/11.13.18.05/projectExpenditureItems/'
                 || i.expenditure_item_id
                 || '/child/ProjectExpenditureItemsDFF/'
                 || i.expenditure_item_id;

        l_envelope := '{"narrativeBillingOverflow1" : "'
                      || i.invoice_narrative
                      || '"
                   }';
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        l_response_clob := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'PATCH',
            p_username    => 'AMY.MARLIN',
            p_password    => 'F8*xe7?M',
 -- P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
    -- P_SCHEME => 'OAUTH_CLIENT_CRED',
            p_body        => l_envelope
        );

        v_statuscode := apex_web_service.g_status_code;    
    -- XX_GPMS.WIP_DEBUG (2, 7777, '', V_STATUSCODE||' '||I.EXPENDITURE_ITEM_ID);   
        dbms_output.put_line(l_url);
        dbms_output.put_line(l_envelope);
    end loop;

end;
/


-- sqlcl_snapshot {"hash":"8e67876eff77cfac9b1ebcb4149f4b144fca93b3","type":"PROCEDURE","name":"UPDATE_NARRATIVES","schemaName":"WKSP_FRONGPMSTDEV"}