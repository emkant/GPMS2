create or replace procedure wksp_frongpmstdev.wip_tag_proc (
    p_expenditure_item_list in varchar2,
    p_project_number        in varchar2,
    p_adj_pct               in number,
    p_adj_amt               in number,
    p_sel_amt               in number
) is

    input_str                varchar2(4000);
    var1                     varchar2(100);
    temp_str                 varchar2(4000);
    exp_id                   varchar2(100);
    p_project_bill_rate_attr number;
    p_project_bill_rate_amt  number;
    p_project_exp_qty        number;
    p_amt_red                number;
    p_new_amt                number;
    p_new_pct                number;
    p_project_amt_pct        number;
begin
    insert into axxml_tab (
        id,
        vc2_data
    ) values ( 600,
               'WIP EXP ITEMS: ' || p_expenditure_item_list );

    input_str := p_expenditure_item_list;
    var1 := instr(input_str, '-', 1, 2);
    while ( var1 > 0 ) loop
        temp_str := substr(input_str, 2, var1 - 2);
        exp_id := temp_str;
        if ( p_adj_pct <> 0 ) then
            update xxgpms_project_costs
            set
                realized_bill_rate_attr = project_bill_rate_attr - ( project_bill_rate_attr * p_adj_pct / 100 ),
                realized_bill_rate_amt = quantity * ( project_bill_rate_attr - ( project_bill_rate_attr * p_adj_pct / 100 ) )
            where
                expenditure_item_id = exp_id;

        else
            p_project_bill_rate_attr := 0;
            p_project_bill_rate_amt := 0;
            p_project_exp_qty := 0;
            p_amt_red := 0;
            p_new_amt := 0;
            p_new_pct := 0;
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
                expenditure_item_id = exp_id;

            p_project_amt_pct := p_project_bill_rate_amt * 100 / p_sel_amt;
            p_amt_red := p_adj_amt * p_project_amt_pct / 100;
            p_new_amt := p_project_bill_rate_amt - p_amt_red;
            p_new_pct := p_new_amt / p_project_exp_qty;
            update xxgpms_project_costs
            set
                realized_bill_rate_attr = p_new_pct,
                realized_bill_rate_amt = p_new_amt
            where
                expenditure_item_id = exp_id;

        end if;

        input_str := substr(input_str, var1, 100);
        var1 := instr(input_str, '-', 1, 2);
    end loop;

end;
/


-- sqlcl_snapshot {"hash":"01661597f8bf0b28331e08c6ecc023e1ec85153f","type":"PROCEDURE","name":"WIP_TAG_PROC","schemaName":"WKSP_FRONGPMSTDEV"}