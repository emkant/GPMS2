create or replace package body wksp_frongpmstdev.xx_gpms as

    instance_url varchar2(200);
    p_url        varchar2(200);
    g_password1  varchar2(100);
    g_token_ts   timestamp := cast ( to_timestamp_tz('2023-03-06 17:05:46 GMT', 'YYYY-MM-DD HH24:MI:SS TZR') as timestamp ) + interval
    '4' hour;

    procedure wip_debug (
        p_debug_level in number,
        p_debug_id    in number,
        p_debug_str   in varchar2,
        p_debug_clob  in clob
    ) is
        pragma autonomous_transaction;
    begin
        insert into axxml_tab (
            session_id,
            id,
            vc2_data,
            xml_clob
        ) values ( v('APP_SESSION'),
                   p_debug_id,
                   p_debug_str,
                   p_debug_clob );

        commit;
    end wip_debug;

    function base64_decode_clob (
        p_decodeclob in clob
    ) return clob is

        blob_loc      blob;
        clob_trim     clob;
        res           clob;
        lang_context  integer := dbms_lob.default_lang_ctx;
        dest_offset   integer := 1;
        src_offset    integer := 1;
        read_offset   integer := 1;
        warning       integer;
        l_clob_length integer := dbms_lob.getlength(p_decodeclob);
        amount        integer := 1440;
 -- must be a whole multiple of 4
        buffer        raw(32000);
        stringbuffer  varchar2(32000);
 -- BASE64 characters are always simple ASCII. Thus you get never any Mulit-Byte character and having the same size as 'amount' is sufficient
    begin
        dbms_lob.createtemporary(res, true);
        if p_decodeclob is null
           or nvl(l_clob_length, 0) = 0 then
            return res;
        elsif l_clob_length <= 32000 then
            res := utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(p_decodeclob)));
        else -- UTL_ENCODE.BASE64_DECODE is limited to 32k, process in chunks if bigger
 -- Remove all NEW_LINE from base64 string
            l_clob_length := dbms_lob.getlength(p_decodeclob);
            dbms_lob.createtemporary(clob_trim, true);
            loop
                exit when read_offset > l_clob_length;
                stringbuffer := replace(
                    replace(
                        dbms_lob.substr(p_decodeclob, amount, read_offset),
                        chr(13),
                        null
                    ),
                    chr(10),
                    null
                );

                dbms_lob.writeappend(clob_trim,
                                     length(stringbuffer),
                                     stringbuffer);
                read_offset := read_offset + amount;
            end loop;

            read_offset := 1;
            l_clob_length := dbms_lob.getlength(clob_trim);
            dbms_lob.createtemporary(blob_loc, true);
            loop
                exit when read_offset > l_clob_length;
                buffer := utl_encode.base64_decode(utl_raw.cast_to_raw(dbms_lob.substr(clob_trim, amount, read_offset)));

                dbms_lob.writeappend(blob_loc,
                                     dbms_lob.getlength(buffer),
                                     buffer);
                read_offset := read_offset + amount;
            end loop;

            dbms_lob.converttoclob(res, blob_loc, dbms_lob.lobmaxsize, dest_offset, src_offset,
                                   dbms_lob.default_csid, lang_context, warning);

            dbms_lob.freetemporary(blob_loc);
            dbms_lob.freetemporary(clob_trim);
        end if;

        return res;
    end base64_decode_clob;

  --
    function update_project_lines_dff (
        p_exp_id                     in number,
        p_internal_comment           varchar2,
        p_narrative_billing_overflow in varchar2 default null,
        p_event_attr                 in varchar2 default null,
        p_standard_bill_rate_attr    in number default null,
        p_project_bill_rate_attr     in number default null,
        p_realized_bill_rate_attr    in number default null,
        p_hours_entered              in number default null
    ) return number is
        l_url           varchar2(4000);
        l_envelope      varchar2(10000);
        l_response_clob clob;
        v_statuscode    number;
    begin
        wip_debug(2, 18000, 'Inside UPDATE_PROJECT_LINES_DFF', '');
        l_url := instance_url
                 || '/fscmRestApi/resources/11.13.18.05/projectExpenditureItems/'
                 || trim(both '-' from p_exp_id)
                 || '/child/ProjectExpenditureItemsDFF/'
                 || trim(both '-' from p_exp_id);

        l_envelope := '{"internalComment" : "'
                      || p_internal_comment
                      || '",
                "narrativeBillingOverflow1" : "'
                      || p_narrative_billing_overflow
                      || '" ,
                "event" : "'
                      || p_event_attr
                      || '" ,
                "standardBillRate" : "'
                      || p_standard_bill_rate_attr
                      || '",
                "projectBillRate" : "'
                      || p_project_bill_rate_attr
                      || '",
                "realizedBillRate" : "'
                      || p_realized_bill_rate_attr
                      || '"
               }';

        wip_debug(2, 180000, l_url, '');
        wip_debug(2, 180001, l_envelope, '');
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        l_response_clob := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'PATCH',
            p_scheme      => 'OAUTH_CLIENT_CRED',
            p_body        => l_envelope
        );

        v_statuscode := apex_web_service.g_status_code;
    -- APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE ();
        wip_debug(2, 180002, '', l_response_clob);
        wip_debug(2, 180003, v_statuscode, '');
        return v_statuscode;
    end;

    procedure update_status (
        p_project_number   in varchar2 default null,
        p_agreement_number in varchar2 default null,
        p_unbilled_flag    in varchar2,
        p_bill_thru_date   in date,
        p_jwt              in varchar2,
        p_bill_from_date   in date default to_date ( '01-01-1997', 'MM-DD-YYYY' )
    ) is

        l_url                  varchar2(4000);
        l_version              varchar2(1000) := '1.2';
        l_envelope             varchar2(10000);
        l_xml_response         xmltype;
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        l_otbi_flag            varchar2(1) := 'N';
        v_contract_id          number;
    begin
        if p_url is null then
            p_url := instance_url || '/xmlpserver/services/ExternalReportWSSService';
        end if;
        l_url := p_url;
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
 --- Code for Project Costs
        delete from xxgpms_project_costs
        where
            session_id = v('APP_SESSION');

        delete from xxgpms_project_events
        where
            session_id = v('APP_SESSION');

        delete from xxgpms_project_contract
        where
            session_id = v('APP_SESSION');

        delete from xxgpms_project_split
        where
            session_id = v('APP_SESSION');

        delete from xxgpms_project_rates
        where
            session_id = v('APP_SESSION');

        delete from xxgpms_project_invoice_history
        where
            session_id = v('APP_SESSION');

        delete from xxgpms_matter_credits
        where
            session_id = v('APP_SESSION');

        delete from xxgpms_interprojects
        where
            session_id = v('APP_SESSION');

        delete from xxgpms_exp_types;

        delete from axxml_tab
        where
            session_id = v('APP_SESSION');

        wip_debug(1, 1000, 'Start Project Number'
                           || p_project_number
                           || '-'
                           || p_unbilled_flag
                           || ' Instance '
                           || instance_url
                           || 'Bill From Date'
                           || p_bill_from_date
                           || 'Bill Thru Date'
                           || p_bill_thru_date, '');

        wip_debug(1, 1001, 'JWT ' || p_jwt, '');
        if p_jwt = 'OTBI' then
            l_otbi_flag := 'Y';
        end if;
        l_envelope := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
			<soap:Header/>
			   <soap:Body>
				  <pub:runReport>
					 <pub:reportRequest>
					   <pub:attributeFormat>xml</pub:attributeFormat>
						 <pub:parameterNameValues>
							<pub:item>
								<pub:name>P_Agreement_Number</pub:name>
								<pub:values>
									<pub:item>'
                      || p_agreement_number
                      || '</pub:item>
								</pub:values>
							</pub:item>
							<pub:item>
								<pub:name>P_Unbilled_Flag</pub:name>
								<pub:values>
									<pub:item>'
                      || p_unbilled_flag
                      || '</pub:item>
								</pub:values>
							</pub:item>
							<pub:item>
								<pub:name>P_Bill_Thru_Date</pub:name>
								<pub:values>
									<pub:item>'
                      || to_char(p_bill_thru_date, 'MM-DD-YYYY')
                      || '</pub:item>
								</pub:values>
							</pub:item>
						</pub:parameterNameValues>
					   <pub:reportAbsolutePath>/Custom/Projects/Project Billing/APEX - Project Costs Report.xdo</pub:reportAbsolutePath>
					   <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
					 </pub:reportRequest>
					 <pub:appParams></pub:appParams>
				  </pub:runReport>
			   </soap:Body>
			</soap:Envelope>';

        wip_debug(2, 10481, '', l_envelope);
        wip_debug(2, 10481.1, '', l_url);
        wip_debug(2, 10481.2, '', l_otbi_flag);
        if l_otbi_flag = 'N' then
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || p_jwt;
            l_xml_response := apex_web_service.make_request(
                p_url      => l_url,
                p_version  => l_version,
                p_action   => 'runReport',
                p_envelope => l_envelope
            );

        else
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
    --   WIP_DEBUG (2, 10481.3, '', APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE);
 -- l_xml_response := apex_web_service.make_request ( p_url => l_url, p_version => l_version, p_action => 'runReport', p_envelope => l_envelope, p_username => g_username, p_password => g_password );
            begin
                l_xml_response := apex_web_service.make_request(
                    p_url      => l_url,
                    p_version  => l_version,
                    p_action   => 'runReport',
                    p_envelope => l_envelope
                --   ,p_username => 'amy.marlin'
                --   ,p_password => 'm9T7w^h%'
                  --    , P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
    -- , P_TOKEN_URL => v('G_SAAS_ACCESS_TOKEN'
                );
            exception
                when others then
                    wip_debug(3, 10482.1, 'Error: ' || apex_web_service.g_status_code, sqlerrm);
                    wip_debug(3, 10482.2, 'URL: ' || l_url, '');
            end;
 -- L_XML_RESPONSE := APEX_WEB_SERVICE.MAKE_REQUEST(P_URL => L_URL, P_VERSION => L_VERSION, P_ACTION => 'runReport', P_ENVELOPE =>
 -- L_ENVELOPE, P_CREDENTIAL_STATIC_ID => 'GPMS_DEV');
        end if;

        wip_debug(2,
                  1048,
                  '',
                  l_xml_response.getclobval());
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        wip_debug(2, 1049, '', l_clob_report_response);
 -- now we need to do the following substr on the clob instead
        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        wip_debug(2, 1050, '', l_clob_report_decode);
        commit;
        insert into xxgpms_project_costs (
            project_id,
            expenditure_item_id,
            project_number,
            billable_flag,
            task_id,
            task_number,
            top_task_number,
            project_status_code,
            project_name,
            expenditure_item_date,
            revenue_recognized_flag,
            bill_hold_flag,
            quantity,
            projfunc_raw_cost,
            raw_cost_rate,
            projfunc_burdened_cost,
            burden_cost_rate,
            invoiced_flag,
            revenue_hold_flag,
            acct_currency_code,
            acct_raw_cost,
            acct_burdened_cost,
            task_billable_flag,
            external_bill_rate,
            total_amount,
            internal_comment,
            narrative_billing_overflow,
            task_start_date,
            task_completion_date,
            project_start_date,
            task_name,
            expenditure_comment,
            unit_of_measure,
            first_name,
            last_name,
            person_name,
            expenditure_type_name,
            expenditure_category_name,
            standard_bill_rate_attr,
            standard_bill_rate_amt,
            project_bill_rate_attr,
            project_bill_rate_amt,
            realized_bill_rate_attr,
            realized_bill_rate_amt,
            event_attr,
            bu_name,
            bu_id,
            job_name,
            job_id,
            system_linkage_function,
            orig_transaction_reference,
            document_name,
            doc_entry_name,
            cst_invoice_submitted_count,
            creation_date,
            session_id,
            contract_number,
            line_number,
            billing_instructions,
            draft_invoice_number,
            invoice_status_code,
            transfer_status_code,
            nlr_org_id,
            wip_category,
            non_labour_resource_name,
            project_currency_code,
            write_up_down_value,
            incurred_by_person_id,
            job_approval_id,
            description,
            bill_set_num,
            contract_line_num,
            exp_bu_id,
            exp_org_id,
            dept_name,
            transaction_source,
            transaction_source_id,
            document_id
        )
            select
                project_id,
                expenditure_item_id,
                project_number,
                billable_flag,
                task_id,
                task_number,
                top_task_number,
                project_status_code,
                project_name,
                expenditure_item_date,
                revenue_recognized_flag,
                bill_hold_flag,
                quantity,
                projfunc_raw_cost,
                raw_cost_rate,
                projfunc_burdened_cost,
                burden_cost_rate,
                invoiced_flag,
                revenue_hold_flag,
                acct_currency_code,
                acct_raw_cost,
                acct_burdened_cost,
                task_billable_flag,
                external_bill_rate,
                round(nvl(external_bill_rate, 0) * quantity,
                      2),
                internal_comment,
                narrative_billing_overflow,
                task_start_date,
                task_completion_date,
                project_start_date,
                task_name,
                expenditure_comment,
                unit_of_measure,
                first_name,
                last_name,
                first_name
                || ' '
                || last_name,
                expenditure_type_name,
                expenditure_category_name,
                to_char(standard_bill_rate_attr, '9999999990.00'),
                to_char((standard_bill_rate_attr * quantity), '9999999990.00'),
                to_char(project_bill_rate_attr, '9999999990.00'),
                to_char((project_bill_rate_attr * quantity), '9999999990.00'),
                to_char(realized_bill_rate_attr, '9999999990.00'),
                to_char((realized_bill_rate_attr * quantity), '9999999990.00'),
                event_attr,
                bu_name,
                bu_id,
                job_name,
                job_id,
                system_linkage_function,
                orig_transaction_reference,
                document_name,
                doc_entry_name,
                cst_invoice_submitted_count,
                sysdate,
                v('APP_SESSION'),
                contract_number,
                line_number,
                billing_instructions,
                invoice_num,
                invoice_status_code,
                transfer_status_code,
                non_labor_resource_org_id,
                wip_category,
                non_labour_resource_name,
                project_currency_code,
                write_up_down_value,
                incurred_by_person_id,
                job_approval_id,
                description,
                bill_set_num,
                contract_line_num,
                exp_bu_id,
                exp_org_id,
                dept_name,
                transaction_source,
                transaction_source_id,
                document_id
            from
                xmltable ( '/DATA_DS/G_PROJECT_CONTRACTS/G_PROJECT_COST'
                        passing xmltype(l_clob_report_decode)
                    columns
                        project_id path 'PROJECT_ID',
                        expenditure_item_id path 'EXPENDITURE_ITEM_ID',
                        project_number path 'PROJECT_NUMBER',
                        billable_flag path 'BILLABLE_FLAG',
                        task_id path 'TASK_ID',
                        task_number path 'TASK_NUMBER',
                        top_task_number path 'TOP_TASK_NUMBER',
                        project_status_code path 'PROJECT_STATUS_CODE',
                        project_name path 'PROJECT_NAME',
                        expenditure_item_date path 'EXPENDITURE_ITEM_DATE',
                        revenue_recognized_flag path 'REVENUE_RECOGNIZED_FLAG',
                        bill_hold_flag path 'BILL_HOLD_FLAG',
                        quantity path 'QUANTITY',
                        projfunc_raw_cost path 'PROJFUNC_RAW_COST',
                        raw_cost_rate path 'RAW_COST_RATE',
                        projfunc_burdened_cost path 'PROJFUNC_BURDENED_COST',
                        burden_cost_rate path 'BURDEN_COST_RATE',
                        invoiced_flag path 'INVOICED_FLAG',
                        revenue_hold_flag path 'REVENUE_HOLD_FLAG',
                        acct_currency_code path 'ACCT_CURRENCY_CODE',
                        acct_raw_cost path 'ACCT_RAW_COST',
                        acct_burdened_cost path 'ACCT_BURDENED_COST',
                        task_billable_flag path 'TASK_BILLABLE_FLAG',
                        external_bill_rate path 'EXTERNAL_BILL_RATE',
                        internal_comment path 'INTERNALCOMMENT',
                        narrative_billing_overflow path 'NARRATIVEBILLINGOVERFLOW',
                        task_start_date path 'TASK_START_DATE',
                        task_completion_date path 'TASK_COMPLETION_DATE',
                        project_start_date path 'PROJECT_START_DATE',
                        task_name path 'TASK_NAME',
                        expenditure_comment path 'EXPENDITURE_COMMENT',
                        unit_of_measure path 'UNIT_OF_MEASURE',
                        first_name path 'FIRST_NAME',
                        last_name path 'LAST_NAME',
                        expenditure_type_name path 'EXPENDITURE_TYPE_NAME',
                        expenditure_category_name path 'EXPENDITURE_CATEGORY_NAME',
                        standard_bill_rate_attr path 'ATTRSTDBILLRATE',
                        project_bill_rate_attr path 'ATTRPRJBILLRATE',
                        realized_bill_rate_attr path 'ATTRRLZBILLRATE',
                        event_attr path 'ATTREVENT',
                        bu_name path 'BU_NAME',
                        bu_id path 'BU_ID',
                        job_name path 'JOB_NAME',
                        job_id path 'JOB_ID',
                        system_linkage_function path 'SYSTEM_LINKAGE_FUNCTION',
                        orig_transaction_reference path 'ORIG_TRANSACTION_REFERENCE',
                        document_name path 'DOCUMENT_NAME',
                        doc_entry_name path 'DOC_ENTRY_NAME',
                        cst_invoice_submitted_count path 'CST_INVOICE_SUBMITTED_COUNT',
                        contract_number path 'CONTRACT_NUMBER',
                        line_number path 'LINE_NUMBER',
                        billing_instructions path 'BILLING_INSTRUCTIONS',
                        invoice_num path 'INVOICE_NUM',
                        invoice_status_code path 'INVOICE_STATUS_CODE',
                        transfer_status_code path 'TRANSFER_STATUS_CODE',
                        non_labor_resource_org_id path 'NON_LABOR_RESOURCE_ORG_ID',
                        wip_category path 'WIP_CATEGORY',
                        non_labour_resource_name path 'NON_LABOUR_RESOURCE_NAME',
                        project_currency_code path 'PROJECT_CURRENCY_CODE',
                        write_up_down_value path 'WRITE_UP_DOWN_VALUE',
                        incurred_by_person_id path 'INCURRED_BY_PERSON_ID',
                        job_approval_id path 'JOB_APPROVAL_ID',
                        description path 'DESCRIPTION',
                        bill_set_num path 'BILL_SET_NUM',
                        contract_line_num path 'CONTRACT_LINE_NUM',
                        exp_bu_id path 'EXP_BU_ID',
                        exp_org_id path 'EXP_ORG_ID',
                        dept_name path 'DEPT_NAME',
                        transaction_source path 'TRANSACTION_SOURCE',
                        transaction_source_id path 'TRANSACTION_SOURCE_ID',
                        document_id path 'DOCUMENT_ID'
                ) xt;

        wip_debug(2, 1051, '', 'Inserted into Project Costs');
 -- WIP CATEGORY
        insert into xxgpms_project_wip_category (
            wip_category,
            session_id,
            draft_number,
            project_number,
            agreement_number
        )
            select
                wip_category,
                session_id,
                null,
                project_number,
                contract_number
            from
                xxgpms_project_costs
            where
                session_id = v('APP_SESSION');

        insert into xxgpms_project_contract (
            project_id,
            project_number,
            project_name,
            legal_entity_name,
            contract_number,
            contract_id,
            bu_name,
            organization_name,
            currency_code,
            contract_type_name,
            customer_name,
            retainer_balance,
            trust_balance,
            business_unit_id,
            transaction_source_id,
            user_transaction_source,
            session_id,
            contract_type_id,
            ebill_matter_id,
            tax_registration_type,
            tax_registration_number,
            tax_registration_country,
            contract_office,
            bill_customer_name,
            bill_customer_acct,
            bill_customer_site,
            client_number
        )
            select
                project_id,
                project_number,
                project_name,
                legal_entity_name,
                contract_number,
                contract_id,
                bu_name,
                organization_name,
                currency_code,
                contract_type_name,
                customer_name,
                retainer_balance,
                trust_balance,
                business_unit_id,
                transaction_source_id,
                user_transaction_source,
                v('APP_SESSION'),
                contract_type_id,
                ebill_matter_id,
                tax_registration_type,
                tax_registration_number,
                tax_registration_country,
                contract_office,
                bill_customer_name,
                bill_customer_acct,
                bill_customer_site,
                client_number
            from
                xmltable ( '/DATA_DS/G_PROJECT_CONTRACTS'
                        passing xmltype(l_clob_report_decode)
                    columns
                        project_id path 'PROJECT_ID',
                        project_number path 'PROJECT_NUMBER',
                        project_name path 'PROJECT_NAME',
                        legal_entity_name path 'LEGAL_ENTITY_NAME',
                        contract_number path 'CONTRACT_NUMBER',
                        contract_id path 'CONTRACT_ID',
                        bu_name path 'BU_NAME',
                        organization_name path 'ORGANIZATION_NAME',
                        currency_code path 'CURRENCY_CODE',
                        contract_type_name path 'CONTRACT_TYPE_NAME',
                        customer_name path 'CUSTOMER_NAME',
                        retainer_balance path 'RETAINER_BALANCE',
                        trust_balance path 'TRUST_BALANCE',
                        business_unit_id path 'BUSINESS_UNIT_ID',
                        transaction_source_id path 'TRANSACTION_SOURCE_ID',
                        user_transaction_source path 'USER_TRANSACTION_SOURCE',
                        contract_type_id path 'CONTRACT_TYPE_ID',
                        ebill_matter_id path 'ATTRIBUTE4',
                        tax_registration_type path 'TAX_REGISTRATION_TYPE',
                        tax_registration_number path 'TAX_REGISTRATION_NUMBER',
                        tax_registration_country path 'TAX_REGISTRATION_COUNTRY',
                        contract_office path 'ATTRIBUTE16',
                        bill_customer_name path 'BILL_CUSTOMER_NAME',
                        bill_customer_acct path 'BILL_CUST_ACCT_NAME',
                        bill_customer_site path 'BILL_CUST_SITE',
                        client_number path 'PARTY_NUMBER'
                ) xt;

        dbms_lob.freetemporary(l_clob_report_response);
        dbms_lob.freetemporary(l_clob_report_decode);
        dbms_lob.freetemporary(l_clob_temp);
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
        wip_debug(3, 1055, 'Project Costs - Completed', '');
 --- Code for Project Events
        l_envelope := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
			<soap:Header/>
			   <soap:Body>
				  <pub:runReport>
					 <pub:reportRequest>
					   <pub:attributeFormat>xml</pub:attributeFormat>
						 <pub:parameterNameValues>
							<pub:item>
								<pub:name>P_Proj_Number</pub:name>
								<pub:values>
									<pub:item>'
                      || p_project_number
                      || '</pub:item>
								</pub:values>
							</pub:item>
							<pub:item>
								<pub:name>P_Agreement_Number</pub:name>
								<pub:values>
									<pub:item>'
                      || p_agreement_number
                      || '</pub:item>
								</pub:values>
							</pub:item>
							<pub:item>
								<pub:name>P_Unbilled_Flag</pub:name>
								<pub:values>
									<pub:item>'
                      || p_unbilled_flag
                      || '</pub:item>
								</pub:values>
							</pub:item>
							<pub:item>
								<pub:name>P_Bill_Thru_Date</pub:name>
								<pub:values>
									<pub:item>'
                      || to_char(p_bill_thru_date, 'MM-DD-YYYY')
                      || '</pub:item>
								</pub:values>
							</pub:item>
						</pub:parameterNameValues>
					   <pub:reportAbsolutePath>/Custom/Projects/Project Billing/Project Events Report.xdo</pub:reportAbsolutePath>
					   <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
					 </pub:reportRequest>
					 <pub:appParams></pub:appParams>
				  </pub:runReport>
			   </soap:Body>
			</soap:Envelope>';

        wip_debug(2, 1056, '', l_envelope);
        if l_otbi_flag = 'N' then
            l_xml_response := apex_web_service.make_request(
                p_url      => l_url,
                p_version  => l_version,
                p_action   => 'runReport',
                p_envelope => l_envelope
            );
        else --l_xml_response := apex_web_service.make_request ( p_url => l_url, p_version => l_version, p_action => 'runReport', p_envelope => l_envelope, p_username => g_username, p_password => g_password );
            l_xml_response := apex_web_service.make_request(
                p_url      => l_url,
                p_version  => l_version,
                p_action   => 'runReport',
                p_envelope => l_envelope --, P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
            );
        end if;
 -- WIP_DEBUG (2, 1059,L_XML_RESPONSE.GETCLOBVAL(),'');
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        wip_debug(2, 1060, '', l_clob_report_decode);
        insert into xxgpms_project_events (
            project_id,
            project_number,
            project_status_code,
            project_name,
            event_id,
            event_num,
            event_desc,
            event_type_code,
            bill_trns_amount,
            bill_trns_currency_code,
            bill_hold_flag,
            revenue_hold_flag,
            invoice_currency_code,
            task_billable_flag,
            task_start_date,
            task_completion_date,
            task_number,
            invoicedstatus,
            project_start_date,
            evnt_completion_date,
            event_internal_comment,
            contract_number,
            contract_line_number,
            fusion_flag,
            evnt_invoice_submitted_count,
            wip_event_tag,
            session_id,
            draft_invoice_number,
            invoice_status_code,
            transfer_status_code,
            wip_category,
            expenditure_type,
            bill_set_num,
            event_type_name,
            task_name
        )
            select
                project_id,
                project_number,
                project_status_code,
                project_name,
                event_id,
                event_num,
                event_desc,
                event_type_code,
                bill_trns_amount,
                bill_trns_currency_code,
                bill_hold_flag,
                revenue_hold_flag,
                invoice_currency_code,
                task_billable_flag,
                task_start_date,
                task_completion_date,
                task_number,
                invoicedstatus,
                project_start_date,
                evnt_completion_date,
                event_internal_comment,
                contract_number,
                contract_line_number,
                'Y',
                evnt_invoice_submitted_count,
                wip_event_tag,
                v('APP_SESSION'),
                invoice_num,
                invoice_status_code,
                transfer_status_code,
                wip_category,
                expenditure_type,
                bill_set_num,
                event_type_name,
                task_name
            from
                xmltable ( '/DATA_DS/G_PROJECT_EVENTS'
                        passing xmltype(l_clob_report_decode)
                    columns
                        project_id path 'PROJECT_ID',
                        project_number path 'SEGMENT1',
                        project_status_code path 'PROJECT_STATUS_CODE',
                        project_name path 'PROJECT_NAME',
                        event_id path 'EVENT_ID',
                        event_num path 'EVENT_NUM',
                        event_desc path 'EVENT_DESC',
                        event_type_code path 'EVENT_TYPE_CODE',
                        bill_trns_amount path 'BILL_TRNS_AMOUNT',
                        bill_trns_currency_code path 'BILL_TRNS_CURRENCY_CODE',
                        bill_hold_flag path 'BILL_HOLD_FLAG',
                        revenue_hold_flag path 'REVENUE_HOLD_FLAG',
                        invoice_currency_code path 'INVOICE_CURRENCY_CODE',
                        task_billable_flag path 'TASK_BILLABLE_FLAG',
                        task_start_date path 'TASK_START_DATE',
                        task_completion_date path 'TASK_COMPLETION_DATE',
                        task_number path 'TASK_NUMBER',
                        invoicedstatus path 'INVOICEDSTATUS',
                        project_start_date path 'PROJECT_START_DATE',
                        evnt_completion_date path 'EVNT_COMPLETION_DATE',
                        event_internal_comment path 'EVENT_INTERNAL_COMMENT',
                        contract_number path 'CONTRACT_NUMBER',
                        contract_line_number path 'CONTRACT_LINE_NUMBER',
                        evnt_invoice_submitted_count path 'EVNT_INVOICE_SUBMITTED_COUNT',
                        wip_event_tag path 'WIP_EVENT_TAG',
                        invoice_num path 'INVOICE_NUM',
                        invoice_status_code path 'INVOICE_STATUS_CODE',
                        transfer_status_code path 'TRANSFER_STATUS_CODE',
                        wip_category path 'ATTRIBUTE2',
                        expenditure_type path 'ATTRIBUTE3',
                        bill_set_num path 'BILL_SET_NUM',
                        event_type_name path 'EVENT_TYPE_NAME',
                        task_name path 'TASK_NAME'
                ) xt;

        dbms_lob.freetemporary(l_clob_report_response);
        dbms_lob.freetemporary(l_clob_report_decode);
        dbms_lob.freetemporary(l_clob_temp);
        apex_web_service.g_request_headers.delete();
        wip_debug(1, 1070, 'Getting Invoice History', '');
        select
            contract_id
        into v_contract_id
        from
            xxgpms_project_contract
        where
                project_number = nvl(p_project_number, project_number)
            and contract_number = nvl(p_agreement_number, contract_number)
            and session_id = v('APP_SESSION')
            and rownum = 1;

        wip_debug(1, 1071, 'Contract ID: ' || v_contract_id, '');
        get_invoice_history(v_contract_id);
        get_matter_credits(v_contract_id);
        get_interprojects(v_contract_id);
        wip_debug(1, 1100, 'End of XX_GPMS.UPDATE_STATUS', '');
    exception
        when others then -- raise_application_error(-20111,'Credentials Error!');
            wip_debug(1, 1999, dbms_utility.format_error_backtrace, '');
    end update_status;

    procedure process_bill_override (
        p_expenditure_item_id in varchar2,
        p_project_number      in varchar2
    ) is

        l_url                        varchar2(4000);
        l_version                    varchar2(10);
        l_response_clob              clob;
        l_envelope                   varchar2(32000);
        p_exp_amt                    number;
        p_internal_comment           varchar2(1000);
        p_narrative_billing_overflow varchar2(1000);
        p_event_attr                 varchar2(50);
        p_standard_bill_rate_attr    number;
        p_project_bill_rate_attr     number;
        p_realized_bill_rate_attr    number;
        p_billable_flag              varchar2(10);
        v_statuscode                 number;
        p_bill_hold_flag             varchar2(100);
    begin
        wip_debug(3, 3000, 'Process Bill Override: ', '');
        l_version := '1.2';
        select
            external_bill_rate,
            replace(internal_comment,
                    chr(10),
                    '\n'),
            replace(narrative_billing_overflow,
                    chr(10),
                    '\n'),
            event_attr,
            standard_bill_rate_attr,
            project_bill_rate_attr,
            realized_bill_rate_attr,
            billable_flag,
            decode(bill_hold_flag, 'O', 'ONE_TIME_HOLD', 'Y', 'BILL_HOLD',
                   'N', 'REMOVE_BILL_HOLD')
        into
            p_exp_amt,
            p_internal_comment,
            p_narrative_billing_overflow,
            p_event_attr,
            p_standard_bill_rate_attr,
            p_project_bill_rate_attr,
            p_realized_bill_rate_attr,
            p_billable_flag,
            p_bill_hold_flag
        from
            xxgpms_project_costs
        where
                expenditure_item_id = p_expenditure_item_id
            and session_id = v('APP_SESSION')
            and project_number = nvl(p_project_number, project_number)
            and rownum < 2;
 --- Update External Bill Rate -------
 -- L_URL := INSTANCE_URL
 --          || '/fscmRestApi/resources/11.13.18.05/projectExpenditureItems/'
 --          || P_EXPENDITURE_ITEM_ID;
 -- L_ENVELOPE := '{"ExternalBillRate" : "'
 --               || TO_CHAR(P_EXP_AMT)
 --               || '",
 --             "ExternalBillRateCurrency" :   "USD",
 --             "ExternalBillRateSourceName" : "PEI_REST",
 --             "ExternalBillRateSourceReference" : "abc"}';
 -- APEX_WEB_SERVICE.G_REQUEST_HEADERS(1).NAME := 'Content-Type';
 -- APEX_WEB_SERVICE.G_REQUEST_HEADERS(1).VALUE := 'application/json';
 -- WIP_DEBUG(3, 3025, L_ENVELOPE, '');
 -- L_RESPONSE_CLOB := APEX_WEB_SERVICE.MAKE_REST_REQUEST(P_URL => L_URL, P_HTTP_METHOD => 'PATCH',
 -- 					--	p_username => g_username,
 -- 					--	p_password => g_password,
 --  P_CREDENTIAL_STATIC_ID => 'GPMS_DEV', P_BODY => L_ENVELOPE);
 -- APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE();
 -- WIP_DEBUG(2, 3050, '', L_RESPONSE_CLOB);
 ---Update Billable Flag ------
        l_url := instance_url
                 || '/fscmRestApi/resources/11.13.18.05/projectCosts/'
                 || p_expenditure_item_id
                 || '/action/adjustProjectCosts';
        if p_billable_flag = 'Y' then
            l_envelope := '{"AdjustmentType" : "Set to Billable"}';
        else
            l_envelope := '{"AdjustmentType" : "Set to nonbillable"}';
        end if;

        wip_debug(2, 3008, '', l_url);
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/vnd.oracle.adf.action+json';
        l_response_clob := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'POST',
 --p_username => g_username,
 --p_password => g_password,
 -- P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
            p_body        => l_envelope,
            p_scheme      => 'OAUTH_CLIENT_CRED'
        );

        apex_web_service.g_request_headers.delete();
        wip_debug(2, 3100, '', l_response_clob);
 ---- Update Billable Flag Done --------
        l_url := instance_url
                 || '/fscmRestApi/resources/11.13.18.05/projectExpenditureItems/'
                 || p_expenditure_item_id
                 || '/child/ProjectExpenditureItemsDFF/'
                 || p_expenditure_item_id;
        l_envelope := '{"internalComment" : "'
                      || p_internal_comment
                      || '",
                    "narrativeBillingOverflow1" : "'
                      || p_narrative_billing_overflow
                      || '" ,
                    "event" : "'
                      || p_event_attr
                      || '" ,
                    "standardBillRate" : "'
                      || p_standard_bill_rate_attr
                      || '",
                    "projectBillRate" : "'
                      || p_project_bill_rate_attr
                      || '",
                    "realizedBillRate" : "'
                      || p_realized_bill_rate_attr
                      || '"
                   }';

        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        l_response_clob := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'PATCH',
 --p_username => g_username,
 --p_password => g_password,
 -- P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
            p_scheme      => 'OAUTH_CLIENT_CRED',
            p_body        => l_envelope
        );

        v_statuscode := apex_web_service.g_status_code;
        apex_web_service.g_request_headers.delete();
        wip_debug(2, 3200, l_url, '');
        wip_debug(2, 3250, l_envelope, '');
        wip_debug(2, 3300, '', l_response_clob);
        wip_debug(2, 3350, v_statuscode, '');
    end process_bill_override;

    procedure process_events_override (
        p_event_id in varchar2
    ) is

        l_url                    varchar2(4000);
        l_version                varchar2(10);
        l_response_clob          clob;
        l_envelope               varchar2(32000);
        p_bill_trns_amount       number;
        p_task_completion_date   date;
        p_event_desc             varchar2(10000);
        p_bill_hold_flag         varchar2(1);
        p_event_internal_comment varchar2(10000);
    begin
        l_version := '1.2';
        select
            bill_trns_amount,
            evnt_completion_date,
            event_desc,
            bill_hold_flag,
            event_internal_comment
        into
            p_bill_trns_amount,
            p_task_completion_date,
            p_event_desc,
            p_bill_hold_flag,
            p_event_internal_comment
        from
            xxgpms_project_events
        where
                event_id = p_event_id
            and session_id = v('APP_SESSION');
 --- Update External Bill Rate -------
        l_url := instance_url
                 || '/fscmRestApi/resources/11.13.18.05/projectBillingEvents/'
                 || p_event_id;
        l_envelope := '{"EventDescription" : "'
                      || p_event_desc
                      || '",
	        	    "BillTrnsAmount" :  '
                      || p_bill_trns_amount
                      || ',
		            "BillHold" : "'
                      || p_bill_hold_flag
                      || '"}';
 --	            "CompletionDate" : "' || to_char(p_task_completion_date,'YYYY-MM-DD') || '"}';
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        l_response_clob := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'PATCH',
 --p_username => g_username,
 --p_password => g_password,
 -- P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
            p_scheme      => 'OAUTH_CLIENT_CRED',
            p_body        => l_envelope
        );

        apex_web_service.g_request_headers.delete();
        wip_debug(2, 3500, l_url, '');
        wip_debug(2, 3550, l_envelope, '');
        wip_debug(2, 3560, '', l_response_clob);
        l_url := instance_url
                 || '/fscmRestApi/resources/11.13.18.05/projectBillingEvents/'
                 || p_event_id
                 || '/child/billingEventDFF/'
                 || p_event_id;
        l_envelope := '{"internalComment" : "'
                      || p_event_internal_comment
                      || '"}';
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        l_response_clob := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'PATCH',
 --p_username => g_username,
 --p_password => g_password,
 -- P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
            p_scheme      => 'OAUTH_CLIENT_CRED',
            p_body        => l_envelope
        );

        apex_web_service.g_request_headers.delete();
    end process_events_override;

    procedure xx_process_hold (
        p_project_number  in varchar2,
        p_contract_number in varchar2 default null,
        p_exp_id          in varchar2 default null
    ) is

        l_row_count pls_integer;
        l_values    apex_json.t_values;
        l_exp_id    varchar2(4000);
        cursor exps_cur (
            cur_proj_number in varchar2,
            cur_exp_id      in varchar2
        ) is
        select
            *
        from
            xxgpms_project_costs
        where
                project_number = nvl(cur_proj_number, project_number)
            and contract_number = nvl(p_contract_number, contract_number)
            and expenditure_item_id in (
                select
                    *
                from
                    table ( apex_string.split(cur_exp_id, ',') )
            )
            and session_id = v('APP_SESSION');

        cursor events_cur (
            cur_proj_number in varchar2
        ) is
        select
            *
        from
            xxgpms_project_events
        where
                project_number = cur_proj_number
            and session_id = v('APP_SESSION');

    begin
        wip_debug(3, 2000, 'Process Hold: '
                           || p_project_number
                           || ' EXP '
                           || p_exp_id, '');

        progress_entries_logger(1, 'Entered');
        dbms_session.sleep(5);
        progress_entries_logger(5, 'Performing Process Bill Override.');
 -- SEND THE EXP ID TO THE CURSOR
        if ( p_exp_id is not null ) then
            apex_json.parse(
                p_values => l_values,
                p_source => p_exp_id
            );
            l_row_count := apex_json.get_count(
                p_path   => 'expids',
                p_values => l_values
            );
            l_exp_id := null;
            for i in 1..l_row_count loop
                l_exp_id := l_exp_id
                            || ','
                            || apex_json.get_varchar2(
                    p_path   => 'expids[%d].EXP_ID',
                    p0       => i,
                    p_values => l_values
                );
            end loop;

            l_exp_id := ltrim(l_exp_id, ',');
        end if;

        wip_debug(3, 2001, 'EXPID: ' || l_exp_id, '');
        for rec in exps_cur(p_project_number, l_exp_id) loop
            xx_gpms.process_bill_override(rec.expenditure_item_id, p_project_number);
        end loop;

        progress_entries_logger(50, 'Process Bill Override Complete.');
        dbms_session.sleep(5);
        progress_entries_logger(52, 'Performing Process Events Override.');
        for rec in events_cur(p_project_number) loop
 --   XX_GPMS.PROCESS_EVENTS_OVERRIDE (REC.EVENT_ID);
            null;
        end loop;
        progress_entries_logger(90, 'Process Events Override Complete.');
        progress_entries_logger(100, 'Process Complete.');
    end xx_process_hold;

    procedure generate_ar_credit (
        p_project_number in varchar2
    ) is
    begin
        null;
    end generate_ar_credit;

    function submit_parallel_ess_job (
        p_business_unit         varchar2,
        p_business_unit_id      number,
        p_transaction_source_id number,
        p_document_id           number,
        p_expenditure_batch     number
    ) return number is

        l_url           varchar2(4000);
        l_envelope      varchar2(32000);
        l_response_clob clob;
        l_sversion      varchar2(100) := '1.1';
        l_senvelope     clob;
        l_sresponse_xml xmltype;
    begin
        wip_debug(2, 4340, 'INSIDE', '');
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
        l_url := instance_url || ':443/fscmService/ErpIntegrationService';
        wip_debug(2, 4345, l_url, '');
        l_senvelope := q'#<?xml version="1.0" encoding="UTF-8"?>#';
        l_senvelope := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/">
                        <soapenv:Header/>
                            <soapenv:Body>
                                <typ:submitESSJobRequest>
                                    <typ:jobPackageName>/oracle/apps/ess/projects/costing/transactions/onestop</typ:jobPackageName>
                                    <typ:jobDefinitionName>ImportProcessParallelEssJob</typ:jobDefinitionName>
                                    <typ:paramList>'
                       || p_business_unit
                       || '</typ:paramList>
                                    <typ:paramList>'
                       || p_business_unit_id
                       || '</typ:paramList>
                                    <typ:paramList>IMPORT_AND_PROCESS</typ:paramList>
                                    <typ:paramList>PREV_NOT_IMPORTED</typ:paramList>
                                    <typ:paramList>#NULL</typ:paramList>
                                    <typ:paramList>'
                       || p_transaction_source_id
                       || '</typ:paramList>
                                    <typ:paramList>'
                       || p_document_id
                       || '</typ:paramList>
                                    <typ:paramList>'
                       || p_expenditure_batch
                       || '</typ:paramList>
                                    <typ:paramList>#NULL</typ:paramList>
                                    <typ:paramList>#NULL</typ:paramList>
                                    <typ:paramList>#NULL</typ:paramList>
                                    <typ:paramList>#NULL</typ:paramList>
                                    <typ:paramList>ORA_PJC_SUMMARY</typ:paramList>
                                </typ:submitESSJobRequest>
                            </soapenv:Body>
                        </soapenv:Envelope>';

        wip_debug(2, 4350, l_sversion, '');
        wip_debug(2, 4400, l_senvelope, '');
 --l_sresponse_xml := apex_web_service.make_request ( p_url => l_url, p_version => l_sversion, p_action => 'submitESSJobRequest', p_envelope => l_senvelope, p_username => g_username, p_password => g_password );
        l_sresponse_xml := apex_web_service.make_request(
            p_url      => l_url,
            p_version  => l_sversion,
            p_action   => 'submitESSJobRequest',
            p_envelope => l_senvelope
 -- ,P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
    -- ,P_SCHEME => 'OAUTH_CLIENT_CRED'
        );

        wip_debug(2,
                  4450,
                  '',
                  l_sresponse_xml.getclobval());
        wip_debug(2, 4460, apex_web_service.g_status_code, '');
        return apex_web_service.g_status_code;
    end;

    function post_justification (
        p_justification varchar2,
        p_response_code out number
    ) return number is
    begin
        null;
    end;

    function process_transfer_split (
        p_expenditure_item_list in varchar2,
        project_number          in varchar2,
        p_justification         in varchar2 default null,
        p_total_hours           in number default 0
    ) return varchar2 is

        input_str                    varchar2(32000);
        var1                         number;
        temp_str                     varchar2(32000);
        exp_id                       varchar2(100);
        v_project_split_num          number := 0;
        l_url                        varchar2(4000);
        l_envelope                   varchar2(32000);
        l_response_clob              clob;
        l_sversion                   varchar2(100) := '1.1';
        l_senvelope                  clob;
        l_sresponse_xml              xmltype;
        l_quantity                   number;
        l_project_number             varchar2(100);
        l_task_number                varchar2(100);
        v_business_unit              varchar2(100);
        v_business_unit_id           number;
        v_user_transaction_source    varchar2(100);
        v_transaction_source_id      number;
        v_expenditure_batch          varchar2(100);
        v_session_id                 number;
        v_transaction_source         varchar2(100);
        v_document                   varchar2(100);
        v_document_entry             varchar2(100);
        v_status                     varchar2(100);
        v_quantity                   number;
        v_original_quantity          number;
        v_unit_of_measure            varchar2(100);
        v_person_name                varchar2(100);
        v_project_number             varchar2(100);
        v_task_number                varchar2(100);
        v_expenditure_type_name      varchar2(100);
        v_document_name              varchar2(100);
        v_doc_entry_name             varchar2(100);
        v_unmatched_flag             varchar2(1) := 'Y';
        v_orig_transaction_reference varchar2(100);
        v_exp_item_date              date;
        v_document_id                number;
        v_exp_org_id                 number;
        v_expenditure_comment        varchar2(1000);
        v_statuscode                 number;
        v_exp_id                     number;
        l_percentage                 number;
        v_response                   clob;
        v_response_code              number;
        v_billable_flag              varchar2(1000);
        v_postings_success           varchar2(10) := 'N';
        cursor c_project_split_cur is
        select
            project_number,
            task_number,
            quantity,
            percentage
        from
            xxgpms_project_split
        where
                session_id = v('APP_SESSION')
            and action = 'MULTI_SPLIT_TRANS';

    begin
        wip_debug(3, 4000, 'Process Transfer Split: ' || project_number, '');
        select
            bu_name,
            business_unit_id
        into
            v_business_unit,
            v_business_unit_id
        from
            xxgpms_project_contract
        where
                rownum = 1
            and session_id = v('APP_SESSION')
            and project_number = project_number;

        wip_debug(2, 4100, v_business_unit, '');
        for i in (
            select
                column_value exp_id
            from
                table (
                    select
                        apex_string.split(
                            ltrim(p_expenditure_item_list, '-'),
                            '-'
                        )
                    from
                        dual
                )
        ) loop
            wip_debug(2, 4105, 'Expenditure Item ID ' || i.exp_id, '');
            select
                v('APP_SESSION'),
                transaction_source,
                document_name,
                doc_entry_name,
                'Pending',
                - 1 * quantity,
                quantity,
                unit_of_measure,
                person_name,
                task_number,
                project_number,
                expenditure_type_name,
                orig_transaction_reference,
                expenditure_item_date,
                transaction_source_id,
                document_id,
                exp_org_id,
                expenditure_comment,
                case billable_flag
                    when 'Y' then
                        'Set to Billable'
                    when 'N' then
                        'Set to nonbillable'
                end
            into
                v_expenditure_batch,
                v_transaction_source,
                v_document,
                v_document_entry,
                v_status,
                v_quantity,
                v_original_quantity,
                v_unit_of_measure,
                v_person_name,
                v_task_number,
                v_project_number,
                v_expenditure_type_name,
                v_orig_transaction_reference,
                v_exp_item_date,
                v_transaction_source_id,
                v_document_id,
                v_exp_org_id,
                v_expenditure_comment,
                v_billable_flag
            from
                xxgpms_project_costs
            where
                    session_id = v('APP_SESSION')
                and expenditure_item_id = i.exp_id;

            l_url := instance_url
                     || '/fscmRestApi/resources/11.13.18.05/projectCosts/'
                     || i.exp_id
                     || '/action/adjustProjectCosts';
            l_envelope := q'#{
        "AdjustmentTypeCode": "REVERSE",
        "ProjectNumber": "#'
                          || v_project_number
                          || q'#",
        "TaskNumber": "#'
                          || v_task_number
                          || q'#",
        "Justification": "#'
                          || p_justification
                          || q'#",
        "Quantity" : "#'
                          || v_original_quantity
                          || q'#"
        }#';

            apex_web_service.g_request_headers(1).name := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'application/vnd.oracle.adf.action+json';
            wip_debug(2, 4150, l_url, '');
            wip_debug(2, 4200, l_envelope, '');
            l_response_clob := apex_web_service.make_rest_request(
                p_url         => l_url,
                p_http_method => 'POST',
                p_scheme      => 'OAUTH_CLIENT_CRED',
                p_body        => l_envelope
            );

            wip_debug(2, 4250, '', l_response_clob);
            wip_debug(3, 4260, apex_web_service.g_status_code, '');

    -- PERFORM_UNPROCESSED_COSTS_CALL(P_EXPENDITURE_ITEM_ID => I.EXP_ID
    --                                , P_REVERSAL => 'Y'
    --                                ,P_INTERNAL_COMMENT=>P_JUSTIFICATION
    --                                ,P_RESPONSE => V_RESPONSE
    --                                ,P_RESPONSE_CODE => V_RESPONSE_CODE);

            if ( apex_web_service.g_status_code in ( 200, 201 ) ) -- Negative Transaction Post is success

             then
    -- 2. Update the Justification on the expenditure item

                v_statuscode := update_project_lines_dff(i.exp_id, p_justification);
                if v_statuscode in ( 200, 201 ) then
      -- 3. Post the Split Add Transactions

    -- OPEN C_PROJECT_SPLIT_CUR;
    -- LOOP
    --   FETCH C_PROJECT_SPLIT_CUR INTO L_PROJECT_NUMBER, L_TASK_NUMBER, L_QUANTITY,L_PERCENTAGE;
    --   IF NVL(L_QUANTITY,0) = 0
    --   THEN
    --     L_QUANTITY := V_ORIGINAL_QUANTITY *(L_PERCENTAGE/100);
    --   END IF;
    --   EXIT WHEN C_PROJECT_SPLIT_CUR % NOTFOUND;
                    for j in (
                        select
                            *
                        from
                            xxgpms_project_split
                        where
                                session_id = v('APP_SESSION')
                            and action = 'MULTI_SPLIT_TRANS'
                    ) loop
                        l_project_number := j.project_number;
                        l_task_number := j.task_number;
                        l_quantity :=
                            case
                                when j.quantity is null then
                                    v_original_quantity * ( j.percentage / 100 )
                                else j.quantity
                            end;

                        l_percentage := j.percentage;
                        v_project_split_num := v_project_split_num + 1;
                        l_url := instance_url || '/fscmRestApi/resources/11.13.18.05/unprocessedProjectCosts';
                        l_envelope := '{"ExpenditureBatch" : "'
                                      || v_expenditure_batch
                                      || '",
                              "TransactionSource" : "'
                                      || v_transaction_source
                                      || '",
                              "BusinessUnit" : "'
                                      || v_business_unit
                                      || '",
                              "Document" : "'
                                      || v_document
                                      || '",
                              "DocumentEntry" : "'
                                      || v_document_entry
                                      || '",
                              "Status" : "'
                                      || v_status
                                      || '",
                              "Quantity" : "'
                                      || l_quantity
                                      || '",
                              "UnitOfMeasureCode" : "'
                                      || v_unit_of_measure
                                      || '",
                              "PersonName" : "'
                                      || v_person_name
                                      || '",
                              "OriginalTransactionReference" : "'
                                      || 'WIP-'
                                      || xxgpms_trans_seq.nextval
                                      || '",
                              "Comment" : "'
                                      || v_expenditure_comment
                                      || '",
                              "ProjectStandardCostCollectionFlexfields" : ['
                                      || '{
                                                                                  "_EXPENDITURE_ITEM_DATE" : "'
                                      || to_char(v_exp_item_date, 'YYYY-MM-DD')
                                      || '",

                               "_ORGANIZATION_ID" : "'
                                      || v_exp_org_id
                                      || '",
                                                                                  "_PROJECT_ID_Display" : "'
                                      || l_project_number
                                      || '",
                                                                                  "_TASK_ID_Display" : "'
                                      || l_task_number
                                      || '",
                                                                                  "_EXPENDITURE_TYPE_ID_Display" : "'
                                      || v_expenditure_type_name
                                      || '"}] }';

                        wip_debug(2, 4300, '', l_url);
                        wip_debug(2, 4305, '', l_envelope);
                        l_response_clob := apex_web_service.make_rest_request(
                            p_url         => l_url,
                            p_http_method => 'POST',
                            p_scheme      => 'OAUTH_CLIENT_CRED',
                            p_body        => l_envelope
                        );

                        wip_debug(2, 4306, '', l_response_clob);
                        wip_debug(3, 4310, apex_web_service.g_status_code, '');
                        if apex_web_service.g_status_code not in ( 200, 201 ) then
                            return '</br> Posting for Project: '
                                   || l_project_number
                                   || ' Task Number '
                                   || l_task_number
                                   || ' and Quantity '
                                   || l_quantity
                                   || ' failed: '
                                   || l_response_clob;

                            exit;
                        else
                            v_postings_success := 'Y';
                        end if;

                    end loop; -- End of Split and Transfers Loop
                else
                    return '</br> Justification Update of Reversal Expenditure Item ID: '
                           || i.exp_id
                           || ' failed: '
                           || l_response_clob;
                end if;

            else
                return '</br> Reversal of Expenditure Item ID: '
                       || i.exp_id
                       || ' failed: '
                       || l_response_clob;
            end if;

        end loop; -- Expenditures Loop

        if v_postings_success = 'Y' then
            wip_debug(3, 4311, 'Postings are success, calling ESS job', '');
            for i in (
                select distinct
                    transaction_source_id,
                    document_id
                from
                    xxgpms_project_costs
                where
                        session_id = v('APP_SESSION')
                    and expenditure_item_id in (
                        select
                            column_value exp_id
                        from
                            table (
                                select
                                    apex_string.split(
                                        ltrim(p_expenditure_item_list, '-'),
                                        '-'
                                    )
                                from
                                    dual
                            )
                    )
            ) loop
                wip_debug(3, 4315, 'Started for transaction source id '
                                   || i.transaction_source_id
                                   || ' document ID '
                                   || i.document_id, '');

                v_statuscode := submit_parallel_ess_job(v_business_unit,
                                                        v_business_unit_id,
                                                        i.transaction_source_id,
                                                        i.document_id,
                                                        v('APP_SESSION'));

                wip_debug(3, 4320, v_statuscode, '');
            end loop;

        end if;

    end process_transfer_split;

    function process_transfer_or_split (
        p_expenditure_item_list  in varchar2,
        project_number           in varchar2,
        p_justification          in varchar2 default null,
        p_destination_project    in varchar2 default null,
        p_destination_tasknumber in varchar2 default null,
        p_destination_quantity   in number default null,
        p_total_hours            in number default 0
    ) return varchar2 is

        input_str                    varchar2(32000);
        var1                         number;
        temp_str                     varchar2(32000);
        exp_id                       varchar2(100);
        v_project_split_num          number := 0;
        l_url                        varchar2(4000);
        l_envelope                   varchar2(32000);
        l_response_clob              clob;
        l_sversion                   varchar2(100) := '1.1';
        l_senvelope                  clob;
        l_sresponse_xml              xmltype;
        l_quantity                   number;
        l_project_number             varchar2(100);
        l_task_number                varchar2(100);
        p_business_unit              varchar2(100);
        p_business_unit_id           number;
        p_user_transaction_source    varchar2(100);
        p_transaction_source_id      number;
        p_expenditure_batch          varchar2(100);
        p_session_id                 number;
        p_transaction_source         varchar2(100);
        p_document                   varchar2(100);
        p_document_entry             varchar2(100);
        p_status                     varchar2(100);
        p_quantity                   number;
        p_unit_of_measure            varchar2(100);
        p_person_name                varchar2(100);
        p_project_number             varchar2(100);
        p_task_number                varchar2(100);
        p_expenditure_type_name      varchar2(100);
        p_document_name              varchar2(100);
        p_doc_entry_name             varchar2(100);
        p_unmatched_flag             varchar2(1) := 'Y';
        p_orig_transaction_reference varchar2(100);
        p_exp_item_date              date;
        p_document_id                number;
        p_exp_org_id                 number;
        p_expenditure_comment        varchar2(1000);
        v_statuscode                 number;
        v_exp_id                     number;
        cursor c_project_split_cur is
        select
            project_number,
            task_number,
            quantity
        from
            xxgpms_project_split
        where
                session_id = v('APP_SESSION')
            and action = 'MULTI_SPLIT_TRANS';

    begin
        wip_debug(3, 4000, 'Process Transfer Split: ' || project_number, '');
        wip_debug(2, 4050, 'Expenditure Item List ' || p_expenditure_item_list, '');
        select
            bu_name,
            business_unit_id
    --   USER_TRANSACTION_SOURCE,
    --   TRANSACTION_SOURCE_ID
        into
            p_business_unit,
            p_business_unit_id
    --   P_USER_TRANSACTION_SOURCE,
    --   P_TRANSACTION_SOURCE_ID
        from
            xxgpms_project_contract
        where
                rownum = 1
            and session_id = v('APP_SESSION')
            and project_number = project_number;

        wip_debug(2, 4100, p_business_unit
                           || '-'
                           || p_user_transaction_source, '');

    -- WHILE (VAR1 > 0) LOOP
    -- FOR I IN (SELECT COLUMN_VALUE EXP_ID FROM TABLE(SELECT APEX_STRING.SPLIT(ltrim(P_EXPENDITURE_ITEM_LIST,'-'),'-') FROM DUAL)
            --  )
    -- LOOP
        select
            v('APP_SESSION'),
            transaction_source,
            document_name,
            doc_entry_name,
            'Pending',
            - 1 * quantity,
            unit_of_measure,
            person_name,
            task_number,
            project_number,
            expenditure_type_name,
            orig_transaction_reference,
            expenditure_item_date,
            transaction_source_id,
            document_id,
            exp_org_id,
            expenditure_comment
        into
            p_expenditure_batch,
            p_transaction_source,
            p_document,
            p_document_entry,
            p_status,
            p_quantity,
            p_unit_of_measure,
            p_person_name,
            p_task_number,
            p_project_number,
            p_expenditure_type_name,
            p_orig_transaction_reference,
            p_exp_item_date,
            p_transaction_source_id,
            p_document_id,
            p_exp_org_id,
            p_expenditure_comment
        from
            xxgpms_project_costs
        where
                session_id = v('APP_SESSION')
        -- AND ROWNUM <2
            and expenditure_item_id = p_expenditure_item_list;

    --   SELECT CASE WHEN P_UNIT_OF_MEASURE IN ('HOURS','Hours') then
    --          'Time Card'
    --          else
    --          'Miscellaneous Expenditure'
    --          end
    --   into   P_DOCUMENT
    --   FROM   DUAL;

    --    SELECT CASE WHEN P_UNIT_OF_MEASURE IN ('HOURS','Hours') then
    --          'Professional Time'
    --          else
    --          'Miscellaneous Expenditure'
    --          end
    --   into   P_DOCUMENT_ENTRY
    --   FROM   DUAL;

        l_url := instance_url || '/fscmRestApi/resources/11.13.18.05/unprocessedProjectCosts';
        l_envelope := '{"ExpenditureBatch" : "'
                      || p_expenditure_batch
                      || '",
                              "TransactionSource" : "'
                      || p_transaction_source
                      || '",
                              "BusinessUnit" : "'
                      || p_business_unit
                      || '",
                              "Document" : "'
                      || p_document
                      || '",
                              "DocumentEntry" : "'
                      || p_document_entry
                      || '",
                              "Status" : "'
                      || p_status
                      || '",
                              "Quantity" : "'
                      || p_quantity
                      || '",
                              "UnitOfMeasureCode" : "'
                      || p_unit_of_measure
                      || '",
                              "PersonName" : "'
                      || p_person_name
                      || '",
                              "ReversedOriginalTransactionReference" : "'
                      || p_orig_transaction_reference
                      || '",
                              "OriginalTransactionReference" : "'
                      || regexp_replace(p_orig_transaction_reference, '*-[0-9]*', '-' || xxgpms_trans_seq.nextval)
                      || '",
                         "UnmatchedNegativeTransactionFlag" : "false",
                          "Comment" : "'
                      || p_expenditure_comment
                      || '",
                              "ProjectStandardCostCollectionFlexfields" : ['
                      || '{
                                                                                  "_EXPENDITURE_ITEM_DATE" : "'
                      || to_char(p_exp_item_date, 'YYYY-MM-DD')
                      || '",

                               "_ORGANIZATION_ID" : "'
                      || p_exp_org_id
                      || '",
                                                                                  "_PROJECT_ID_Display" : "'
                      || p_project_number
                      || '",
                                                                                  "_TASK_ID_Display" : "'
                      || p_task_number
                      || '",
                                                                                  "_EXPENDITURE_TYPE_ID_Display" : "'
                      || p_expenditure_type_name
                      || '"}] }';

        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        wip_debug(2, 4150, l_url, '');
        wip_debug(2, 4200, l_envelope, '');
        l_response_clob := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'POST',
        --p_username => g_username,
        --p_password => g_password,
        -- P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
            p_scheme      => 'OAUTH_CLIENT_CRED',
            p_body        => l_envelope
        );

        wip_debug(2, 4250, '', l_response_clob);
        wip_debug(3, 4260, apex_web_service.g_status_code, '');

    -- END LOOP;

        if ( apex_web_service.g_status_code in ( 200, 201 ) ) -- Negative Transaction Post is success

         then
    -- 2. Update the Justification on the expenditure item

            v_statuscode := update_project_lines_dff(p_expenditure_item_list, p_justification);
            if v_statuscode in ( 200, 201 ) then
      -- 3. Post the Split Add Transactions

                open c_project_split_cur;
                loop
                    fetch c_project_split_cur into
                        l_project_number,
                        l_task_number,
                        l_quantity;
                    exit when c_project_split_cur%notfound;
      -- L_PROJECT_NUMBER := P_DESTINATION_PROJECT;
      -- L_TASK_NUMBER  := P_DESTINATION_TASKNUMBER;
      -- L_QUANTITY := P_DESTINATION_QUANTITY;

                    v_project_split_num := v_project_split_num + 1;
                    l_envelope := '{"ExpenditureBatch" : "'
                                  || p_expenditure_batch
                                  || '",
                              "TransactionSource" : "'
                                  || p_transaction_source
                                  || '",
                              "BusinessUnit" : "'
                                  || p_business_unit
                                  || '",
                              "Document" : "'
                                  || p_document
                                  || '",
                              "DocumentEntry" : "'
                                  || p_document_entry
                                  || '",
                              "Status" : "'
                                  || p_status
                                  || '",
                              "Quantity" : "'
                                  || l_quantity
                                  || '",
                              "UnitOfMeasureCode" : "'
                                  || p_unit_of_measure
                                  || '",
                              "PersonName" : "'
                                  || p_person_name
                                  || '",
                              "OriginalTransactionReference" : "'
                                  || 'WIP-'
                                  || xxgpms_trans_seq.nextval
                                  || '",
                              "Comment" : "'
                                  || p_expenditure_comment
                                  || '",
                              "ProjectStandardCostCollectionFlexfields" : ['
                                  || '{
                                                                                  "_EXPENDITURE_ITEM_DATE" : "'
                                  || to_char(p_exp_item_date, 'YYYY-MM-DD')
                                  || '",

                               "_ORGANIZATION_ID" : "'
                                  || p_exp_org_id
                                  || '",
                                                                                  "_PROJECT_ID_Display" : "'
                                  || l_project_number
                                  || '",
                                                                                  "_TASK_ID_Display" : "'
                                  || l_task_number
                                  || '",
                                                                                  "_EXPENDITURE_TYPE_ID_Display" : "'
                                  || p_expenditure_type_name
                                  || '"}] }';

                    l_response_clob := apex_web_service.make_rest_request(
                        p_url         => l_url,
                        p_http_method => 'POST',
        --p_username => g_username,
        --p_password => g_password,
        -- P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
                        p_scheme      => 'OAUTH_CLIENT_CRED',
                        p_body        => l_envelope
                    );

                    wip_debug(2, 4300, '', l_response_clob);
                    wip_debug(3, 4310, apex_web_service.g_status_code, '');
                    if apex_web_service.g_status_code not in ( 200, 201 ) then
                        return '</br> Posting for Project: '
                               || l_project_number
                               || ' Task Number '
                               || l_task_number
                               || ' and Quantity '
                               || l_quantity
                               || ' failed: '
                               || l_response_clob;

                        exit;
                    end if;

                end loop;

                if apex_web_service.g_status_code in ( 200, 201 ) then
                    v_statuscode := submit_parallel_ess_job(p_business_unit, p_business_unit_id, p_transaction_source_id, p_document_id
                    , p_expenditure_batch);
                    wip_debug(3, 4320, v_statuscode, '');
                end if;

                delete from xxgpms_project_split
                where
                    session_id = v('APP_SESSION');

                return 0;
                wip_debug(3, 4321, 'Completed', '');
            else
                return '</br> Justification Update of Reversal Expenditure Item ID: '
                       || p_expenditure_item_list
                       || ' failed: '
                       || l_response_clob;
            end if;

        else
            return '</br> Reversal of Expenditure Item ID: '
                   || p_expenditure_item_list
                   || ' failed: '
                   || l_response_clob;
        end if;

    end process_transfer_or_split;
---
    procedure wip_adjust_wrapper (
        p_expenditure_item_list in varchar2,
        p_project_number        in varchar2,
        p_adj_pct               in number default null,
        p_adj_amt               in number default null,
        p_sel_amt               in number default null,
        p_adjusted_hours        in number default null,
        p_attribute             in varchar2 default null,
        p_attribute_value       in varchar2 default null,
        p_justification         in varchar2,
        p_response_code         out number,
        p_response              out varchar2
    ) is
        v_hold_code varchar2(1000);
        v_response  clob;
        v_status    number;
    begin
    -- UPDATING BILL HOLD ATTRIBUTE
        wip_debug(2, 20100, 'Entered into WIP_ADJUST_WRAPPER with the values of P_EXPENDITURE_ITEM_LIST: '
                            || p_expenditure_item_list
                            || ' P_PROJECT_NUMBER: '
                            || p_project_number
                            || ' P_ADJ_PCT: '
                            || p_adj_pct
                            || ' P_ADJ_AMT: '
                            || p_adj_amt
                            || ' P_SEL_AMT: '
                            || p_sel_amt
                            || ' P_ADJUSTED_HOURS: '
                            || p_adjusted_hours
                            || ' P_ATTRIBUTE: '
                            || p_attribute
                            || ' P_ATTRIBUTE_VALUE: '
                            || p_attribute_value
                            || ' P_JUSTIFICATION :'
                            || p_justification, '');

        if p_attribute = 'H' then
            v_hold_code :=
                case p_attribute_value
                    when 'Once' then
                        'ONE_TIME_HOLD'
                    when 'Until Released' then
                        'BILL_HOLD'
                    when 'Release Hold' then
                        'REMOVE_BILL_HOLD'
                    when 'Bill Only' then
                        'ONE_TIME_HOLD'
                end;

            xx_gpms.perform_adjust_project_costs(
                p_expenditure_item_id  => p_expenditure_item_list,
                p_adjustment_type_code => v_hold_code,
                p_justification        => p_justification,
                p_response             => v_response,
                p_response_code        => v_status
            );      

    -- CANCEL THE LINE  
        elsif p_attribute = 'C' then
            xx_gpms.perform_adjust_project_costs(
                p_expenditure_item_id  => p_expenditure_item_list,
                p_adjustment_type_code => 'REVERSE',
                p_justification        => p_justification,
                p_response             => v_response,
                p_response_code        => v_status
            );

    -- UPDATE THE EXPENDITURE TYPE                  
        elsif p_attribute = 'E' then
            xx_gpms.perform_adjust_project_costs(
                p_expenditure_item_id  => p_expenditure_item_list,
                p_adjustment_type_code => 'TRANSFER',
                p_expenditure_type     => p_attribute_value,
                p_justification        => p_justification,
                p_response             => v_response,
                p_response_code        => v_status
            );   

    -- UPDATE THE BILLABLE FLAG
        elsif p_attribute = 'B' then
            xx_gpms.perform_adjust_project_costs(
                p_expenditure_item_id => p_expenditure_item_list,
                p_adjustment_type     =>
                                   case initcap(p_attribute_value)
                                       when 'Yes' then
                                           'Set to Billable'
                                       when 'No'  then
                                           'Set to nonbillable'
                                   end,
                p_justification       => p_justification,
                p_response            => v_response,
                p_response_code       => v_status
            );   

    -- HOURS ADJUSTMENT                                         
        elsif
            p_attribute is null
            and p_adjusted_hours is not null
        then
            xx_gpms.wip_adjust_hours(
                p_expenditure_item_id => p_expenditure_item_list,
                p_adjusted_hours      => p_adjusted_hours,
                p_justification       => p_justification,
                p_response_code       => v_status,
                p_response            => v_response
            );
    
    -- AMOUNT OR DISCOUNT ADJUSTMENT                               
        elsif
            p_attribute is null
            and p_adjusted_hours is null
        then
            v_status := xx_gpms.wip_tag_adjustment(
                p_expenditure_item_list => p_expenditure_item_list,
                p_project_number        => p_project_number,
                p_adj_pct               => p_adj_pct,
                p_adj_amt               => p_adj_amt,
                p_sel_amt               => p_sel_amt,
                p_billable_flag         => 'Y',
                p_justification_comment => p_justification
            );
        end if;

        wip_debug(2, 20101, 'Final Response V_RESPONSE: '
                            || v_response
                            || ' V_STATUS: '
                            || v_status, '');

        p_response := v_response;
        p_response_code := v_status;
    end;

    procedure wip_adjust_hours (
        p_expenditure_item_id in varchar2,
        p_adjusted_hours      in number,
        p_justification       in varchar2,
        p_response_code       out number,
        p_response            out varchar2
    ) is
        v_response              clob;
        v_response_code         number;
        v_project_costs_row     xxgpms_project_costs%rowtype;
        v_project_contracts_row xxgpms_project_contract%rowtype;
    begin
        wip_debug(2, 15000, 'Entered into WIP_ADJUST_HOURS: ' || p_expenditure_item_id, '');
        select
            *
        into v_project_costs_row
        from
            xxgpms_project_costs
        where
                session_id = v('APP_SESSION')
            and nvl(billable_flag, '~') = 'Y'
            and expenditure_item_id = trim(both '-' from p_expenditure_item_id);

        wip_debug(2, 15001, 'STEP 1', '');
    -- 1. REVERSAL OF THE CURRENT EXP LINE
        perform_unprocessed_costs_call(
            p_expenditure_item_id => p_expenditure_item_id,
            p_reversal            => 'Y',
            p_internal_comment    => trim(both ':' from p_justification)
                                --    ,P_STANDARD_BILL_RATE_ATTR => V_PROJECT_COSTS_ROW.STANDARD_BILL_RATE_ATTR
                                --    ,P_PROJECT_BILL_RATE_ATTR => V_PROJECT_COSTS_ROW.PROJECT_BILL_RATE_ATTR
                                --    ,P_REALIZED_BILL_RATE_ATTR => V_PROJECT_COSTS_ROW.REALIZED_BILL_RATE_ATTR
            ,
            p_hours_entered       => p_adjusted_hours,
            p_response            => v_response,
            p_response_code       => v_response_code
        );

        if ( v_response_code in ( 200, 201 ) ) -- Negative Transaction Post is success

         then
            wip_debug(2, 15002, 'STEP 2', '');
      -- SPLIT TRANSACTION TO CREATE TWO NEW LINES
            perform_unprocessed_costs_call(
                p_expenditure_item_id => p_expenditure_item_id,
                p_internal_comment    => trim(both ':' from p_justification),
                p_hours_entered       => p_adjusted_hours,
                p_response            => v_response,
                p_response_code       => v_response_code
            );

            wip_debug(2, 15003, 'STEP 2.1', '');
            perform_unprocessed_costs_call(
                p_expenditure_item_id     => p_expenditure_item_id,
                p_internal_comment        => trim(both ':' from p_justification),
                p_hours_entered           => v_project_costs_row.quantity - p_adjusted_hours,
                p_realized_bill_rate_attr => 0,
                p_response                => v_response,
                p_response_code           => v_response_code
            );

            wip_debug(2, 15004, 'END OF HOURS ADJUSTMENT', '');
       -- 3. Import Costs ESS Job
            if v_response_code in ( 200, 201 ) then
                select
                    *
                into v_project_contracts_row
                from
                    xxgpms_project_contract
                where
                        rownum = 1
                    and session_id = v('APP_SESSION')
                    and project_number = v_project_costs_row.project_number;

                v_response_code := submit_parallel_ess_job(v_project_contracts_row.bu_name,
                                                           v_project_contracts_row.business_unit_id,
                                                           v_project_costs_row.transaction_source_id,
                                                           v_project_costs_row.document_id,
                                                           v('APP_SESSION'));

                p_response := v_response;
                p_response_code := v_response_code;
            else
                p_response := v_response;
                p_response_code := v_response_code;
            end if;

        else
            wip_debug(2, 15005, 'Step1 Failure:'
                                || v_response
                                || ' CODE:'
                                || v_response_code, '');

            p_response := v_response;
            p_response_code := v_response_code;
        end if;

    exception
        when others then
            wip_debug(2, 15099, sqlerrm, '');
    end;

    function wip_tag_adjustment (
        p_expenditure_item_list in varchar2,
        p_project_number        in varchar2,
        p_adj_pct               in number,
        p_adj_amt               in number,
        p_sel_amt               in number,
        p_billable_flag         in varchar2 default 'Y',
        p_justification_comment in varchar2,
        p_bill_hold_flag        in varchar2 default null
    ) return number is

        input_str                varchar2(32000);
        temp_str                 varchar2(32000);
    -- EXP_ID                   VARCHAR2(100);
        var1                     number;
        retcode                  number;
        p_project_bill_rate_attr number;
        p_project_bill_rate_amt  number;
        p_project_exp_qty        number;
        p_amt_red                number;
        p_new_amt                number;
        p_new_rate               number;
        p_project_amt_pct        number;
        p_split_count            number;
        p_bu_name                varchar2(100);
    begin
        wip_debug(3, 5000, 'WIP Tag Adjustment: '
                           || p_project_number
                           || ' BILLABLE FLAG: '
                           || p_billable_flag, '');

        wip_debug(3, 5050, 'WIP EXP ITEMS: '
                           || p_expenditure_item_list
                           || '- adj amt: '
                           || p_adj_amt
                           || '- adj pct: '
                           || p_adj_pct
                           || '- sel amt: '
                           || p_sel_amt
                           || 'JUSTIFICATION_COMMENT'
                           || p_justification_comment
                           || 'P_BILL_HOLD_FLAG'
                           || p_bill_hold_flag, '');

        dbms_session.sleep(5);
        select
            count(*)
        into p_split_count
        from
            xxgpms_project_split
        where
            session_id = v('APP_SESSION');

        wip_debug(3, 5100, p_split_count, '');
    -- IF P_SPLIT_COUNT > 0 THEN
    --   RETCODE := PROCESS_TRANSFER_SPLIT (P_EXPENDITURE_ITEM_LIST, P_PROJECT_NUMBER);
    -- END IF;

    -- UPDATE XXGPMS_PROJECT_COSTS
    -- SET
    --   REALIZED_BILL_RATE_ATTR = 0,
    --   REALIZED_BILL_RATE_AMT = 0,
    --   PROJECT_BILL_RATE_AMT = QUANTITY * PROJECT_BILL_RATE_ATTR
    -- WHERE
    --   BILLABLE_FLAG = 'N';
        input_str := p_expenditure_item_list;
    -- VAR1 := INSTR(INPUT_STR, '-', 1, 2);
    -- WHILE (VAR1 > 0) LOOP
    --   WIP_DEBUG(3,5101,VAR1||' TEMP_STR:'||TEMP_STR||' INPUT_STR: '||INPUT_STR,'');
    --   TEMP_STR := SUBSTR(INPUT_STR, 2, VAR1 - 2);
    --   EXP_ID := TEMP_STR;
        for i in (
            select
                column_value exp_id
            from
                (
                    select
                        column_value
                    from
                        table (
                            select
                                apex_string.split(p_expenditure_item_list, '-')
                            from
                                dual
                        )
                )
            where
                column_value is not null
                and column_value <> '-'
        ) loop
            wip_debug(3, 5104, i.exp_id, '');
            wip_debug(3,
                      5105,
                      'SESSION ID: ' || v('APP_SESSION'),
                      '');
            if ( p_adj_pct <> 0 ) then -- This update statement reduces the rate by an adjusted percentage and calculate the extended amount
                wip_debug(3, 5105.5, p_billable_flag, '');
                update xxgpms_project_costs
                set
                    realized_bill_rate_attr = project_bill_rate_attr - ( project_bill_rate_attr * p_adj_pct / 100 ),
                    realized_bill_rate_amt = quantity * ( project_bill_rate_attr - ( project_bill_rate_attr * p_adj_pct / 100 ) ),
                    project_bill_rate_amt = quantity * project_bill_rate_attr,
                    billable_flag = nvl(p_billable_flag, billable_flag),
                    internal_comment = ltrim(p_justification_comment, ':'),
                    bill_hold_flag =
                        case
                            when p_bill_hold_flag <> 'BO' then
                                p_bill_hold_flag
                        end
                where
                        expenditure_item_id = i.exp_id
                    and session_id = v('APP_SESSION');

                wip_debug(3, 5106, 'Rows Effected:' || sql%rowcount, '');
            else
                p_project_bill_rate_attr := 0;
                p_project_bill_rate_amt := 0;
                p_project_exp_qty := 0;
                p_amt_red := 0;
                p_new_amt := 0;
                p_new_rate := 0;
                p_project_amt_pct := 0;
                select
                    project_bill_rate_attr,
                    project_bill_rate_amt,
                    quantity
                into
                    p_project_bill_rate_attr,
                    p_project_bill_rate_amt,
                    p_project_exp_qty
                from
                    xxgpms_project_costs
                where
                        expenditure_item_id = i.exp_id
                    and session_id = v('APP_SESSION')
                fetch first row only;
        -- IF BILLABLE FLAG IS SET TO N THEN SET STANDARD BILL RATE,AGREEMENT BILL RATE AND REALIZED BILL RATE TO 0
                if nvl(p_billable_flag, '~') = 'N' then
                    update xxgpms_project_costs
                    set
                        realized_bill_rate_attr = 0,
                        standard_bill_rate_attr = 0,
                        project_bill_rate_attr = 0,
                        billable_flag = 'N',
                        internal_comment = ltrim(p_justification_comment, ':')
                    where
                        expenditure_item_id = i.exp_id;

                else
                    p_project_amt_pct := p_project_bill_rate_amt * 100 / p_sel_amt;
                    p_amt_red := ( p_sel_amt - p_adj_amt ) * p_project_amt_pct / 100;
                    p_new_amt := p_project_bill_rate_amt - p_amt_red;
                    p_new_rate := p_new_amt / p_project_exp_qty;
                    wip_debug(3, 5150, p_sel_amt, '');
                    wip_debug(3, 5200, p_amt_red, '');
                    wip_debug(3, 5250, p_new_amt, '');
                    wip_debug(3, 5300, p_new_rate, '');
                    wip_debug(3, 5305, p_billable_flag, '');
                    update xxgpms_project_costs
                    set
                        realized_bill_rate_attr = p_new_rate,
                        realized_bill_rate_amt = p_new_amt,
                        project_bill_rate_amt = quantity * project_bill_rate_attr,
                        billable_flag = nvl(p_billable_flag, billable_flag),
                        internal_comment = ltrim(p_justification_comment, ':'),
                        bill_hold_flag =
                            case
                                when p_bill_hold_flag <> 'BO' then
                                    p_bill_hold_flag
                            end
                    where
                        expenditure_item_id = i.exp_id;

                    wip_debug(3, 5306, 'Updated for Exp ID: ' || i.exp_id, '');
                end if;

    --   INPUT_STR := SUBSTR(INPUT_STR, VAR1, 32000);
    --   VAR1 := INSTR(INPUT_STR, '-', 1, 2);
            end if;

        end loop;

        if p_bill_hold_flag = 'BO' then
            update xxgpms_project_costs
            set
                bill_hold_flag = 'O'
            where
                expenditure_item_id not in (
                    select
                        *
                    from
                        table (
                            select
                                apex_string.split(p_expenditure_item_list, '-')
                            from
                                dual
                        )
                )
                and session_id = v('APP_SESSION')
                and project_number = p_project_number;

        end if;

        return 0;
    end wip_tag_adjustment;

    procedure generate_events (
        p_project_number   in varchar2,
        p_agreement_number in varchar2,
        p_bill_thru_date   in date
    ) is

        p_event_id               number;
        p_bill_trans_amt         number;
        p_current_bill_trans_amt number;
        event_found_flag         varchar2(1);
        contract_found_flag      varchar2(1);
        p_contract_number        varchar2(100);
        p_bu_name                varchar2(50);
        p_currency_code          varchar2(50);
        p_contract_type_name     varchar2(50);
        p_organization_name      varchar2(50);
        p_contract_line_number   varchar2(50);
        p_event_type_name        varchar2(50);
        p_event_desc             varchar2(50);
        p_task_number            varchar2(50);
    begin
        wip_debug(3, 6000, 'Generate Events: Project:'
                           || p_project_number
                           || ' Agreement :'
                           || p_agreement_number, '');
 -- We have to group by "Project, Contract, WIP Category & Task number" while generating the events.
        delete from xxgpms_project_events
        where
                session_id = v('APP_SESSION')
            and event_type_name = 'WIP Adjustment';

        for i in (
            select
                sum(project_bill_rate_amt) - sum(realized_bill_rate_amt) bill_trans_amt,
                project_number,
                contract_number                                          agreement_number,
                wip_category,
                task_number,
                contract_line_num,
                exp_bu_id,
                exp_org_id,
                dept_name
            from
                xxgpms_project_costs
            where
                    project_number = nvl(p_project_number, project_number)
                and contract_number = nvl(p_agreement_number, contract_number)
                and session_id = v('APP_SESSION')
 -- AND REALIZED_BILL_RATE_ATTR <> 0
                and nvl(project_bill_rate_amt, 0) - nvl(realized_bill_rate_amt, 0) <> 0
 -- AND EVENT_ATTR <> 'WIP'
            group by
                project_number,
                contract_number,
                contract_line_num,
                wip_category,
                task_number,
                exp_bu_id,
                exp_org_id,
                dept_name
        ) loop
            wip_debug(3, 6050, 'BILL_TRANS_AMT ' || i.bill_trans_amt, '');
            if i.bill_trans_amt <> 0 then
                begin
                    select
                        contract_number,
                        bu_name,
                        currency_code,
                        contract_type_name,
                        organization_name,
                        i.task_number,
 -- task number
 -- 1,
 -- Contract Line Number
                        'WIP Adjustment',
 -- Event Type
                        'Adjustment created via APEX form' -- Event Description
                    into
                        p_contract_number,
                        p_bu_name,
                        p_currency_code,
                        p_contract_type_name,
                        p_organization_name,
                        p_task_number,
 -- P_CONTRACT_LINE_NUMBER,
                        p_event_type_name,
                        p_event_desc
                    from
                        xxgpms_project_contract
                    where
                            project_number = nvl(i.project_number, project_number)
                        and contract_number = nvl(i.agreement_number, contract_number)
                        and session_id = v('APP_SESSION')
                        and rownum = 1;

                    contract_found_flag := 'Y';
                exception
                    when no_data_found then
                        contract_found_flag := 'N';
                    when others then
                        contract_found_flag := 'X';
                end;

                wip_debug(3, 6100, p_current_bill_trans_amt, '');
 -- WIP_DEBUG (3, 6150, P_BILL_TRANS_AMT, '');
                wip_debug(3, 6110, i.project_number
                                   || ' '
                                   || i.agreement_number
                                   || ' '
                                   || i.wip_category
                                   || ' '
                                   || i.task_number, '');
 --     BEGIN
 --       SELECT
 --         EVENT_ID INTO P_EVENT_ID
 --       FROM
 --         XXGPMS_PROJECT_EVENTS A
 --       WHERE
 --         PROJECT_NUMBER = nvl(i.PROJECT_NUMBER,project_number)
 --       and contract_number = nvl(i.agreement_number,contract_number)
 --       and WIP_CATEGORY = i.WIP_CATEGORY
 --       and TASK_NUMBER = i.TASK_NUMBER
 --       AND SESSION_ID = V ('APP_SESSION')
 --       AND NVL(INVOICEDSTATUS,'Uninvoiced') <> 'Fully Invoiced'
 --       AND EVENT_ID IS NOT NULL
 --       AND ROWNUM <2;
 --       EVENT_FOUND_FLAG := 'Y';
 -- EXCEPTION
 --   WHEN NO_DATA_FOUND THEN
 --     EVENT_FOUND_FLAG := 'N';
 --   WHEN OTHERS THEN
 --     EVENT_FOUND_FLAG := 'X';
 -- END;
                wip_debug(3, 6150, 'CONTRACT_FOUND_FLAG '
                                   || contract_found_flag
                                   || ' EVENT_FOUND_FLAG : '
                                   || event_found_flag
                                   || ' '
                                   || p_event_id, '');

                if contract_found_flag = 'Y' then
 -- IF EVENT_FOUND_FLAG = 'N' THEN
                    insert into xxgpms_project_events (
                        project_number,
                        bill_trns_amount,
                        bill_trns_currency_code,
                        evnt_completion_date,
                        task_number,
                        contract_number,
                        contract_line_number,
                        business_unit_name,
                        organization_name,
                        contract_type_name,
                        event_type_name,
                        event_desc,
                        fusion_flag,
                        session_id,
                        wip_category,
                        exp_bu_id,
                        exp_org_id,
                        dept_name
                    ) values ( i.project_number,
                               - 1 * i.bill_trans_amt,
                               p_currency_code,
                               p_bill_thru_date,
                               i.task_number,
                               i.agreement_number,
                               i.contract_line_num,
                               p_bu_name,
                               i.dept_name,
                               p_contract_type_name,
                               p_event_type_name,
                               p_event_desc,
                               'N',
                               v('APP_SESSION'),
                               i.wip_category,
                               i.exp_bu_id,
                               i.exp_org_id,
                               i.dept_name );

                    update xxgpms_project_costs
                    set
                        event_attr = 'WIP'
                    where
                        event_attr is null
                        and wip_category = i.wip_category
                        and task_number = i.task_number;
 --   ELSIF EVENT_FOUND_FLAG = 'Y' THEN
 --   -- Event is Found. So We will derive the Transaction Amount value existing on it.
 --   BEGIN
 --     SELECT NVL(SUM(- 1 * NVL(BILL_TRNS_AMOUNT,0)),0) CURRENT_BILL_TRANS_AMT
 --     INTO   P_CURRENT_BILL_TRANS_AMT
 --     FROM   XXGPMS_PROJECT_EVENTS A
 --     WHERE  PROJECT_NUMBER = NVL(I.PROJECT_NUMBER,PROJECT_NUMBER)
 --     AND    CONTRACT_NUMBER = NVL(I.AGREEMENT_NUMBER,CONTRACT_NUMBER)
 --     AND    WIP_CATEGORY = I.WIP_CATEGORY
 --     AND    TASK_NUMBER  = I.TASK_NUMBER
 --     AND   SESSION_ID = V ('APP_SESSION')
 --     AND   NVL(INVOICEDSTATUS,'Uninvoiced') = 'Fully Invoiced';
 --   EXCEPTION
 --     WHEN OTHERS THEN
 --       P_CURRENT_BILL_TRANS_AMT := 0;
 --   END;
 --   P_BILL_TRANS_AMT := NVL(I.BILL_TRANS_AMT,0) - P_CURRENT_BILL_TRANS_AMT;
 --     UPDATE XXGPMS_PROJECT_EVENTS
 --     SET
 --       BILL_TRNS_AMOUNT = - 1 * P_BILL_TRANS_AMT
 --     WHERE  PROJECT_NUMBER  = NVL(I.PROJECT_NUMBER,PROJECT_NUMBER)
 --     AND    CONTRACT_NUMBER = NVL(I.AGREEMENT_NUMBER,CONTRACT_NUMBER)
 --     AND    WIP_CATEGORY    = I.WIP_CATEGORY
 --     AND    TASK_NUMBER     = I.TASK_NUMBER
 --     AND    PROJECT_NUMBER  = i.PROJECT_NUMBER
 --     AND    EVENT_ID        = P_EVENT_ID;
 --     UPDATE XXGPMS_PROJECT_COSTS
 --     SET
 --       EVENT_ATTR = 'WIP'
 --     WHERE
 --       EVENT_ATTR IS NULL
 --       AND PROJECT_NUMBER = nvl(i.PROJECT_NUMBER, project_number)
 --       and contract_number = nvl(i.agreement_number,contract_number)
 --       AND  WIP_CATEGORY   = I.WIP_CATEGORY
 --       AND  TASK_NUMBER    = I.TASK_NUMBER
 --       AND SESSION_ID = V (
 --         'APP_SESSION'
 --       );
 --   END IF;
                end if;

            end if;

        end loop;

    end generate_events;

    procedure post_event_attributes (
        p_billing_events_uniq_id in number,
        p_wip_category           in varchar2,
        p_response_code          out number
    ) is
        l_url           varchar2(1000);
        l_envelope      varchar2(500);
        l_response_clob clob;
    begin
        l_url := instance_url
                 || '/fscmRestApi/resources/11.13.18.05/projectBillingEvents/'
                 || p_billing_events_uniq_id
                 || '/child/billingEventDFF/'
                 || p_billing_events_uniq_id;
        wip_debug(3, 11000, l_url, '');
        l_envelope := '{"wipCategory":"'
                      || p_wip_category
                      || '"}';
        wip_debug(3, 11001, l_envelope, '');
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        l_response_clob := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'POST',
 --p_username => g_username,
 --p_password => g_password,
 --P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
            p_scheme      => 'OAUTH_CLIENT_CRED',
            p_body        => l_envelope
        );

        wip_debug(3, 11002, l_response_clob, '');
        wip_debug(3, 11003, apex_web_service.g_status_code, '');
        p_response_code := apex_web_service.g_status_code;
        apex_web_service.g_request_headers.delete();
    end;

    procedure parse_job_id (
        p_response in xmltype,
        p_job_id   out number
    ) is
        l_clob_report_response clob;
        l_xml_report_response  xmltype;
    begin
        wip_debug(3,
                  130000,
                  p_response.getclobval(),
                  '');
        l_clob_report_response := p_response.getclobval();
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => p_response,
            p_xpath => ' //err/response'
 --, P_NS    => ' xmlns="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types"'
        );
        wip_debug(3, 130001, 'Step 1 Response ', l_clob_report_response);
        l_clob_report_response := replace(l_clob_report_response,
                                          rtrim(
                                              substr(l_clob_report_response,
                                                     instr(l_clob_report_response, '<!'),
                                                     instr(l_clob_report_response, '<env:') - 1),
                                              '<env:Envel'
                                          ),
                                          '');

        wip_debug(3, 130001, 'Step 2 Response ', l_clob_report_response);
        l_clob_report_response := replace(l_clob_report_response,
                                          substr(l_clob_report_response,
                                                 instr(l_clob_report_response, '------'),
                                                 instr(l_clob_report_response, ']]>') - 1),
                                          '')
                                  || '</response>';

        wip_debug(3, 130001, 'Step 3 Response ', l_clob_report_response);
        l_xml_report_response := sys.xmltype.createxml(l_clob_report_response);
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_report_response,
            p_xpath => '//response/submitESSJobRequestResponse'
 --, P_NS    => 'xmlns="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types"'
        );
        wip_debug(3, 130002, 'Parsed Response ', l_clob_report_response);
    end;

--
    procedure generate_events_and_post (
        p_project_number  in varchar2 default null,
        p_bill_thru_date  in date,
        p_contract_number in varchar2,
        p_justification   in varchar2,
        p_total_up_down   in number default 0,
        p_bill_from_date  in date default to_date ( '01-01-1997', 'MM-DD-YYYY' )
    ) is

        l_url                       varchar2(4000);
        name                        varchar2(4000);
        buffer                      varchar2(4000);
        l_envelope                  varchar2(32000);
        l_senvelope                 clob;
        l_response_xml              varchar2(32000);
        l_sresponse_xml             xmltype;
        l_response_clob             clob;
        p_nic_number                varchar2(100);
        l_version                   varchar2(100);
        l_sversion                  varchar2(100) := '1.1';
        l_temp                      varchar2(32000);
        p_business_unit_name        varchar2(100);
        p_organization_name         varchar2(100);
        p_contract_type_name        varchar2(100);
        p_contract_line_number      varchar2(100);
        p_event_type_name           varchar2(100);
        p_event_description         varchar2(100);
        p_task_number               varchar2(100);
        p_completion_date           date;
        p_bill_trans_amount         number;
        p_project_bill_rate_amt     number;
        p_event_id                  number;
        p_fusion_flag               varchar2(1) := 'N';
        event_found_flag            varchar2(1) := 'N';
        p_event_id_tmp              varchar2(50);
        p_event_no_ret_tmp          varchar2(10);
        p_event_num                 varchar2(10);
        p_project_name              varchar2(100);
        p_project_id                number;
        p_bu_name                   varchar2(100);
        p_bu_id                     number;
        p_invoice_date              date;
        p_contract_id               number;
        temp_contract_number        varchar2(10);
        temp_contract_id            number;
        cmte_approval_required_flag varchar2(1);
        cmte_approval_adjustment    number;
        p_cmte_bill_rate_amt        number;
        p_cmte_evnt_rate_amt        number;
        cmte_adj_pct                number;
        lv_response                 number := 1;
        v_response_code             number;
        ls_response_clob            clob;
        l_job_id                    varchar2(100);
    begin
        for i in (
            select
                business_unit_name,
                organization_name,
                contract_type_name,
                contract_line_number,
                event_type_name,
                event_desc,
                task_number,
                evnt_completion_date,
                bill_trns_amount,
                event_id,
                fusion_flag,
                event_num,
                wip_category,
                project_number,
                exp_bu_id,
                exp_org_id,
                dept_name
 --   DECODE(P_PROJECT_NUMBER, NULL, NULL, PROJECT_NUMBER) PROJECT_NUMBER
            from
                xxgpms_project_events
            where
                    nvl(project_number, '~') = nvl(p_project_number,
                                                   nvl(project_number, '~'))
                and nvl(contract_number, '~') = nvl(p_contract_number,
                                                    nvl(contract_number, '~'))
                and session_id = v('APP_SESSION')
                and nvl(invoicedstatus, 'Uninvoiced') <> 'Fully Invoiced'
        ) loop
            event_found_flag := 'Y';
            wip_debug(3, 7199, 'GENERATE EVENTS AND POST -- '
                               || 'BEFORE: '
                               || i.wip_category
                               || ' '
                               || i.task_number
                               || ' '
                               || i.bill_trns_amount, '');

            if nvl(i.bill_trns_amount, 0) <> 0 then
                if i.fusion_flag = 'N' then
        --- Create Project Events -------
                    l_url := instance_url || '/fscmRestApi/resources/11.13.18.05/projectBillingEvents';
                    wip_debug(3, 7201, l_url, '');
                    l_envelope := '{"BusinessUnitName" : "'
                                  || i.business_unit_name
                                  || '",
                          "OrganizationName":"'
                                  || i.dept_name
                                  || '",
                           "ContractTypeName" : "'
                                  || i.contract_type_name
                                  || '",
                                        "ContractNumber" : "'
                                  || p_contract_number
                                  || '",
                                        "ContractLineNumber" : "'
                                  || i.contract_line_number
                                  || '",
                                        "EventTypeName" : "'
                                  || i.event_type_name
                                  || '",
                                        "EventDescription" : "'
                                  || i.event_desc
                                  || '",
                                        "ProjectNumber" : "'
                                  || i.project_number
                                  || '",
                                        "TaskNumber" : "'
                                  || i.task_number
                                  || '",
                                        "CompletionDate" : "'
                                  || to_char(i.evnt_completion_date, 'YYYY-MM-DD')
                                  || '",
                                        "BillTrnsAmount" : '
                                  || i.bill_trns_amount
                                  || '
           }';

                    wip_debug(3, 7202, l_envelope, '');
                    apex_web_service.g_request_headers(1).name := 'Content-Type';
                    apex_web_service.g_request_headers(1).value := 'application/json';
                    l_response_clob := apex_web_service.make_rest_request(
                        p_url         => l_url,
                        p_http_method => 'POST',
 --p_username => g_username,
 --p_password => g_password,
 --P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
                        p_scheme      => 'OAUTH_CLIENT_CRED',
                        p_body        => l_envelope
                    );

                    wip_debug(3, 7203, l_response_clob, '');
                    wip_debug(3, 7203.5, apex_web_service.g_status_code, '');
                    if apex_web_service.g_status_code in ( 200, 201 ) then
                        wip_debug(3, 7204, 'Response of Posting Event for Agreement '
                                           || p_contract_number
                                           || ' Project '
                                           || i.project_number
                                           || ' WIP Category '
                                           || i.wip_category
                                           || ' Task Number '
                                           || i.task_number
                                           || 'Org Name'
                                           || i.dept_name
                                           || ' is '
                                           || apex_web_service.g_status_code, '');

                        lv_response := lv_response * 1;
 -- NOW THAT THE EVENT IS POSTED, LETS POST THE WIP CATEGORY
                        select
                            json_query(l_response_clob, '$.EventId' with wrapper)     as value,
                            json_query(l_response_clob, '$.EventNumber' with wrapper) as value
                        into
                            p_event_id_tmp,
                            p_event_no_ret_tmp
                        from
                            dual;

                        p_event_id_tmp := replace(
                            replace(p_event_id_tmp, '[', ''),
                            ']',
                            ''
                        );

                        wip_debug(3, 7205, 'After Posting Event Data '
                                           || p_event_id_tmp
                                           || ' '
                                           || p_event_no_ret_tmp
                                           || ' '
                                           || lv_response
                                           || ' '
                                           || i.wip_category, '');
 -- POST_EVENT_ATTRIBUTES(P_EVENT_ID_TMP,I.WIP_CATEGORY,V_RESPONSE_CODE);
                        l_url := instance_url
                                 || '/fscmRestApi/resources/11.13.18.05/projectBillingEvents/'
                                 || p_event_id_tmp
                                 || '/child/billingEventDFF/'
                                 || p_event_id_tmp;
                        wip_debug(3, 11000, l_url, '');
                        l_envelope := '{"wipCategory":"'
                                      || i.wip_category
                                      || '"
                              ,"revenueOffice":"'
                                      || i.exp_bu_id
                                      || '"
                             ,"expenditureOrganization":"'
                                      || i.exp_org_id
                                      || '"}';

                        wip_debug(3, 11001, l_envelope, '');
                        apex_web_service.g_request_headers(1).name := 'Content-Type';
                        apex_web_service.g_request_headers(1).value := 'application/json';
                        l_response_clob := apex_web_service.make_rest_request(
                            p_url         => l_url,
                            p_http_method => 'PATCH',
 --p_username => g_username,
 --p_password => g_password,
 --P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
                            p_scheme      => 'OAUTH_CLIENT_CRED',
                            p_body        => l_envelope
                        );

                        wip_debug(3, 11002, l_response_clob, '');
                        v_response_code := apex_web_service.g_status_code;
                        wip_debug(3, 7206, 'Response of Posting Event WIP Category for Agreement '
                                           || p_contract_number
                                           || ' Project '
                                           || i.project_number
                                           || ' WIP Category '
                                           || i.wip_category
                                           || ' Task Number '
                                           || i.task_number
                                           || ' is '
                                           || v_response_code, '');

                        if v_response_code not in ( 200, 201 ) then
                            lv_response := 0;
                            exit;
                        end if;

                    else
                        lv_response := 0;
                        exit;
                    end if;

                    update xxgpms_project_events
                    set
                        fusion_flag = 'Y',
                        event_id = to_number(substr(p_event_id_tmp,
                                                    2,
                                                    length(p_event_id_tmp) - 2)),
                        event_num = to_number(substr(p_event_no_ret_tmp,
                                                     2,
                                                     length(p_event_no_ret_tmp) - 2))
                    where
                            project_number = nvl(p_project_number, project_number)
                        and contract_number = nvl(p_contract_number, contract_number)
                        and wip_category = i.wip_category
                        and task_number = i.task_number
                        and session_id = v('APP_SESSION')
                        and nvl(invoicedstatus, 'Uninvoiced') <> 'Fully Invoiced';

                    update xxgpms_project_costs
                    set
                        event_attr = p_contract_number
                                     || ' - '
                                     || to_number(substr(p_event_no_ret_tmp,
                                                         2,
                                                         length(p_event_no_ret_tmp) - 2))
                    where
                        event_attr is not null;

                else
                    l_url := instance_url
                             || '/fscmRestApi/resources/11.13.18.05/projectBillingEvents/'
                             || i.event_id;
                    wip_debug(3, 7210, l_url, '');
                    l_envelope := '{"BillTrnsAmount" : '
                                  || i.bill_trns_amount
                                  || '}';
                    wip_debug(3, 7211, l_envelope, '');
                    apex_web_service.g_request_headers(1).name := 'Content-Type';
                    apex_web_service.g_request_headers(1).value := 'application/json';
                    l_response_clob := apex_web_service.make_rest_request(
                        p_url         => l_url,
                        p_http_method => 'PATCH',
 --p_username => g_username,
 --p_password => g_password,
 --   P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
                        p_scheme      => 'OAUTH_CLIENT_CRED',
                        p_body        => l_envelope
                    );

                    wip_debug(3, 7212, l_response_clob, '');
                    wip_debug(3, 7213, 'Response of PATCHING Event for Agreement '
                                       || p_contract_number
                                       || ' Project '
                                       || i.project_number
                                       || ' WIP Category '
                                       || i.wip_category
                                       || ' Task Number '
                                       || i.task_number
                                       || ' is '
                                       || apex_web_service.g_status_code, '');

                    if apex_web_service.g_status_code in ( 200, 201 ) then
                        lv_response := lv_response * 1;
                    else
                        lv_response := 0;
                        exit;
                    end if;

                    update xxgpms_project_costs
                    set
                        event_attr = p_contract_number
                                     || ' - '
                                     || i.event_num
                    where
                        event_attr is not null;

                end if;
            end if;

        end loop;

        wip_debug(3, 7213, 'Final Response Status after Event Loop Exiting is: ' || lv_response, '');
    exception
        when others then
            event_found_flag := 'N';
            p_bill_trans_amount := 0;
    end;

    procedure generate_draft_invoice (
        p_project_number  in varchar2 default null,
        p_bill_thru_date  in date,
        p_contract_number in varchar2,
        p_justification   in varchar2,
        p_total_up_down   in number default 0,
        p_bill_from_date  in date default to_date ( '01-01-1997', 'MM-DD-YYYY' )
    ) is

        l_url                       varchar2(4000);
        name                        varchar2(4000);
        buffer                      varchar2(4000);
        l_envelope                  varchar2(32000);
        l_senvelope                 clob;
        l_response_xml              varchar2(32000);
        l_sresponse_xml             xmltype;
        l_response_clob             clob;
        p_nic_number                varchar2(100);
        l_version                   varchar2(100);
        l_sversion                  varchar2(100) := '1.1';
        l_temp                      varchar2(32000);
        p_business_unit_name        varchar2(100);
        p_organization_name         varchar2(100);
        p_contract_type_name        varchar2(100);
        p_contract_line_number      varchar2(100);
        p_event_type_name           varchar2(100);
        p_event_description         varchar2(100);
        p_task_number               varchar2(100);
        p_completion_date           date;
        p_bill_trans_amount         number;
        p_project_bill_rate_amt     number;
        p_event_id                  number;
        p_fusion_flag               varchar2(1) := 'N';
        event_found_flag            varchar2(1) := 'N';
        p_event_id_tmp              varchar2(50);
        p_event_no_ret_tmp          varchar2(10);
        p_event_num                 varchar2(10);
        p_project_name              varchar2(100);
        p_project_id                number;
        p_bu_name                   varchar2(100);
        p_bu_id                     number;
        p_invoice_date              date;
        p_contract_id               number;
        temp_contract_number        varchar2(10);
        temp_contract_id            number;
        cmte_approval_required_flag varchar2(1);
        cmte_approval_adjustment    number;
        p_cmte_bill_rate_amt        number;
        p_cmte_evnt_rate_amt        number;
        cmte_adj_pct                number;
        lv_response                 number := 1;
        v_response_code             number;
        ls_response_clob            clob;
        l_job_id                    varchar2(100);
    begin
        wip_debug(3, 7000, 'Generate Draft Invoice: Project'
                           || p_project_number
                           || ' Agreement:'
                           || p_contract_number, '');

        wip_debug(3, 7050, p_project_number, '');
        wip_debug(3,
                  7100,
                  to_char(p_bill_thru_date, 'MM-DD-YYYY'),
                  '');
        wip_debug(3,
                  7101,
                  to_char(p_bill_from_date, 'MM-DD-YYYY'),
                  '');
        wip_debug(3, 7150, p_contract_number, '');
        l_version := '1.2';
        begin
            for i in (
                select
                    business_unit_name,
                    organization_name,
                    contract_type_name,
                    contract_line_number,
                    event_type_name,
                    event_desc,
                    task_number,
                    evnt_completion_date,
                    bill_trns_amount,
                    event_id,
                    fusion_flag,
                    event_num,
                    wip_category,
                    project_number,
                    exp_bu_id,
                    exp_org_id,
                    dept_name
 --   DECODE(P_PROJECT_NUMBER, NULL, NULL, PROJECT_NUMBER) PROJECT_NUMBER
                from
                    xxgpms_project_events
                where
                        nvl(project_number, '~') = nvl(p_project_number,
                                                       nvl(project_number, '~'))
                    and nvl(contract_number, '~') = nvl(p_contract_number,
                                                        nvl(contract_number, '~'))
                    and session_id = v('APP_SESSION')
                    and nvl(invoicedstatus, 'Uninvoiced') <> 'Fully Invoiced'
            ) loop
                event_found_flag := 'Y';
                wip_debug(3, 7199, 'BEFORE: '
                                   || i.wip_category
                                   || ' '
                                   || i.task_number
                                   || ' '
                                   || i.bill_trns_amount, '');

                if nvl(i.bill_trns_amount, 0) <> 0 then
                    if i.fusion_flag = 'N' then
 --- Create Project Events -------
                        l_url := instance_url || '/fscmRestApi/resources/11.13.18.05/projectBillingEvents';
                        wip_debug(3, 7201, l_url, '');
                        l_envelope := '{"BusinessUnitName" : "'
                                      || i.business_unit_name
                                      || '",
                          "OrganizationName":"'
                                      || i.dept_name
                                      || '",
                           "ContractTypeName" : "'
                                      || i.contract_type_name
                                      || '",
                                        "ContractNumber" : "'
                                      || p_contract_number
                                      || '",
                                        "ContractLineNumber" : "'
                                      || i.contract_line_number
                                      || '",
                                        "EventTypeName" : "'
                                      || i.event_type_name
                                      || '",
                                        "EventDescription" : "'
                                      || i.event_desc
                                      || '",
                                        "ProjectNumber" : "'
                                      || i.project_number
                                      || '",
                                        "TaskNumber" : "'
                                      || i.task_number
                                      || '",
                                        "CompletionDate" : "'
                                      || to_char(i.evnt_completion_date, 'YYYY-MM-DD')
                                      || '",
                                        "BillTrnsAmount" : '
                                      || i.bill_trns_amount
                                      || '
           }';

                        wip_debug(3, 7202, l_envelope, '');
                        apex_web_service.g_request_headers(1).name := 'Content-Type';
                        apex_web_service.g_request_headers(1).value := 'application/json';
                        l_response_clob := apex_web_service.make_rest_request(
                            p_url         => l_url,
                            p_http_method => 'POST',
 --p_username => g_username,
 --p_password => g_password,
 --P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
                            p_scheme      => 'OAUTH_CLIENT_CRED',
                            p_body        => l_envelope
                        );

                        wip_debug(3, 7203, l_response_clob, '');
                        wip_debug(3, 7203.5, apex_web_service.g_status_code, '');
                        if apex_web_service.g_status_code in ( 200, 201 ) then
                            wip_debug(3, 7204, 'Response of Posting Event for Agreement '
                                               || p_contract_number
                                               || ' Project '
                                               || i.project_number
                                               || ' WIP Category '
                                               || i.wip_category
                                               || ' Task Number '
                                               || i.task_number
                                               || 'Org Name'
                                               || i.dept_name
                                               || ' is '
                                               || apex_web_service.g_status_code, '');

                            lv_response := lv_response * 1;
 -- NOW THAT THE EVENT IS POSTED, LETS POST THE WIP CATEGORY
                            select
                                json_query(l_response_clob, '$.EventId' with wrapper)     as value,
                                json_query(l_response_clob, '$.EventNumber' with wrapper) as value
                            into
                                p_event_id_tmp,
                                p_event_no_ret_tmp
                            from
                                dual;

                            p_event_id_tmp := replace(
                                replace(p_event_id_tmp, '[', ''),
                                ']',
                                ''
                            );

                            wip_debug(3, 7205, 'After Posting Event Data '
                                               || p_event_id_tmp
                                               || ' '
                                               || p_event_no_ret_tmp
                                               || ' '
                                               || lv_response
                                               || ' '
                                               || i.wip_category, '');
 -- POST_EVENT_ATTRIBUTES(P_EVENT_ID_TMP,I.WIP_CATEGORY,V_RESPONSE_CODE);
                            l_url := instance_url
                                     || '/fscmRestApi/resources/11.13.18.05/projectBillingEvents/'
                                     || p_event_id_tmp
                                     || '/child/billingEventDFF/'
                                     || p_event_id_tmp;
                            wip_debug(3, 11000, l_url, '');
                            l_envelope := '{"wipCategory":"'
                                          || i.wip_category
                                          || '"
                              ,"revenueOffice":"'
                                          || i.exp_bu_id
                                          || '"
                             ,"expenditureOrganization":"'
                                          || i.exp_org_id
                                          || '"}';

                            wip_debug(3, 11001, l_envelope, '');
                            apex_web_service.g_request_headers(1).name := 'Content-Type';
                            apex_web_service.g_request_headers(1).value := 'application/json';
                            l_response_clob := apex_web_service.make_rest_request(
                                p_url         => l_url,
                                p_http_method => 'PATCH',
 --p_username => g_username,
 --p_password => g_password,
 --P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
                                p_scheme      => 'OAUTH_CLIENT_CRED',
                                p_body        => l_envelope
                            );

                            wip_debug(3, 11002, l_response_clob, '');
                            v_response_code := apex_web_service.g_status_code;
                            wip_debug(3, 7206, 'Response of Posting Event WIP Category for Agreement '
                                               || p_contract_number
                                               || ' Project '
                                               || i.project_number
                                               || ' WIP Category '
                                               || i.wip_category
                                               || ' Task Number '
                                               || i.task_number
                                               || ' is '
                                               || v_response_code, '');

                            if v_response_code not in ( 200, 201 ) then
                                lv_response := 0;
                                exit;
                            end if;

                        else
                            lv_response := 0;
                            exit;
                        end if;

                        update xxgpms_project_events
                        set
                            fusion_flag = 'Y',
                            event_id = to_number(substr(p_event_id_tmp,
                                                        2,
                                                        length(p_event_id_tmp) - 2)),
                            event_num = to_number(substr(p_event_no_ret_tmp,
                                                         2,
                                                         length(p_event_no_ret_tmp) - 2))
                        where
                                project_number = nvl(p_project_number, project_number)
                            and contract_number = nvl(p_contract_number, contract_number)
                            and wip_category = i.wip_category
                            and task_number = i.task_number
                            and session_id = v('APP_SESSION')
                            and nvl(invoicedstatus, 'Uninvoiced') <> 'Fully Invoiced';

                        update xxgpms_project_costs
                        set
                            event_attr = p_contract_number
                                         || ' - '
                                         || to_number(substr(p_event_no_ret_tmp,
                                                             2,
                                                             length(p_event_no_ret_tmp) - 2))
                        where
                            event_attr is not null;

                    else
                        l_url := instance_url
                                 || '/fscmRestApi/resources/11.13.18.05/projectBillingEvents/'
                                 || i.event_id;
                        wip_debug(3, 7210, l_url, '');
                        l_envelope := '{"BillTrnsAmount" : '
                                      || i.bill_trns_amount
                                      || '}';
                        wip_debug(3, 7211, l_envelope, '');
                        apex_web_service.g_request_headers(1).name := 'Content-Type';
                        apex_web_service.g_request_headers(1).value := 'application/json';
                        l_response_clob := apex_web_service.make_rest_request(
                            p_url         => l_url,
                            p_http_method => 'PATCH',
 --p_username => g_username,
 --p_password => g_password,
 --   P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
                            p_scheme      => 'OAUTH_CLIENT_CRED',
                            p_body        => l_envelope
                        );

                        wip_debug(3, 7212, l_response_clob, '');
                        wip_debug(3, 7213, 'Response of PATCHING Event for Agreement '
                                           || p_contract_number
                                           || ' Project '
                                           || i.project_number
                                           || ' WIP Category '
                                           || i.wip_category
                                           || ' Task Number '
                                           || i.task_number
                                           || ' is '
                                           || apex_web_service.g_status_code, '');

                        if apex_web_service.g_status_code in ( 200, 201 ) then
                            lv_response := lv_response * 1;
                        else
                            lv_response := 0;
                            exit;
                        end if;

                        update xxgpms_project_costs
                        set
                            event_attr = p_contract_number
                                         || ' - '
                                         || i.event_num
                        where
                            event_attr is not null;

                    end if;
                end if;

            end loop;

            wip_debug(3, 7214, 'Final Response Status after Event Loop Exiting is: ' || lv_response, '');
        exception
            when others then
                event_found_flag := 'N';
                p_bill_trans_amount := 0;
        end;
 -- Retrive Project information
    -- SELECT
    --   DISTINCT PROJECT_NAME,
    --   PROJECT_ID,
    --   BU_NAME,
    --   BU_ID INTO P_PROJECT_NAME,
    --   P_PROJECT_ID,
    --   P_BU_NAME,
    --   P_BU_ID
    -- FROM
    --   XXGPMS_PROJECT_COSTS
    -- WHERE
    --   PROJECT_NUMBER = NVL(P_PROJECT_NUMBER, PROJECT_NUMBER)
    --   AND CONTRACT_NUMBER = NVL(P_CONTRACT_NUMBER, CONTRACT_NUMBER)
    --   AND SESSION_ID = V ('APP_SESSION')
    --   AND ROWNUM = 1;
        select
            contract_id,
            project_name,
            project_id,
            bu_name,
            business_unit_id
        into
            p_contract_id,
            p_project_name,
            p_project_id,
            p_bu_name,
            p_bu_id
        from
            xxgpms_project_contract
        where
                project_number = nvl(p_project_number, project_number)
            and contract_number = nvl(p_contract_number, contract_number)
            and session_id = v('APP_SESSION')
            and rownum = 1;

 -- COMMENTING THE BELOW CODE AS NO LONGER REQUIRED
 --     BEGIN
 --       CMTE_APPROVAL_REQUIRED_FLAG := 'N';
 --       CMTE_APPROVAL_ADJUSTMENT := 0;
 --       SELECT
 --         SUM(NVL(PROJECT_BILL_RATE_AMT,
 --         0)) INTO P_CMTE_BILL_RATE_AMT
 --       FROM
 --         XXGPMS_PROJECT_COSTS
 --       WHERE
 --         PROJECT_NUMBER = NVL(P_PROJECT_NUMBER,
 --         PROJECT_NUMBER)
 --         AND CONTRACT_NUMBER = NVL(P_CONTRACT_NUMBER,
 --         CONTRACT_NUMBER)
 --         AND SESSION_ID = V ('APP_SESSION')
 --         AND REALIZED_BILL_RATE_ATTR <> 0;
 --       SELECT
 --         SUM(NVL(BILL_TRNS_AMOUNT,
 --         0)) INTO P_CMTE_EVNT_RATE_AMT
 --       FROM
 --         XXGPMS_PROJECT_EVENTS
 --       WHERE
 --         PROJECT_NUMBER = NVL(P_PROJECT_NUMBER,
 --         PROJECT_NUMBER)
 --         AND CONTRACT_NUMBER = NVL(P_CONTRACT_NUMBER,
 --         CONTRACT_NUMBER)
 --         AND SESSION_ID = V ('APP_SESSION')
 --         AND NVL(INVOICEDSTATUS,
 --         'Uninvoiced') <> 'Fully Invoiced';
 --     EXCEPTION
 --       WHEN NO_DATA_FOUND THEN
 --         P_CMTE_EVNT_RATE_AMT := '0';
 --         P_CMTE_BILL_RATE_AMT := 0;
 --       WHEN OTHERS THEN
 --         P_CMTE_EVNT_RATE_AMT := '0';
 --         P_CMTE_BILL_RATE_AMT := 0;
 --     END;
 --     IF P_CMTE_BILL_RATE_AMT > 0 AND P_CMTE_EVNT_RATE_AMT > 0 THEN
 --       CMTE_ADJ_PCT := (P_CMTE_BILL_RATE_AMT - P_CMTE_EVNT_RATE_AMT) * 100 / P_CMTE_BILL_RATE_AMT;
 --       IF ( CMTE_ADJ_PCT < -15
 --       OR CMTE_ADJ_PCT > 15 ) THEN
 --         CMTE_APPROVAL_REQUIRED_FLAG := 'Y';
 --         CMTE_APPROVAL_ADJUSTMENT := P_CMTE_BILL_RATE_AMT - P_CMTE_EVNT_RATE_AMT;
 --       ELSE
 --         CMTE_APPROVAL_REQUIRED_FLAG := 'N';
 --         CMTE_APPROVAL_ADJUSTMENT := P_CMTE_BILL_RATE_AMT - P_CMTE_EVNT_RATE_AMT;
 --       END IF;
 --     END IF;
 --  -- Retrive Project information
 --     SELECT
 --       DISTINCT PROJECT_NAME,
 --       PROJECT_ID,
 --       BU_NAME,
 --       BU_ID INTO P_PROJECT_NAME,
 --       P_PROJECT_ID,
 --       P_BU_NAME,
 --       P_BU_ID
 --     FROM
 --       XXGPMS_PROJECT_COSTS
 --     WHERE
 --       PROJECT_NUMBER = NVL(P_PROJECT_NUMBER,
 --       PROJECT_NUMBER)
 --       AND CONTRACT_NUMBER = NVL(P_CONTRACT_NUMBER,
 --       CONTRACT_NUMBER)
 --       AND SESSION_ID = V ('APP_SESSION')
 --       AND ROWNUM = 1;
 --  /* Set the Project Level DFF */
 --     L_URL := INSTANCE_URL
 --       || ':443/fscmService/ProjectDefinitionPublicServiceV2';
 --     WIP_DEBUG (3, 7200, 'L_URL '||L_URL, '');
 --     L_SENVELOPE := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/projects/foundation/projectDefinition/publicService/maintainProjectV2/types/" xmlns:main="http://xmlns.oracle.com/apps/projects/foundation/projectDefinition/publicService/maintainProjectV2/" xmlns:proj="http://xmlns.oracle.com/apps/projects/foundation/projectDefinition/flex/ProjectClassCodeDff/" xmlns:proj1="http://xmlns.oracle.com/apps/projects/foundation/projectDefinition/flex/ProjectDff/">
 --                               <soapenv:Header/>
 --                                <soapenv:Body>
 -- 		                <typ:mergeProjectData>
 -- 				 <typ:Project>
 -- 				    <main:ProjectId>'
 --       || P_PROJECT_ID
 --       || '</main:ProjectId>
 -- 				    <main:ProjectDff>
 -- 				       <proj1:ProjectId>'
 --       || P_PROJECT_ID
 --       || '</proj1:ProjectId>
 -- 				       <proj1:billingCommitteeApprovalRequir>'
 --       || CMTE_APPROVAL_REQUIRED_FLAG
 --       || '</proj1:billingCommitteeApprovalRequir>
 -- 				       <proj1:writeOffAmount>'
 --       || CMTE_APPROVAL_ADJUSTMENT
 --       || '</proj1:writeOffAmount>
 -- 				       <proj1:writeOffReason>'
 --       || P_JUSTIFICATION
 --       || '</proj1:writeOffReason>
 -- 				    </main:ProjectDff>
 -- 				 </typ:Project>
 -- 			       </typ:mergeProjectData>
 -- 			      </soapenv:Body>
 -- 		             </soapenv:Envelope>';
 --       WIP_DEBUG (3, 7205, 'L_SENVELOPE '||L_SENVELOPE, '');
 --  --l_sresponse_xml := apex_web_service.make_request ( p_url => l_url, p_version => l_sversion, p_action => 'mergeProjectData', p_envelope => l_senvelope, p_username => g_username, p_password => g_password );
 --     L_SRESPONSE_XML := APEX_WEB_SERVICE.MAKE_REQUEST ( P_URL => L_URL, P_VERSION => L_SVERSION, P_ACTION => 'mergeProjectData', P_ENVELOPE => L_SENVELOPE
 --  -- ,P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
 --     );

 /*   End Project DFF Update */
 /* Generate Invoice Web Service Call */
        wip_debug(3, 7219, 'lv_response ' || lv_response, '');
        if lv_response <> 0 then
            p_invoice_date := p_bill_thru_date;
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
            l_url := instance_url || ':443/fscmService/ErpIntegrationService';
            wip_debug(3, 7220, l_url, '');
            wip_debug(3,
                      7220.5,
                      apex_web_service.g_request_headers(1).value,
                      '');

            l_senvelope := q'#<?xml version="1.0" encoding="UTF-8"?>#';
            l_senvelope := l_senvelope
                           || '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/">
		              <soapenv:Header/>
			       <soapenv:Body>
			        <typ:submitESSJobRequest>
				 <typ:jobPackageName>oracle/apps/ess/projects/billing/workarea/invoice</typ:jobPackageName>
				 <typ:jobDefinitionName>InvoiceGenerationJob</typ:jobDefinitionName>
				 <typ:paramList>'
                           || p_bu_name
                           || '</typ:paramList>
				 <typ:paramList>'
                           || p_bu_id
                           || '</typ:paramList>
				 <typ:paramList>EX</typ:paramList>
				 <typ:paramList>Y</typ:paramList>
				 <typ:paramList>Y</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>'
                           || p_contract_id
                           || '</typ:paramList>
				 <typ:paramList>'
                           || p_contract_number
                           || '</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>'
                           ||
                case
                    when p_project_number is not null then
                        p_project_id
                    else null
                end
                           || '</typ:paramList>
				 <typ:paramList>'
                           ||
                case
                    when p_project_number is not null then
                        replace(p_project_name, '&', ';')
                    else null
                end
                           || '</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>'
                           || to_char(p_bill_from_date, 'YYYY-MM-DD')
                           || '</typ:paramList>
				 <typ:paramList>'
                           || to_char(p_bill_thru_date, 'YYYY-MM-DD')
                           || '</typ:paramList>
				 <typ:paramList>N</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>'
                           || to_char(p_invoice_date, 'YYYY-MM-DD')
                           || '</typ:paramList>
				 <typ:paramList>N</typ:paramList>
				 <typ:paramList>SUMMARY</typ:paramList>
				 <typ:paramList>N</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>#NULL</typ:paramList>
				 <typ:paramList>1</typ:paramList>
			       </typ:submitESSJobRequest>
			      </soapenv:Body>
			     </soapenv:Envelope>';

            wip_debug(3, 7221, l_senvelope, '');
            l_sresponse_xml := apex_web_service.make_request(
                p_url      => l_url,
                p_version  => l_sversion,
                p_action   => 'submitESSJobRequest',
                p_envelope => l_senvelope
 -- ,P_SCHEME    => 'OAUTH_CLIENT_CRED'
 -- ,P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
 -- ,p_username => g_username
 -- ,p_password => g_password
            );

            wip_debug(3,
                      7222,
                      l_sresponse_xml.getclobval(),
                      '');
            if apex_web_service.g_status_code in ( 200, 201 ) then
                ls_response_clob := l_sresponse_xml.getclobval();
                with t as (
                    select
                        ls_response_clob as k
                    from
                        dual
                )
                select
                    substr(actual_string, start_col, end_col - start_col)
                into l_job_id
                from
                    (
                        select
                            instr(k, '<result xmlns="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/">'
                            ) + 112 start_col,
                            instr(k, '</result>')                                                                                                              end_col
                            ,
                            k                                                                                                                                  actual_string
                        from
                            t
                    );

                wip_debug(3, 7223, l_job_id, '');
                dbms_session.sleep(25);
       -- UPDATE_INVOICE_HEADER_DFFS (P_CONTRACT_ID, L_JOB_ID, P_TOTAL_UP_DOWN, V_RESPONSE_CODE);
 -- final step is to submit the invoice
        -- SUBMIT_INVOICE;
            end if;

            apex_web_service.g_request_headers.delete();
 -- Invoke Save Session
            xx_process_hold(p_project_number);
        end if;

    end generate_draft_invoice;

    procedure tag_events (
        p_project_number        in varchar2,
        p_expenditure_item_list in varchar2,
        p_event_num_list        in varchar2,
        p_sel_amt               in number
    ) is

        p_contract_number      varchar2(100);
        p_contract_line_number varchar2(50);
        input_str              varchar2(32000);
        temp_str               varchar2(32000);
        exp_id                 varchar2(100);
        p_bill_trns_amount     number;
        var1                   number;
        retcode                int;
    begin
        wip_debug(3, 8000, p_event_num_list, '');
        select
            contract_number,
            bill_trns_amount,
            contract_line_number
        into
            p_contract_number,
            p_bill_trns_amount,
            p_contract_line_number
        from
            xxgpms_project_events
        where
            event_num = substr(p_event_num_list,
                               2,
                               length(p_event_num_list) - 2);
 -- UPDATE xxgpms_project_costs
 --     SET event_attr = null
 --   WHERE event_attr = p_contract_number || '-' || substr(p_event_num_list,2,length(p_event_num_list)-2);
        retcode := wip_tag_adjustment(p_expenditure_item_list, p_project_number, 0, p_bill_trns_amount, p_sel_amt,
                                      'Y', '');

        input_str := p_expenditure_item_list;
        var1 := instr(input_str, '-', 1, 2);
        while ( var1 > 0 ) loop
            temp_str := substr(input_str, 2, var1 - 2);
            exp_id := temp_str;
            update xxgpms_project_costs
            set
                event_attr = p_contract_number
                             || '-'
                             || p_contract_line_number
                             || '-'
                             || substr(p_event_num_list,
                                       2,
                                       length(p_event_num_list) - 2)
            where
                expenditure_item_id = exp_id;

            input_str := substr(input_str, var1, 32000);
            var1 := instr(input_str, '-', 1, 2);
        end loop;

    exception
        when others then
            wip_debug(3, 8100, 'Error Selecting Event', '');
    end tag_events;

    function get_project_details (
        p_session_id        in number,
        p_project_number    in varchar2,
        o_project_name      out varchar2,
        o_bu_name           out varchar2,
        o_legal_entity_name out varchar2,
        o_currency_code     out varchar2,
        o_customer_name     out varchar2,
        o_retainer_balance  out varchar2,
        o_contract_id       out varchar2
    ) return number is
    begin
        wip_debug(1, 9000, p_project_number, '');
        begin
            select
                project_name,
                bu_name,
                legal_entity_name,
                currency_code,
                customer_name,
                nvl(retainer_balance, 0) retainer_balance,
                contract_id
            into
                o_project_name,
                o_bu_name,
                o_legal_entity_name,
                o_currency_code,
                o_customer_name,
                o_retainer_balance,
                o_contract_id
            from
                xxgpms_project_contract
            where
                    session_id = v('APP_SESSION')
                and project_number = nvl(p_project_number, project_number)
            fetch first row only;

            wip_debug(1, 9000, o_currency_code, '');
        exception
            when others then
                wip_debug(1, 9001, 'retcode 1', sqlerrm);
                return 1;
        end;

        return 0;
    end get_project_details; --- CODE TO POPULATE THE RATES ON THE PROJECT COSTS TO DEFAULT VALUES
 --  ADDED BY EMMANUEL
    procedure populate_rates_onload (
        p_project_id     number,
        p_task_id        number default null,
        p_wip_category   varchar2 default null,
        p_project_number varchar2 default null,
        p_contract_id    number
    ) is

        l_url                        varchar2(4000) := p_url;
        l_version                    varchar2(10) := 1.2;
        l_response_clob              clob;
        l_envelope                   varchar2(32000);
        p_exp_amt                    number;
        p_internal_comment           varchar2(1000);
        p_narrative_billing_overflow varchar2(1000);
        p_event_attr                 varchar2(50);
        p_standard_bill_rate_attr    number;
        p_project_bill_rate_attr     number;
        p_realized_bill_rate_attr    number;
        p_billable_flag              varchar2(10);
        p_expenditure_item_id        number;
        v_statuscode                 number;
        v_value                      number;
        l_xml_response               xmltype;
        l_clob_report_response       clob;
        l_clob_report_decode         clob;
        l_clob_temp                  clob;
        v_attr1                      varchar2(1000);
        v_attr2                      varchar2(1000);
        l_standard_rate              number;
        l_agreement_rate             number;
    begin
        wip_debug(3, 9000, 'Populate Rates Onload for Project Number: ' || p_project_number, ' PROJECT ID '
                                                                                             || p_project_id
                                                                                             || ' TASK '
                                                                                             || p_task_id
                                                                                             || ' WIP CATEGORY: '
                                                                                             || p_wip_category);

        l_version := '1.2';
 -- Call to the OTBI to fetch the projects rates
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
        l_envelope := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
			<soap:Header/>
			   <soap:Body>
				  <pub:runReport>
					 <pub:reportRequest>
					   <pub:attributeFormat>xml</pub:attributeFormat>
						 <pub:parameterNameValues>
							<pub:item>
								<pub:name>P_PROJECT_ID</pub:name>
								<pub:values>
									<pub:item>'
                      || p_project_id
                      || '</pub:item>
								</pub:values>
							</pub:item>
                            <pub:item>
								<pub:name>P_CONTRACT_ID</pub:name>
								<pub:values>
									<pub:item>'
                      || p_contract_id
                      || '</pub:item>
								</pub:values>
							</pub:item>
						</pub:parameterNameValues>
					   <pub:reportAbsolutePath>/Custom/Projects/Project Billing/Project Costs Report.xdo</pub:reportAbsolutePath>
					   <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
					 </pub:reportRequest>
					 <pub:appParams></pub:appParams>
				  </pub:runReport>
			   </soap:Body>
			</soap:Envelope>';
        wip_debug(3, 9000, 'Populate Rates Envelope ', l_envelope);
        wip_debug(3, 9001, 'Populate Rates URL ', l_url);
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
        wip_debug(3,
                  9002,
                  'Populate Rates Bearer Token ',
                  'Bearer ' || v('G_SAAS_ACCESS_TOKEN'));
 -- l_xml_response := apex_web_service.make_request ( p_url => l_url, p_version => l_version, p_action => 'runReport', p_envelope => l_envelope, p_username => g_username, p_password => g_password );
        l_xml_response := apex_web_service.make_request(
            p_url      => l_url,
            p_version  => l_version,
            p_action   => 'runReport',
            p_envelope => l_envelope
 -- ,P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
        );

        wip_debug(3,
                  9003,
                  'Populate Rates Web Service Response',
                  l_xml_response.getclobval());
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        commit;
 -- End
        wip_debug(3, 9004, 'Populate Rates Web Service Response Decoded', l_clob_report_decode);
        insert into xxgpms_project_rates (
            session_id,
            user_email,
            created_date,
            project_id,
            project_number,
            task_id,
            proj_element_id,
            carrying_out_organization_id,
            attribute_number1,
            attribute_number2,
            attribute_number3,
            person_id,
            start_date_active,
            incurred_by_person_id,
            end_date_active,
            rate_unit,
            rate,
            rate_schedule_id,
            expenditure_type_id,
            person_job_id,
            raw_cost_rate, -- EXPENDITURE_ITEM_DATE,
            markup_percentage,
            job_id,
            standard_rate,
            agreement_rate,
            expenditure_item_id
        )
            select
                v('APP_SESSION'),
                v('G_SAAS_USER'),
                systimestamp,
                project_id,
                project_number,
                task_id,
                proj_element_id,
                carrying_out_organization_id,
                attribute_number1,
                attribute_number2,
                attribute_number3,
                person_id,
                start_date_active,
                incurred_by_person_id,
                end_date_active,
                rate_unit,
                rate,
                rate_schedule_id,
                expenditure_type_id,
                person_job_id,
                raw_cost_rate, -- EXPENDITURE_ITEM_DATE,
                markup_percentage,
                job_id,
                standard_rate,
                agreement_rate,
                expenditure_item_id
            from
                xmltable ( '/DATA_DS/G_RATES'
                        passing xmltype(l_clob_report_decode)
                    columns
                        project_id path 'PROJECT_ID',
                        project_number path 'PROJECT_NUMBER',
                        task_id path 'TASK_ID',
                        proj_element_id path 'PROJ_ELEMENT_ID',
                        carrying_out_organization_id path 'CARRYING_OUT_ORGANIZATION_ID',
                        attribute_number1 path 'ATTRIBUTE_NUMBER1',
                        attribute_number2 path 'ATTRIBUTE_NUMBER2',
                        attribute_number3 path 'ATTRIBUTE_NUMBER3',
                        person_id path 'PERSON_ID',
                        start_date_active path 'START_DATE_ACTIVE',
                        incurred_by_person_id path 'INCURRED_BY_PERSON_ID',
                        end_date_active path 'END_DATE_ACTIVE',
                        rate_unit path 'RATE_UNIT',
                        rate path 'RATE',
                        rate_schedule_id path 'RATE_SCHEDULE_ID',
                        expenditure_type_id path 'EXPENDITURE_TYPE_ID',
                        person_job_id path 'PERSON_JOB_ID',
                        raw_cost_rate path 'RAW_COST_RATE', -- EXPENDITURE_ITEM_DATE PATH 'EXPENDITURE_ITEM_DATE'
                        markup_percentage path 'MARKUP_PERCENTAGE',
                        job_id path 'JOB_ID',
                        standard_rate path 'STANDARD_RATE',
                        agreement_rate path 'AGREEMENT_RATE',
                        expenditure_item_id path 'EXPENDITURE_ITEM_ID'
                ) xt;

        commit;
        wip_debug(2, 9005, 'Populate Rates, Insert Complete!', '');
 -- Find all the expenditure costs that needs the rates populated
        for i in (
            select distinct
                expenditure_item_id,
                project_id,
                wip_category,
                task_id,
                incurred_by_person_id,
                expenditure_item_date,
                job_id
            from
                xxgpms_project_costs
            where
                    session_id = v('APP_SESSION')
                and project_id = p_project_id
                and ( nvl(standard_bill_rate_attr, 0) = 0
                      or nvl(project_bill_rate_attr, 0) = 0 )
        ) loop
 --- Update Bill Rate DFF -------
 -- WIP_DEBUG (
 --   2,
 --   9010,
 --   'Populate Rates, Entered into the Loop, Data Found to be updated ' || I.EXPENDITURE_ITEM_ID||' '||I.PROJECT_ID||' '||I.WIP_CATEGORY||' '||I.TASK_ID||' '||I.INCURRED_BY_PERSON_ID||' '||I.EXPENDITURE_ITEM_DATE,
 --   ''
 -- );
 -- -- Get the value as per WIP Category
 --   begin
 --     select attribute_number1
 --     into   v_attr1
 --     from   xxgpms_project_rates
 --     where  project_id = i.project_id
 --     and    task_id    = i.task_id
 --     and    incurred_by_person_id = i.incurred_by_person_id
 --     and    i.expenditure_item_date between start_date_active and end_date_active;
 --   exception
 --     when others
 --     then
 --       v_attr1 := null;
 --   end;
 --   WIP_DEBUG (
 --   2,
 --   9011,
 --   'v_attr1: '|| I.EXPENDITURE_ITEM_ID||' PERSON ID '||I.INCURRED_BY_PERSON_ID||' JOB ID '||I.JOB_ID||' EXP DATE '||I.EXPENDITURE_ITEM_DATE||' '||v_attr1,
 --   ''
 -- );
 --     begin
 --     select attribute_number2
 --     into   v_attr2
 --     from   xxgpms_project_rates
 --     where  project_id = i.project_id
 --     and    task_id    = i.task_id
 --     and    person_job_id = i.job_id;
 --     -- and    i.expenditure_item_date between start_date_active and end_date_active;
 --   exception
 --     when others
 --     then
 --       v_attr2 := null;
 --   end;
 --   WIP_DEBUG (
 --   2,
 --   9012,
 --   'v_attr2: '|| I.EXPENDITURE_ITEM_ID||' PERSON ID '||I.INCURRED_BY_PERSON_ID||' JOB ID '||I.JOB_ID||' EXP DATE '||I.EXPENDITURE_ITEM_DATE||' '||v_attr2,
 --   ''
 -- );
 -- begin
 --   V_VALUE := NULL;
 -- if i.wip_category = 'Labor' and v_attr1 is not null
 -- then
 --   select nvl(rate,markup_percentage*raw_cost_rate)
 --   into   v_value
 --   from   xxgpms_project_rates
 --   where  project_id = i.project_id
 --   and    task_id = i.task_id
 --   and    rate_schedule_id = v_attr1
 --   and    incurred_by_person_id = i.incurred_by_person_id;
 -- elsif i.wip_category = 'Labor' and v_attr1 is null and v_attr2 is not null
 -- then
 --   select nvl(rate,markup_percentage*raw_cost_rate)
 --   into   v_value
 --   from   xxgpms_project_rates
 --   where  project_id = i.project_id
 --   and    task_id = i.task_id
 --   and    rate_schedule_id = v_attr2
 --   and    person_job_id = i.job_id;
 -- elsif i.wip_category <> 'Labor'
 -- then
 --   select nvl(rate,markup_percentage*raw_cost_rate)
 --   into   v_value
 --   from   xxgpms_project_rates
 --   where  project_id = i.project_id
 --   and    task_id = i.task_id
 --   and    rate_schedule_id = attribute_number3
 --   and    nvl(incurred_by_person_id,'-999') = nvl(i.incurred_by_person_id,'-999');
 -- end if;
 -- exception
 --   when others then
 --     v_value := null;
 -- end;
            begin
                select
                    nvl(standard_rate, 0),
                    nvl(agreement_rate, 0)
                into
                    l_standard_rate,
                    l_agreement_rate
                from
                    xxgpms_project_rates
                where
                        expenditure_item_id = i.expenditure_item_id
                    and session_id = v('APP_SESSION');

            exception
                when others then
                    wip_debug(2, 9888, 'Error : ' || sqlerrm, '');
                    l_standard_rate := 0;
                    l_agreement_rate := 0;
            end;
 --   L_STANDARD_RATE := TO_CHAR(L_STANDARD_RATE,'9999999990.00');
 --   L_AGREEMENT_RATE := TO_CHAR(L_AGREEMENT_RATE,'9999999990.00');
            wip_debug(2,
                      9013,
                      'Populate Rates, Value Returned '
                      || to_char(l_standard_rate, '9999990.99')
                      || ' '
                      || to_char(l_agreement_rate, '9999990.99')
                      || ' for '
                      || i.expenditure_item_id
                      || ' '
                      || i.project_id
                      || ' '
                      || i.wip_category
                      || ' '
                      || i.task_id
                      || ' '
                      || i.incurred_by_person_id
                      || ' '
                      || i.expenditure_item_date,
                      '');

            l_url := instance_url
                     || '/fscmRestApi/resources/11.13.18.05/projectExpenditureItems/'
                     || i.expenditure_item_id
                     || '/child/ProjectExpenditureItemsDFF/'
                     || i.expenditure_item_id;

            l_envelope := '{
            "standardBillRate": '
                          || to_char(l_standard_rate, '9999990.99')
                          || '
            ,"projectBillRate": '
                          || to_char(l_agreement_rate, '9999990.99')
                          || '
            ,"realizedBillRate": '
                          || to_char(l_agreement_rate, '9999990.99')
                          || '
            }';

            apex_web_service.g_request_headers(1).name := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'application/json';
            wip_debug(3, 9014, l_url, '');
            wip_debug(3, 9015, i.expenditure_item_id
                               || ' for Envelope: '
                               || l_envelope, '');
 -- APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).NAME := 'Authorization';
 -- APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'Bearer ' || v ('G_SAAS_ACCESS_TOKEN');
            l_response_clob := apex_web_service.make_rest_request(
                p_url         => l_url,
                p_http_method => 'PATCH',
 --  P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
 -- p_token_url => v ('G_SAAS_ACCESS_TOKEN'),
 -- P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
 --  p_username => g_username,
 --  p_password => g_password,
                p_scheme      => 'OAUTH_CLIENT_CRED',
                p_body        => l_envelope
            );

            apex_web_service.g_request_headers.delete();
            wip_debug(2, 9050, i.expenditure_item_id, l_response_clob);
            v_statuscode := apex_web_service.g_status_code;
 -- UPDATE THE TABLE DATA IF THE WEBSERVICE RESPONSE IS SUCCESS
            wip_debug(2, 9016, 'webservice response for populate_rates_onload '
                               || i.expenditure_item_id
                               || ' '
                               || v_statuscode
                               || ' Response: '
                               || apex_web_service.g_status_code, '');

            if v_statuscode in ( 200, 201 ) then
                update xxgpms_project_costs
                set
                    standard_bill_rate_attr = l_standard_rate,
                    project_bill_rate_attr = l_agreement_rate,
                    realized_bill_rate_attr = l_agreement_rate,
                    standard_bill_rate_amt = to_char((l_standard_rate * quantity), '9999999990.00'),
                    project_bill_rate_amt = to_char((l_agreement_rate * quantity), '9999999990.00'),
                    realized_bill_rate_amt = to_char((l_agreement_rate * quantity), '9999999990.00')
                where
                    expenditure_item_id = i.expenditure_item_id;

            end if;

        end loop;

        wip_debug(2, 9350, 'End Populate Rates Onload for Project: ' || p_project_number, '');
    end populate_rates_onload; ---
    procedure get_user_details (
        user_email in varchar2
    ) is

        l_url                  varchar2(4000) := p_url;
        l_version              varchar2(1000) := '1.2';
        l_envelope             varchar2(10000);
        l_xml_response         xmltype;
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        l_otbi_flag            varchar2(1) := 'N';
    begin
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
        l_envelope := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
			<soap:Header/>
			   <soap:Body>
				  <pub:runReport>
					 <pub:reportRequest>
					   <pub:attributeFormat>xml</pub:attributeFormat>
						 <pub:parameterNameValues>
							<pub:item>
								<pub:name>USER_EMAIL</pub:name>
								<pub:values>
									<pub:item>'
                      || user_email
                      || '</pub:item>
								</pub:values>
							</pub:item>
						</pub:parameterNameValues>
					   <pub:reportAbsolutePath>/Custom/Projects/Project Billing/Project Costs Report.xdo</pub:reportAbsolutePath>
					   <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
					 </pub:reportRequest>
					 <pub:appParams></pub:appParams>
				  </pub:runReport>
			   </soap:Body>
			</soap:Envelope>';
        wip_debug(3, 6000, 'Users Envelope ', l_envelope);
 -- l_xml_response := apex_web_service.make_request ( p_url => l_url, p_version => l_version, p_action => 'runReport', p_envelope => l_envelope, p_username => g_username, p_password => g_password );
        l_xml_response := apex_web_service.make_request(
            p_url      => l_url,
            p_version  => l_version,
            p_action   => 'runReport',
            p_envelope => l_envelope
 -- ,P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
        );

        wip_debug(3,
                  6001,
                  'Web Service Response ',
                  l_xml_response.getclobval());
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        commit;
        insert into xxgpms_user_roles (
            user_login,
            user_id,
            role_name,
            first_name,
            last_name,
            location_code,
            location_name,
            town,
            country,
            department,
            username,
            active_flag
        )
            select
                user_login,
                user_id,
                role_name,
                first_name,
                last_name,
                location_code,
                location_name,
                town,
                country,
                department,
                username,
                active_flag
            from
                xmltable ( '/DATA_DS/G_USER_ROLES'
                        passing xmltype(l_clob_report_decode)
                    columns
                        user_login path 'USER_LOGIN',
                        user_id path 'USER_ID',
                        role_name path 'ROLE_NAME',
 -- CREATION_DATE PATH 'CREATION_DATE',
                        first_name path 'FIRST_NAME',
                        last_name path 'LAST_NAME',
                        location_code path 'LOCATION_CODE',
                        location_name path 'LOCATION_NAME',
                        town path 'TOWN',
                        country path 'COUNTRY',
                        department path 'DEPARTMENT',
                        username path 'USERNAME',
                        active_flag path 'ACTIVE_FLAG'
                ) xt;

        dbms_lob.freetemporary(l_clob_report_response);
        dbms_lob.freetemporary(l_clob_report_decode);
        dbms_lob.freetemporary(l_clob_temp);
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
    end; --
    procedure get_users is

        l_url                  varchar2(4000) := p_url;
        l_version              varchar2(1000) := '1.2';
        l_envelope             varchar2(10000);
        l_xml_response         xmltype;
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        l_otbi_flag            varchar2(1) := 'N';
    begin
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
        wip_debug(3, 6000, 'Users Envelope ', l_envelope);
 -- l_xml_response := apex_web_service.make_request ( p_url => l_url, p_version => l_version, p_action => 'runReport', p_envelope => l_envelope, p_username => g_username, p_password => g_password );
        l_xml_response := apex_web_service.make_request(
            p_url      => l_url,
            p_version  => l_version,
            p_action   => 'runReport',
            p_envelope => l_envelope
 -- ,P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
        );

        wip_debug(3,
                  6001,
                  'Web Service Response ',
                  l_xml_response.getclobval());
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        commit;
        insert into xxgpms_users (
            user_id,
            business_group_id,
            active_flag,
            user_guid,
            username,
            multitenancy_username,
            person_id,
            party_id,
            object_version_number
        )
            select
                user_id,
                business_group_id,
                active_flag,
                user_guid,
                username,
                multitenancy_username,
                person_id,
                party_id,
                object_version_number
            from
                xmltable ( '/DATA_DS/G_USERS'
                        passing xmltype(l_clob_report_decode)
                    columns
                        user_id path 'USER_ID',
                        business_group_id path 'BUSINESS_GROUP_ID',
                        active_flag path 'ACTIVE_FLAG',
                        user_guid path 'USER_GUID',
                        username path 'USERNAME',
                        multitenancy_username path 'MULTITENANCY_USERNAME',
                        person_id path 'PERSON_ID',
                        party_id path 'PARTY_ID',
                        object_version_number path 'OBJECT_VERSION_NUMBER'
                ) xt;

        dbms_lob.freetemporary(l_clob_report_response);
        dbms_lob.freetemporary(l_clob_report_decode);
        dbms_lob.freetemporary(l_clob_temp);
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
    end;

    procedure update_invoice_header_dffs (
        p_contract_id   in number,
        p_job_id        in number,
        p_attr1         in number default 0,
        p_response_code out number
    ) is

        l_url                        varchar2(4000);
        l_version                    varchar2(10) := 1.2;
        l_response_clob              clob;
        l_envelope                   varchar2(32000);
        p_exp_amt                    number;
        p_internal_comment           varchar2(1000);
        p_narrative_billing_overflow varchar2(1000);
        p_event_attr                 varchar2(50);
        p_standard_bill_rate_attr    number;
        p_project_bill_rate_attr     number;
        p_realized_bill_rate_attr    number;
        p_billable_flag              varchar2(10);
        p_expenditure_item_id        number;
        v_statuscode                 number;
        v_value                      number;
        l_xml_response               xmltype;
        l_clob_report_response       clob;
        l_clob_report_decode         clob;
        l_clob_temp                  clob;
        v_attr1                      varchar2(1000);
        v_attr2                      varchar2(1000);
        l_standard_rate              number;
        l_agreement_rate             number;
        v_invoice_id                 number;
        l_attr1                      number;
        l_attr2                      number;
        l_attr3                      number;
        l_attr4                      number;
        l_attr5                      number;
        l_attr6                      number;
    begin
        wip_debug(3, 12000, 'Update Invoice Header DFFs
      Contract ID : ' || p_contract_id, ' JOB ID ' || p_job_id);
        l_version := '1.2';
        if p_url is null then
            p_url := instance_url || '/xmlpserver/services/ExternalReportWSSService';
        end if;
        l_url := p_url;
 -- Call to the OTBI to fetch the projects rates
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
        l_envelope := q'#<?xml version="1.0" encoding="UTF-8"?>#';
        l_envelope := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
						<soap:Header/>
			   <soap:Body>
				  <pub:runReport>
					 <pub:reportRequest>
					   <pub:attributeFormat>xml</pub:attributeFormat>
						 <pub:parameterNameValues>
							<pub:item>
								<pub:name>P_CONTRACT_ID</pub:name>
								<pub:values>
									<pub:item>'
                      || p_contract_id
                      || '</pub:item>
								</pub:values>
							</pub:item>
              <pub:item>
								<pub:name>P_JOB_ID</pub:name>
								<pub:values>
									<pub:item>'
                      || p_job_id
                      || '</pub:item>
								</pub:values>
							</pub:item>
						</pub:parameterNameValues>
					   <pub:reportAbsolutePath>/Custom/Projects/Project Billing/Project Costs Report.xdo</pub:reportAbsolutePath>
					   <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
					 </pub:reportRequest>
					 <pub:appParams></pub:appParams>
				  </pub:runReport>
			   </soap:Body>
			</soap:Envelope>';
        wip_debug(3, 120001, 'Envelope ', l_envelope);
        wip_debug(3, 120002, 'URL ', l_url);
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
 -- APEX_WEB_SERVICE.G_REQUEST_HEADERS (1).VALUE := 'Bearer eyJ4NXQiOiJpeHZkTmRWSWJQdy1VVzUtdFhybS1lTE1GWFEiLCJraWQiOiJ0cnVzdHNlcnZpY2UiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJBTVkuTUFSTElOIiwiaXNzIjoid3d3Lm9yYWNsZS5jb20iLCJleHAiOjE2ODg2NTQwMjQsInBybiI6IkFNWS5NQVJMSU4iLCJpYXQiOjE2ODg2Mzk2MjR9.XbZJNiWIf9GJXFlYF7P59BPV7O45pk9UlCEgfKGEgXGrLFTN2qC9IGYF9I35rsDLJ0HzJHu77IcmrSerSAYzfwPLor2GBDtIXyiKrVa45bZaTZ_YM6OLeD8Ic_axuZkuwDLcpASXNGNkJOHGG8gVBg7E7FHeY8vcO_vW7b33UJsLtblKVfR8UkQTx9_pHyNY_2-iOw8gN8-OreT_JVhEU53kHaTyW0OVq_GAniyhLjhq59JYfcA08ZI0XHAu0T5BSP3gfa3QmUMqkigVUagUl2tyO7Nitqt43MPiZ8tFUJVbgFAWZYFvLksBnq9uWPWe7_Fs3sfbBvdivYBoemLF1w';
 -- l_xml_response := apex_web_service.make_request ( p_url => l_url, p_version => l_version, p_action => 'runReport', p_envelope => l_envelope, p_username => g_username, p_password => g_password );
        l_xml_response := apex_web_service.make_request(
            p_url      => l_url,
            p_version  => l_version,
            p_action   => 'runReport',
            p_envelope => l_envelope
 -- ,P_CREDENTIAL_STATIC_ID => 'GPMS_DEV'
        );

        wip_debug(3,
                  120003,
                  'Bearer Token ',
                  'Bearer ' || v('G_SAAS_ACCESS_TOKEN'));
        wip_debug(3,
                  120004,
                  'Web Service Response',
                  l_xml_response.getclobval());
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        commit;
 -- End
        wip_debug(3, 120005, 'Web Service Response Decoded', l_clob_report_decode);
        begin
            delete from xxgpms_project_invoices
            where
                session_id = v('APP_SESSION');

            commit;
 -- SELECT
 --     INVOICE_ID
 -- INTO V_INVOICE_ID
 --   FROM
 --     XMLTABLE( '/DATA_DS/G_INVOICE_HEADERS' PASSING XMLTYPE (L_CLOB_REPORT_DECODE) COLUMNS INVOICE_ID PATH 'INVOICE_ID') XT;
 -- exception
 --   when others then
 --   V_INVOICE_ID := NULL;
            insert into xxgpms_project_invoices (
                invoice_id,
                contract_id,
                invoice_currency_code,
                request_id,
                created_by,
                creation_date,
                invoice_line_id,
                invoice_curr_billed_amt,
                invoice_date,
                org_id,
                session_id,
                write_off_amount
            )
                select
                    invoice_id,
                    contract_id,
                    invoice_currency_code,
                    request_id,
                    created_by,
                    creation_date,
                    invoice_line_id,
                    invoice_curr_billed_amt,
                    invoice_date,
                    org_id,
                    v('APP_SESSION'),
                    write_off_amount
                from
                    xmltable ( '/DATA_DS/G_INVOICE_HEADERS'
                            passing xmltype(l_clob_report_decode)
                        columns
                            invoice_id path 'INVOICE_ID',
                            contract_id path 'CONTRACT_ID',
                            invoice_currency_code path 'INVOICE_CURRENCY_CODE',
                            request_id path 'REQUEST_ID',
                            created_by path 'PC',
                            creation_date path 'CREATION_DATE',
                            invoice_line_id path 'INVOICE_LINE_ID',
                            invoice_curr_billed_amt path 'INVOICE_CURR_BILLED_AMT',
                            invoice_date path 'INVOICE_DATE',
                            org_id path 'ORG_ID',
                            write_off_amount path 'WRITE_OFF_AMOUNT'
                    );

        end;

        commit;
        wip_debug(3, 120006, 'Response of Web service' || apex_web_service.g_status_code, '');
        begin
            select distinct
                job_approval_id
            into l_attr2
            from
                xxgpms_project_costs
            where
                    1 = 1 --SESSION_ID   = V('APP_SESSION')
                and project_id in (
                    select distinct
                        project_id
                    from
                        xxgpms_project_contract
                    where
                        contract_id = p_contract_id
                )
                and job_approval_id is not null;

        exception
            when others then
                l_attr2 := null;
        end;

        for i in (
            select
                *
            from
                xxgpms_project_invoices
            where
                session_id = v('APP_SESSION')
        ) loop
 -- PATCH THE DFF VALUES
 -- ATTRIBUTE 1 IS  TOTAL WRITE/UP DOWN AMOUNT
 -- select sum(INVOICE_CURR_BILLED_AMT)*-1
 -- into   L_ATTR1
 -- from   xxgpms_project_invoices
 -- where  1=1--session_id = v('APP_SESSION')
 -- and    contract_id = P_CONTRACT_ID;
 -- and    trunc(creation_date) = trunc(sysdate)
            l_attr1 := i.write_off_amount;
 -- ATTRIBUTE 2 IS THE JOB APPROVAL ID
 -- for i in (select sum(BILL_TRNS_AMOUNT) amt ,wip_category
 --  from   XXGPMS_PROJECT_EVENTS
 --  where  session_id = v('APP_SESSION')
 --  group  by wip_category)
 -- loop
 --   if i.wip_category = 'Labor Fees'
 --   then
 --     l_attr3 := i.amt;
 --   elsif i.wip_category =  'Hard Costs'
 --   then
 --     l_attr4 := i.amt;
 --   elsif i.wip_category = 'Soft Costs'
 --   then
 --     l_attr5 := i.amt;
 --   elsif i.wip_category = 'Fees'
 --   then
 --     l_attr6 := i.amt;
 --   end if;
 -- end loop;
            wip_debug(3, 120007, i.invoice_id
                                 || ' '
                                 || l_attr1
                                 || ' '
                                 || l_attr2
                                 || ' '
                                 || l_attr3
                                 || ' '
                                 || l_attr4
                                 || ' '
                                 || l_attr5
                                 || ' '
                                 || l_attr6, '');

            l_url := instance_url
                     || '/fscmRestApi/resources/11.13.18.05/projectContractInvoices/'
                     || i.invoice_id
                     || '/child/InvoiceHeaderDff/'
                     || i.invoice_id;

            wip_debug(3, 120008, l_url, '');
            l_envelope := '{"writeOffAmount" : "'
                          || nvl(l_attr1, 0)
                          || '",
      "jobApprovalLevel" : "'
                          || l_attr2
                          || '",
      "totalLaborAmount" : "'
                          || nvl(l_attr3, 0)
                          || '",
      "totalHardCostAmount" : "'
                          || nvl(l_attr4, 0)
                          || '",
      "totalSoftCostAmount" : "'
                          || nvl(l_attr5, 0)
                          || '",
      "totalFeesAmount" : "'
                          || nvl(l_attr6, 0)
                          || '"
       }';

            wip_debug(3, 120009, l_envelope, '');
            apex_web_service.g_request_headers(1).name := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'application/json';
            l_response_clob := apex_web_service.make_rest_request(
                p_url         => l_url,
                p_http_method => 'PATCH',
                p_scheme      => 'OAUTH_CLIENT_CRED',
                p_body        => l_envelope
            );

            wip_debug(3, 120010, l_response_clob, '');
            wip_debug(3, 120011, apex_web_service.g_status_code, '');
        end loop;

    end; -- Submit the Invoice
    procedure submit_invoice is

        l_url                        varchar2(4000) := p_url;
        l_version                    varchar2(10) := 1.2;
        l_response_clob              clob;
        l_envelope                   varchar2(32000);
        p_exp_amt                    number;
        p_internal_comment           varchar2(1000);
        p_narrative_billing_overflow varchar2(1000);
        p_event_attr                 varchar2(50);
        p_standard_bill_rate_attr    number;
        p_project_bill_rate_attr     number;
        p_realized_bill_rate_attr    number;
        p_billable_flag              varchar2(10);
        p_expenditure_item_id        number;
        v_statuscode                 number;
        v_value                      number;
        l_xml_response               xmltype;
        l_clob_report_response       clob;
        l_clob_report_decode         clob;
        l_clob_temp                  clob;
        v_attr1                      varchar2(1000);
        v_attr2                      varchar2(1000);
        l_standard_rate              number;
        l_agreement_rate             number;
        v_invoice_id                 number;
        l_attr1                      number;
        l_attr2                      number;
        l_attr3                      number;
        l_attr4                      number;
        l_attr5                      number;
        l_attr6                      number;
    begin
        wip_debug(3, 13000, 'Submit the Invoice', '');
        l_version := '1.2';
        for i in (
            select
                *
            from
                xxgpms_project_invoices
            where
                session_id = v('APP_SESSION')
        ) loop
            l_url := instance_url
                     || '/fscmRestApi/resources/11.13.18.05/projectContractInvoices/'
                     || i.invoice_id
                     || '/action/submitProjectContractInvoice';
            wip_debug(3, 13001, l_url, 'Invoice ' || i.invoice_id);
            apex_web_service.g_request_headers(1).name := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'application/vnd.oracle.adf.action+json';
            l_response_clob := apex_web_service.make_rest_request(
                p_url         => l_url,
                p_http_method => 'POST',
                p_scheme      => 'OAUTH_CLIENT_CRED'
            );

            wip_debug(3, 13002, l_response_clob, '');
            wip_debug(3, 13003, apex_web_service.g_status_code, '');
        end loop;

    end; --
    procedure get_invoice_history (
        p_contract_id in number
    ) is

        l_url                  varchar2(4000) := p_url;
        l_version              varchar2(10) := 1.2;
        l_response_clob        clob;
        l_envelope             varchar2(32000);
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        l_xml_response         xmltype;
    begin
        wip_debug(3, 15000, 'Get Invoice History Contract ID: ' || p_contract_id, null);
        l_version := '1.2';
        if p_url is null then
            p_url := instance_url || '/xmlpserver/services/ExternalReportWSSService';
        end if;
        l_url := p_url;
 -- Call to the OTBI to fetch the projects rates
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
        l_envelope := q'#<?xml version="1.0" encoding="UTF-8"?>#';
        l_envelope := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
						<soap:Header/>
			   <soap:Body>
				  <pub:runReport>
					 <pub:reportRequest>
					   <pub:attributeFormat>xml</pub:attributeFormat>
						 <pub:parameterNameValues>
							<pub:item>
								<pub:name>P_CONTRACT_ID_2</pub:name>
								<pub:values>
									<pub:item>'
                      || p_contract_id
                      || '</pub:item>
								</pub:values>
                                </pub:item>
						</pub:parameterNameValues>
					   <pub:reportAbsolutePath>/Custom/Projects/Project Billing/Project Costs Report.xdo</pub:reportAbsolutePath>
					   <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
					 </pub:reportRequest>
					 <pub:appParams></pub:appParams>
				  </pub:runReport>
			   </soap:Body>
			</soap:Envelope>';
        wip_debug(3, 150001, 'Envelope ', l_envelope);
        wip_debug(3, 150002, 'URL ', l_url);
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
        l_xml_response := apex_web_service.make_request(
            p_url      => l_url,
            p_version  => l_version,
            p_action   => 'runReport',
            p_envelope => l_envelope
        );

        wip_debug(3,
                  150003,
                  'Bearer Token ',
                  'Bearer ' || v('G_SAAS_ACCESS_TOKEN'));
        wip_debug(3,
                  150004,
                  'Web Service Response',
                  l_xml_response.getclobval());
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        commit;
        wip_debug(3, 150005, 'Web Service Response Decoded', l_clob_report_decode);
        begin
            insert into xxgpms_project_invoice_history (
                invoice_date,
                invoice_number,
                adjustments,
                invoice_amount,
                tax,
                total_invoice_amount,
                open_balance,
                last_receipt_date,
                session_id,
                contract_id,
                invoice_id
            )
                select
                    invoice_date,
                    invoice_number,
                    nvl(adjustments, 0),
                    invoice_amount,
                    tax,
                    total_invoice_amount,
                    open_balance,
                    last_receipt_date,
                    v('APP_SESSION'),
                    p_contract_id,
                    invoice_id
                from
                    xmltable ( '/DATA_DS/G_INVOICE_HISTORY'
                            passing xmltype(l_clob_report_decode)
                        columns
                            invoice_date path 'TRX_DATE',
                            invoice_number path 'TRX_NUMBER',
                            adjustments path 'ADJUSTED_AMOUNT',
                            invoice_amount path 'INVOICE_AMOUNT',
                            tax path 'TAX_AMOUNT',
                            total_invoice_amount path 'TOTAL_INVOICE_AMOUNT',
                            open_balance path 'AMOUNT_DUE_REMAINING',
                            last_receipt_date path 'LAST_RCPT_DATE',
                            invoice_id path 'PROJECT_INVOICE_ID'
                    );

        end;

        commit;
        wip_debug(3, 150006, 'Response of Web service' || apex_web_service.g_status_code, '');
    exception
        when others then
            wip_debug(3, 15555, dbms_utility.format_error_backtrace
                                || ' '
                                || sqlerrm, '');
    end get_invoice_history;
  --
    procedure get_matter_credits (
        p_contract_id in number
    ) is

        l_url                  varchar2(4000) := p_url;
        l_version              varchar2(10) := 1.2;
        l_response_clob        clob;
        l_envelope             varchar2(32000);
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        l_xml_response         xmltype;
    begin
        wip_debug(3, 19000, 'Get Matter Credits Contract ID: ' || p_contract_id, null);
        l_version := '1.2';
        if p_url is null then
            p_url := instance_url || '/xmlpserver/services/ExternalReportWSSService';
        end if;
        l_url := p_url;
 -- Call to the OTBI to fetch the projects rates
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
        l_envelope := q'#<?xml version="1.0" encoding="UTF-8"?>#';
        l_envelope := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
						<soap:Header/>
			   <soap:Body>
				  <pub:runReport>
					 <pub:reportRequest>
					   <pub:attributeFormat>xml</pub:attributeFormat>
						 <pub:parameterNameValues>
							<pub:item>
								<pub:name>P_CONTRACT_ID</pub:name>
								<pub:values>
									<pub:item>'
                      || p_contract_id
                      || '</pub:item>
								</pub:values>
                                </pub:item>
						</pub:parameterNameValues>
					   <pub:reportAbsolutePath>/Custom/Projects/Project Billing/Project Costs Report.xdo</pub:reportAbsolutePath>
					   <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
					 </pub:reportRequest>
					 <pub:appParams></pub:appParams>
				  </pub:runReport>
			   </soap:Body>
			</soap:Envelope>';
        wip_debug(3, 19001, 'Envelope ', l_envelope);
        wip_debug(3, 19002, 'URL ', l_url);
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
        l_xml_response := apex_web_service.make_request(
            p_url      => l_url,
            p_version  => l_version,
            p_action   => 'runReport',
            p_envelope => l_envelope
        );

        wip_debug(3,
                  19003,
                  'Bearer Token ',
                  'Bearer ' || v('G_SAAS_ACCESS_TOKEN'));
        wip_debug(3,
                  19004,
                  'Web Service Response',
                  l_xml_response.getclobval());
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        commit;
        wip_debug(3, 19005, 'Web Service Response Decoded', l_clob_report_decode);
        begin
            insert into xxgpms_matter_credits (
                matter_number,
                invoice_currency_code,
                credit_type,
                billed,
                paid,
                applied,
                available,
                session_id
            )
                select
                    project_number,
                    invoice_currency_code,
                    expenditure_type_name,
                    billed_amount,
                    paid_amount,
                    applied_amount,
                    available_amount,
                    v('APP_SESSION')
                from
                    xmltable ( '/DATA_DS/G_MATTER_CREDITS'
                            passing xmltype(l_clob_report_decode)
                        columns
                            project_number path 'PROJECT_NUMBER',
                            invoice_currency_code path 'INVOICE_CURRENCY_CODE',
                            expenditure_type_name path 'EXPENDITURE_TYPE_NAME',
                            billed_amount path 'BILLED_AMOUNT',
                            paid_amount path 'PAID_AMOUNT',
                            applied_amount path 'APPLIED_AMOUNT',
                            available_amount path 'AVAILABLE_AMOUNT'
                    );

        end;

        commit;
        wip_debug(3, 19006, 'Response of Web service ' || apex_web_service.g_status_code, '');
    exception
        when others then
            wip_debug(3, 19099, dbms_utility.format_error_backtrace
                                || ' '
                                || sqlerrm, '');
    end get_matter_credits;
  --
    procedure get_interprojects (
        p_contract_id in number
    ) is

        l_url                  varchar2(4000) := p_url;
        l_version              varchar2(10) := 1.2;
        l_response_clob        clob;
        l_envelope             varchar2(32000);
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        l_xml_response         xmltype;
    begin
        wip_debug(3, 21000, 'Get Inter Projects Contract ID: ' || p_contract_id, null);
        l_version := '1.2';
        if p_url is null then
            p_url := instance_url || '/xmlpserver/services/ExternalReportWSSService';
        end if;
        l_url := p_url;
 -- Call to the OTBI to fetch the projects rates
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
        l_envelope := q'#<?xml version="1.0" encoding="UTF-8"?>#';
        l_envelope := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
						<soap:Header/>
			   <soap:Body>
				  <pub:runReport>
					 <pub:reportRequest>
					   <pub:attributeFormat>xml</pub:attributeFormat>
						 <pub:parameterNameValues>
							<pub:item>
								<pub:name>P_CONTRACT_ID</pub:name>
								<pub:values>
									<pub:item>'
                      || p_contract_id
                      || '</pub:item>
								</pub:values>
                                </pub:item>
						</pub:parameterNameValues>
					   <pub:reportAbsolutePath>/Custom/Projects/Project Billing/Project Costs Report.xdo</pub:reportAbsolutePath>
					   <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
					 </pub:reportRequest>
					 <pub:appParams></pub:appParams>
				  </pub:runReport>
			   </soap:Body>
			</soap:Envelope>';
        wip_debug(3, 21001, 'Envelope ', l_envelope);
        wip_debug(3, 21002, 'URL ', l_url);
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
        l_xml_response := apex_web_service.make_request(
            p_url      => l_url,
            p_version  => l_version,
            p_action   => 'runReport',
            p_envelope => l_envelope
        );

        wip_debug(3,
                  21003,
                  'Bearer Token ',
                  'Bearer ' || v('G_SAAS_ACCESS_TOKEN'));
        wip_debug(3,
                  21004,
                  'Web Service Response',
                  l_xml_response.getclobval());
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        commit;
        wip_debug(3, 21005, 'Web Service Response Decoded', l_clob_report_decode);
        begin
            insert into xxgpms_interprojects (
                project_number,
                labor_wip,
                fees_wip,
                hard_wip,
                soft_wip,
                session_id
            )
                select
                    project_number,
                    labor_wip,
                    fees_wip,
                    hard_wip,
                    soft_wip,
                    v('APP_SESSION')
                from
                    xmltable ( '/DATA_DS/G_INTERPROJECT'
                            passing xmltype(l_clob_report_decode)
                        columns
                            project_number path 'PROJECT_NUMBER',
                            labor_wip path 'LABOR_WIP',
                            fees_wip path 'FEES_WIP',
                            hard_wip path 'HARD_WIP',
                            soft_wip path 'SOFT_WIP'
                    );

        end;

        commit;
        wip_debug(3, 21006, 'Response of Web service ' || apex_web_service.g_status_code, '');
    exception
        when others then
            wip_debug(3, 21099, dbms_utility.format_error_backtrace
                                || ' '
                                || sqlerrm, '');
    end get_interprojects;
  --
    procedure get_all_matters is

        l_response_clob        clob;
        l_url                  varchar2(4000) := p_url;
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        l_version              varchar2(10) := 1.2;
        l_envelope             varchar2(32000);
        l_xml_response         xmltype;
        v_statuscode           number;
        v_last_load_ts         timestamp;
    begin
        wip_debug(3, 160000, 'Get All Matters and Tasks', '');
        l_version := '1.2';
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
        update xxgpms_job_logs
        set
            start_ts = systimestamp
        where
            job_name = 'LOAD_PROJECTS';
    --

        begin
            select
                end_ts
            into v_last_load_ts
            from
                xxgpms_job_logs
            where
                job_name = 'LOAD_PROJECTS'
            order by
                end_ts desc
            fetch first row only;

        exception
            when others then
                v_last_load_ts := null;
        end;

        l_envelope := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
			<soap:Header/>
			   <soap:Body>
				  <pub:runReport>
					 <pub:reportRequest>
					   <pub:attributeFormat>xml</pub:attributeFormat>
                       <pub:parameterNameValues>
							<pub:item>
								<pub:name>P_PROJECT_CREATION_DATE</pub:name>
								<pub:values>
									<pub:item>'
                      || nvl(v_last_load_ts, '01-01-1001')
                      || '</pub:item>
								</pub:values>
							</pub:item>
                       </pub:parameterNameValues>
					   <pub:reportAbsolutePath>/Custom/Projects/Project Billing/Project Costs Report.xdo</pub:reportAbsolutePath>
					   <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
					 </pub:reportRequest>
					 <pub:appParams></pub:appParams>
				  </pub:runReport>
			   </soap:Body>
			</soap:Envelope>';
    --
        wip_debug(3, 160001, 'Get Matters and Tasks Envelope ', l_envelope);
        wip_debug(3, 160002, l_url, '');
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
        wip_debug(3,
                  160003,
                  'Get Matters and Tasks Bearer Token ',
                  'Bearer ' || v('G_SAAS_ACCESS_TOKEN'));
        if l_url is null then
            l_url := instance_url || '/xmlpserver/services/ExternalReportWSSService';
        end if;
        l_xml_response := apex_web_service.make_request(
            p_url      => l_url,
            p_version  => l_version,
            p_action   => 'runReport',
            p_envelope => l_envelope
        );

        v_statuscode := apex_web_service.g_status_code;
        wip_debug(3,
                  160004,
                  'Response',
                  l_xml_response.getclobval());
        wip_debug(3, 160005, 'Status Code: ' || v_statuscode, '');
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        commit;
        wip_debug(3, 160005, 'CLOB Response', l_clob_report_decode);
        if apex_web_service.g_status_code in ( 200, 201 ) then
            merge into xxgpms_projects d
            using (
                select
                    project_number,
                    task_id,
                    v('APP_SESSION')
                from
                    xmltable ( '/DATA_DS/G_ALL_PROJECTS'
                            passing xmltype(l_clob_report_decode)
                        columns
                            project_number path 'PROJECT_NUMBER',
                            task_id path 'TASK_NUMBER'
                    )
            ) xt on ( d.project_number = xt.project_number
                      and d.task_id = xt.task_id )
            when not matched then
            insert (
                d.project_number,
                d.task_id )
            values
                ( xt.project_number,
                  xt.task_id );

    --   insert into xxgpms_projects (project_number
    --   ,task_id
    --   ,session_id
    --   )
    --   select PROJECT_NUMBER,
    --          TASK_ID,
    --          V('APP_SESSION')
    --   from
    --     XMLTABLE( '/DATA_DS/G_ALL_PROJECTS' PASSING XMLTYPE (L_CLOB_REPORT_DECODE)
    --       COLUMNS PROJECT_NUMBER PATH 'PROJECT_NUMBER',
    --               TASK_ID PATH 'TASK_NUMBER') XT;
    -- insert into XXGPMS_JOB_LOGS(JOB_NAME,END_TS,STATUS) values ('LOAD_PROJECTS',SYSTIMESTAMP,'A');
            update xxgpms_job_logs
            set
                end_ts = systimestamp
            where
                job_name = 'LOAD_PROJECTS';

        end if;

    exception
        when others then
            wip_debug(3, 161000, dbms_utility.format_error_backtrace, '');
    end;
  ---
    procedure get_all_exp_types is

        l_response_clob        clob;
        l_url                  varchar2(4000) := p_url;
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        l_version              varchar2(10) := 1.2;
        l_envelope             varchar2(32000);
        l_xml_response         xmltype;
        v_statuscode           number;
    begin
        wip_debug(3, 20000, 'Get All Exp Types', '');
        l_version := '1.2';
        dbms_lob.createtemporary(l_clob_report_response, true);
        dbms_lob.createtemporary(l_clob_report_decode, true);
        dbms_lob.createtemporary(l_clob_temp, true);
    --
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
    --
        wip_debug(3, 20001, 'Get Exp Types Envelope ', l_envelope);
        wip_debug(3, 20002, l_url, '');
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer ' || v('G_SAAS_ACCESS_TOKEN');
        wip_debug(3,
                  20003,
                  'Get Exp types Bearer Token ',
                  'Bearer ' || v('G_SAAS_ACCESS_TOKEN'));
        if l_url is null then
            l_url := instance_url || '/xmlpserver/services/ExternalReportWSSService';
        end if;
        l_xml_response := apex_web_service.make_request(
            p_url      => l_url,
            p_version  => l_version,
            p_action   => 'runReport',
            p_envelope => l_envelope
        );

        v_statuscode := apex_web_service.g_status_code;
        wip_debug(3,
                  20004,
                  'Response',
                  l_xml_response.getclobval());
        wip_debug(3, 20005, 'Status Code: ' || v_statuscode, '');
        l_clob_report_response := apex_web_service.parse_xml_clob(
            p_xml   => l_xml_response,
            p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
            p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
        );

        l_clob_temp := substr(l_clob_report_response,
                              instr(l_clob_report_response, '>') + 1,
                              instr(
                                   substr(l_clob_report_response,
                                          instr(l_clob_report_response, '>') + 1),
                                   '</ns2:report'
                               ) - 1);

        l_clob_report_response := l_clob_temp;
        l_clob_report_decode := base64_decode_clob(l_clob_report_response);
        commit;
        wip_debug(3, 20006, 'CLOB Response', l_clob_report_decode);
        if apex_web_service.g_status_code in ( 200, 201 ) then
            insert into xxgpms_exp_types (
                expenditure_type_name,
                expenditure_type_id,
                session_id
            )
                select
                    expenditure_type_name,
                    expenditure_type_id,
                    v('APP_SESSION')
                from
                    xmltable ( '/DATA_DS/G_EXP_TYPES'
                            passing xmltype(l_clob_report_decode)
                        columns
                            expenditure_type_name path 'EXPENDITURE_TYPE_NAME',
                            expenditure_type_id path 'EXPENDITURE_TYPE_ID'
                    ) xt;

        end if;

    exception
        when others then
            wip_debug(3, 21000, dbms_utility.format_error_backtrace, '');
    end;
  ---
    procedure perform_unprocessed_costs_call (
        p_expenditure_item_id        varchar2,
        p_reversal                   in varchar2 default null,
        p_internal_comment           varchar2,
        p_narrative_billing_overflow in varchar2 default null,
        p_event_attr                 in varchar2 default null,
        p_standard_bill_rate_attr    in number default null,
        p_project_bill_rate_attr     in number default null,
        p_realized_bill_rate_attr    in number default null,
        p_hours_entered              in number default null,
        p_response                   out varchar2,
        p_response_code              out number
    ) is

        v_exp_costs_row     xxgpms_project_costs%rowtype;
        l_url               varchar2(4000);
        l_envelope          varchar2(32000);
        l_response_clob     clob;
        v_expenditure_batch varchar2(100);
        v_status            varchar2(100);
        v_original_quantity number;
        v_business_unit     varchar2(100);
        v_business_unit_id  number;
    begin
        select
            bu_name,
            business_unit_id
        into
            v_business_unit,
            v_business_unit_id
        from
            xxgpms_project_contract
        where
                rownum = 1
            and session_id = v('APP_SESSION')
            and project_number = project_number;

        for i in (
            select
                column_value exp_id
            from
                table (
                    select
                        apex_string.split(
                            trim(both '-' from p_expenditure_item_id),
                            '-'
                        )
                    from
                        dual
                )
        ) loop
            wip_debug(2, 14105, 'Expenditure Item ID ' || i.exp_id, '');
            select
                v('APP_SESSION'),
                transaction_source,
                document_name,
                doc_entry_name,
                'Pending',
                case
                    when p_reversal = 'Y' then
                        - 1 * quantity
                    else
                        p_hours_entered
                end,
                quantity,
                unit_of_measure,
                person_name,
                task_number,
                project_number,
                expenditure_type_name,
                orig_transaction_reference,
                expenditure_item_date,
                transaction_source_id,
                document_id,
                exp_org_id,
                expenditure_comment,
                realized_bill_rate_attr,
                project_bill_rate_attr,
                standard_bill_rate_attr
            into
                v_expenditure_batch,
                v_exp_costs_row.transaction_source,
                v_exp_costs_row.document_name,
                v_exp_costs_row.doc_entry_name,
                v_status,
                v_exp_costs_row.quantity,
                v_original_quantity,
                v_exp_costs_row.unit_of_measure,
                v_exp_costs_row.person_name,
                v_exp_costs_row.task_number,
                v_exp_costs_row.project_number,
                v_exp_costs_row.expenditure_type_name,
                v_exp_costs_row.orig_transaction_reference,
                v_exp_costs_row.expenditure_item_date,
                v_exp_costs_row.transaction_source_id,
                v_exp_costs_row.document_id,
                v_exp_costs_row.exp_org_id,
                v_exp_costs_row.expenditure_comment,
                v_exp_costs_row.realized_bill_rate_attr,
                v_exp_costs_row.project_bill_rate_attr,
                v_exp_costs_row.standard_bill_rate_attr
            from
                xxgpms_project_costs
            where
                    session_id = v('APP_SESSION')
                and expenditure_item_id = i.exp_id;

            l_url := instance_url || '/fscmRestApi/resources/11.13.18.05/unprocessedProjectCosts';
            l_envelope := '{"ExpenditureBatch" : "'
                          || v_expenditure_batch
                          || '",
                              "TransactionSource" : "'
                          || v_exp_costs_row.transaction_source
                          || '",
                              "BusinessUnit" : "'
                          || v_business_unit
                          || '",
                              "Document" : "'
                          || v_exp_costs_row.document_name
                          || '",
                              "DocumentEntry" : "'
                          || v_exp_costs_row.doc_entry_name
                          || '",
                              "Status" : "'
                          || v_status
                          || '",
                              "Quantity" : "'
                          || v_exp_costs_row.quantity
                          || '",
                              "UnitOfMeasureCode" : "'
                          || v_exp_costs_row.unit_of_measure
                          || '",
                              "PersonName" : "'
                          || v_exp_costs_row.person_name
                          || '",
                              "ReversedOriginalTransactionReference" : "'
                          ||
                case
                    when p_reversal = 'Y' then
                        v_exp_costs_row.orig_transaction_reference
                    else null
                end
                          || '",
                              "OriginalTransactionReference" : "'
                          ||
                case
                    when p_reversal = 'Y' then
                        regexp_replace(v_exp_costs_row.orig_transaction_reference, '*-[0-9]*', '-' || xxgpms_trans_seq.nextval)
                    else 'WIP-' || xxgpms_trans_seq.nextval
                end
                          || '",'
                          ||
                case
                    when p_reversal = 'Y' then
                        '
                         "UnmatchedNegativeTransactionFlag" : "false",'
                end
                          || '
                          "Comment" : "'
                          || v_exp_costs_row.expenditure_comment
                          || '",
                              "ProjectStandardCostCollectionFlexfields" : ['
                          || '{
                                                                                  "_EXPENDITURE_ITEM_DATE" : "'
                          || to_char(v_exp_costs_row.expenditure_item_date, 'YYYY-MM-DD')
                          || '",

                               "_ORGANIZATION_ID" : "'
                          || v_exp_costs_row.exp_org_id
                          || '",
                                                                                  "_PROJECT_ID_Display" : "'
                          || v_exp_costs_row.project_number
                          || '",
                                                                                  "_TASK_ID_Display" : "'
                          || v_exp_costs_row.task_number
                          || '",
                                                                                  "_EXPENDITURE_TYPE_ID_Display" : "'
                          || v_exp_costs_row.expenditure_type_name
                          || '"}],
                        "UnprocessedCostRestDFF":['
                          || '{"internalComment" : "'
                          || p_internal_comment
                          || '",
                               "narrativeBillingOverflow1" : "'
                          || p_narrative_billing_overflow
                          || '" ,
                               "event" : "'
                          || p_event_attr
                          || '" ,
                               "standardBillRate" : "'
                          || trim(v_exp_costs_row.standard_bill_rate_attr)
                          || '",
                               "projectBillRate" : "'
                          || trim(v_exp_costs_row.project_bill_rate_attr)
                          || '",
                               "realizedBillRate" : "'
                          || trim(nvl(p_realized_bill_rate_attr, v_exp_costs_row.realized_bill_rate_attr))
                          || '"}]}';

            apex_web_service.g_request_headers(1).name := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'application/json';
            wip_debug(2, 14150, l_url, '');
            wip_debug(2, 14200, l_envelope, '');
            l_response_clob := apex_web_service.make_rest_request(
                p_url         => l_url,
                p_http_method => 'POST',
                p_scheme      => 'OAUTH_CLIENT_CRED',
                p_body        => l_envelope
            );

            p_response_code := apex_web_service.g_status_code;
            p_response := l_response_clob;
            wip_debug(2, 14250, '', l_response_clob);
            wip_debug(3, 14260, apex_web_service.g_status_code, '');
        end loop;

    exception
        when others then
            wip_debug(3, 14300, sqlerrm, '');
    end;
  ---
    procedure perform_split_transfer (
        p_expenditure_item_id varchar2,
        p_justification       varchar2,
        p_response            out varchar2,
        p_response_code       out number,
        p_source_project      varchar2 default null,
        p_action              varchar2,
        p_total_hours         number
    ) is

        l_response_clob        clob;
        l_url                  varchar2(4000) := p_url;
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        l_version              varchar2(10) := 1.2;
        l_envelope             varchar2(32000);
        l_xml_response         xmltype;
        v_statuscode           number;
        v_final_response       clob;
        v_derived_quantity     number;
        v_task_number          number;
        v_billable_flag        varchar2(100);
    begin
        wip_debug(2, 170000, '', p_expenditure_item_id);
        if ( p_action in ( 'S', 'T' ) ) then
            for i in (
                select
                    column_value exp_id
                from
                    table (
                        select
                            apex_string.split(p_expenditure_item_id, '-')
                        from
                            dual
                    )
            ) loop
                l_url := instance_url
                         || '/fscmRestApi/resources/11.13.18.05/projectCosts/'
                         || i.exp_id
                         || '/action/adjustProjectCosts';
                wip_debug(2, 170001, '', l_url);
                for splits in (
                    select
                        *
                    from
                        xxgpms_project_split
                    where
                            session_id = v('APP_SESSION')
                        and action <> 'MULTI_SPLIT_TRANS'
                ) loop
                    if
                        splits.action = 'SPLIT'
                        and splits.task_number is null
                    then
                        select
                            task_number
                        into v_task_number
                        from
                            xxgpms_project_costs
                        where
                                expenditure_item_id = i.exp_id
                            and session_id = v('APP_SESSION');

                    end if;

                    if
                        splits.quantity is null
                        and splits.percentage is not null
                    then
               -- CONVERT PERCENTAGE TO QUANTITY
                        begin
                            select
                                quantity * ( splits.percentage / 100 )
                            into v_derived_quantity
                            from
                                xxgpms_project_costs
                            where
                                    expenditure_item_id = i.exp_id
                                and session_id = v('APP_SESSION');

                        exception
                            when others then
                                v_derived_quantity := null;
                        end;

                    end if;

                    begin
                        select
                            case billable_flag
                                when 'Y' then
                                    'Set to Billable'
                                when 'N' then
                                    'Set to nonbillable'
                            end
                        into v_billable_flag
                        from
                            xxgpms_project_costs
                        where
                                session_id = v('APP_SESSION')
                            and expenditure_item_id = i.exp_id;

                    exception
                        when others then
                            null;
                    end;

                    l_envelope := q'#{
                          "AdjustmentTypeCode": "#'
                                  || splits.action
                                  || q'#",
                          "ProjectNumber": "#'
                                  || splits.project_number
                                  || q'#",
                          "TaskNumber": "#'
                                  || nvl(splits.task_number, v_task_number)
                                  || q'#",
                          "Justification": "#'
                                  || p_justification
                                  || q'#",
                          "Quantity" : "#'
                                  || nvl(splits.quantity, v_derived_quantity)
                                  || q'#",
                          "AdjustmentType" : "#'
                                  || v_billable_flag
                                  || q'#"
                          }#';

                    wip_debug(2, 170002, '', l_envelope);
                    apex_web_service.g_request_headers(1).name := 'Content-Type';
                    apex_web_service.g_request_headers(1).value := 'application/vnd.oracle.adf.action+json';
                    l_response_clob := apex_web_service.make_rest_request(
                        p_url         => l_url,
                        p_http_method => 'POST',
                        p_body        => l_envelope,
                        p_scheme      => 'OAUTH_CLIENT_CRED'
                    );

                    apex_web_service.g_request_headers.delete();
                    wip_debug(2, 170003, '', l_response_clob);
                    p_response_code := apex_web_service.g_status_code;
                    select
                        results
                    into p_response
                    from
                        (
                            json_table ( l_response_clob, '$'
                                columns
                                    results varchar2 ( 1000 ) path '$.result'
                            )
                        );

                    if apex_web_service.g_status_code not in ( 200, 201 ) then
                        v_final_response := v_final_response
                                            || '</br> '
                                            || splits.action
                                            || ' of Expenditure Item ID: '
                                            || i.exp_id
                                            || ' to the project '
                                            || splits.project_number
                                            || ' and task '
                                            || splits.task_number
                                            || ' failed due to the following reason: '
                                            || l_response_clob;

                        exit;
                    else
                        v_statuscode := update_project_lines_dff(i.exp_id, p_justification);
                        if v_statuscode in ( 200, 201 ) then
                            v_final_response := v_final_response
                                                || '</br> '
                                                || splits.action
                                                || ' of Expenditure Item ID: '
                                                || i.exp_id
                                                || ' to the project '
                                                || splits.project_number
                                                || ' and task '
                                                || splits.task_number
                                                || ' succeeded: '
                                                || l_response_clob;

                        end if;

                    end if;

                end loop;

            end loop;

        else
    --   FOR I IN (SELECT COLUMN_VALUE EXP_ID FROM TABLE(SELECT APEX_STRING.SPLIT(P_EXPENDITURE_ITEM_ID,'-') FROM DUAL)
            --  )
    --   LOOP
            v_final_response := v_final_response
                                || ' '
                                || process_transfer_split(
                p_expenditure_item_list => p_expenditure_item_id,
                project_number          => p_source_project,
                p_justification         => p_justification,
                p_total_hours           => p_total_hours
            );
    --   END LOOP;
        -- P_RESPONSE := ltrim(V_FINAL_RESPONSE,'</br>');
            wip_debug(3, 170004, v_final_response, null);
            p_response := v_final_response;
        end if;

    exception
        when others then
            wip_debug(3, 171000, null, dbms_utility.format_error_backtrace);
    end;

---
    procedure perform_adjust_project_costs (
        p_expenditure_item_id  varchar2,
        p_adjustment_type_code in varchar2 default null,
        p_justification        in varchar2,
        p_expenditure_type     in varchar2 default null,
        p_quantity             in number default null,
        p_response             out varchar2,
        p_response_code        out number,
        p_adjustment_type      in varchar2 default null
    ) is
        l_url               varchar2(1000);
        v_project_costs_row xxgpms_project_costs%rowtype;
        l_response_clob     clob;
        l_envelope          varchar2(32000);
    begin
        wip_debug(2, 18000, p_expenditure_item_id, '');
        for i in (
            select
                column_value exp_id
            from
                table (
                    select
                        apex_string.split(
                            trim(both '-' from p_expenditure_item_id),
                            '-'
                        )
                    from
                        dual
                )
        ) loop
            l_url := instance_url
                     || '/fscmRestApi/resources/11.13.18.05/projectCosts/'
                     || i.exp_id
                     || '/action/adjustProjectCosts';
            select
                *
            into v_project_costs_row
            from
                xxgpms_project_costs
            where
                    session_id = v('APP_SESSION')
                and expenditure_item_id = i.exp_id;

            if p_adjustment_type_code is not null then
                l_envelope := q'#{
                               "AdjustmentTypeCode": "#'
                              || p_adjustment_type_code
                              || q'#",
                               "ProjectNumber": "#'
                              || v_project_costs_row.project_number
                              || q'#",
                               "TaskNumber": "#'
                              || v_project_costs_row.task_number
                              || q'#",
                               "Justification": "#'
                              || p_justification
                              || q'#",
                               "Quantity": "#'
                              || nvl(p_quantity, v_project_costs_row.quantity)
                              || q'#",
                               "ExpenditureType": "#'
                              || p_expenditure_type
                              || q'#"
                               }#';
            elsif p_adjustment_type is not null then
                l_envelope := q'#{
                               "AdjustmentType": "#'
                              || p_adjustment_type
                              || q'#",
                               "ProjectNumber": "#'
                              || v_project_costs_row.project_number
                              || q'#",
                               "TaskNumber": "#'
                              || v_project_costs_row.task_number
                              || q'#",
                               "Justification": "#'
                              || p_justification
                              || q'#",
                               "Quantity": "#'
                              || nvl(p_quantity, v_project_costs_row.quantity)
                              || q'#",
                               "ExpenditureType": "#'
                              || p_expenditure_type
                              || q'#"
                               }#';
            end if;

            apex_web_service.g_request_headers(1).name := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'application/vnd.oracle.adf.action+json';
            wip_debug(2, 18001, '', l_url);
            wip_debug(2, 18002, '', l_envelope);
            l_response_clob := apex_web_service.make_rest_request(
                p_url         => l_url,
                p_http_method => 'POST',
                p_body        => l_envelope,
                p_scheme      => 'OAUTH_CLIENT_CRED'
            );

            apex_web_service.g_request_headers.delete();
            wip_debug(2, 18003, '', l_response_clob);
            p_response_code := apex_web_service.g_status_code;
            p_response := l_response_clob;
        end loop;

    exception
        when others then
            wip_debug(2, 18099, '', sqlerrm);
    end;

---

    procedure perform_split_transfer_new (
        p_expenditure_item_id varchar2,
        p_justification       varchar2,
        p_response            out varchar2,
        p_response_code       out number,
        p_source_project      varchar2 default null,
        p_action              varchar2
    ) is

        l_response_clob        clob;
        l_url                  varchar2(4000) := p_url;
        l_clob_report_response clob;
        l_clob_report_decode   clob;
        l_clob_temp            clob;
        l_version              varchar2(10) := 1.2;
        l_envelope             varchar2(32000);
        l_xml_response         xmltype;
        v_statuscode           number;
        v_final_response       clob;
        v_derived_quantity     number;
    begin
        wip_debug(2, 170000, '', p_expenditure_item_id);
        for i in (
            select
                column_value exp_id
            from
                table (
                    select
                        apex_string.split(p_expenditure_item_id, '-')
                    from
                        dual
                )
        ) loop
            l_url := instance_url
                     || '/fscmRestApi/resources/11.13.18.05/projectCosts/'
                     || i.exp_id
                     || '/action/adjustProjectCosts';
            wip_debug(2, 170001, '', l_url);
            for splits in (
                select
                    *
                from
                    xxgpms_project_split
                where
                    session_id = v('APP_SESSION')
            ) loop
                if
                    splits.quantity is null
                    and splits.percentage is not null
                then
        -- CONVERT PERCENTAGE TO QUANTITY
                    begin
                        select
                            quantity * ( splits.percentage / 100 )
                        into v_derived_quantity
                        from
                            xxgpms_project_costs
                        where
                                expenditure_item_id = i.exp_id
                            and session_id = v('APP_SESSION');

                    exception
                        when others then
                            v_derived_quantity := null;
                    end;
                end if;

                if splits.action <> 'MULTI_SPLIT_TRANS' then
                    l_envelope := q'#{
                          "AdjustmentTypeCode": "#'
                                  || splits.action
                                  || q'#",
                          "ProjectNumber": "#'
                                  || splits.project_number
                                  || q'#",
                          "TaskNumber": "#'
                                  || splits.task_number
                                  || q'#",
                          "Justification": "#'
                                  || p_justification
                                  || q'#",
                          "Quantity" : "#'
                                  || nvl(splits.quantity, v_derived_quantity)
                                  || q'#"
                          }#';

                    wip_debug(2, 170002, '', l_envelope);
                    apex_web_service.g_request_headers(1).name := 'Content-Type';
                    apex_web_service.g_request_headers(1).value := 'application/vnd.oracle.adf.action+json';
                    l_response_clob := apex_web_service.make_rest_request(
                        p_url         => l_url,
                        p_http_method => 'POST',
                        p_body        => l_envelope,
                        p_scheme      => 'OAUTH_CLIENT_CRED'
                    );

                    apex_web_service.g_request_headers.delete();
                    wip_debug(2, 170003, '', l_response_clob);
                    p_response_code := apex_web_service.g_status_code;
                    if apex_web_service.g_status_code not in ( 200, 201 ) then
                        v_final_response := v_final_response
                                            || '</br> '
                                            || splits.action
                                            || ' of Expenditure Item ID: '
                                            || i.exp_id
                                            || ' to the project '
                                            || splits.project_number
                                            || ' and task '
                                            || splits.task_number
                                            || ' failed due to the following reason: '
                                            || l_response_clob;

                        exit;
                    else
                        v_final_response := v_final_response
                                            || '</br> '
                                            || splits.action
                                            || ' of Expenditure Item ID: '
                                            || i.exp_id
                                            || ' to the project '
                                            || splits.project_number
                                            || ' and task '
                                            || splits.task_number
                                            || ' succeeded: '
                                            || l_response_clob;
                    end if;
    -- ELSE
    --     V_FINAL_RESPONSE := V_FINAL_RESPONSE||' '||PROCESS_TRANSFER_SPLIT (P_EXPENDITURE_ITEM_LIST =>  I.EXP_ID,
    --                                                                        PROJECT_NUMBER    => P_SOURCE_PROJECT,
    --                                                                        P_JUSTIFICATION => P_JUSTIFICATION
    --                                                                       );
                end if;

            end loop;

      -- IF V_FINAL_RESPONSE <> '0'
      -- THEN
      --   EXIT;
      -- END IF;
        end loop;

        p_response := ltrim(v_final_response, '</br>');
    exception
        when others then
            wip_debug(3, 171000, '', dbms_utility.format_error_backtrace);
    end;

    procedure download_logs is
        l_context apex_exec.t_context;
        l_export  apex_data_export.t_export;
    begin
        l_context := apex_exec.open_query_context(
            p_location  => apex_exec.c_location_local_db,
            p_sql_query => 'select * from axxml_tab'
        );

        l_export := apex_data_export.export(
            p_context   => l_context,
            p_format    => apex_data_export.c_format_csv,
            p_file_name => 'Logs'
        );

        apex_exec.close(l_context);
        apex_data_export.download(p_export => l_export);
    exception
        when others then
            apex_exec.close(l_context);
            raise;
    end;

begin
 --   SELECT
 --     VALUE INTO G_PASSWORD1
 --   FROM
 --     GPMS_PROFILE_OPTIONS
 --   WHERE
 --     PROFILE_OPTION = 'CLOUD_PASSWORD';
 -- apex_credential.set_session_credentials (
 --   p_credential_static_id => 'GPMS_DEV',
 --   p_username => 'amy.marlin',
 --   p_password => g_password1
 -- );
 --   APEX_CREDENTIAL.SET_SESSION_TOKEN (
 --     P_CREDENTIAL_STATIC_ID => 'GPMS_DEV',
 --     P_TOKEN_TYPE => APEX_CREDENTIAL.C_TOKEN_ACCESS,
 --     P_TOKEN_VALUE => V ('G_SAAS_ACCESS_TOKEN'),
 --     P_TOKEN_EXPIRES => TRUNC(G_TOKEN_TS)
 --   );
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
 --  begin
 --     apex_credential.set_session_credentials (
 --     p_credential_static_id => 'GPMS_DEV',
 --     p_client_id => 'amy.marlin',
 --     p_client_secret => v('G_SAAS_ACCESS_TOKEN') );
 --  end;
exception
    when others then
        wip_debug(2,
                  99999,
                  'CLIENT: '
                  || v('P0_CLIENT')
                  || ' ENV : '
                  || v('P0_ENV')
                  || ' ERROR: '
                  || sqlerrm,
                  '');

        raise;
end;
/


-- sqlcl_snapshot {"hash":"d42a5d0fec0099bb42d49f3c6478d2a216dc72ad","type":"PACKAGE_BODY","name":"XX_GPMS","schemaName":"WKSP_FRONGPMSTDEV"}