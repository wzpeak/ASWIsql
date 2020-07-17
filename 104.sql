with

  real_tab1  as (




        SELECT

          item_info.INVENTORY_ITEM_ID                                INVENTORY_ITEM_ID
        , item_info.ORGANIZATION_ID                                   ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                    MRP_ITEM_ID
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM


            ,orders.RESOURCE_ID                                                  RESOURCE_ID
--             ,orders.TRANSACTION_ID                                               TRANSACTION_ID

--             item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
            ,orders.RESOURCE_HOURS                            ONE_RESOURCE_HOURS
            ,0                                                TWO_RESOURCE_HOURS
            ,0                                                THREE_RESOURCE_HOURS
            ,0                                                FOUR_RESOURCE_HOURS

            ,orders.CUMMULATIVE_QUANTITY                      ONE_CUMMULATIVE_QUANTITY
            ,0                                                TWO_CUMMULATIVE_QUANTITY
            ,0                                                THREE_CUMMULATIVE_QUANTITY
            ,0                                                FOUR_CUMMULATIVE_QUANTITY


        FROM

                 MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_RESOURCE_REQUIREMENTSRC_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select  *   from  MSC_SYSTEM_ITEMS_V where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat
        WHERE
                mrp_name.PLAN_ID = orders.PLAN_ID
            ---find  only one mrp item
            AND orders.ASSEMBLY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
            AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID
            --          find  real item  by  id and  org_code
            AND mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
            AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
            AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID

           --  filter for 'MPS planning'    both mapping  id and  org_code0
           AND item_method.INVENTORY_ITEM_ID =  orders.ASSEMBLY_ITEM_ID
           AND item_method.ORGANIZATION_ID   =   orders.ORGANIZATION_ID
            and item_method.plan_id = orders.plan_id




 -- relate  item category
            AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
            AND item_cat.ORGANIZATION_ID =   item_info.ORGANIZATION_ID

            AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))



            AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
            AND item_store_org.ORGANIZATION_CODE   = :P_ITEM_ORG
--             AND item_method.MRP_PLANNING_CODE   = 'MPS planning'
            AND 1 = :P_HIERARCHIES

--              AND orders.PLANNED_ORDER_TYPE  IN('Buy','购买')

            AND to_char(orders.END_DATE, 'YYYY-MM-DD')  IN
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
            FROM MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE  =  (select WEEK_START_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE
                                                                )
                                                        )

--         group by   item_info.INVENTORY_ITEM_ID

 UNION ALL


      SELECT

          item_info.INVENTORY_ITEM_ID                                INVENTORY_ITEM_ID
        , item_info.ORGANIZATION_ID                                   ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                    MRP_ITEM_ID
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM
--         , item_info.PREPROCESSING_LEAD_TIME + item_info.POSTPROCESSING_LEAD_TIME + item_info.FULL_LEAD_TIME          LEAD_TIME
--         , item_info.MINIMUM_ORDER_QUANTITY                              MIN_QTY


            ,orders.RESOURCE_ID                                                  RESOURCE_ID
--             ,orders.TRANSACTION_ID                                               TRANSACTION_ID

--             item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
            ,0                                                ONE_RESOURCE_HOURS
            ,orders.RESOURCE_HOURS                            TWO_RESOURCE_HOURS
            ,0                                                THREE_RESOURCE_HOURS
            ,0                                                FOUR_RESOURCE_HOURS

            ,0                                                ONE_CUMMULATIVE_QUANTITY
            ,orders.CUMMULATIVE_QUANTITY                      TWO_CUMMULATIVE_QUANTITY
            ,0                                                THREE_CUMMULATIVE_QUANTITY
            ,0                                                FOUR_CUMMULATIVE_QUANTITY


        FROM

                 MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_RESOURCE_REQUIREMENTSRC_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select  *   from  MSC_SYSTEM_ITEMS_V where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat
        WHERE
                mrp_name.PLAN_ID = orders.PLAN_ID
            ---find  only one mrp item
            AND orders.ASSEMBLY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
            AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID
            --          find  real item  by  id and  org_code
            AND mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
            AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
            AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID

           --  filter for 'MPS planning'    both mapping  id and  org_code0
           AND item_method.INVENTORY_ITEM_ID =  orders.ASSEMBLY_ITEM_ID
           AND item_method.ORGANIZATION_ID   =   orders.ORGANIZATION_ID
            and item_method.plan_id = orders.plan_id




 -- relate  item category
            AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
            AND item_cat.ORGANIZATION_ID =   item_info.ORGANIZATION_ID

            AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))



            AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
            AND item_store_org.ORGANIZATION_CODE   = :P_ITEM_ORG
--             AND item_method.MRP_PLANNING_CODE   = 'MPS planning'
            AND 1 = :P_HIERARCHIES

            -- oders   filter
            AND to_char(orders.END_DATE, 'YYYY-MM-DD')  IN
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
            FROM MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE  =  (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE
                                                                )
                                                        )

--         group by   item_info.INVENTORY_ITEM_ID

     UNION ALL

       SELECT

          item_info.INVENTORY_ITEM_ID                                INVENTORY_ITEM_ID
        , item_info.ORGANIZATION_ID                                   ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                    MRP_ITEM_ID
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM
--         , item_info.PREPROCESSING_LEAD_TIME + item_info.POSTPROCESSING_LEAD_TIME + item_info.FULL_LEAD_TIME          LEAD_TIME
--         , item_info.MINIMUM_ORDER_QUANTITY                              MIN_QTY


            ,orders.RESOURCE_ID                                                  RESOURCE_ID
--             ,orders.TRANSACTION_ID                                               TRANSACTION_ID

--             item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
            ,0                                            ONE_RESOURCE_HOURS
            ,0                                                TWO_RESOURCE_HOURS
            ,orders.RESOURCE_HOURS                              THREE_RESOURCE_HOURS
            ,0                                                FOUR_RESOURCE_HOURS

            ,0                                              ONE_CUMMULATIVE_QUANTITY
            ,0                                                TWO_CUMMULATIVE_QUANTITY
            ,orders.CUMMULATIVE_QUANTITY                       THREE_CUMMULATIVE_QUANTITY
            ,0                                                FOUR_CUMMULATIVE_QUANTITY


        FROM

                 MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_RESOURCE_REQUIREMENTSRC_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select  *   from  MSC_SYSTEM_ITEMS_V where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat
        WHERE
                mrp_name.PLAN_ID = orders.PLAN_ID
            ---find  only one mrp item
            AND orders.ASSEMBLY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
            AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID
            --          find  real item  by  id and  org_code
            AND mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
            AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
            AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID

           --  filter for 'MPS planning'    both mapping  id and  org_code0
           AND item_method.INVENTORY_ITEM_ID =  orders.ASSEMBLY_ITEM_ID
           AND item_method.ORGANIZATION_ID   =   orders.ORGANIZATION_ID
            and item_method.plan_id = orders.plan_id




 -- relate  item category
            AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
            AND item_cat.ORGANIZATION_ID =   item_info.ORGANIZATION_ID

            AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))



            AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
            AND item_store_org.ORGANIZATION_CODE   = :P_ITEM_ORG
--             AND item_method.MRP_PLANNING_CODE   = 'MPS planning'
            AND 1 = :P_HIERARCHIES

            -- oders   filter
            AND to_char(orders.END_DATE, 'YYYY-MM-DD')  IN
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
            FROM MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE =  (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE)
                                                                )
                                                        )

--         group by   item_info.INVENTORY_ITEM_ID
     UNION ALL

       SELECT

          item_info.INVENTORY_ITEM_ID                                INVENTORY_ITEM_ID
        , item_info.ORGANIZATION_ID                                   ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                    MRP_ITEM_ID
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM
--         , item_info.PREPROCESSING_LEAD_TIME + item_info.POSTPROCESSING_LEAD_TIME + item_info.FULL_LEAD_TIME          LEAD_TIME
--         , item_info.MINIMUM_ORDER_QUANTITY                              MIN_QTY


            ,orders.RESOURCE_ID                                                  RESOURCE_ID
--             ,orders.TRANSACTION_ID                                               TRANSACTION_ID

--             item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
            ,0                                                ONE_RESOURCE_HOURS
            ,0                                                TWO_RESOURCE_HOURS
            ,0                                                THREE_RESOURCE_HOURS
            ,orders.RESOURCE_HOURS                            FOUR_RESOURCE_HOURS

            ,0                                                ONE_CUMMULATIVE_QUANTITY
            ,0                                                TWO_CUMMULATIVE_QUANTITY
            ,0                                                THREE_CUMMULATIVE_QUANTITY
            ,orders.CUMMULATIVE_QUANTITY                      FOUR_CUMMULATIVE_QUANTITY


        FROM

                 MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_RESOURCE_REQUIREMENTSRC_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select  *   from  MSC_SYSTEM_ITEMS_V where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat
        WHERE
                mrp_name.PLAN_ID = orders.PLAN_ID
            ---find  only one mrp item
            AND orders.ASSEMBLY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
            AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID
            --          find  real item  by  id and  org_code
            AND mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
            AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
            AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID

           --  filter for 'MPS planning'    both mapping  id and  org_code0
           AND item_method.INVENTORY_ITEM_ID =  orders.ASSEMBLY_ITEM_ID
           AND item_method.ORGANIZATION_ID   =   orders.ORGANIZATION_ID
            and item_method.plan_id = orders.plan_id




 -- relate  item category
            AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
            AND item_cat.ORGANIZATION_ID =   item_info.ORGANIZATION_ID

            AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))



            AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
            AND item_store_org.ORGANIZATION_CODE   = :P_ITEM_ORG
--             AND item_method.MRP_PLANNING_CODE   = 'MPS planning'
            AND 1 = :P_HIERARCHIES
            -- oders   filter
            AND to_char(orders.END_DATE, 'YYYY-MM-DD')  IN
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
            FROM MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE =  (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = (select WEEK_NEXT_DATE
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE))
                                                                )
                                                        )
),
 mid_tab  as (
                 select   real_tab1.INVENTORY_ITEM_ID
                       ,real_tab1.ITEM_ORG
                       ,real_tab1.MRP_ITEM_ID
                       ,real_tab1.ITEM_NUMBER
                       ,real_tab1.UOM
                       ,real_tab1.RESOURCE_ID

                       ,sum(  real_tab1.ONE_RESOURCE_HOURS           )              ONE_HOURS
                       ,sum(  real_tab1.TWO_RESOURCE_HOURS              )           TWO_HOURS
                       ,sum(  real_tab1.THREE_RESOURCE_HOURS            )           THREE_HOURS
                       ,sum(  real_tab1.FOUR_RESOURCE_HOURS             )           FOUR_HOURS
                      ,sum(    real_tab1.ONE_CUMMULATIVE_QUANTITY         )        ONE_CUMMULATIVE_QUANTITY
                       ,sum(    real_tab1.TWO_CUMMULATIVE_QUANTITY         )        TWO_CUMMULATIVE_QUANTITY
                       ,sum(    real_tab1.THREE_CUMMULATIVE_QUANTITY      )         THREE_CUMMULATIVE_QUANTITY
                       ,sum(    real_tab1.FOUR_CUMMULATIVE_QUANTITY       )         FOUR_CUMMULATIVE_QUANTITY


                     FROM real_tab1
                     GROUP BY
                        real_tab1.INVENTORY_ITEM_ID
                       ,real_tab1.ITEM_ORG
                       ,real_tab1.MRP_ITEM_ID
                       ,real_tab1.ITEM_NUMBER
                       ,real_tab1.UOM
                       ,real_tab1.RESOURCE_ID
           ),

--         group by   item_info.INVENTORY_ITEM_ID
  -----------------------------------------------发你个县----------------------


cat_tab as (

      SELECT   mid_tab.*, work_hours.ATTRIBUTE_NUMBER1
      ,(SUM(mid_tab.ONE_HOURS)  over( order by mid_tab.INVENTORY_ITEM_ID ) ) -  mid_tab.ONE_HOURS  as  ONE_RUNNING

      ,(SUM(mid_tab.TWO_HOURS)   over( order by mid_tab.INVENTORY_ITEM_ID ) ) - mid_tab.TWO_HOURS as  TWO_RUNNING

      ,(SUM(mid_tab.THREE_HOURS)   over( order by mid_tab.INVENTORY_ITEM_ID )) - mid_tab.THREE_HOURS  as  THREE_RUNNING

      ,(SUM(mid_tab.FOUR_HOURS)  over( order by mid_tab.INVENTORY_ITEM_ID )) - mid_tab.FOUR_HOURS  as  FOUR_RUNNING
       FROM     mid_tab ,
                 MSC_DIM_RESOURCE_V         re_id_parent
              ,WIS_WORK_CENTERS_VL        work_hours
      where
        re_id_parent.id =   mid_tab.RESOURCE_ID
    AND re_id_parent.PARENT_ID =  work_hours.WORK_CENTER_ID


)

 SELECT
        cat_tab.*
        ,  CASE      WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)  > = 0    AND   0 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)    = 0   AND  0 < :P_DAYS )
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_ONE
          ,  CASE      WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)  > = 1   AND   1 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)    = 1   AND   1 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_TWO
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)  > = 2   AND   2 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)    = 2   AND   2 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_THREE
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)  > = 3   AND   3 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)    = 3   AND   3 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_FOUR
                   ,  CASE      WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)  > = 4   AND   4 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)    = 4   AND   4 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_FIVE
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)  > = 5   AND   5 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)    = 5   AND   5 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_SIX
                   ,  CASE     WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)  > = 6   AND   6 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / 5)    = 6   AND   6 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_SEVEN



        ,  CASE      WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)  > = 0    AND   0 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)    = 0   AND  0 < :P_DAYS )
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_ONE
          ,  CASE      WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)  > = 1   AND   1 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)    = 1   AND   1 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_TWO
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)  > = 2   AND   2 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)    = 2   AND   2 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_THREE
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)  > = 3   AND   3 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)    = 3   AND   3 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_FOUR
                   ,  CASE      WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)  > = 4   AND   4 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)    = 4   AND   4 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_FIVE
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)  > = 5   AND   5 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)    = 5   AND   5 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_SIX
                   ,  CASE     WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)  > = 6   AND   6 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / 5)    = 6   AND   6 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_SEVEN


        ,  CASE      WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)  > = 0    AND   0 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)    = 0   AND  0 < :P_DAYS )
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_ONE
          ,  CASE      WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)  > = 1   AND   1 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)    = 1   AND   1 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_TWO
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)  > = 2   AND   2 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)    = 2   AND   2 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_THREE
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)  > = 3   AND   3 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)    = 3   AND   3 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_FOUR
                   ,  CASE      WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)  > = 4   AND   4 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)    = 4   AND   4 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_FIVE
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)  > = 5   AND   5 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)    = 5   AND   5 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_SIX
                   ,  CASE     WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)  > = 6   AND   6 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / 5)    = 6   AND   6 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_SEVEN


        ,  CASE      WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)  > = 0    AND   0 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)    = 0   AND  0 < :P_DAYS )
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_ONE
          ,  CASE      WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)  > = 1   AND   1 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)    = 1   AND   1 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_TWO
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)  > = 2   AND   2 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)    = 2   AND   2 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_THREE
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)  > = 3   AND   3 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)    = 3   AND   3 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_FOUR
                   ,  CASE      WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)  > = 4   AND   4 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)    = 4   AND   4 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_FIVE
                   ,  CASE       WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)  > = 5   AND   5 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)    = 5   AND   5 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_SIX
                   ,  CASE     WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)  > = 6   AND   6 = :P_DAYS ) OR
                            ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / 5)    = 6   AND   6 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_SEVEN




 FROM  cat_tab




