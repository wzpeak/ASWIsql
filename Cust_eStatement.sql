

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
    ,AR_MEMO_LINES_ALL_B                    memo_mid
WHERE 
    in_head.CUSTOMER_TRX_ID = in_line.CUSTOMER_TRX_ID  
AND  in_head.BILL_TO_CUSTOMER_ID = pty_act.CUST_ACCOUNT_ID 
AND  party_info.PARTY_ID = pty_act.PARTY_ID 
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
AND  party_info.PARTY_ID = pty_act.PARTY_ID 
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



---------------------------------------------------------anather  GDATA------------
SELECT total_tab.customer,
       sum(total_tab.in_all_amt )    all_amt


FROM 

(SELECT 
       SUM(in_line.EXTENDED_AMOUNT)                in_all_amt,
        party_info.PARTY_NAME                      customer
FROM   
    RA_CUSTOMER_TRX_ALL   in_head,
    RA_CUSTOMER_TRX_LINES_ALL  in_line,
     HZ_CUST_ACCOUNTS                       pty_act,
      XLE_ENTITY_PROFILES                         legal_entity,
    HZ_PARTIES                             party_info 
WHERE 
     in_head.CUSTOMER_TRX_ID = in_line.CUSTOMER_TRX_ID  
AND  in_head.BILL_TO_CUSTOMER_ID = pty_act.CUST_ACCOUNT_ID 
AND  party_info.PARTY_ID = pty_act.PARTY_ID 
AND in_head.LEGAL_ENTITY_ID = legal_entity.LEGAL_ENTITY_ID

AND (legal_entity.LEGAL_ENTITY_ID    IN (:P_COMPANY) OR 'agn' IN (:P_COMPANY || 'agn'))
AND in_line.LINE_TYPE IN  ('LINE','TAX')
AND in_head.COMPLETE_FLAG ='Y'

AND party_info.PARTY_NAME       =:CUSTOMER
AND in_head.TRX_DATE < :PERIOD_FROM 
-- AND in_head.TRX_CLASS  IN ( 'INV','CM','DM')  
GROUP BY  party_info.PARTY_NAME

UNION ALL 

------cash  receipt------
SELECT
       sum(ra_header.AMOUNT)*-1                                      in_all_amt,
       party_info.PARTY_NAME                      customer


FROM
      AR_CASH_RECEIPTS_ALL                   ra_header,
      HZ_CUST_ACCOUNTS                       pty_act,
        XLE_ENTITY_PROFILES                         legal_entity,
      HZ_PARTIES                             party_info 
WHERE
     ra_header.PAY_FROM_CUSTOMER = pty_act.CUST_ACCOUNT_ID
     AND ra_header.LEGAL_ENTITY_ID = legal_entity.LEGAL_ENTITY_ID
AND  party_info.PARTY_ID = pty_act.PARTY_ID 
AND (legal_entity.LEGAL_ENTITY_ID    IN (:P_COMPANY) OR 'agn' IN (:P_COMPANY || 'agn'))
AND party_info.PARTY_NAME       =:CUSTOMER
AND ra_header.RECEIPT_DATE <   :PERIOD_FROM 

group  by   party_info.PARTY_NAME

UNION ALL 
---------invocie   adj ---------------------
SELECT 
             sum( in_adj.AMOUNT )                       in_all_amt,
             party_info.PARTY_NAME                      customer
 
FROM 
RA_CUSTOMER_TRX_ALL                        in_head,
AR_ADJUSTMENTS_ALL                          in_adj,
 HZ_CUST_ACCOUNTS                       pty_act,
 HZ_PARTIES                             party_info 

WHERE in_head.CUSTOMER_TRX_ID = in_adj.CUSTOMER_TRX_ID 
AND  in_head.BILL_TO_CUSTOMER_ID = pty_act.CUST_ACCOUNT_ID 
AND  party_info.PARTY_ID = pty_act.PARTY_ID 
AND in_head.COMPLETE_FLAG ='Y'

AND party_info.PARTY_NAME       =:CUSTOMER
AND in_head.TRX_DATE < :PERIOD_FROM 
AND in_head.TRX_CLASS  = 'INV'  
GROUP BY  party_info.PARTY_NAME 
---------cash  receipt   adj--------------
-- SELECT 
--              sum( in_adj.AMOUNT )                       in_all_amt,
--              party_info.PARTY_NAME                      customer
 
-- FROM 
-- RA_CUSTOMER_TRX_ALL                        in_head,
-- AR_ADJUSTMENTS_ALL                          in_adj,
--  HZ_CUST_ACCOUNTS                       pty_act,
--  HZ_PARTIES                             party_info 

-- WHERE in_head.CUSTOMER_TRX_ID = in_adj.CUSTOMER_TRX_ID 
-- AND  in_head.BILL_TO_CUSTOMER_ID = pty_act.CUST_ACCOUNT_ID 
-- AND  party_info.PARTY_ID = pty_act.PARTY_ID 
-- AND in_head.COMPLETE_FLAG ='Y'

-- AND party_info.PARTY_NAME       =:CUSTOMER
-- AND in_head.TRX_DATE <= :PERIOD_FROM 
-- AND in_head.TRX_CLASS  = 'INV'  
-- GROUP BY  party_info.PARTY_NAME    
)   total_tab

group  by   total_tab.customer