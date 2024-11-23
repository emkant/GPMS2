create unique index wksp_frongpmstdev.prt_environments_u1 on
    wksp_frongpmstdev.prt_environments (
        organization_id,
        environment_name
    );


-- sqlcl_snapshot {"hash":"9f647783bbc9a0fc036d22d7d6e9cd96c57442e8","type":"INDEX","name":"PRT_ENVIRONMENTS_U1","schemaName":"WKSP_FRONGPMSTDEV","sxml":"<INDEX  xmlns  =\"http://xmlns.oracle.com/ku\"  version  =\"1.0\"><UNIQUE></UNIQUE><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>PRT_ENVIRONMENTS_U1</NAME><TABLE_INDEX><ON_TABLE><SCHEMA>WKSP_FRONGPMSTDEV</SCHEMA><NAME>PRT_ENVIRONMENTS</NAME></ON_TABLE><COL_LIST><COL_LIST_ITEM><NAME>ORGANIZATION_ID</NAME></COL_LIST_ITEM><COL_LIST_ITEM><NAME>ENVIRONMENT_NAME</NAME></COL_LIST_ITEM></COL_LIST></TABLE_INDEX></INDEX>"}