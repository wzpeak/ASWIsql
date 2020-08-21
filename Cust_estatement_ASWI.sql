

WITH
    all_cust_info
    AS
    (
        SELECT
            --  customer_tab.PARTY_NAME                 parent_name
            -- ,sub_customer_tab.PARTY_NAME             son_name,
            sub_customer_tab.PARTY_NUMBER

        FROM
            HZ_PARTIES                               customer_tab  -- customer  table
                                    , HZ_PARTIES                               sub_customer_tab  -- customer  table
                                    , HZ_CUST_ACCOUNTS                         cust_acct_tab --  customer's account table
                                    , HZ_CUST_ACCOUNTS                         to_acct_tab  --  customer's account table
                                    , HZ_CUST_ACCT_RELATE_ALL                  related_tab
        --  customer's account    related customer's  account 

        WHERE  
                                -- find sub customer by their account
                                            to_acct_tab.PARTY_ID = sub_customer_tab.PARTY_ID
            -- realted to new  sub customer's account
            AND related_tab.RELATED_CUST_ACCOUNT_ID = to_acct_tab.CUST_ACCOUNT_ID
            -- find the relationship with input customer
            AND cust_acct_tab.CUST_ACCOUNT_ID = related_tab.CUST_ACCOUNT_ID
            --  find input customer's account
            AND customer_tab.PARTY_ID = cust_acct_tab.PARTY_ID
            -- find the input customer name's info
            AND customer_tab.PARTY_NUMBER = :P_CUSTOMER_NAME 
        UNION ALL 
             SELECT :P_CUSTOMER_NAME  FROM DUAL 
    ),
    all_info_inv
    ---calculate  the total amount  of  invoice  
    AS
    (

        SELECT
            SUM( in_line.EXTENDED_AMOUNT )             in_amt
        , in_head.TRX_NUMBER
        , in_head.CUSTOMER_TRX_ID
        , party_info.PARTY_NAME                      customer
        , party_info.PARTY_NUMBER                    PARTY_NUMBER
        , in_head.TRX_DATE    
        , in_head.TRX_CLASS


        FROM
            RA_CUSTOMER_TRX_ALL                        in_head
        , RA_CUSTOMER_TRX_LINES_ALL                   in_line
        , HZ_CUST_ACCOUNTS                            pty_act
        , HZ_PARTIES                                  party_info

        WHERE
                in_head.CUSTOMER_TRX_ID = in_line.CUSTOMER_TRX_ID
            AND in_head.BILL_TO_CUSTOMER_ID = pty_act.CUST_ACCOUNT_ID
            AND pty_act.PARTY_ID = party_info.PARTY_ID
            -- AND pty_act.PARTY_ID = :PARTY_ID
            AND in_head.TRX_CLASS       IN ( 'INV' ,'CM','DM')
            -- AND in_head.CUSTOMER_TRX_ID = 300000003668702
            -- find all customers
            AND party_info.PARTY_NUMBER   IN (
            SELECT PARTY_NUMBER
            from all_cust_info
           )

        GROUP BY 
            
         in_head.TRX_NUMBER
        ,in_head.CUSTOMER_TRX_ID
        ,party_info.PARTY_NAME
        ,party_info.PARTY_NUMBER
        ,in_head.TRX_DATE
        ,in_head.TRX_CLASS
    ),
    -- invocie amount and  adjustment
    inv_and_ad
    AS
    (

        SELECT
            all_info_inv.TRX_NUMBER
                            , all_info_inv.customer
                            , all_info_inv.PARTY_NUMBER
                            , all_info_inv.CUSTOMER_TRX_ID
                            , all_info_inv.TRX_DATE
                            , all_info_inv.TRX_CLASS
                            , all_info_inv.in_amt - NVL(SUM( in_adj.ACCTD_AMOUNT), 0)   ACCTD_AMOUNT
        FROM all_info_inv , AR_ADJUSTMENTS_ALL                  in_adj
        WHERE 
                all_info_inv.CUSTOMER_TRX_ID = in_adj.CUSTOMER_TRX_ID(+)
            AND 'A' =in_adj.STATUS(+)
        GROUP BY             all_info_inv.in_amt
                            ,all_info_inv.TRX_NUMBER
                            ,all_info_inv.customer
                            ,all_info_inv.PARTY_NUMBER
                            ,all_info_inv.CUSTOMER_TRX_ID
                            ,all_info_inv.TRX_DATE
                            ,all_info_inv.TRX_CLASS
    )
    ,result_tab AS (
    SELECT
        inv_and_ad.TRX_NUMBER
                            , inv_and_ad.customer
                            , inv_and_ad.PARTY_NUMBER
                            , inv_and_ad.CUSTOMER_TRX_ID
                            , inv_and_ad.TRX_DATE
                            , inv_and_ad.TRX_CLASS
                            , inv_and_ad.ACCTD_AMOUNT
                            , inv_and_ad.ACCTD_AMOUNT  -  SUM(ABS(NVL(applied_tab.AMOUNT_APPLIED,0)))   total_ap_amt
    FROM inv_and_ad , AR_RECEIVABLE_APPLICATIONS_ALL     applied_tab
    WHERE 
                inv_and_ad.CUSTOMER_TRX_ID = applied_tab.APPLIED_CUSTOMER_TRX_ID(+)
        AND applied_tab.STATUS(+)  = 'APP'
        AND applied_tab.DISPLAY(+) = 'Y'
    GROUP BY         inv_and_ad.ACCTD_AMOUNT
                        ,inv_and_ad.TRX_NUMBER
                        ,inv_and_ad.customer
                        ,inv_and_ad.PARTY_NUMBER
                        ,inv_and_ad.CUSTOMER_TRX_ID
                        ,inv_and_ad.TRX_DATE
                        ,inv_and_ad.TRX_CLASS

    --------------------UNION ALL  receipt cash record-----------------------
UNION ALL

    SELECT
        ra_header.RECEIPT_NUMBER                  TRX_NUMBER
        , party_info.PARTY_NAME                    customer
        , party_info.PARTY_NUMBER                   PARTY_NUMBER
        , ra_header.CASH_RECEIPT_ID                CUSTOMER_TRX_ID
        , ra_header.RECEIPT_DATE                   TRX_DATE
        , 'CASH'                                   TRX_CLASS
        , ra_header.AMOUNT                         ACCTD_AMOUNT
        , ra_header.AMOUNT - SUM(NVL(applied_tab.AMOUNT_APPLIED,0))   total_app_amt


    FROM AR_CASH_RECEIPTS_ALL                   ra_header,
        HZ_CUST_ACCOUNTS                       pty_act,
        HZ_PARTIES                             party_info
        , AR_RECEIVABLE_APPLICATIONS_ALL     applied_tab

    WHERE 
        ra_header.PAY_FROM_CUSTOMER = pty_act.CUST_ACCOUNT_ID
        AND party_info.PARTY_ID         = pty_act.PARTY_ID
        AND ra_header.CASH_RECEIPT_ID   = applied_tab.CASH_RECEIPT_ID(+)
        AND 'APP'                        = applied_tab.STATUS(+)
        AND 'CASH'                       = applied_tab.APPLICATION_TYPE(+)
        AND 'Y'                          = applied_tab.DISPLAY(+)

        AND pty_act.PARTY_ID = party_info.PARTY_ID
        -- AND pty_act.PARTY_ID = :PARTY_ID
        AND party_info.PARTY_NUMBER   IN (
            SELECT PARTY_NUMBER
        from all_cust_info
           )
    --    AND ra_header.CASH_RECEIPT_ID = 300000003918335

    GROUP BY 
         ra_header.CASH_RECEIPT_ID
        ,ra_header.RECEIPT_NUMBER
        ,ra_header.AMOUNT
        , party_info.PARTY_NAME
        , party_info.PARTY_NUMBER
        , ra_header.RECEIPT_DATE
    ) 
    SELECT  
              result_tab.TRX_NUMBER
             ,result_tab.customer
             ,result_tab.PARTY_NUMBER
             ,result_tab.CUSTOMER_TRX_ID
             ,result_tab.TRX_DATE
             ,result_tab.TRX_CLASS
             ,result_tab.ACCTD_AMOUNT
             ,result_tab.TOTAL_AP_AMT
            --  add the data flag for the rtf calculate 
            --  , CASE  WHEN  result_tab.TRX_DATE  <  trunc(ADD_MONTHS(SYSDATE,-1), 'mm')
             , CASE  WHEN  result_tab.TRX_DATE     <  trunc(SYSDATE, 'mm')-- temp just for show data
                     THEN  'BF'
                     ELSE  'NOT_BF'                                           
                END   as   BF_STATUS  
                -- show all details for whloe last month  
             , CASE  WHEN  result_tab.TRX_DATE    BETWEEN  trunc(ADD_MONTHS(SYSDATE,-1), 'mm')   AND  LAST_DAY(TRUNC(ADD_MONTHS(SYSDATE,-1)))+1-1/86400
                     THEN  'SHOW'
                     ELSE  'NOT_SHOW'                                           
                END   as   ALL_DETAILS  
                -- total for last 2 month
             , CASE  WHEN  result_tab.TRX_DATE    BETWEEN  trunc(ADD_MONTHS(SYSDATE,-2), 'mm')   AND  LAST_DAY(TRUNC(ADD_MONTHS(SYSDATE,-2)))+1-1/86400
                     THEN  'LST_TWO'
                     ELSE  'NOT_LST_TWO'                                           
                END   as   LST_TWO  
                -- total for last 3 month or ago
             , CASE  WHEN  result_tab.TRX_DATE    <=  LAST_DAY(TRUNC(ADD_MONTHS(SYSDATE,-3)))+1-1/86400
                     THEN  'LST_THREE'
                     ELSE  'NOT_LST_THREE'                                           
                END   as   LST_THREE  


    FROM  result_tab 











-----------------------------------------------------draft-----------------------------------------------
receipt_info
AS
(
        SELECT
    sum(ra_header.AMOUNT)*-1                                      in_all_amt,
    party_info.PARTY_NAME                                         customer


FROM
    AR_CASH_RECEIPTS_ALL                   ra_header,
    HZ_CUST_ACCOUNTS                       pty_act,
    HZ_PARTIES                             party_info
WHERE
                ra_header.PAY_FROM_CUSTOMER = pty_act.CUST_ACCOUNT_ID
    AND party_info.PARTY_ID         = pty_act.PARTY_ID
    AND party_info.PARTY_NAME       =:CUSTOMER

GROUP BY    party_info.PARTY_NAME
    )


SELECT all_info_inv.* 
          , all_info_inv.in_amt  - NVL(SUM(re_app.AMOUNT_APPLIED )  ,0  )   left_amt

FROM all_info_inv , AR_RECEIVABLE_APPLICATIONS_ALL              re_app

WHERE 
         re_app.APPLIED_CUSTOMER_TRX_ID(+) = all_info_inv.CUSTOMER_TRX_ID
GROUP BY 
          all_info_inv.in_amt             
        , all_info_inv.TRX_NUMBER
        , all_info_inv.CUSTOMER_TRX_ID
        , all_info_inv.customer
        , all_info_inv.TRX_DATE
        , all_info_inv.REL_TRX_DATE
        , all_info_inv.TRX_CLASS  


SELECT party_info.PARTY_NAME, party_info.PARTY_NUMBER
FROM
     HZ_CUST_ACCOUNTS                       pty_act,
     HZ_PARTIES                             party_info
where  party_info.PARTY_ID = pty_act.PARTY_ID


-- <?sum(TOTAL_AP_AMT)?>   trunc(sysdate, 'mm') 

-- <?sum(TOTAL_AP_AMT[../BF_STATUS='BF'])?> 
-- <?sum(TOTAL_AP_AMT[../ALL_DETAILS='NOT_SHOW'])?> 
-- <?sum(TOTAL_AP_AMT[../LST_TWO='LST_TWO'])?> 
-- <?sum(TOTAL_AP_AMT[../LST_THREE='LST_THREE'])?> 


-- <?if:TRX_DATE>'2020/08/10'?>

-- <?sum(ACCTD_AMOUNT[../TRX_DATE > sysdate])?> 

-- <?format-date:TRX_DATE; 'DD/MM/YYYY'?>
-- <?format-date:G_2/LAST_THR_MONTH; 'YYYY年M月'?>


-- <?sum(ACCTD_AMOUNT)?><?ACCTD_AMOUNT?>
<?format-number(ACCTD_AMOUNT,'#,##0.00;-#,##0.00')?>
<?format-number(TOTAL_AP_AMT,'#,##0.00;-#,##0.00')?>
<?format-number(sum(TOTAL_AP_AMT[../BF_STATUS='BF']),'#,##0.00;-#,##0.00')?>
-- <?for-each:current-group()?>
<?sum(TOTAL_AP_AMT[../BF_STATUS='BF'])?>

<?sum(TOTAL_AP_AMT[../ALL_DETAILS='SHOW'])?>+<?sum(TOTAL_AP_AMT[../LST_TWO='LST_TWO'])?>+<?sum(TOTAL_AP_AMT[../LST_THREE='LST_THREE'])?>