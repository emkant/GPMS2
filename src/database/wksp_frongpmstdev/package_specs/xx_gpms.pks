create or replace package wksp_frongpmstdev.xx_gpms as
    procedure wip_debug (
        p_debug_level in number,
        p_debug_id    in number,
        p_debug_str   in varchar2,
        p_debug_clob  in clob
    );

    function base64_decode_clob (
        p_decodeclob in clob
    ) return clob;

    function update_project_lines_dff (
        p_exp_id                     in number,
        p_internal_comment           varchar2,
        p_narrative_billing_overflow in varchar2 default null,
        p_event_attr                 in varchar2 default null,
        p_standard_bill_rate_attr    in number default null,
        p_project_bill_rate_attr     in number default null,
        p_realized_bill_rate_attr    in number default null,
        p_hours_entered              in number default null
    ) return number;

    procedure update_status (
        p_project_number   in varchar2 default null,
        p_agreement_number in varchar2 default null,
        p_unbilled_flag    in varchar2,
        p_bill_thru_date   in date,
        p_jwt              in varchar2,
        p_bill_from_date   in date default to_date ( '01-01-1997', 'MM-DD-YYYY' )
    );

    procedure generate_ar_credit (
        p_project_number in varchar2
    );

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
    );

    procedure wip_adjust_hours (
        p_expenditure_item_id in varchar2,
        p_adjusted_hours      in number,
        p_justification       in varchar2,
        p_response_code       out number,
        p_response            out varchar2
    );

    function wip_tag_adjustment (
        p_expenditure_item_list in varchar2,
        p_project_number        in varchar2,
        p_adj_pct               in number,
        p_adj_amt               in number,
        p_sel_amt               in number,
        p_billable_flag         in varchar2 default 'Y',
        p_justification_comment in varchar2,
        p_bill_hold_flag        in varchar2 default null
    ) return number;

    procedure xx_process_hold (
        p_project_number  in varchar2,
        p_contract_number in varchar2 default null,
        p_exp_id          in varchar2 default null
    );

    procedure process_bill_override (
        p_expenditure_item_id in varchar2,
        p_project_number      in varchar2
    );

    procedure generate_events (
        p_project_number   in varchar2,
        p_agreement_number in varchar2,
        p_bill_thru_date   in date
    );

    procedure post_event_attributes (
        p_billing_events_uniq_id in number,
        p_wip_category           in varchar2,
        p_response_code          out number
    );

    procedure parse_job_id (
        p_response in xmltype,
        p_job_id   out number
    );

    procedure generate_events_and_post (
        p_project_number  in varchar2 default null,
        p_bill_thru_date  in date,
        p_contract_number in varchar2,
        p_justification   in varchar2,
        p_total_up_down   in number default 0,
        p_bill_from_date  in date default to_date ( '01-01-1997', 'MM-DD-YYYY' )
    );

    procedure generate_draft_invoice (
        p_project_number  in varchar2 default null,
        p_bill_thru_date  in date,
        p_contract_number in varchar2,
        p_justification   in varchar2,
        p_total_up_down   in number default 0,
        p_bill_from_date  in date default to_date ( '01-01-1997', 'MM-DD-YYYY' )
    );

    procedure tag_events (
        p_project_number        in varchar2,
        p_expenditure_item_list in varchar2,
        p_event_num_list        in varchar2,
        p_sel_amt               in number
    );

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
    ) return number;

    procedure populate_rates_onload (
        p_project_id     number,
        p_task_id        number default null,
        p_wip_category   varchar2 default null,
        p_project_number varchar2 default null,
        p_contract_id    number
    );

    procedure update_invoice_header_dffs (
        p_contract_id   in number,
        p_job_id        in number,
        p_attr1         in number default 0,
        p_response_code out number
    );

    procedure get_invoice_history (
        p_contract_id in number
    );

    procedure get_matter_credits (
        p_contract_id in number
    );

    procedure get_interprojects (
        p_contract_id in number
    );

    procedure submit_invoice;

    procedure get_user_details (
        user_email in varchar2
    );

    procedure get_all_matters;

    procedure get_all_exp_types;

    function submit_parallel_ess_job (
        p_business_unit         varchar2,
        p_business_unit_id      number,
        p_transaction_source_id number,
        p_document_id           number,
        p_expenditure_batch     number
    ) return number;

    function process_transfer_split (
        p_expenditure_item_list in varchar2,
        project_number          in varchar2,
        p_justification         in varchar2 default null,
        p_total_hours           in number default 0
    ) return varchar2;

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
    );

    procedure perform_adjust_project_costs (
        p_expenditure_item_id  varchar2,
        p_adjustment_type_code in varchar2 default null,
        p_justification        in varchar2,
        p_expenditure_type     in varchar2 default null,
        p_quantity             in number default null,
        p_response             out varchar2,
        p_response_code        out number,
        p_adjustment_type      varchar2 default null
    );

    procedure perform_split_transfer (
        p_expenditure_item_id varchar2,
        p_justification       varchar2,
        p_response            out varchar2,
        p_response_code       out number,
        p_source_project      varchar2 default null,
        p_action              varchar2,
        p_total_hours         number
    );

    procedure perform_split_transfer_new (
        p_expenditure_item_id varchar2,
        p_justification       varchar2,
        p_response            out varchar2,
        p_response_code       out number,
        p_source_project      varchar2 default null,
        p_action              varchar2
    );

    procedure get_users;

    procedure download_logs;

end;
/


-- sqlcl_snapshot {"hash":"3384e3fd75fe3cbb4989a02c35e3c2403930fbb4","type":"PACKAGE_SPEC","name":"XX_GPMS","schemaName":"WKSP_FRONGPMSTDEV"}