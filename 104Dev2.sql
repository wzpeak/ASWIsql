
with

        sum_onhand
        AS
        (
                SELECT ori_orders_h.PLAN_ID
                 , ori_orders_h.INVENTORY_ITEM_ID
                 , ori_orders_h.ORGANIZATION_ID
                 , ori_orders_h.SUGGESTED_DUE_DATE
                 , SUM(NVL(ori_orders_h.ORDER_QUANTITY,0) )  order_quantity
                --                  , ori_orders_f.ORDER_QUANTITY   forc_qty


                FROM
                        MSC_ANALYTIC_FACT_ORD_V                   ori_orders_h
                        , MSC_ANALYTIC_PRIVATE_PLAN_V                mrp_name
                --       , MSC_ANALYTIC_FACT_ORD_V                   ori_orders_f
                where
                        ori_orders_h.PLAN_ID            =  mrp_name.PLAN_ID
                        AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
                        -- AND ori_orders_h.INVENTORY_ITEM_ID  =  ori_orders_f.INVENTORY_ITEM_ID
                        -- AND ori_orders_h.ORGANIZATION_ID    =  ori_orders_f.ORGANIZATION_ID
                        -- AND ori_orders_h.SUGGESTED_DUE_DATE    =  ori_orders_f.SUGGESTED_DUE_DATE
                        AND ori_orders_h.ORDER_QUANTITY is not null
                        AND ori_orders_h.ORDER_TYPE = 18

                group by
                   ori_orders_h.PLAN_ID
                 , ori_orders_h.INVENTORY_ITEM_ID
                 , ori_orders_h.ORGANIZATION_ID
                 , ori_orders_h.SUGGESTED_DUE_DATE
        ),
        sum_forcast
        AS
        (
                SELECT ori_orders_f.PLAN_ID
                 , ori_orders_f.INVENTORY_ITEM_ID
                 , ori_orders_f.ORGANIZATION_ID
             ---    , ori_orders_f.SUGGESTED_DUE_DATE
                 , SUM(NVL(ori_orders_f.ORDER_QUANTITY,0) )  order_quantity
                --                  , ori_orders_f.ORDER_QUANTITY   forc_qty


                FROM
                        MSC_ANALYTIC_FACT_ORD_V                   ori_orders_f
                      , MSC_ANALYTIC_PRIVATE_PLAN_V                mrp_name
                --       , MSC_ANALYTIC_FACT_ORD_V                   ori_orders_f
                where
                        ori_orders_f.PLAN_ID            =  mrp_name.PLAN_ID
                        AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
                        -- AND ori_orders_f.INVENTORY_ITEM_ID  =  ori_orders_f.INVENTORY_ITEM_ID
                        -- AND ori_orders_f.ORGANIZATION_ID    =  ori_orders_f.ORGANIZATION_ID
                        -- AND ori_orders_f.SUGGESTED_DUE_DATE    =  ori_orders_f.SUGGESTED_DUE_DATE
                        AND ori_orders_f.ORDER_QUANTITY is not null
                        AND ori_orders_f.ORDER_TYPE  = 1029
                        AND to_char(ori_orders_f.SUGGESTED_DUE_DATE, 'YYYY-MM-DD')  IN
                                                        (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
                        FROM MSC_ANALYTIC_CALENDARS_V
                        where WEEK_START_DATE  =  (select WEEK_START_DATE
                        from MSC_ANALYTIC_CALENDARS_V
                        where to_char(CALENDAR_DATE,'YYYY-MM-DD' ) IN ( select to_char(sum_onhand.SUGGESTED_DUE_DATE,'YYYY-MM-DD'  )
                        from sum_onhand )
                                                                )
                                                        )

                group by
                   ori_orders_f.PLAN_ID
                 , ori_orders_f.INVENTORY_ITEM_ID
                 , ori_orders_f.ORGANIZATION_ID
                --  , ori_orders_f.SUGGESTED_DUE_DATE
        ),
        tab_onhand_forcast
        AS
        (

                SELECT sum_onhand.PLAN_ID
                 , sum_onhand.INVENTORY_ITEM_ID
                 , sum_onhand.ORGANIZATION_ID
             ---    , sum_onhand.SUGGESTED_DUE_DATE
                 , sum_onhand.ORDER_QUANTITY   on_hand_qty
                 , sum_forcast.ORDER_QUANTITY   forc_qty

                , ROUND(sum_onhand.ORDER_QUANTITY/sum_forcast.ORDER_QUANTITY,2)   as day_of_cover

                FROM
                        sum_onhand
                      , sum_forcast
                where
                            sum_onhand.PLAN_ID            =  sum_forcast.PLAN_ID
                        AND sum_onhand.INVENTORY_ITEM_ID  =  sum_forcast.INVENTORY_ITEM_ID
                        AND sum_onhand.ORGANIZATION_ID    =  sum_forcast.ORGANIZATION_ID
                -- AND sum_onhand.SUGGESTED_DUE_DATE    =  sum_forcast.SUGGESTED_DUE_DATE
                --   AND to_char(sum_forcast.SUGGESTED_DUE_DATE, 'YYYY-MM-DD')  IN
                --                                 (    SELECT to_char(CALENDAR_DATE,'YYYY-MM-DD') set_time
                --         FROM MSC_ANALYTIC_CALENDARS_V
                --         where WEEK_START_DATE  =  (select WEEK_START_DATE
                --         from MSC_ANALYTIC_CALENDARS_V
                --         where CALENDAR_DATE = sum_onhand.SUGGESTED_DUE_DATE 
                --                                         )
                --                                 )

                -- group by
                --    sum_onhand.PLAN_ID
                --  , sum_onhand.INVENTORY_ITEM_ID
                --  , sum_onhand.ORGANIZATION_ID
                --  , sum_onhand.SUGGESTED_DUE_DATE
                --                  , sum_onhand.ORDER_QUANTITY   on_hand_qty
                --                  , sum_forcast.ORDER_QUANTITY   forc_qty
        ),

        days_mid
        as
        (


                                                                        SELECT

                                item_info.INVENTORY_ITEM_ID                                INVENTORY_ITEM_ID
        , item_info.ORGANIZATION_ID                                   ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                    MRP_ITEM_ID
        , mrp_item.ORGANIZATION_ID                                      MRP_ITEM_ORG
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM

        -- , item_info.ATTRIBUTE6                                          ATTRIBUTE6
        -- , item_info.ATTRIBUTE7                                          ATTRIBUTE7
        -- , item_info.ATTRIBUTE_NUMBER1                                   ATTRIBUTE_NUMBER1
        -- , item_info.ATTRIBUTE2                                          ATTRIBUTE2

        , item_info.ATTRIBUTE_NUMBER2                                   ATTRIBUTE_NUMBER2
        , item_info.ATTRIBUTE5                                          ATTRIBUTE5
        , itemEffB.ATTRIBUTE_CHAR6                                      PRODUCT_CODE
        , itemEffB_sp.Attribute_Char1                                   PRODUCT_SPEC

            , orders.RESOURCE_ID                                                  RESOURCE_ID
--             ,orders.TRANSACTION_ID                                               TRANSACTION_ID

--             item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
            , orders.RESOURCE_HOURS                            ONE_RESOURCE_HOURS
            , 0                                                TWO_RESOURCE_HOURS
            , 0                                                THREE_RESOURCE_HOURS
            , 0                                                FOUR_RESOURCE_HOURS

            , orders.CUMMULATIVE_QUANTITY                      ONE_CUMMULATIVE_QUANTITY
            , 0                                                TWO_CUMMULATIVE_QUANTITY
            , 0                                                THREE_CUMMULATIVE_QUANTITY
            , 0                                                FOUR_CUMMULATIVE_QUANTITY

                        -- --             add days of  cover


                        FROM

                                MSC_ANALYTIC_PRIVATE_PLAN_V                mrp_name
                , EGP_SYSTEM_ITEMS_V                        item_info
                , MSC_RESOURCE_REQUIREMENTSRC_V              orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select *
                                from MSC_SYSTEM_ITEMS_V
                                where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                , MSC_AP_ITEM_CATEGORIES_V                   item_cat
--                 add   days of cover on hand
                , EGO_ITEM_EFF_B                              itemEffB
                , EGO_ITEM_EFF_B                              itemEffB_sp


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

                                -- dev2  sort attr
                                AND item_info.INVENTORY_ITEM_ID = itemEffB.INVENTORY_ITEM_ID(+)
                                and item_info.ORGANIZATION_ID   = itemEffB.ORGANIZATION_ID(+)
                                and 'ASWI_GZ_FG_SALES' = itemEffB.CONTEXT_CODE(+)

                                AND item_info.INVENTORY_ITEM_ID = itemEffB_sp.INVENTORY_ITEM_ID(+)
                                and item_info.ORGANIZATION_ID   = itemEffB_sp.ORGANIZATION_ID(+)
                                and 'ASWI_GZ_FG' = itemEffB_sp.CONTEXT_CODE(+)






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
        , mrp_item.ORGANIZATION_ID                                      MRP_ITEM_ORG
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM
--         , item_info.PREPROCESSING_LEAD_TIME + item_info.POSTPROCESSING_LEAD_TIME + item_info.FULL_LEAD_TIME          LEAD_TIME
--         , item_info.MINIMUM_ORDER_QUANTITY                              MIN_QTY
        , item_info.ATTRIBUTE_NUMBER2                                   ATTRIBUTE_NUMBER2
        , item_info.ATTRIBUTE5                                          ATTRIBUTE5
        , itemEffB.ATTRIBUTE_CHAR6                                      PRODUCT_CODE
        , itemEffB_sp.Attribute_Char1                                   PRODUCT_SPEC

            , orders.RESOURCE_ID                                                  RESOURCE_ID
--             ,orders.TRANSACTION_ID                                               TRANSACTION_ID

--             item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
            , 0                                                ONE_RESOURCE_HOURS
            , orders.RESOURCE_HOURS                            TWO_RESOURCE_HOURS
            , 0                                                THREE_RESOURCE_HOURS
            , 0                                                FOUR_RESOURCE_HOURS

            , 0                                                ONE_CUMMULATIVE_QUANTITY
            , orders.CUMMULATIVE_QUANTITY                      TWO_CUMMULATIVE_QUANTITY
            , 0                                                THREE_CUMMULATIVE_QUANTITY
            , 0                                                FOUR_CUMMULATIVE_QUANTITY



                        FROM

                                MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_RESOURCE_REQUIREMENTSRC_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select *
                                from MSC_SYSTEM_ITEMS_V
                                where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat 
                                 , EGO_ITEM_EFF_B                              itemEffB
                , EGO_ITEM_EFF_B                              itemEffB_sp
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

                                -- dev2  sort attr
                                AND item_info.INVENTORY_ITEM_ID = itemEffB.INVENTORY_ITEM_ID(+)
                                and item_info.ORGANIZATION_ID   = itemEffB.ORGANIZATION_ID(+)
                                and 'ASWI_GZ_FG_SALES' = itemEffB.CONTEXT_CODE(+)

                                AND item_info.INVENTORY_ITEM_ID = itemEffB_sp.INVENTORY_ITEM_ID(+)
                                and item_info.ORGANIZATION_ID   = itemEffB_sp.ORGANIZATION_ID(+)
                                and 'ASWI_GZ_FG' = itemEffB_sp.CONTEXT_CODE(+)



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
        , mrp_item.ORGANIZATION_ID                                      MRP_ITEM_ORG
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM
--         , item_info.PREPROCESSING_LEAD_TIME + item_info.POSTPROCESSING_LEAD_TIME + item_info.FULL_LEAD_TIME          LEAD_TIME
--         , item_info.MINIMUM_ORDER_QUANTITY                              MIN_QTY
         , item_info.ATTRIBUTE_NUMBER2                                   ATTRIBUTE_NUMBER2
        , item_info.ATTRIBUTE5                                          ATTRIBUTE5
        , itemEffB.ATTRIBUTE_CHAR6                                      PRODUCT_CODE
        , itemEffB_sp.Attribute_Char1                                   PRODUCT_SPEC

            , orders.RESOURCE_ID                                                  RESOURCE_ID
--             ,orders.TRANSACTION_ID                                               TRANSACTION_ID

--             item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
            , 0                                            ONE_RESOURCE_HOURS
            , 0                                                TWO_RESOURCE_HOURS
            , orders.RESOURCE_HOURS                              THREE_RESOURCE_HOURS
            , 0                                                FOUR_RESOURCE_HOURS

            , 0                                              ONE_CUMMULATIVE_QUANTITY
            , 0                                                TWO_CUMMULATIVE_QUANTITY
            , orders.CUMMULATIVE_QUANTITY                       THREE_CUMMULATIVE_QUANTITY
            , 0                                                FOUR_CUMMULATIVE_QUANTITY



                        FROM

                                MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_RESOURCE_REQUIREMENTSRC_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select *
                                from MSC_SYSTEM_ITEMS_V
                                where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat 
                                 , EGO_ITEM_EFF_B                              itemEffB
                , EGO_ITEM_EFF_B                              itemEffB_sp
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

                                -- dev2  sort attr
                                AND item_info.INVENTORY_ITEM_ID = itemEffB.INVENTORY_ITEM_ID(+)
                                and item_info.ORGANIZATION_ID   = itemEffB.ORGANIZATION_ID(+)
                                and 'ASWI_GZ_FG_SALES' = itemEffB.CONTEXT_CODE(+)

                                AND item_info.INVENTORY_ITEM_ID = itemEffB_sp.INVENTORY_ITEM_ID(+)
                                and item_info.ORGANIZATION_ID   = itemEffB_sp.ORGANIZATION_ID(+)
                                and 'ASWI_GZ_FG' = itemEffB_sp.CONTEXT_CODE(+)


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
        , mrp_item.ORGANIZATION_ID                                      MRP_ITEM_ORG
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM
--         , item_info.PREPROCESSING_LEAD_TIME + item_info.POSTPROCESSING_LEAD_TIME + item_info.FULL_LEAD_TIME          LEAD_TIME
--         , item_info.MINIMUM_ORDER_QUANTITY                              MIN_QTY
        , item_info.ATTRIBUTE_NUMBER2                                   ATTRIBUTE_NUMBER2
        , item_info.ATTRIBUTE5                                          ATTRIBUTE5
        , itemEffB.ATTRIBUTE_CHAR6                                      PRODUCT_CODE
        , itemEffB_sp.Attribute_Char1                                   PRODUCT_SPEC

            , orders.RESOURCE_ID                                                  RESOURCE_ID
--             ,orders.TRANSACTION_ID                                               TRANSACTION_ID

--             item_info.INVENTORY_ITEM_ID               ONE_INVENTORY_ITEM_ID
            , 0                                                ONE_RESOURCE_HOURS
            , 0                                                TWO_RESOURCE_HOURS
            , 0                                                THREE_RESOURCE_HOURS
            , orders.RESOURCE_HOURS                            FOUR_RESOURCE_HOURS

            , 0                                                ONE_CUMMULATIVE_QUANTITY
            , 0                                                TWO_CUMMULATIVE_QUANTITY
            , 0                                                THREE_CUMMULATIVE_QUANTITY
            , orders.CUMMULATIVE_QUANTITY                      FOUR_CUMMULATIVE_QUANTITY



                        FROM

                                MSC_ANALYTIC_PRIVATE_PLAN_V              mrp_name
                , EGP_SYSTEM_ITEMS_V                       item_info
                , MSC_RESOURCE_REQUIREMENTSRC_V                  orders
                , MSC_ANALYTIC_ITEMS                       item_method
                , (select *
                                from MSC_SYSTEM_ITEMS_V
                                where PLAN_ID = -1  )                     mrp_item
                , INV_ORG_PARAMETERS                       item_store_org
                 , MSC_AP_ITEM_CATEGORIES_V                   item_cat
                                 , EGO_ITEM_EFF_B                              itemEffB
                , EGO_ITEM_EFF_B                              itemEffB_sp
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

                                -- dev2  sort attr
                                AND item_info.INVENTORY_ITEM_ID = itemEffB.INVENTORY_ITEM_ID(+)
                                and item_info.ORGANIZATION_ID   = itemEffB.ORGANIZATION_ID(+)
                                and 'ASWI_GZ_FG_SALES' = itemEffB.CONTEXT_CODE(+)

                                AND item_info.INVENTORY_ITEM_ID = itemEffB_sp.INVENTORY_ITEM_ID(+)
                                and item_info.ORGANIZATION_ID   = itemEffB_sp.ORGANIZATION_ID(+)
                                and 'ASWI_GZ_FG' = itemEffB_sp.CONTEXT_CODE(+)


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

        real_tab1
        AS
        (
                SELECT days_mid.* , tab_onhand_forcast.day_of_cover
                FROM days_mid , tab_onhand_forcast
                WHERE  
                                                 --                 add   days of cover on hand
                                    days_mid.MRP_ITEM_ID               =  tab_onhand_forcast.INVENTORY_ITEM_ID(+)
                        AND days_mid.MRP_ITEM_ORG              =  tab_onhand_forcast.ORGANIZATION_ID(+)

        ),
        -- list and order  all origin data, ready for next calculate
        mid_tab
        as
        (
                select real_tab1.INVENTORY_ITEM_ID
                       , real_tab1.ITEM_ORG
                       , real_tab1.MRP_ITEM_ID
                       , real_tab1.MRP_ITEM_ORG
                       , real_tab1.ITEM_NUMBER
                       , real_tab1.UOM
                       , real_tab1.RESOURCE_ID
                --        , real_tab1.ATTRIBUTE6                                          ATTRIBUTE6
                --        , real_tab1.ATTRIBUTE7                                          ATTRIBUTE7
                --        , real_tab1.ATTRIBUTE_NUMBER1                                   ATTRIBUTE_NUMBER1
                --        , real_tab1.ATTRIBUTE2                                          ATTRIBUTE2
                        , real_tab1.ATTRIBUTE_NUMBER2                                   ATTRIBUTE_NUMBER2
                        , real_tab1.ATTRIBUTE5                                          ATTRIBUTE5
                        , real_tab1.PRODUCT_CODE                                      PRODUCT_CODE
                        , real_tab1.PRODUCT_SPEC                                      PRODUCT_SPEC

                       , real_tab1.day_of_cover                                        day_of_cover

                       , sum(  real_tab1.ONE_RESOURCE_HOURS           )              ONE_HOURS
                       , sum(  real_tab1.TWO_RESOURCE_HOURS              )           TWO_HOURS
                       , sum(  real_tab1.THREE_RESOURCE_HOURS            )           THREE_HOURS
                       , sum(  real_tab1.FOUR_RESOURCE_HOURS             )           FOUR_HOURS
                      , sum(    real_tab1.ONE_CUMMULATIVE_QUANTITY         )        ONE_CUMMULATIVE_QUANTITY
                       , sum(    real_tab1.TWO_CUMMULATIVE_QUANTITY         )        TWO_CUMMULATIVE_QUANTITY
                       , sum(    real_tab1.THREE_CUMMULATIVE_QUANTITY      )         THREE_CUMMULATIVE_QUANTITY
                       , sum(    real_tab1.FOUR_CUMMULATIVE_QUANTITY       )         FOUR_CUMMULATIVE_QUANTITY


                FROM real_tab1
                GROUP BY
                        real_tab1.INVENTORY_ITEM_ID
                       ,real_tab1.ITEM_ORG
                       ,real_tab1.MRP_ITEM_ID
                       ,real_tab1.MRP_ITEM_ORG
                       ,real_tab1.ITEM_NUMBER
                       ,real_tab1.UOM
                       ,real_tab1.RESOURCE_ID
                --        , real_tab1.ATTRIBUTE6
                --        , real_tab1.ATTRIBUTE7
                --        , real_tab1.ATTRIBUTE_NUMBER1
                --        , real_tab1.ATTRIBUTE2
                 , real_tab1.ATTRIBUTE_NUMBER2
                , real_tab1.ATTRIBUTE5       
                , real_tab1.PRODUCT_CODE  
                , real_tab1.PRODUCT_SPEC  

                       , real_tab1.day_of_cover

        ),

        --         group by   item_info.INVENTORY_ITEM_ID
        -----------------------------------------------发你个县----------------------


        cat_tab
        as
        (

                SELECT mid_tab.*, work_hours.ATTRIBUTE_NUMBER1  AS HOURS_NUM ,re_id_parent.NAME 

                -- denpend on the  sort  category  1、2、3  2020、07、22
                , CASE WHEN   1 = :P_SORT       THEN 
                -- order  by   days of  cover 
       (SUM(mid_tab.ONE_HOURS)      over( order by mid_tab.RESOURCE_ID, mid_tab.day_of_cover,mid_tab.INVENTORY_ITEM_ID ) ) -  mid_tab.ONE_HOURS   
                     WHEN  2  = :P_SORT    THEN 
       (SUM(mid_tab.ONE_HOURS)      over( order by  mid_tab.RESOURCE_ID,mid_tab.PRODUCT_CODE, mid_tab.PRODUCT_SPEC, mid_tab.ATTRIBUTE5,mid_tab.INVENTORY_ITEM_ID ) ) -  mid_tab.ONE_HOURS  
                     WHEN 3  = :P_SORT   THEN 
       (SUM(mid_tab.ONE_HOURS)      over( order by   mid_tab.RESOURCE_ID,mid_tab.ATTRIBUTE_NUMBER2,mid_tab.INVENTORY_ITEM_ID  ) ) -  mid_tab.ONE_HOURS   
                    ELSE NULl END  as  ONE_RUNNING 

       , CASE WHEN  1 = :P_SORT  THEN 
       (SUM(mid_tab.TWO_HOURS)      over( order by mid_tab.RESOURCE_ID, mid_tab.day_of_cover,mid_tab.INVENTORY_ITEM_ID ) ) -  mid_tab.TWO_HOURS   
                     WHEN 2  = :P_SORT  THEN
       (SUM(mid_tab.TWO_HOURS)     over( order by mid_tab.RESOURCE_ID, mid_tab.PRODUCT_CODE, mid_tab.PRODUCT_SPEC, mid_tab.ATTRIBUTE5,mid_tab.INVENTORY_ITEM_ID ) ) -  mid_tab.TWO_HOURS  
                     WHEN 3  = :P_SORT   THEN
       (SUM(mid_tab.TWO_HOURS)      over( order by mid_tab.RESOURCE_ID,  mid_tab.ATTRIBUTE_NUMBER2,mid_tab.INVENTORY_ITEM_ID  ) ) -  mid_tab.TWO_HOURS   
                    ELSE NULl END as  TWO_RUNNING 

       , CASE WHEN  1 = :P_SORT  THEN 
       (SUM(mid_tab.THREE_HOURS)      over( order by mid_tab.RESOURCE_ID, mid_tab.day_of_cover,mid_tab.INVENTORY_ITEM_ID ) ) -  mid_tab.THREE_HOURS   
                     WHEN 2  = :P_SORT  THEN
       (SUM(mid_tab.THREE_HOURS)      over( order by mid_tab.RESOURCE_ID, mid_tab.PRODUCT_CODE, mid_tab.PRODUCT_SPEC, mid_tab.ATTRIBUTE5,mid_tab.INVENTORY_ITEM_ID ) ) -  mid_tab.THREE_HOURS  
                     WHEN 3  = :P_SORT   THEN
       (SUM(mid_tab.THREE_HOURS)      over( order by  mid_tab.RESOURCE_ID, mid_tab.ATTRIBUTE_NUMBER2,mid_tab.INVENTORY_ITEM_ID  ) ) -  mid_tab.THREE_HOURS   
                    ELSE NULl END as  THREE_RUNNING 
       , CASE WHEN  1 = :P_SORT  THEN 
       (SUM(mid_tab.FOUR_HOURS)      over( order by mid_tab.RESOURCE_ID, mid_tab.day_of_cover,mid_tab.INVENTORY_ITEM_ID ) ) -  mid_tab.FOUR_HOURS   
                     WHEN 2  = :P_SORT  THEN 
       (SUM(mid_tab.FOUR_HOURS)      over( order by mid_tab.RESOURCE_ID, mid_tab.PRODUCT_CODE, mid_tab.PRODUCT_SPEC, mid_tab.ATTRIBUTE5,mid_tab.INVENTORY_ITEM_ID ) ) -  mid_tab.FOUR_HOURS  
                     WHEN 3  = :P_SORT  THEN
       (SUM(mid_tab.FOUR_HOURS)      over( order by mid_tab.RESOURCE_ID,  mid_tab.ATTRIBUTE_NUMBER2,mid_tab.INVENTORY_ITEM_ID  ) ) -  mid_tab.FOUR_HOURS   
                    ELSE NULl  END  as  FOUR_RUNNING

                --       , (SUM(mid_tab.TWO_HOURS)      over( order by mid_tab.ATTRIBUTE_NUMBER1, mid_tab.ATTRIBUTE2  ) ) - mid_tab.TWO_HOURS as  TWO_RUNNING

                --       , (SUM(mid_tab.THREE_HOURS)    over( order by mid_tab.ATTRIBUTE_NUMBER1, mid_tab.ATTRIBUTE2  )) - mid_tab.THREE_HOURS  as  THREE_RUNNING

                --       , (SUM(mid_tab.FOUR_HOURS)     over( order by mid_tab.ATTRIBUTE_NUMBER1, mid_tab.ATTRIBUTE2  )) - mid_tab.FOUR_HOURS  as  FOUR_RUNNING

                FROM mid_tab ,
                        MSC_DIM_RESOURCE_V         re_id_parent
              , WIS_WORK_CENTERS_VL        work_hours
                where
        re_id_parent.id =   mid_tab.RESOURCE_ID
                        AND re_id_parent.PARENT_ID =  work_hours.WORK_CENTER_ID


        )

SELECT
        cat_tab.*
        , CASE      WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 0 AND 0 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 0 AND 0 < :P_DAYS )
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_ONE
          , CASE      WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 1 AND 1 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 1 AND 1 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_TWO
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 2 AND 2 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 2 AND 2 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_THREE
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 3 AND 3 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 3 AND 3 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_FOUR
                   , CASE      WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 4 AND 4 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 4 AND 4 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_FIVE
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 5 AND 5 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 5 AND 5 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_SIX
                   , CASE     WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 6 AND 6 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 6 AND 6 < :P_DAYS )
--
                     THEN  cat_tab.ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_SEVEN



        , CASE      WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)  > = 0 AND 0 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)    = 0 AND 0 < :P_DAYS )
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_ONE
          , CASE      WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)  > = 1 AND 1 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)    = 1 AND 1 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_TWO
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)  > = 2 AND 2 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)    = 2 AND 2 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_THREE
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)  > = 3 AND 3 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)    = 3 AND 3 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_FOUR
                   , CASE      WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)  > = 4 AND 4 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)    = 4 AND 4 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_FIVE
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)  > = 5 AND 5 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)    = 5 AND 5 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_SIX
                   , CASE     WHEN ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)  > = 6 AND 6 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.TWO_RUNNING,0) / cat_tab.HOURS_NUM)    = 6 AND 6 < :P_DAYS )
--
                     THEN  cat_tab.TWO_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS TWO_SEVEN


        , CASE      WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 0 AND 0 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)    = 0 AND 0 < :P_DAYS )
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_ONE
          , CASE      WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 1 AND 1 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)    = 1 AND 1 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_TWO
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 2 AND 2 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)    = 2 AND 2 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_THREE
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 3 AND 3 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)    = 3 AND 3 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_FOUR
                   , CASE      WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 4 AND 4 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)    = 4 AND 4 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_FIVE
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 5 AND 5 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)    = 5 AND 5 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_SIX
                   , CASE     WHEN ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 6 AND 6 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.THREE_RUNNING,0) / cat_tab.HOURS_NUM)    = 6 AND 6 < :P_DAYS )
--
                     THEN  cat_tab.THREE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS THREE_SEVEN


        , CASE      WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)  > = 0 AND 0 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)    = 0 AND 0 < :P_DAYS )
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_ONE
          , CASE      WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)  > = 1 AND 1 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)    = 1 AND 1 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_TWO
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)  > = 2 AND 2 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)    = 2 AND 2 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_THREE
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)  > = 3 AND 3 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)    = 3 AND 3 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_FOUR
                   , CASE      WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)  > = 4 AND 4 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)    = 4 AND 4 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_FIVE
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)  > = 5 AND 5 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)    = 5 AND 5 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_SIX
                   , CASE     WHEN ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)  > = 6 AND 6 = :P_DAYS ) OR
                ( FLOOR(NVL(cat_tab.FOUR_RUNNING,0) / cat_tab.HOURS_NUM)    = 6 AND 6 < :P_DAYS )
--
                     THEN  cat_tab.FOUR_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS FOUR_SEVEN




FROM cat_tab




