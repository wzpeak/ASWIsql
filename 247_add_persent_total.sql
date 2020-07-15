WITH
    mast_item
    as
    (
        SELECT
            item_info.INVENTORY_ITEM_ID                                   INVENTORY_ITEM_ID
         , item_info.ORGANIZATION_ID                                   ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                    MRP_ITEM_ID
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.DESCRIPTION                                         DESCRIPTION
        , item_info.PRIMARY_UOM_CODE                                    UOM 
        , item_info.PREPROCESSING_LEAD_TIME + item_info.POSTPROCESSING_LEAD_TIME + item_info.FULL_LEAD_TIME          LEAD_TIME
        , item_info.MINIMUM_ORDER_QUANTITY                              MIN_QTY 



        -- , orders.FIRM_QUANTITY                                            FIRM_QUANTITY 
        -- , orders.FIRM_STATUS                                              FIRM_STATUS 
        -- , orders.ORDER_TYPE                                               ORDER_TYPE 
     --    , orders.SUPPLIER_ID                                                 SUPPLIER_ID
        , COALESCE(orders.SUPPLIER_ID ,-99991)                                             SUPPLIER_ID
        , COALESCE(orders.SUPPLIER_SITE_ID ,-99991)                                             SUPPLIER_SITE_ID
        -- ,SUM(trx.TRANSACTION_QUANTITY)/24                               AVG_WEEK


        FROM
            MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
       , EGP_SYSTEM_ITEMS_V                       item_info
--        , MSC_ANALYTIC_ORG_FLAT_V_DYD              mrp_store_org
       , MSC_ANALYTIC_FACT_ORD_V                  orders
       , MSC_ANALYTIC_ITEMS                       item_method
       , (select *
            from MSC_SYSTEM_ITEMS_V
            where PLAN_ID = -1  )                     mrp_item
       , INV_ORG_PARAMETERS                       item_store_org

       , MSC_AP_ITEM_CATEGORIES_V                   item_cat
        --        , MSC_DIM_CSTM_LEVEL_DATA_V                item_lvl

        --        , INV_MATERIAL_TXNS                        trx



        WHERE 
        mrp_name.PLAN_ID = orders.PLAN_ID
            ---find  only one mrp item
            AND orders.INVENTORY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
            AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID
            --          find  real item  by  id and  org_code 
            AND mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
            AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
            AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID

            --  filter for 'MRP planning'    both mapping  id and  org_code0
            AND item_method.INVENTORY_ITEM_ID =  orders.INVENTORY_ITEM_ID
            AND item_method.ORGANIZATION_ID   =   orders.ORGANIZATION_ID
            and item_method.plan_id = orders.plan_id

            -- relate  item category
            AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
            AND item_cat.ORGANIZATION_ID =   item_info.ORGANIZATION_ID

            AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))



            AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
            AND item_store_org.ORGANIZATION_CODE   = :P_ITEM_ORG
            AND item_method.MRP_PLANNING_CODE   = 'MRP planning'
            AND 1 = :P_HIERARCHIES

        group by   item_info.INVENTORY_ITEM_ID   
                  , item_info.ORGANIZATION_ID             
                  ,mrp_item.INVENTORY_ITEM_ID            
                  ,item_info.ITEM_NUMBER            
                  ,item_info.DESCRIPTION             
                  ,item_info.PRIMARY_UOM_CODE       
                  ,item_info.PREPROCESSING_LEAD_TIME
                  ,item_info.MINIMUM_ORDER_QUANTITY 
                  ,item_info.POSTPROCESSING_LEAD_TIME
                  ,item_info.FULL_LEAD_TIME
                --   , orders.FIRM_QUANTITY 
                --   , orders.FIRM_STATUS   
                --   , orders.ORDER_TYPE    
                  , orders.SUPPLIER_SITE_ID
                  ,orders.SUPPLIER_ID 
    ),
    week_avg
    as
    (
        SELECT mast_item.INVENTORY_ITEM_ID
           , COALESCE(po_header.VENDOR_SITE_ID ,-99991)                   VENDOR_SITE_ID 
           , COALESCE(po_header.VENDOR_ID ,-99991)                        VENDOR_ID 
            , SUM(trx.TRANSACTION_QUANTITY)/24                               AVG_WEEK
        FROM mast_item , INV_MATERIAL_TXNS             trx, PO_HEADERS_ALL  po_header
        WHERE     
                 trx.INVENTORY_ITEM_ID =  mast_item.INVENTORY_ITEM_ID
            and trx.ORGANIZATION_ID   =  mast_item.ITEM_ORG
            --     relate po  id  for  vender  name
            AND trx.TRANSACTION_SOURCE_ID  = po_header.PO_HEADER_ID
            AND mast_item.SUPPLIER_SITE_ID = po_header.VENDOR_SITE_ID
            AND mast_item.SUPPLIER_ID = po_header.VENDOR_ID
            AND trx.TRANSACTION_TYPE_ID = 18
            AND (trx.TRANSACTION_DATE   BETWEEN   (:P_DATE - 180)   AND  :P_DATE)
        GROUP by mast_item.INVENTORY_ITEM_ID,po_header.VENDOR_SITE_ID,po_header.VENDOR_ID
    ),
    future_one
    as
    (
        SELECT
            item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
                 , COALESCE(orders.SUPPLIER_SITE_ID ,-99991)                       ONE_SUPPLIER_SITE_ID 
                 , COALESCE(orders.SUPPLIER_ID ,-99991)                            ONE_SUPPLIER_ID
                -- ,temp_mid_1.ITEM_NUMBER
                -- ,temp_mid_1.UOM
                -- ,temp_mid_1.LEAD_TIME
                -- ,temp_mid_1.MIN_QTY
                -- ,temp_mid_1.FIRM_QUANTITY
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 18 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SOH
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SPO
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 5 
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_PPO
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1001 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_TD

        -- ,temp_mid_1.FIRM_STATUS
        -- ,temp_mid_1.ORDER_TYPE
        FROM

            MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_ANALYTIC_FACT_ORD_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select *
            from MSC_SYSTEM_ITEMS_V
            where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat
        WHERE 
                mrp_name.PLAN_ID = orders.PLAN_ID
            ---find  only one mrp item
            AND orders.INVENTORY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
            AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID
            --          find  real item  by  id and  org_code 
            AND mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
            AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
            AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID

            --  filter for 'MRP planning'    both mapping  id and  org_code0
            AND item_method.INVENTORY_ITEM_ID =  orders.INVENTORY_ITEM_ID
            AND item_method.ORGANIZATION_ID   =   orders.ORGANIZATION_ID
            and item_method.plan_id = orders.plan_id




            -- relate  item category
            AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
            AND item_cat.ORGANIZATION_ID =   item_info.ORGANIZATION_ID

            AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))



            AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
            AND item_store_org.ORGANIZATION_CODE   = :P_ITEM_ORG
            AND item_method.MRP_PLANNING_CODE   = 'MRP planning'
            AND 1 = :P_HIERARCHIES

            -- oders   filter 
            AND (orders.FIRM_STATUS = 'Firm' or orders.ORDER_TYPE IN( 18,1,1001))
            AND orders.ORDER_TYPE IN( 18,1,5,1001)
            AND to_char(COALESCE(orders.FIRM_DATE,orders.SUGGESTED_DUE_DATE), 'YYYY-MM-DD')  IN 
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
            FROM MSC_ANALYTIC_CALENDARS_V
            where WEEK_START_DATE =  (select WEEK_START_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE
                                                                )    
                                                        )

        group by   item_info.INVENTORY_ITEM_ID    , orders.SUPPLIER_SITE_ID, orders.SUPPLIER_ID

    ),
    future_two
    as
    (
        SELECT
            item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
                 , COALESCE(orders.SUPPLIER_SITE_ID ,-99991)                       ONE_SUPPLIER_SITE_ID
                 , COALESCE(orders.SUPPLIER_ID ,-99991)                             ONE_SUPPLIER_ID
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 18 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SOH
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SPO
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 5 
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_PPO
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1001 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_TD

        FROM

            MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_ANALYTIC_FACT_ORD_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
               , (select *
            from MSC_SYSTEM_ITEMS_V
            where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat
        WHERE 
                mrp_name.PLAN_ID = orders.PLAN_ID
            ---find  only one mrp item
            AND orders.INVENTORY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
            AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID
            --          find  real item  by  id and  org_code 
            AND mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
            AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
            AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID

            --  filter for 'MRP planning'    both mapping  id and  org_code0
            AND item_method.INVENTORY_ITEM_ID =  orders.INVENTORY_ITEM_ID
            AND item_method.ORGANIZATION_ID   =   orders.ORGANIZATION_ID
            and item_method.plan_id = orders.plan_id





            -- relate  item category
            AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
            AND item_cat.ORGANIZATION_ID   =   item_info.ORGANIZATION_ID

            AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))



            AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
            AND item_store_org.ORGANIZATION_CODE   = :P_ITEM_ORG
            AND item_method.MRP_PLANNING_CODE   = 'MRP planning'
            AND 1 = :P_HIERARCHIES

            -- oders   filter 
            AND (orders.FIRM_STATUS = 'Firm' or orders.ORDER_TYPE IN( 18,1,1001))
            AND orders.ORDER_TYPE IN( 18,1,5,1001)
            AND to_char(COALESCE(orders.FIRM_DATE,orders.SUGGESTED_DUE_DATE), 'YYYY-MM-DD')  IN 
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
            FROM MSC_ANALYTIC_CALENDARS_V
            where WEEK_START_DATE =  (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE
                                                                )    
                                                        )

        group by   item_info.INVENTORY_ITEM_ID    , orders.SUPPLIER_SITE_ID  , orders.SUPPLIER_ID

    ),
    future_three
    as
    (
        SELECT
            item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
                 , COALESCE(orders.SUPPLIER_SITE_ID ,-99991)                        ONE_SUPPLIER_SITE_ID
                 , COALESCE(orders.SUPPLIER_ID ,-99991)                             ONE_SUPPLIER_ID
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 18 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SOH
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SPO
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 5 
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_PPO
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1001 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_TD

        FROM

            MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_ANALYTIC_FACT_ORD_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select *
            from MSC_SYSTEM_ITEMS_V
            where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat
        WHERE 
                mrp_name.PLAN_ID = orders.PLAN_ID
            ---find  only one mrp item
            AND orders.INVENTORY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
            AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID
            --          find  real item  by  id and  org_code 
            AND mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
            AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
            AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID

            --  filter for 'MRP planning'    both mapping  id and  org_code0
            AND item_method.INVENTORY_ITEM_ID =  orders.INVENTORY_ITEM_ID
            AND item_method.ORGANIZATION_ID   =   orders.ORGANIZATION_ID
            and item_method.plan_id = orders.plan_id




            -- relate  item category
            AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
            AND item_cat.ORGANIZATION_ID =   item_info.ORGANIZATION_ID

            AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))



            AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
            AND item_store_org.ORGANIZATION_CODE   = :P_ITEM_ORG
            AND item_method.MRP_PLANNING_CODE   = 'MRP planning'
            AND 1 = :P_HIERARCHIES

            -- oders   filter 
             AND (orders.FIRM_STATUS = 'Firm' or orders.ORDER_TYPE IN( 18,1,1001))
            AND orders.ORDER_TYPE IN( 18,1,5,1001)
            AND to_char(COALESCE(orders.FIRM_DATE,orders.SUGGESTED_DUE_DATE), 'YYYY-MM-DD')  IN 
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
            FROM MSC_ANALYTIC_CALENDARS_V
            where WEEK_START_DATE =  (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE)
                                                                )    
                                                        )

        group by   item_info.INVENTORY_ITEM_ID    , orders.SUPPLIER_SITE_ID, orders.SUPPLIER_ID
    ),
    future_four
    as
    (
        SELECT
            item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
                 , COALESCE(orders.SUPPLIER_SITE_ID ,-99991)                      ONE_SUPPLIER_SITE_ID
                 , COALESCE(orders.SUPPLIER_ID ,-99991)                           ONE_SUPPLIER_ID
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 18 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SOH
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SPO
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 5 
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_PPO
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1001 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_TD

        FROM

            MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_ANALYTIC_FACT_ORD_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select *
            from MSC_SYSTEM_ITEMS_V
            where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat
        WHERE 
                mrp_name.PLAN_ID = orders.PLAN_ID
            ---find  only one mrp item
            AND orders.INVENTORY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
            AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID
            --          find  real item  by  id and  org_code 
            AND mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
            AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
            AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID

            --  filter for 'MRP planning'    both mapping  id and  org_code0
            AND item_method.INVENTORY_ITEM_ID =  orders.INVENTORY_ITEM_ID
            AND item_method.ORGANIZATION_ID   =   orders.ORGANIZATION_ID
            and item_method.plan_id = orders.plan_id





            -- relate  item category
            AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
            AND item_cat.ORGANIZATION_ID =   item_info.ORGANIZATION_ID

            AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))



            AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
            AND item_store_org.ORGANIZATION_CODE   = :P_ITEM_ORG
            AND item_method.MRP_PLANNING_CODE   = 'MRP planning'
            AND 1 = :P_HIERARCHIES

            -- oders   filter 
            AND (orders.FIRM_STATUS = 'Firm' or orders.ORDER_TYPE IN( 18,1,1001))
            AND orders.ORDER_TYPE IN( 18,1,5,1001)
            AND to_char(COALESCE(orders.FIRM_DATE,orders.SUGGESTED_DUE_DATE), 'YYYY-MM-DD')  IN 
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
            FROM MSC_ANALYTIC_CALENDARS_V
            where WEEK_START_DATE =  (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE))
                                                                )    
                                                        )

        group by   item_info.INVENTORY_ITEM_ID    , orders.SUPPLIER_SITE_ID, orders.SUPPLIER_ID
    ),
    all_order_tabl
    AS
    (
        SELECT mast_item.*  
        , week_avg.AVG_WEEK 
        , future_one.ONE_SOH 
        , future_one.ONE_SPO 
        , future_one.ONE_PPO 
        , future_one.ONE_TD 

        , future_two.ONE_SOH   TWO_SOH
        , future_two.ONE_SPO   TWO_SPO
        , future_two.ONE_PPO   TWO_PPO
        , future_two.ONE_TD    TWO_TD 

        , future_three.ONE_SOH     THRE_SOH
        , future_three.ONE_SPO     THRE_SPO
        , future_three.ONE_PPO     THRE_PPO
        , future_three.ONE_TD      THRE_TD 

        , future_four.ONE_SOH      FOUR_SOH
        , future_four.ONE_SPO      FOUR_SPO
        , future_four.ONE_PPO      FOUR_PPO
        , future_four.ONE_TD       FOUR_TD

        FROM mast_item , week_avg, future_one , future_two , future_three , future_four
        WHERE
       --left join  week_avg
                mast_item.INVENTORY_ITEM_ID = week_avg.INVENTORY_ITEM_ID(+)
            and mast_item.SUPPLIER_SITE_ID       = week_avg.VENDOR_SITE_ID(+)
            -- and mast_item.SUPPLIER_ID            = week_avg.VENDOR_ID(+)
            -- left join  future one 
            and mast_item.INVENTORY_ITEM_ID = future_one.ONE_INVENTORY_ITEM_ID(+)
            and mast_item.SUPPLIER_SITE_ID       = future_one.ONE_SUPPLIER_SITE_ID(+)
            -- and mast_item.SUPPLIER_ID            = future_one.ONE_SUPPLIER_ID(+)
            -- left join  future two 
            and mast_item.INVENTORY_ITEM_ID      = future_two.ONE_INVENTORY_ITEM_ID(+)
            and mast_item.SUPPLIER_SITE_ID       = future_two.ONE_SUPPLIER_SITE_ID(+)
            -- and mast_item.SUPPLIER_ID            = future_two.ONE_SUPPLIER_ID(+)
            -- left join  future three 
            and mast_item.INVENTORY_ITEM_ID      = future_three.ONE_INVENTORY_ITEM_ID(+)
            and mast_item.SUPPLIER_SITE_ID       = future_three.ONE_SUPPLIER_SITE_ID(+)
            -- and mast_item.SUPPLIER_ID            = future_three.ONE_SUPPLIER_ID(+)
            -- left join  future future_four 
            and mast_item.INVENTORY_ITEM_ID      = future_four.ONE_INVENTORY_ITEM_ID(+)
            and mast_item.SUPPLIER_SITE_ID       = future_four.ONE_SUPPLIER_SITE_ID(+)
            -- and mast_item.SUPPLIER_ID            = future_four.ONE_SUPPLIER_ID(+)
    ),

    add_source_rule
    AS
    (
        SELECT
            item_info.INVENTORY_ITEM_ID
       , item_info.ITEM_NUMBER
       , item_info.ORGANIZATION_ID
       , percent_tab.SOURCE_PARTNER_ID                                   supplier
       , percent_tab.SOURCE_PARTNER_SITE_ID                              supplier_site
       , percent_tab.ALLOCATION_PERCENT                                  alc_percent
       , mrp_item.ITEM_NAME


        FROM
            EGP_SYSTEM_ITEMS_V                       item_info
   , INV_ORG_PARAMETERS                       item_store_org
   , (select *
            from MSC_SYSTEM_ITEMS_V
            where PLAN_ID = -1  )                     mrp_item

--    ,MSC_SR_ASSIGNMENTS                        sr_sign
--    ,MSC_ASSIGNMENT_SETS                       sign_set
      , (select a_tab.*
            from MSC_SOURCING_LEVELS_V a_tab inner join (select INVENTORY_ITEM_ID, ORGANIZATION_ID, SOURCING_RULE_ID, ASSIGNMENT_SET_ID
      , max(EFFECTIVE_DATE) as EFFECTIVE_DATE
                from MSC_SOURCING_LEVELS_V
                group by INVENTORY_ITEM_ID,ORGANIZATION_ID,SOURCING_RULE_ID,ASSIGNMENT_SET_ID) B on 
         a_tab.INVENTORY_ITEM_ID=B.INVENTORY_ITEM_ID
                    and a_tab.ORGANIZATION_ID  =B.ORGANIZATION_ID
                    and a_tab.SOURCING_RULE_ID =B.SOURCING_RULE_ID
                    and a_tab.ASSIGNMENT_SET_ID =B.ASSIGNMENT_SET_ID )                      percent_tab
     , MSC_PLAN_DEFINITIONS                                                   plan_set
     , MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name

        WHERE
                  --          find  real item  by  id and  org_code 
          mrp_item.ITEM_NAME          =  item_info.ITEM_NUMBER
            AND mrp_item.ORGANIZATION_CODE  =  item_store_org.ORGANIZATION_CODE
            AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID

            --item  related sr  assignments
            AND mrp_item.INVENTORY_ITEM_ID  = percent_tab.INVENTORY_ITEM_ID
            AND mrp_item.ORGANIZATION_ID    = percent_tab.ORGANIZATION_ID

            -- related assign set  and   plan id
            AND plan_set.ASSIGNMENT_SET_ID  = percent_tab.ASSIGNMENT_SET_ID
            AND plan_set.PLAN_ID            =  mrp_name.PLAN_ID

            -- AND sign_set.ASSIGNMENT_SET_ID  = sr_sign.ASSIGNMENT_SET_ID 

            AND percent_tab.RANK = 1
            AND percent_tab.SOURCE_PARTNER_ID        is not null
            AND percent_tab.SOURCE_PARTNER_SITE_ID   is not null

            AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
    ),
    tab_a as (

SELECT 
         COALESCE(add_source_rule.INVENTORY_ITEM_ID ,all_order_tabl.INVENTORY_ITEM_ID)     INVENTORY_ITEM_ID
        ,COALESCE(add_source_rule.ORGANIZATION_ID ,all_order_tabl.ITEM_ORG)                 ITEM_ORG
        ,COALESCE(add_source_rule.SUPPLIER ,all_order_tabl.SUPPLIER_ID)                 SUPPLIER_ID
        ,COALESCE(add_source_rule.SUPPLIER_SITE  ,all_order_tabl.SUPPLIER_SITE_ID)                 SUPPLIER_SITE_ID
        ,COALESCE(add_source_rule.ITEM_NUMBER  ,all_order_tabl.ITEM_NUMBER)                 ITEM_NUMBER

        ,  all_order_tabl.DESCRIPTION                                                        DESCRIPTION

        ,  all_order_tabl.AVG_WEEK                                                        AVG_WEEK
        ,  all_order_tabl.ONE_SOH                                                        ONE_SOH
        ,  all_order_tabl.UOM                                                             UOM
        ,  all_order_tabl.ONE_SPO                                                             ONE_SPO
        ,  all_order_tabl.LEAD_TIME                                                             LEAD_TIME
        ,  all_order_tabl.ONE_PPO                                                             ONE_PPO
        ,  all_order_tabl.MIN_QTY                                                             MIN_QTY
        ,  all_order_tabl.ONE_TD                                                             ONE_TD
        ,  all_order_tabl.TWO_SOH                                                             TWO_SOH
        ,  all_order_tabl.TWO_SPO                                                             TWO_SPO
        ,  all_order_tabl.TWO_PPO                                                             TWO_PPO
        ,  all_order_tabl.TWO_TD                                                             TWO_TD
        ,  all_order_tabl.THRE_SOH                                                             THRE_SOH
        ,  all_order_tabl.THRE_SPO                                                             THRE_SPO
        ,  all_order_tabl.THRE_PPO                                                             THRE_PPO
        ,  all_order_tabl.THRE_TD                                                             THRE_TD
        ,  all_order_tabl.FOUR_SOH                                                             FOUR_SOH
        ,  all_order_tabl.FOUR_SPO                                                             FOUR_SPO
        ,  all_order_tabl.FOUR_PPO                                                             FOUR_PPO
        ,  all_order_tabl.FOUR_TD                                                              FOUR_TD



        ,  add_source_rule.ALC_PERCENT                                                            ALC_PERCENT


       

FROM       add_source_rule  full join all_order_tabl 

on   
          add_source_rule.INVENTORY_ITEM_ID  = all_order_tabl.INVENTORY_ITEM_ID
    and   add_source_rule.ORGANIZATION_ID    = all_order_tabl.ITEM_ORG
    and   add_source_rule.SUPPLIER           = all_order_tabl.SUPPLIER_ID
    and   add_source_rule.SUPPLIER_SITE      = all_order_tabl.SUPPLIER_SITE_ID  ),
    tab_b as (

    SELECT  tab_a.* ,sup_v.SUPPLIER_NAME  SUPPLIER_CODE ,sup_site_v.NAME SUPPLIER_SITE_CODE
    FROM tab_a ,MSC_DIM_SUPPLIER_SITE_V sup_v ,MSC_DIM_SUPPLIER_SITE_V sup_site_v
    WHERE 
              tab_a.SUPPLIER_ID = sup_v.PARENT_ID(+) 
          AND tab_a.SUPPLIER_SITE_ID = sup_site_v.ID(+)  ),
          sys_qty
    as
    
    (

        select T2901753.C39334884 as QUANTITY_RELEASED,
            T2901753.C477984733 as EXPIRATION_DATE,
            T2901753.C202238716 as REPORT_DATE,
            T2901753.C154071095 as DAY_OF_YEAR,
            T2901753.C74241182 as PARENT_MONTH,
            T2901753.C358676734 as SEGMENT1,
            T2901753.C282981021 as PARTY_NAME1,
            T2901753.C382218218 as VENDOR_SITE_CODE,
            T2901753.C453017474 as ITEM_NUMBER,
            T2901753.C284554434 as ITEM_ID,
            T2901753.C523995133 as VENDOR_PRODUCT_NUM,
            T2901753.C15565991 as VENDOR_ID268,
            T2901753.C403221656 as ITEM_DESCRIPTION,
            T2901753.C306253662 as C_CATEGORY_NAME

            ,T2901753.PKA_VendorSiteId0 as VENDOR_SITE_ID
        from
            (SELECT V380216164.QUANTITY_RELEASED AS C39334884, V380216164.EXPIRATION_DATE AS C477984733, V162917909.REPORT_DATE AS C202238716, V162917909.DAY_OF_YEAR AS C154071095, V162917909.PARENT_MONTH AS C74241182, V492164244.SEGMENT1 AS C358676734, V492164244.PARTY_NAME1 AS C282981021, V250398895.VENDOR_SITE_CODE AS C382218218, V385839313.ITEM_NUMBER AS C453017474, V380216164.ITEM_ID AS C284554434, V380216164.VENDOR_PRODUCT_NUM AS C523995133, V380216164.VENDOR_ID268 AS C15565991, V380216164.ITEM_DESCRIPTION AS C403221656, V380216164.C_CATEGORY_NAME AS C306253662, V380216164.TYPE_LOOKUP_CODE263 AS C460297595, V380216164.PO_LINE_ID AS BDep_PoLineId0, V380216164.PO_HEADER_ID1 AS PKA_PurchasingDocumentHeaderP0, V380216164.C_CATEGORY_ID AS PKA_CategoryCategoryId0, V250398895.VENDOR_SITE_ID AS PKA_VendorSiteId0, V492164244.VENDOR_ID557 AS PKA_VendorId0, V492164244.PARTY_ID824 AS PKA_PartyPartyId0, V385839313.INVENTORY_ITEM_ID AS PKA_InventoryItemId0, V385839313.ORGANIZATION_ID1596 AS PKA_OrganizationId0
            FROM (SELECT PurchasingDocumentLine.EXPIRATION_DATE, PurchasingDocumentLine.ITEM_DESCRIPTION, PurchasingDocumentLine.ITEM_ID, PurchasingDocumentLine.PO_LINE_ID, PurchasingDocumentLine.VENDOR_PRODUCT_NUM, PurchasingDocumentHeader.PO_HEADER_ID AS PO_HEADER_ID1, PurchasingDocumentHeader.TYPE_LOOKUP_CODE AS TYPE_LOOKUP_CODE263, PurchasingDocumentHeader.VENDOR_ID AS VENDOR_ID268, PurchasingDocumentHeader.VENDOR_SITE_ID AS VENDOR_SITE_ID270, PurchasingDocumentVersion.PROCESSED_DATE, (TRUNC(PurchasingDocumentVersion.PROCESSED_DATE)) AS PROCESSED_DATE_ONLY, POSystemParameters.INVENTORY_ORGANIZATION_ID, Category.CATEGORY_ID AS C_CATEGORY_ID, Category.CATEGORY_NAME AS C_CATEGORY_NAME, (PO_CORE_S.get_ga_line_quantity_released(PurchasingDocumentLine.PO_LINE_ID)) AS QUANTITY_RELEASED
                FROM PO_LINES_ALL PurchasingDocumentLine, PO_HEADERS_ALL PurchasingDocumentHeader, PO_VERSIONS_INIT_SEQUENCE_V PurchasingDocumentVersion, PO_SYSTEM_PARAMETERS_ALL POSystemParameters, EGP_CATEGORIES_VL Category
                WHERE (PurchasingDocumentLine.PO_HEADER_ID = PurchasingDocumentHeader.PO_HEADER_ID AND PurchasingDocumentHeader.PO_HEADER_ID = PurchasingDocumentVersion.PO_HEADER_ID AND PurchasingDocumentHeader.PRC_BU_ID = POSystemParameters.PRC_BU_ID AND PurchasingDocumentLine.CATEGORY_ID = Category.CATEGORY_ID(+)) AND ( ( ((  ( (PurchasingDocumentHeader.TYPE_LOOKUP_CODE = 'BLANKET' ) ) OR ( (PurchasingDocumentHeader.TYPE_LOOKUP_CODE = 'CONTRACT' ) )  )) ) AND (((PurchasingDocumentHeader.REQ_BU_ID IN (select POR_GRANTS_UTIL.get_default_financial_bu
                    from dual)) OR (EXISTS   (SELECT 0
                    FROM PO_AGENT_ACCESSES PoAgentAccess
                    WHERE PoAgentAccess.agent_id IN (SELECT HRC_SESSION_UTIL.GET_USER_PERSONID
                        FROM DUAL) AND PoAgentAccess.PRC_BU_ID                  = PurchasingDocumentHeader.PRC_BU_ID AND ( (PurchasingDocumentHeader.type_lookup_code = 'STANDARD' AND PoAgentAccess.access_action_code         = 'MANAGE_PURCHASE_ORDERS') OR (PurchasingDocumentHeader.type_lookup_code IN ('BLANKET', 'CONTRACT') AND PoAgentAccess.access_action_code         = 'MANAGE_PURCHASE_AGREEMENTS')  ) AND PoAgentAccess.active_flag                = 'Y' AND PoAgentAccess.allowed_flag               = 'Y' AND (PoAgentAccess.access_others_level_code IN ('VIEW','MODIFY','FULL') OR PurchasingDocumentHeader.agent_id      = PoAgentAccess.agent_id)  )) OR EXISTS (SELECT NULL
                    FROM fnd_grants gnt
                    WHERE exists (                                                                                    SELECT /*+ index(fnd_session_role_sets FND_SESSION_ROLE_SETS_U1) no_unnest */ null
                            FROM fnd_session_role_sets
                            WHERE session_role_set_key = fnd_global.session_role_set_key and role_guid = gnt.grantee_key
                        UNION ALL
                            SELECT fnd_global.user_guid AS path
                            FROM dual
                            WHERE fnd_global.user_guid = gnt.grantee_key) AND exists (select /*+ no_unnest */ null
                        from fnd_compiled_menu_functions cmf
                        where cmf.function_id = 300000000016758 and cmf.menu_id = gnt.menu_id) AND gnt.object_id = 300000000015357 AND gnt.grant_type = 'ALLOW' AND gnt.instance_type = 'SET' AND gnt.start_date <= SYSDATE and (gnt.end_date is null or gnt.end_date >= sysdate) AND ((gnt.CONTEXT_NAME is NULL) or (gnt.context_name is not null and gnt.context_value like fnd_global.get_conn_ds_attribute(gnt.context_name))) AND (gnt.instance_set_id = 300000000015361 AND (PurchasingDocumentHeader.type_lookup_code='STANDARD' and PurchasingDocumentHeader.REQ_BU_ID IN (  
SELECT ORG_ID
                        FROM FUN_USER_ROLE_DATA_ASGNMNTS
                        WHERE USER_GUID = FND_GLOBAL.USER_GUID
                            AND ROLE_NAME = GNT.ROLE_NAME AND ACTIVE_FLAG='Y' ))

                        OR

                        (PurchasingDocumentHeader.type_lookup_code IN ('BLANKET','CONTRACT')
                        AND EXISTS
  (SELECT 1
                        FROM FUN_USER_ROLE_DATA_ASGNMNTS FUN,
                            PO_GA_ORG_ASSIGNMENTS BU
                        WHERE FUN.USER_GUID = FND_GLOBAL.USER_GUID
                            AND FUN.ORG_ID  =BU.REQ_BU_ID
                            AND FUN.ROLE_NAME = GNT.ROLE_NAME AND FUN.ACTIVE_FLAG='Y'
  ) ))))) )) V380216164, (SELECT SupplierSite.VENDOR_SITE_CODE, SupplierSite.VENDOR_SITE_ID, Supplier.VENDOR_ID AS VENDOR_ID2164
                FROM POZ_SUPPLIER_SITES_ALL_M SupplierSite, POZ_SUPPLIERS Supplier
                WHERE SupplierSite.VENDOR_ID = Supplier.VENDOR_ID(+)) V250398895, (SELECT Supplier.SEGMENT1, Supplier.VENDOR_ID AS VENDOR_ID557, Party.PARTY_ID AS PARTY_ID824, Party.PARTY_NAME AS PARTY_NAME1
                FROM POZ_SUPPLIERS Supplier, HZ_PARTIES Party
                WHERE (Supplier.PARTY_ID = Party.PARTY_ID) AND ( (1=1))) V492164244, (SELECT FndCalDayEO.REPORT_DATE, FndCalDayEO.LAST_UPDATE_DATE, FndCalDayEO.LAST_UPDATED_BY, FndCalDayEO.CREATION_DATE, FndCalDayEO.CREATED_BY, FndCalDayEO.LAST_UPDATE_LOGIN, FndCalDayEO.PARENT_MONTH, FndCalDayEO.DAY_OF_YEAR
                FROM FND_CAL_DAY FndCalDayEO) V162917909, (SELECT ItemBasePEO.INVENTORY_ITEM_ID, ItemBasePEO.ITEM_NUMBER, ItemBasePEO.ORGANIZATION_ID AS ORGANIZATION_ID1596
                FROM EGP_SYSTEM_ITEMS_B_V ItemBasePEO) V385839313
            WHERE V380216164.VENDOR_SITE_ID270 = V250398895.VENDOR_SITE_ID AND V250398895.VENDOR_ID2164 = V492164244.VENDOR_ID557(+) AND V380216164.PROCESSED_DATE_ONLY = V162917909.REPORT_DATE(+) AND V380216164.ITEM_ID = V385839313.INVENTORY_ITEM_ID(+) AND V380216164.INVENTORY_ORGANIZATION_ID = V385839313.ORGANIZATION_ID1596(+) AND ( ( (V380216164.TYPE_LOOKUP_CODE263 = 'BLANKET' ) ) )) T2901753

    ),

    filter_dirty as (
            SELECT   *   FROM sys_qty  
            WHERE 
                sys_qty.REPORT_DATE is  not NULL

    ), 

    sys_qty_temp as 
(
select dirty_tab.*
            from filter_dirty  dirty_tab inner join (select ITEM_ID, ITEM_NUMBER, VENDOR_SITE_CODE, SEGMENT1,VENDOR_SITE_ID
      , max(REPORT_DATE ) as REPORT_DATE
                from filter_dirty   
                WHERE  EXPIRATION_DATE >=sysdate  or  EXPIRATION_DATE is null
                group by ITEM_ID, ITEM_NUMBER, VENDOR_SITE_CODE, SEGMENT1,VENDOR_SITE_ID) B on 
                        dirty_tab.ITEM_ID=B.ITEM_ID
                    and dirty_tab.ITEM_NUMBER  =B.ITEM_NUMBER
                    and dirty_tab.VENDOR_SITE_CODE =B.VENDOR_SITE_CODE
                    and dirty_tab.SEGMENT1 =B.SEGMENT1                   
                    and dirty_tab.VENDOR_SITE_ID =B.VENDOR_SITE_ID                   )



                    SELECT tab_b.* ,sys_qty_temp.QUANTITY_RELEASED
                    FROM  tab_b ,  sys_qty_temp
                    WHERE
                             tab_b.INVENTORY_ITEM_ID = sys_qty_temp.ITEM_ID (+)
                        AND  tab_b.SUPPLIER_CODE     = sys_qty_temp.PARTY_NAME1(+)
                        AND  tab_b.SUPPLIER_SITE_CODE     = sys_qty_temp.VENDOR_SITE_CODE(+)