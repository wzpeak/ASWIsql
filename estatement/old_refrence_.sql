
    SELECT
        UPPER(legal_entity.NAME)                          BUSINESS_UINT,
        in_head.TRX_NUMBER,
        party_info.PARTY_NAME                      customer,
        to_char( in_head.TRX_DATE,'DD/MM/YYYY')    TRX_DATE,
        in_head.TRX_DATE                           REL_TRX_DATE,
        to_char( in_head.TRX_DATE,'YYYY/MM/DD')    TRX_DATE_OR,
        memo.name ||' '|| in_line.DESCRIPTION      as     DESCRIPTION,
        in_line.EXTENDED_AMOUNT,
        null    APP_AMT,
        party_info.ADDRESS1                      address1
    FROM
        RA_CUSTOMER_TRX_ALL   in_head,
        RA_CUSTOMER_TRX_LINES_ALL  in_line,
        -- FUN_ALL_BUSINESS_UNITS_V                       business_unit,
        XLE_ENTITY_PROFILES                         legal_entity,
        HZ_CUST_ACCOUNTS                       pty_act,
        HZ_PARTIES                             party_info ,
        AR_MEMO_LINES_ALL_TL                  memo
    , AR_MEMO_LINES_ALL_B                    memo_mid
    WHERE 
    in_head.CUSTOMER_TRX_ID = in_line.CUSTOMER_TRX_ID
        AND in_head.BILL_TO_CUSTOMER_ID = pty_act.CUST_ACCOUNT_ID
        AND party_info.PARTY_ID = pty_act.PARTY_ID
        AND in_head.LEGAL_ENTITY_ID = legal_entity.LEGAL_ENTITY_ID

        AND memo_mid.MEMO_LINE_SEQ_ID = in_line.MEMO_LINE_SEQ_ID
        AND memo_mid.MEMO_LINE_ID = memo.MEMO_LINE_ID
        AND memo.LANGUAGE  = USERENV('LANG')

        AND (legal_entity.LEGAL_ENTITY_ID    IN (:P_COMPANY) OR 'agn' IN (:P_COMPANY || 'agn'))
        -- AND (party_info.PARTY_NAME       IN (:CUSTOMER) OR 'agn' IN (:CUSTOMER || 'agn'))
        AND party_info.PARTY_NAME    =:CUSTOMER
        AND (in_head.TRX_DATE BETWEEN   :PERIOD_FROM AND :PERIOD_TO )
    ----AND in_head.TRX_CLASS  IN ( 'INV' ,'CM','DM')

UNION ALL
    ----------------------situation 2-----------
    SELECT
        UPPER(legal_entity.NAME)                          BUSINESS_UINT,
        ra_header.RECEIPT_NUMBER                   TRX_NUMBER,
        party_info.PARTY_NAME                      customer,
        to_char( ra_header.RECEIPT_DATE,'DD/MM/YYYY')                   TRX_DATE,
        ra_header.RECEIPT_DATE                                          REL_TRX_DATE,
        to_char( ra_header.RECEIPT_DATE,'YYYY/MM/DD')                   TRX_DATE_OR,
        ra_header.COMMENTS        AS      DESCRIPTION,
        null                                      EXTENDED_AMOUNT,
        --    ra_lines.AMOUNT_APPLIED*-1                                      APP_AMT,
        ra_header.AMOUNT*-1                                     APP_AMT,
        party_info.ADDRESS1                      address1


    FROM
        AR_CASH_RECEIPTS_ALL                        ra_header,
        --   AR_RECEIVABLE_APPLICATIONS_ALL              ra_lines,
        HZ_CUST_ACCOUNTS                       pty_act,
        --   FUN_ALL_BUSINESS_UNITS_V                       business_unit,
        XLE_ENTITY_PROFILES                         legal_entity,
        HZ_PARTIES                             party_info
    WHERE
    -- ra_lines.CASH_RECEIPT_ID  = ra_header.CASH_RECEIPT_ID 
    ra_header.PAY_FROM_CUSTOMER = pty_act.CUST_ACCOUNT_ID
        AND party_info.PARTY_ID = pty_act.PARTY_ID
        AND ra_header.LEGAL_ENTITY_ID = legal_entity.LEGAL_ENTITY_ID
        -- AND ra_lines.DISPLAY = 'Y'
        -----AND ra_lines.STATUS = 'APP'
        ----AND ra_header.STATUS ='APP'

        -- AND (business_unit.SHORT_CODE     IN (:BUSINESS_UINT) OR 'agn' IN (:BUSINESS_UINT || 'agn'))
        AND (legal_entity.LEGAL_ENTITY_ID    IN (:P_COMPANY) OR 'agn' IN (:P_COMPANY || 'agn'))
        -- AND (party_info.PARTY_NAME       IN (:CUSTOMER) OR 'agn' IN (:CUSTOMER || 'agn'))

        AND party_info.PARTY_NAME    =:CUSTOMER
        AND (ra_header.RECEIPT_DATE BETWEEN   :PERIOD_FROM AND :PERIOD_TO )

order by TRX_DATE_OR



WITH
    SAWITH0
    AS
    (
        select T289026.C15851796 as c1
        from
            (SELECT V296094479.CHECK_NUMBER AS C15851796, V296094479.CHECK_ID AS PKA_CheckId0
            FROM (SELECT Checks.CHECK_ID, Checks.CHECK_NUMBER
                FROM AP_CHECKS_ALL Checks, FUN_BU_PERF_V BusinessUnit
                WHERE (Checks.ORG_ID = BusinessUnit.BU_ID) AND (( EXISTS (SELECT NULL
                    FROM fnd_grants gnt
                    WHERE exists (                            SELECT /*+ index(fnd_session_role_sets FND_SESSION_ROLE_SETS_U1) no_unnest */ null
                            FROM fnd_session_role_sets
                            WHERE session_role_set_key = fnd_global.session_role_set_key and role_guid = gnt.grantee_key
                        UNION ALL
                            SELECT fnd_global.user_guid AS path
                            FROM dual
                            WHERE fnd_global.user_guid = gnt.grantee_key) AND exists (select /*+ no_unnest */ null
                        from fnd_compiled_menu_functions cmf
                        where cmf.function_id = 300000000018439 and cmf.menu_id = gnt.menu_id) AND gnt.object_id = 300000000008574 AND gnt.grant_type = 'ALLOW' AND gnt.instance_type = 'SET' AND gnt.start_date <= SYSDATE and (gnt.end_date is null or gnt.end_date >= sysdate) AND ((gnt.CONTEXT_NAME is NULL) or (gnt.context_name is not null and gnt.context_value like fnd_global.get_conn_ds_attribute(gnt.context_name))) AND (gnt.instance_set_id = 300000000021266 AND BusinessUnit.BU_ID IN
(                            SELECT org1.pay_bu_id
                            FROM fun_interco_organizations org1, FUN_USER_ROLE_DATA_ASGNMNTS urd1
                            WHERE urd1.USER_GUID = FND_GLOBAL.USER_GUID AND urd1.ROLE_NAME = GNT.ROLE_NAME AND urd1.ACTIVE_FLAG!='N'
                                AND TO_CHAR(org1.interco_org_id) = urd1.INTERCO_ORG_ID
                        UNION
                            SELECT org2.rec_bu_id
                            FROM fun_interco_organizations org2, FUN_USER_ROLE_DATA_ASGNMNTS urd2
                            WHERE urd2.USER_GUID = FND_GLOBAL.USER_GUID AND urd2.ROLE_NAME = GNT.ROLE_NAME AND urd2.ACTIVE_FLAG!='N'
                                AND TO_CHAR(org2.interco_org_id) = urd2.INTERCO_ORG_ID
) )) OR EXISTS (SELECT NULL
                    FROM fnd_grants gnt
                    WHERE exists (                            SELECT /*+ index(fnd_session_role_sets FND_SESSION_ROLE_SETS_U1) no_unnest */ null
                            FROM fnd_session_role_sets
                            WHERE session_role_set_key = fnd_global.session_role_set_key and role_guid = gnt.grantee_key
                        UNION ALL
                            SELECT fnd_global.user_guid AS path
                            FROM dual
                            WHERE fnd_global.user_guid = gnt.grantee_key) AND exists (select /*+ no_unnest */ null
                        from fnd_compiled_menu_functions cmf
                        where cmf.function_id = 300000000018439 and cmf.menu_id = gnt.menu_id) AND gnt.object_id = 300000000008574 AND gnt.grant_type = 'ALLOW' AND gnt.instance_type = 'SET' AND gnt.start_date <= SYSDATE and (gnt.end_date is null or gnt.end_date >= sysdate) AND ((gnt.CONTEXT_NAME is NULL) or (gnt.context_name is not null and gnt.context_value like fnd_global.get_conn_ds_attribute(gnt.context_name))) AND (gnt.instance_set_id = 300000000018459 AND BusinessUnit.BU_ID IN (SELECT HR.ORGANIZATION_ID BU_ID
                        FROM HR_ORGANIZATION_INFORMATION_X HR, GL_ACCESS_SET_LEDGERS ASL, FUN_USER_ROLE_DATA_ASGNMNTS URDA
                        WHERE HR.ORG_INFORMATION_CONTEXT = 'FUN_BUSINESS_UNIT' AND HR.ORG_INFORMATION3 = TO_CHAR(ASL.LEDGER_ID) AND ASL.ACCESS_SET_ID = URDA.ACCESS_SET_ID AND USER_GUID = FND_GLOBAL.USER_GUID AND ROLE_NAME = GNT.ROLE_NAME AND ACTIVE_FLAG!='N'))) OR EXISTS (SELECT NULL
                    FROM fnd_grants gnt
                    WHERE exists (                            SELECT /*+ index(fnd_session_role_sets FND_SESSION_ROLE_SETS_U1) no_unnest */ null
                            FROM fnd_session_role_sets
                            WHERE session_role_set_key = fnd_global.session_role_set_key and role_guid = gnt.grantee_key
                        UNION ALL
                            SELECT fnd_global.user_guid AS path
                            FROM dual
                            WHERE fnd_global.user_guid = gnt.grantee_key) AND exists (select /*+ no_unnest */ null
                        from fnd_compiled_menu_functions cmf
                        where cmf.function_id = 300000000018439 and cmf.menu_id = gnt.menu_id) AND gnt.object_id = 300000000008574 AND gnt.grant_type = 'ALLOW' AND gnt.instance_type = 'SET' AND gnt.start_date <= SYSDATE and (gnt.end_date is null or gnt.end_date >= sysdate) AND ((gnt.CONTEXT_NAME is NULL) or (gnt.context_name is not null and gnt.context_value like fnd_global.get_conn_ds_attribute(gnt.context_name))) AND (gnt.instance_set_id = 300000000008576 AND BusinessUnit.BU_ID IN (SELECT ORG_ID
                        FROM FUN_USER_ROLE_DATA_ASGNMNTS
                        WHERE USER_GUID = FND_GLOBAL.USER_GUID AND ROLE_NAME = GNT.ROLE_NAME AND ACTIVE_FLAG!='N')))))) V296094479) T289026
    )
select D1.c1 as c1, D1.c2 as c2
from ( select distinct 0 as c1,
        D1.c1 as c2
    from
        SAWITH0 D1
    order by c2 ) D1
where rownum <= 75001


<?for-each-group:G_1;./PARTY_NUMBER?>
<??>

<?format-date:G_2/LAST_MONTH_FIRST; 'DD/MM/YYYY'?>