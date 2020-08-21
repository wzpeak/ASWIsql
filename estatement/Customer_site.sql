
--   RA_CUSTOMER_TRX_ALL                    trx_head,
--   RA_CUSTOMER_TRX_LINES_ALL              trx_line,
--   HZ_CUST_SITE_USES_ALL                  use_site,   SITE_USE_ID (300000003900887)
--   HZ_PARTY_SITE_USES                     ship_use_site,
--   HZ_CUST_ACCT_SITES_ALL                 act_site,
--   ZX_LINES                               tax_line,
--   ZX_REGISTRATIONS                       rig_number,
--   ZX_PARTY_TAX_PROFILE                   rig_profile,
--   HZ_CUST_ACCOUNTS                       pty_act,
--   HZ_LOCATIONS                           address_loc,
--   HZ_LOCATIONS                           ship_loc,
--   HZ_PARTY_SITES                         site_pty,
--   HZ_PARTY_SITES                         ship_site_pty,
--   HZ_PARTIES                             party_info ,
--   FND_TERRITORIES_TL                         country_code,
--   FND_TERRITORIES_TL                         ship_country_code ,

--  CUST_ACCT_SITE_ID (300000003900861)   HZ_CUST_ACCT_SITES_ALL  site  和 account 关联
--  CUST_ACCOUNT_ID   (300000003900860)  <----------> 关联 HZ_CUST_ACCOUNTS (accnout 表) <---->PARTY_ID (300000003900858)  HZ_PARTIES
--  PARTY_SITE_ID     (300000003900862)  <-----------> HZ_PARTY_SITES 


-- HZ_CUST_ACCT_RELATE_ALL
-- RELATED_CUST_ACCOUNT_ID (300000003900899)   <---->PARTY_ID ( 300000003900897 )   ACCOUNT_NUMBER (16019)
--  got it    use  Account related to Account , and  HZ_PARTIES is the  customer info 

-- 2020/08/12
-- dff  有就有，有就显示
-- 新增加的  only show   first page  and  last page
-- statement message  从 config 配置里面拿
-- title  要重复
--  有些地方需要 留空 就是  P

/*                            
 需求 还是这样：时间节点： 
                        1 today 的前一个月的最后一天：LAST_DAY(TRUNC(ADD_MONTHS(SYSDATE,-1)))+1-1/86400
                        2 today 的前一个月的第一天： trunc(ADD_MONTHS(SYSDATE,-1), 'mm') 
*/

-- PARTY_NAME  =  PARTY_NAME (Customer A 001)    PARTY_NUMBER (49030)
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
    AND customer_tab.PARTY_NAME = :P_CUSTOMER_NAME


SELECT HZ_PARTY_SITES.*  
  
FROM  HZ_PARTIES party_info ,HZ_CUST_ACCOUNTS acct_info , HZ_CUST_ACCT_SITES_ALL site_info , HZ_PARTY_SITES 
WHERE  
        party_info.PARTY_ID  = acct_info.PARTY_ID 
    and acct_info.CUST_ACCOUNT_ID   =  site_info.CUST_ACCOUNT_ID 
    and site_info.PARTY_SITE_ID = HZ_PARTY_SITES.PARTY_SITE_ID


      