alter table wksp_frongpmstdev.prt_environments
    add constraint prt_environments_fk1
        foreign key ( organization_id )
            references wksp_frongpmstdev.prt_organizations ( organization_id )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"080c1fd119d08d3692ec934bd3f5f5beb502a96f","type":"REF_CONSTRAINT","name":"PRT_ENVIRONMENTS_FK1","schemaName":"WKSP_FRONGPMSTDEV"}