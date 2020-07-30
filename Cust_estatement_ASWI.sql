

WITH
    all_info_inv
    AS
    (

        SELECT
            SUM( in_line.EXTENDED_AMOUNT )             in_amt
        , in_head.TRX_NUMBER
        , in_head.CUSTOMER_TRX_ID
        , party_info.PARTY_NAME                      customer
        , to_char( in_head.TRX_DATE,'DD/MM/YYYY')    TRX_DATE
        , in_head.TRX_DATE                           REL_TRX_DATE
        ,in_head.TRX_CLASS  


        FROM
            RA_CUSTOMER_TRX_ALL                         in_head
        , RA_CUSTOMER_TRX_LINES_ALL                   in_line
        , HZ_CUST_ACCOUNTS                            pty_act
        , HZ_PARTIES                                  party_info

        WHERE
            in_head.CUSTOMER_TRX_ID = in_line.CUSTOMER_TRX_ID
            AND in_head.BILL_TO_CUSTOMER_ID = pty_act.CUST_ACCOUNT_ID
            AND party_info.PARTY_ID = pty_act.PARTY_ID
            AND in_head.TRX_CLASS       IN ( 'INV' ,'CM','DM')
        -- AND party_info.PARTY_NAME    =:CUSTOMER 

        GROUP BY 
            
        in_head.TRX_NUMBER
        ,in_head.CUSTOMER_TRX_ID
        ,party_info.PARTY_NAME
        ,in_head.TRX_DATE
        ,in_head.TRX_CLASS 
    )

   SELECT  all_info_inv.* 
          ,all_info_inv.in_amt  - SUM(re_app.AMOUNT_APPLIED )       left_amt

   FROM  all_info_inv , AR_RECEIVABLE_APPLICATIONS_ALL              re_app

   WHERE 
         re_app.APPLIED_CUSTOMER_TRX_ID = all_info_inv.CUSTOMER_TRX_ID 
   GROUP BY 
          all_info_inv.in_amt             
        , all_info_inv.TRX_NUMBER
        , all_info_inv.CUSTOMER_TRX_ID
        , all_info_inv.customer
        , all_info_inv.TRX_DATE
        , all_info_inv.REL_TRX_DATE
        , all_info_inv.TRX_CLASS  
