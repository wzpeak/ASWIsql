


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
            AND item_method.MRP_PLANNING_CODE   = 'MPS planning'
            AND 1 = :P_HIERARCHIES

            -- oders   filter
--             AND orders.ORDER_TYPE IN( 18,1,5,1001)
            
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
            AND item_method.MRP_PLANNING_CODE   = 'MPS planning'
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
            AND item_method.MRP_PLANNING_CODE   = 'MPS planning'
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
            AND item_method.MRP_PLANNING_CODE   = 'MPS planning'
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

--         group by   item_info.INVENTORY_ITEM_ID
  -----------------------------------------------发你个县----------------------

    origin_tab  as (



SELECT   mast_item.*
         ,future_one.RESOURCE_HOURS            ONE_HOURS
         ,future_one.CUMMULATIVE_QUANTITY      ONE_CUMMULATIVE_QUANTITY
         ,future_two.RESOURCE_HOURS            TWO_HOURS
         ,future_two.CUMMULATIVE_QUANTITY      TWO_CUMMULATIVE_QUANTITY
         ,future_three.RESOURCE_HOURS          THREE_HOURS
         ,future_three.CUMMULATIVE_QUANTITY    THREE_CUMMULATIVE_QUANTITY
         ,future_four.RESOURCE_HOURS           FOUR_HOURS
         ,future_four.CUMMULATIVE_QUANTITY     FOUR_CUMMULATIVE_QUANTITY



FROM  mast_item , future_one ,future_two , future_three ,future_four
WHERE
-- left join  future one
          mast_item.INVENTORY_ITEM_ID = future_one.ONE_INVENTORY_ITEM_ID
-- left join  future two
      and  mast_item.INVENTORY_ITEM_ID = future_two.ONE_INVENTORY_ITEM_ID
-- left join  future three
      and  mast_item.INVENTORY_ITEM_ID = future_three.ONE_INVENTORY_ITEM_ID
-- left join  future future_four
      and  mast_item.INVENTORY_ITEM_ID = future_four.ONE_INVENTORY_ITEM_ID       )

      SELECT   origin_tab.*
      ,SUM(origin_tab.ONE_HOURS) over( order by origin_tab.INVENTORY_ITEM_ID ) as  ONE_RUNNING

      ,SUM(origin_tab.TWO_HOURS) over( order by origin_tab.INVENTORY_ITEM_ID ) as  TWO_RUNNING

      ,SUM(origin_tab.THREE_HOURS) over( order by origin_tab.INVENTORY_ITEM_ID ) as  THREE_RUNNING

      ,SUM(origin_tab.FOUR_HOURS) over( order by origin_tab.INVENTORY_ITEM_ID ) as  FOUR_RUNNING
      FROM     origin_tab


