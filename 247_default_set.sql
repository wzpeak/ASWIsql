WITH
    mast_item
    as
    (
        SELECT
            item_info.INVENTORY_ITEM_ID                                   INVENTORY_ITEM_ID
         , item_info.ORGANIZATION_ID                                   ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                    MRP_ITEM_ID
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM 
        , item_info.PREPROCESSING_LEAD_TIME + item_info.POSTPROCESSING_LEAD_TIME + item_info.FULL_LEAD_TIME          LEAD_TIME
        , item_info.MINIMUM_ORDER_QUANTITY                              MIN_QTY 



        -- , orders.FIRM_QUANTITY                                            FIRM_QUANTITY 
        -- , orders.FIRM_STATUS                                              FIRM_STATUS 
        -- , orders.ORDER_TYPE                                               ORDER_TYPE 
     --    , orders.SUPPLIER_ID                                                 SUPPLIER_ID
        , COALESCE(orders.SUPPLIER_SITE_ID ,-99991)                                             SUPPLIER_SITE_ID
        -- ,SUM(trx.TRANSACTION_QUANTITY)/24                               AVG_WEEK


        FROM
            MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
       , EGP_SYSTEM_ITEMS_V                       item_info
--        , MSC_ANALYTIC_ORG_FLAT_V_DYD              mrp_store_org
       , MSC_ANALYTIC_FACT_ORD_V                  orders
       , MSC_ANALYTIC_ITEMS                       item_method
       ,  (select  *   from  MSC_SYSTEM_ITEMS_V where PLAN_ID = -1  )                     mrp_item
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
                  ,item_info.PRIMARY_UOM_CODE       
                  ,item_info.PREPROCESSING_LEAD_TIME
                  ,item_info.MINIMUM_ORDER_QUANTITY 
                  ,item_info.POSTPROCESSING_LEAD_TIME
                  ,item_info.FULL_LEAD_TIME
                --   , orders.FIRM_QUANTITY 
                --   , orders.FIRM_STATUS   
                --   , orders.ORDER_TYPE    
                  , orders.SUPPLIER_SITE_ID
    ),
    week_avg
    as
    (
        SELECT mast_item.INVENTORY_ITEM_ID
           , COALESCE(po_header.VENDOR_SITE_ID ,-99991)                   VENDOR_SITE_ID 
            , SUM(trx.TRANSACTION_QUANTITY)/24                               AVG_WEEK
        FROM mast_item , INV_MATERIAL_TXNS             trx, PO_HEADERS_ALL  po_header
        WHERE     
                 trx.INVENTORY_ITEM_ID =  mast_item.INVENTORY_ITEM_ID
            and  trx.ORGANIZATION_ID   =  mast_item.ITEM_ORG
            --     relate po  id  for  vender  name
            AND trx.TRANSACTION_SOURCE_ID  = po_header.PO_HEADER_ID
            AND mast_item.SUPPLIER_SITE_ID = po_header.VENDOR_SITE_ID  
            AND trx.TRANSACTION_TYPE_ID = 18
            AND (trx.TRANSACTION_DATE   BETWEEN   (:P_DATE - 180)   AND  :P_DATE)
        GROUP by mast_item.INVENTORY_ITEM_ID,po_header.VENDOR_SITE_ID 
    ),
    future_one
    as
    (
        SELECT
            item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
                 , COALESCE(orders.SUPPLIER_SITE_ID ,-99991)                       ONE_SUPPLIER_SITE_ID 
                -- ,temp_mid_1.ITEM_NUMBER
                -- ,temp_mid_1.UOM
                -- ,temp_mid_1.LEAD_TIME
                -- ,temp_mid_1.MIN_QTY
                -- ,temp_mid_1.FIRM_QUANTITY
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 18 
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SOH
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1 
                     THEN  orders.FIRM_QUANTITY
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
                     THEN  orders.FIRM_QUANTITY
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
                , (select  *   from  MSC_SYSTEM_ITEMS_V where PLAN_ID = -1  )                     mrp_item
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
            AND orders.ORDER_TYPE IN( 18,1,5,1001)
            AND orders.FIRM_STATUS = 'Firm'
            AND to_char(COALESCE(orders.FIRM_DATE,orders.SUGGESTED_DUE_DATE), 'YYYY-MM-DD')  IN 
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
            FROM MSC_ANALYTIC_CALENDARS_V
            where WEEK_START_DATE =  (select WEEK_START_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE
                                                                )    
                                                        )

        group by   item_info.INVENTORY_ITEM_ID    , orders.SUPPLIER_SITE_ID

    ),
    future_two
    as
    (
        SELECT
            item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
                 , COALESCE(orders.SUPPLIER_SITE_ID ,-99991)                       ONE_SUPPLIER_SITE_ID
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 18 
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SOH
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1 
                     THEN  orders.FIRM_QUANTITY
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
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_TD

        FROM

            MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_ANALYTIC_FACT_ORD_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
               , (select  *   from  MSC_SYSTEM_ITEMS_V where PLAN_ID = -1  )                     mrp_item
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
            AND orders.ORDER_TYPE IN( 18,1,5,1001)
            AND orders.FIRM_STATUS = 'Firm'
            AND to_char(COALESCE(orders.FIRM_DATE,orders.SUGGESTED_DUE_DATE), 'YYYY-MM-DD')  IN 
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
            FROM MSC_ANALYTIC_CALENDARS_V
            where WEEK_START_DATE =  (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE
                                                                )    
                                                        )

        group by   item_info.INVENTORY_ITEM_ID    , orders.SUPPLIER_SITE_ID

    ),
    future_three
    as
    (
        SELECT
            item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
                 , COALESCE(orders.SUPPLIER_SITE_ID ,-99991)                        ONE_SUPPLIER_SITE_ID
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 18 
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SOH
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1 
                     THEN  orders.FIRM_QUANTITY
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
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_TD

        FROM

            MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_ANALYTIC_FACT_ORD_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select  *   from  MSC_SYSTEM_ITEMS_V where PLAN_ID = -1  )                     mrp_item
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
            AND orders.ORDER_TYPE IN( 18,1,5,1001)
            AND orders.FIRM_STATUS = 'Firm'
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

        group by   item_info.INVENTORY_ITEM_ID    , orders.SUPPLIER_SITE_ID
    ),
    future_four
    as
    (
        SELECT
            item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
                 ,COALESCE(orders.SUPPLIER_SITE_ID ,-99991)                      ONE_SUPPLIER_SITE_ID
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 18 
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_SOH
                , SUM(
                CASE WHEN  orders.ORDER_TYPE = 1 
                     THEN  orders.FIRM_QUANTITY
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
                     THEN  orders.FIRM_QUANTITY
                     ELSE  0
                END  
                )  as   ONE_TD

        FROM

            MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_ANALYTIC_FACT_ORD_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select  *   from  MSC_SYSTEM_ITEMS_V where PLAN_ID = -1  )                     mrp_item
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
            AND orders.ORDER_TYPE IN( 18,1,5,1001)
            AND orders.FIRM_STATUS = 'Firm'
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

        group by   item_info.INVENTORY_ITEM_ID    , orders.SUPPLIER_SITE_ID
    )

SELECT   mast_item.*  
        ,week_avg.AVG_WEEK 
        ,future_one.ONE_SOH 
        ,future_one.ONE_SPO 
        ,future_one.ONE_PPO 
        ,future_one.ONE_TD 

        ,future_two.ONE_SOH   TWO_SOH
        ,future_two.ONE_SPO   TWO_SPO
        ,future_two.ONE_PPO   TWO_PPO
        ,future_two.ONE_TD    TWO_TD 

        ,future_three.ONE_SOH     THRE_SOH
        ,future_three.ONE_SPO     THRE_SPO
        ,future_three.ONE_PPO     THRE_PPO
        ,future_three.ONE_TD      THRE_TD 

        ,future_four.ONE_SOH      FOUR_SOH
        ,future_four.ONE_SPO      FOUR_SPO
        ,future_four.ONE_PPO      FOUR_PPO
        ,future_four.ONE_TD       FOUR_TD 

FROM  mast_item ,week_avg, future_one ,future_two , future_three ,future_four 
WHERE
       --left join  week_avg
           mast_item.INVENTORY_ITEM_ID = week_avg.INVENTORY_ITEM_ID(+)
      and  mast_item.SUPPLIER_SITE_ID       = week_avg.VENDOR_SITE_ID(+)
-- left join  future one 
      and  mast_item.INVENTORY_ITEM_ID = future_one.ONE_INVENTORY_ITEM_ID(+)
      and  mast_item.SUPPLIER_SITE_ID       = future_one.ONE_SUPPLIER_SITE_ID(+)
-- left join  future two 
      and  mast_item.INVENTORY_ITEM_ID = future_two.ONE_INVENTORY_ITEM_ID(+)
      and  mast_item.SUPPLIER_SITE_ID       = future_two.ONE_SUPPLIER_SITE_ID(+)
-- left join  future three 
      and  mast_item.INVENTORY_ITEM_ID = future_three.ONE_INVENTORY_ITEM_ID(+)
      and  mast_item.SUPPLIER_SITE_ID       = future_three.ONE_SUPPLIER_SITE_ID(+)
-- left join  future future_four 
      and  mast_item.INVENTORY_ITEM_ID = future_four.ONE_INVENTORY_ITEM_ID(+)
      and  mast_item.SUPPLIER_SITE_ID       = future_four.ONE_SUPPLIER_SITE_ID(+)