create or replace procedure wksp_frongpmstdev.proc_update_status (
    p_project_number in varchar2
) is

    l_url             varchar2(4000);
    name              varchar2(4000);
    buffer            varchar2(4000);
    l_envelope        varchar2(4000);
    p_username        varchar2(4000);
    p_password        varchar(4000);
    l_response_xml    xmltype;
    l_response_clob   clob;
    p_nic_number      varchar2(100);
    l_version         varchar2(1000);
    l_report_response varchar2(32000);
    l_report_decode   varchar2(32000);
    l_temp            varchar2(32000);
begin
    p_username := 'amy.marlin';
    p_password := 'Arn36576'; 
--p_password := 'Fr0ntera!123'; 
    l_version := '1.2'; 
--- Code for Project Costs 
--DELETE FROM XXGPMS_PROJECT_COSTS WHERE SESSION_ID = V('SESSION'); 
--DELETE FROM XXGPMS_PROJECT_EVENTS WHERE SESSION_ID = V('SESSION'); 
    delete from xxgpms_project_costs;

    delete from xxgpms_project_events;

    delete from axxml_tab;

    insert into axxml_tab (
        id,
        vc2_data
    ) values ( 1,
               'PROC_UPDATE_STATUS for ' || p_project_number ); 
--l_url := 'https://eda.fa.us1.oraclecloud.com/xmlpserver/services/ExternalReportWSSService'; 
    l_url := 'https://adc3-zlnq-fa-ext.oracledemos.com/xmlpserver/services/ExternalReportWSSService';
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
            </pub:parameterNameValues>	 
           <pub:reportAbsolutePath>/Custom/Project Accounting/Project Costs Report.xdo</pub:reportAbsolutePath> 
           <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload> 
         </pub:reportRequest> 
         <pub:appParams></pub:appParams> 
      </pub:runReport> 
   </soap:Body> 
</soap:Envelope>';
    l_response_xml := apex_web_service.make_request(
        p_url      => l_url,
        p_version  => l_version,
        p_action   => 'runReport',
        p_envelope => l_envelope,
        p_username => p_username,
        p_password => p_password
    );

    insert into axxml_tab (
        id,
        xml_data
    ) values ( 2,
               l_response_xml );

    l_report_response := apex_web_service.parse_xml(
        p_xml   => l_response_xml,
        p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
        p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
    );

    insert into axxml_tab (
        id,
        xml_data
    ) values ( 3,
               l_report_response );

    l_temp := substr(l_report_response,
                     instr(l_report_response, '>') + 1,
                     instr(
                      substr(l_report_response,
                             instr(l_report_response, '>') + 1),
                      '</ns2:report'
                  ) - 1);

    l_report_response := l_temp; 

--l_report_response := 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCEtLUdlbmVyYXRlZCBieSBPcmFjbGUgQkkgUHVibGlzaGVyIC1EYXRhZW5naW5lLCBkYXRhbW9kZWw6X0N1c3RvbV9Qcm9jdXJlbWVudF9QdXJjaGFzaW5nX1N1cHBsaWVyU2FtcGxlX3hkbSAtLT4KPERBVEFfRFM+CjxHXzE+CjxTVVBQTElFUl9OVU1CRVI+MTI1MjwvU1VQUExJRVJfTlVNQkVSPjxTVVBQTElFUl9OQU1FPkxlZSBTdXBwbGllczwvU1VQUExJRVJfTkFNRT4KPC9HXzE+CjxHXzE+CjxTVVBQTElFUl9OVU1CRVI+MTI1MzwvU1VQUExJRVJfTlVNQkVSPjxTVVBQTElFUl9OQU1FPlN0YWZmaW5nIFNlcnZpY2VzPC9TVVBQTElFUl9OQU1FPgo8L0dfMT4KPC9EQVRBX0RTPg=='; 

    l_report_decode := utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(l_report_response)));

    insert into axxml_tab (
        id,
        xml_data
    ) values ( 4,
               l_report_decode );

    insert into xxgpms_project_costs (
        project_id,
        project_number,
        billable_flag,
        task_id,
        task_number,
        project_status_code,
        project_name,
        expenditure_item_id,
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
        job_name,
        job_id,
        session_id
    )
        select
            project_id,
            project_number,
            billable_flag,
            task_id     path,
            task_number path,
            project_status_code,
            project_name,
            expenditure_item_id,
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
            job_name,
            job_id,
            v('APP_SESSION')
        from   
--       AXXML_TAB x,  
            xmltable ( '/DATA_DS/G_PROJECT_COST'
                    passing xmltype(l_report_decode)
                columns
                    project_id path 'PROJECT_ID',
                    project_number path 'PROJECT_NUMBER',
                    billable_flag path 'BILLABLE_FLAG',
                    task_id path 'TASK_ID',
                    task_number path 'TASK_NUMBER',
                    project_status_code path 'PROJECT_STATUS_CODE',
                    project_name path 'PROJECT_NAME',
                    expenditure_item_id path 'EXPENDITURE_ITEM_ID',
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
                    job_name path 'JOB_NAME',
                    job_id path 'JOB_ID'
            ) xt; 

--- Code for Project Events 
--l_url := 'https://eda.fa.us1.oraclecloud.com/xmlpserver/services/ExternalReportWSSService'; 
    l_url := 'https://adc3-zlnq-fa-ext.oracledemos.com/xmlpserver/services/ExternalReportWSSService';
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
            </pub:parameterNameValues>	 
           <pub:reportAbsolutePath>/Custom/Project Accounting/Project Events Report.xdo</pub:reportAbsolutePath> 
           <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload> 
         </pub:reportRequest> 
         <pub:appParams></pub:appParams> 
      </pub:runReport> 
   </soap:Body> 
</soap:Envelope>';
    l_response_xml := apex_web_service.make_request(
        p_url      => l_url,
        p_version  => l_version,
        p_action   => 'runReport',
        p_envelope => l_envelope,
        p_username => p_username,
        p_password => p_password
    );

    insert into axxml_tab (
        id,
        xml_data
    ) values ( 2,
               l_response_xml );

    l_report_response := apex_web_service.parse_xml(
        p_xml   => l_response_xml,
        p_xpath => ' //runReportResponse/runReportReturn/reportBytes',
        p_ns    => ' xmlns="http://xmlns.oracle.com/oxp/service/PublicReportService"'
    );

    insert into axxml_tab (
        id,
        xml_data
    ) values ( 3,
               l_report_response );

    l_temp := substr(l_report_response,
                     instr(l_report_response, '>') + 1,
                     instr(
                      substr(l_report_response,
                             instr(l_report_response, '>') + 1),
                      '</ns2:report'
                  ) - 1);

    l_report_response := l_temp; 

--l_report_response := 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCEtLUdlbmVyYXRlZCBieSBPcmFjbGUgQkkgUHVibGlzaGVyIC1EYXRhZW5naW5lLCBkYXRhbW9kZWw6X0N1c3RvbV9Qcm9jdXJlbWVudF9QdXJjaGFzaW5nX1N1cHBsaWVyU2FtcGxlX3hkbSAtLT4KPERBVEFfRFM+CjxHXzE+CjxTVVBQTElFUl9OVU1CRVI+MTI1MjwvU1VQUExJRVJfTlVNQkVSPjxTVVBQTElFUl9OQU1FPkxlZSBTdXBwbGllczwvU1VQUExJRVJfTkFNRT4KPC9HXzE+CjxHXzE+CjxTVVBQTElFUl9OVU1CRVI+MTI1MzwvU1VQUExJRVJfTlVNQkVSPjxTVVBQTElFUl9OQU1FPlN0YWZmaW5nIFNlcnZpY2VzPC9TVVBQTElFUl9OQU1FPgo8L0dfMT4KPC9EQVRBX0RTPg=='; 

    l_report_decode := utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(l_report_response)));

    insert into axxml_tab (
        id,
        xml_data
    ) values ( 5,
               l_report_decode );

    insert into xxgpms_project_events (
        project_id,
        segment1,
        project_status_code,
        project_name,
        event_id,
        event_num,
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
        task_name,
        project_start_date,
        evnt_completion_date,
        event_internal_comment,
        event_desc,
        session_id
    )
        select
            project_id,
            segment1,
            project_status_code,
            project_name,
            event_id,
            event_num,
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
            task_name,
            project_start_date,
            evnt_completion_date,
            event_internal_comment,
            event_desc,
            v('APP_SESSION')
        from
            xmltable ( '/DATA_DS/G_PROJECT_EVENTS'
                    passing xmltype(l_report_decode)
                columns
                    project_id path 'PROJECT_ID',
                    segment1 path 'SEGMENT1',
                    project_status_code path 'PROJECT_STATUS_CODE',
                    project_name path 'PROJECT_NAME',
                    event_id path 'EVENT_ID',
                    event_num path 'EVENT_NUM',
                    event_type_code path 'EVENT_TYPE_CODE',
                    bill_trns_amount path 'BILL_TRNS_AMOUNT',
                    bill_trns_currency_code path 'BILL_TRNS_CURRENCY_CODE',
                    bill_hold_flag path 'BILL_HOLD_FLAG',
                    revenue_hold_flag path 'REVENUE_HOLD_FLAG',
                    invoice_currency_code path 'INVOICE_CURRENCY_CODE',
                    task_billable_flag path 'TASK_BILLABLE_FLAG',
                    task_start_date path 'TASK_START_DATE',
                    task_completion_date path 'TASK_COMPLETION_DATE',
                    task_number path 'PROTASK_NUMBERJECT_ID',
                    invoicedstatus path 'INVOICEDSTATUS',
                    task_name path 'TASK_NAME',
                    project_start_date path 'PROJECT_START_DATE',
                    evnt_completion_date path 'EVNT_COMPLETION_DATE',
                    event_internal_comment path 'EVENT_INTERNAL_COMMENT',
                    event_desc path 'EVENT_DESC'
            ) xt;

    insert into axxml_tab (
        id,
        vc2_data
    ) values ( 6,
               'PROC_UPDATE_STATUS End ' );

end;
/


-- sqlcl_snapshot {"hash":"32019255b0057799abc129084aac98d22eea0aca","type":"PROCEDURE","name":"PROC_UPDATE_STATUS","schemaName":"WKSP_FRONGPMSTDEV"}