

WITH
    all_info_inv
    ---calculate  the total amount  of  invoice  
    AS
    (

        SELECT
            SUM( in_line.EXTENDED_AMOUNT )             in_amt
        , in_head.TRX_NUMBER
        , in_head.CUSTOMER_TRX_ID
        , party_info.PARTY_NAME                      customer
        , in_head.TRX_DATE    
        , in_head.TRX_CLASS


        FROM
            RA_CUSTOMER_TRX_ALL                         in_head
        , RA_CUSTOMER_TRX_LINES_ALL                   in_line
        , HZ_CUST_ACCOUNTS                            pty_act
        , HZ_PARTIES                                  party_info

        WHERE
                in_head.CUSTOMER_TRX_ID = in_line.CUSTOMER_TRX_ID
            AND in_head.BILL_TO_CUSTOMER_ID = pty_act.CUST_ACCOUNT_ID
            AND pty_act.PARTY_ID = party_info.PARTY_ID
            AND pty_act.PARTY_ID = :PARTY_ID
            AND in_head.TRX_CLASS       IN ( 'INV' ,'CM','DM')
        -- AND in_head.CUSTOMER_TRX_ID = 300000003668702
        -- AND party_info.PARTY_NAME    =:CUSTOMER 

        GROUP BY 
            
         in_head.TRX_NUMBER
        ,in_head.CUSTOMER_TRX_ID
        ,party_info.PARTY_NAME
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
                            ,all_info_inv.CUSTOMER_TRX_ID
                            ,all_info_inv.TRX_DATE
                            ,all_info_inv.TRX_CLASS
    )
    SELECT 
                              inv_and_ad.TRX_NUMBER
                            , inv_and_ad.customer
                            , inv_and_ad.CUSTOMER_TRX_ID
                            , inv_and_ad.TRX_DATE
                            , inv_and_ad.TRX_CLASS
                            , inv_and_ad.ACCTD_AMOUNT
                            , inv_and_ad.ACCTD_AMOUNT  -  SUM(ABS(applied_tab.AMOUNT_APPLIED))   total_ap_amt
    FROM inv_and_ad , AR_RECEIVABLE_APPLICATIONS_ALL     applied_tab
    WHERE 
                inv_and_ad.CUSTOMER_TRX_ID = applied_tab.APPLIED_CUSTOMER_TRX_ID(+)
        AND applied_tab.STATUS(+)  = 'APP'
        AND applied_tab.DISPLAY(+) = 'Y'
    GROUP BY         inv_and_ad.ACCTD_AMOUNT
                        ,inv_and_ad.TRX_NUMBER
                        ,inv_and_ad.customer
                        ,inv_and_ad.CUSTOMER_TRX_ID
                        ,inv_and_ad.TRX_DATE
                        ,inv_and_ad.TRX_CLASS

    --------------------UNION ALL  receipt cash record-----------------------
UNION ALL

    SELECT
          ra_header.RECEIPT_NUMBER                 TRX_NUMBER
        , party_info.PARTY_NAME                    customer
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
        AND pty_act.PARTY_ID = :PARTY_ID
    --    AND ra_header.CASH_RECEIPT_ID = 300000003918335

    GROUP BY 
         ra_header.CASH_RECEIPT_ID
        ,ra_header.RECEIPT_NUMBER
        ,ra_header.AMOUNT
        , party_info.PARTY_NAME
        , ra_header.RECEIPT_DATE  











------------------------------------------------------------------------------
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
