create or replace package body wksp_frongpmstdev.ma_util as

    p_url        varchar2(200);
    instance_url varchar2(200);

    procedure fetch_invoices is

        l_url                  varchar2(4000);
        l_version              varchar2(1000) := '1.2';
        l_envelope             varchar2(10000);
        l_xml_response         xmltype;
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        v_contract_id          number;
    begin
        if p_url is null then
            p_url := instance_url || '/xmlpserver/services/ExternalReportWSSService';
        end if;
        l_url := p_url;
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
        l_envelope := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
			<soap:Header/>
			   <soap:Body>
				  <pub:runReport>
					 <pub:reportRequest>
					   <pub:attributeFormat>xml</pub:attributeFormat>
					   <pub:reportAbsolutePath>/Custom/Projects/Project Billing/Project Costs Report.xdo</pub:reportAbsolutePath>
					   <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
					 </pub:reportRequest>
					 <pub:appParams></pub:appParams>
				  </pub:runReport>
			   </soap:Body>
			</soap:Envelope>';
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
        begin
            l_xml_response := apex_web_service.make_request(
                p_url      => l_url,
                p_version  => l_version,
                p_action   => 'runReport',
                p_envelope => l_envelope
            );
        exception
            when others then
                null;
        end; 
    -- XX_GPMS.WIP_DEBUG (2, 1048, '', L_XML_RESPONSE.GETCLOBVAL ());
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        xx_gpms.wip_debug(2, 1049, '', l_clob_report_response);
 -- now we need to do the following substr on the clob instead
        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := xx_gpms.base64_decode_clob(l_clob_report_response);
        xx_gpms.wip_debug(2, 1050, '', l_clob_report_decode);
        if apex_web_service.g_status_code in ( 200, 201 ) then
            delete from ma_approval_invoices;

            insert into ma_approval_invoices
                (
                    select
                        *
                    from
                        xmltable ( '/DATA_DS/G_INV_APPROVAL'
                                passing xmltype(l_clob_report_decode)
                            columns
                                taskid path 'TASKID',
                                tasknumber path 'TASKNUMBER',
                                task_definition_name path 'TASKDEFINITIONNAME',
                                priority path 'PRIORITY',
                                title path 'TITLE',
                                identification_key path 'IDENTIFICATIONKEY',
                                contract_number path 'CONTRACT_NUMBER',
                                invoice_num path 'INVOICE_NUM',
                                invoice_status_code path 'INVOICE_STATUS_CODE',
                                assignee path 'ASSIGNEE',
                                assignee_display_name path 'ASSIGNEESDISPLAYNAME',
                                invoice_currency_code path 'INVOICE_CURRENCY_CODE',
                                invoice_date path 'INVOICE_DATE',
                                invoice_amount path 'INVOICE_AMOUNT',
                                write_off_amount path 'WRITE_OFF_AMOUNT',
                                bill_customer_name path 'BILL_CUSTOMER_NAME',
                                bill_cust_acct_num path 'BILL_CUST_ACCT_NUM',
                                bill_cust_acct_name path 'BILL_CUST_ACCT_NAME',
                                bill_cust_site path 'BILL_CUST_SITE'
                        )
                );

        end if;

    exception
        when others then
            xx_gpms.wip_debug(3, dbms_utility.format_error_backtrace, '', '');
    end;

    procedure webservice_call (
        p_web_service_type varchar2,
        p_request          clob,
        p_response_code    out number,
        p_response         out clob
    ) is
        v_webservice_config_row webservice_config%rowtype;
        l_response_clob         clob;
        l_url                   varchar2(1000);
    begin
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        select
            *
        into v_webservice_config_row
        from
            webservice_config
        where
            name = p_web_service_type;

        l_response_clob := apex_web_service.make_rest_request(
            p_url         => instance_url || v_webservice_config_row.url,
            p_http_method => v_webservice_config_row.action,
            p_scheme      => 'OAUTH_CLIENT_CRED',
            p_body        => p_request
        );

        p_response := l_response_clob;
        p_response_code := apex_web_service.g_status_code;
        webservice_logger(instance_url || v_webservice_config_row.url, p_request, l_response_clob, apex_web_service.g_status_code);
    exception
        when others then
            webservice_logger(instance_url || v_webservice_config_row.url, p_request, l_response_clob, apex_web_service.g_status_code
            );
    end;

    procedure mass_approve_invoices (
        p_task_numbers varchar2,
        p_response     clob
    ) is

        v_envelope      varchar2(1000);
        v_rest_api      varchar2(100) := 'MA_BULK_APPROVAL';
        v_response_code number;
        v_response      varchar2(4000);
    begin
        select
            envelope
        into v_envelope
        from
            webservice_config
        where
            name = v_rest_api;

        v_envelope := replace(v_envelope, 'task_numbers', p_task_numbers);
        xx_gpms.wip_debug(1, 1, 'ENVELOPE ' || v_envelope, '');
        webservice_call(v_rest_api, v_envelope, v_response_code, v_response);
    exception
        when others then
            raise;
    end;

    procedure mass_reject_invoices (
        p_task_numbers  varchar2,
        p_justification varchar2,
        p_response      clob
    ) is

        v_envelope      varchar2(1000);
        v_rest_api      varchar2(100) := 'MA_BULK_REJECTION';
        v_response_code number;
        v_response      varchar2(4000);
    begin
        select
            envelope
        into v_envelope
        from
            webservice_config
        where
            name = v_rest_api;

        v_envelope := replace(v_envelope, 'task_numbers', p_task_numbers);
        v_envelope := replace(v_envelope, '_comments', p_justification);
        xx_gpms.wip_debug(1, 1, 'ENVELOPE ' || v_envelope, '');
        webservice_call(v_rest_api, v_envelope, v_response_code, v_response);
        if v_response_code not in ( 200, 201 ) then
            null;
        end if;
    exception
        when others then
            raise;
    end;

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
                upper(organization_name) = v('P0_CLIENT')
        )
        and upper(environment_name) = v('P0_ENV');

    apex_web_service.oauth_set_token(p_token => v('G_SAAS_ACCESS_TOKEN'));
end ma_util;
/


-- sqlcl_snapshot {"hash":"27a4f96aef5d36f2bbc35944c7c3087179ccf99b","type":"PACKAGE_BODY","name":"MA_UTIL","schemaName":"WKSP_FRONGPMSTDEV"}