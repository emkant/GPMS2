create or replace force editionable view wksp_frongpmstdev.databasechangelog_details (
    deployment_id,
    id,
    author,
    filename,
    sql,
    sxml,
    dateexecuted,
    exectype,
    md5sum,
    description,
    comments,
    liquibase,
    contexts,
    labels
) as
    select
        da.deployment_id,
        da.id,
        da.author,
        da.filename,
        da.sql,
        da.sxml,
        d.dateexecuted,
        d.exectype,
        d.md5sum,
        d.description,
        d.comments,
        d.liquibase,
        d.contexts,
        d.labels
    from
        wksp_frongpmstdev.databasechangelog         d
        left join wksp_frongpmstdev.databasechangelog_actions da on d.id = da.id
                                                                    and d.author = da.author
                                                                    and d.filename = da.filename
    order by
        1,
        7;


-- sqlcl_snapshot {"hash":"80fca6aadf05c650bbd639965f4ab1ea02d86469","type":"VIEW","name":"DATABASECHANGELOG_DETAILS","schemaName":"WKSP_FRONGPMSTDEV"}