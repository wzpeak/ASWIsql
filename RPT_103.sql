With
        days_mid
        --排序条件中间表*关键逻辑
        as
        (
                SELECT
                        item_info.INVENTORY_ITEM_ID                                INVENTORY_ITEM_ID
        , item_info.DESCRIPTION                                      DESCRIPTION 
        , item_info.ORGANIZATION_ID                                  ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                 MRP_ITEM_ID
        , mrp_item.ORGANIZATION_ID                                   MRP_ITEM_ORG
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM
        -- , item_info.ATTRIBUTE6                                          ATTRIBUTE6 --这里取口味
        -- , item_info.ATTRIBUTE7                                          ATTRIBUTE7 --规格
        -- , item_info.ATTRIBUTE_NUMBER1                                   ATTRIBUTE_NUMBER1 --自定义
        -- , item_info.ATTRIBUTE2                                          ATTRIBUTE2 --外包装
        , item_info.ATTRIBUTE_NUMBER2                                   ATTRIBUTE_NUMBER2
        , item_info.ATTRIBUTE5                                          ATTRIBUTE5
        , itemEffB.ATTRIBUTE_CHAR6                                      PRODUCT_CODE
		
		, orders.RESOURCE_HOURS                                ONE_RESOURCE_HOURS  --这里开始取订单时间
            , 0                                                TWO_RESOURCE_HOURS
            , 0                                                THREE_RESOURCE_HOURS
            , 0                                                FOUR_RESOURCE_HOURS
			
		, orders.CUMMULATIVE_QUANTITY                          ONE_CUMMULATIVE_QUANTITY  --这里可以不用参与排序
            , 0                                                TWO_CUMMULATIVE_QUANTITY
            , 0                                                THREE_CUMMULATIVE_QUANTITY
            , 0                                                FOUR_CUMMULATIVE_QUANTITY
			
		, orders.RESOURCE_ID                                                  RESOURCE_ID --这里可以不用参与排序
            , orders.USAGE_RATE                                                 USAGE_RATE
            , 0                                                 USAGE_RATE1   
            , 0                                                 USAGE_RATE2
            , 0                                                 USAGE_RATE3
			
		, ori_orders_h.SUGGESTED_DUE_DATE                       DUE_DATE
        , item_cate_name.CATEGORY_NAME                           CATEGORY_NAME
                FROM


                        EGP_SYSTEM_ITEMS_V                           item_info
                , (select *
                        from MSC_SYSTEM_ITEMS_V
                        where PLAN_ID = -1  )                     mrp_item
                , MSC_AP_ITEM_CATEGORIES_V                   item_cat
                , EGO_ITEM_EFF_B                             itemEffB
		, INV_ORG_PARAMETERS                       item_store_org

                , MSC_RESOURCE_REQUIREMENTSRC_V              orders
				, MSC_ANALYTIC_FACT_ORD_V                    ori_orders_h
				, MSC_ANALYTIC_PRIVATE_PLAN_V                mrp_name

				, MSC_AP_CATALOG_CATEGORIES_V                item_cate_name

                WHERE
                                    mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
                        AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
                        AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID
                        AND item_info.INVENTORY_ITEM_ID = itemEffB.INVENTORY_ITEM_ID(+)
                        and item_info.ORGANIZATION_ID   = itemEffB.ORGANIZATION_ID(+)
                        and 'ASWI_GZ_FG_SALES' = itemEffB.CONTEXT_CODE(+)

                        -- 关联物料与类别
                        AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
                        AND item_cat.ORGANIZATION_ID =   item_info.ORGANIZATION_ID
                        AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))

                        AND item_cat.CATEGORY_ID = item_cate_name.CATEGORY_ID

                        --取Order
                        AND orders.ASSEMBLY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
                        AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID

                        --取时间
                        And ori_orders_h.ORDER_ID = orders.SUPPLY_ID
                        and orders.resource_id = :P_RESOURCE_ID
                        and to_char(ori_orders_h.SUGGESTED_DUE_DATE, 'YYYY-MM-DD') =to_char(:P_DATE, 'YYYY-MM-DD')

                        --取计划
                        AND mrp_name.COMPILE_DESIGNATOR  = :P_MRP_NAME
                        and mrp_name.PLAN_ID = orders.PLAN_ID

                --修改后取数正确
        ),


        real_tab1
        --汇总当周数据
        AS
        (
                select days_mid.INVENTORY_ITEM_ID
                       , days_mid.DESCRIPTION                                 
                       , days_mid.ITEM_ORG
                       , days_mid.MRP_ITEM_ID
                       , days_mid.MRP_ITEM_ORG
                       , days_mid.ITEM_NUMBER
                       , days_mid.UOM
                       , days_mid.RESOURCE_ID
                --        , days_mid.ATTRIBUTE6                                      ATTRIBUTE6
                --        , days_mid.ATTRIBUTE7                                      ATTRIBUTE7
                --        , days_mid.ATTRIBUTE_NUMBER1                               ATTRIBUTE_NUMBER1
                --        , days_mid.ATTRIBUTE2                                      ATTRIBUTE2
                        , days_mid.ATTRIBUTE_NUMBER2                                 ATTRIBUTE_NUMBER2
                        , days_mid.ATTRIBUTE5                                        ATTRIBUTE5
                        , days_mid.PRODUCT_CODE                                      PRODUCT_CODE

                       , days_mid.USAGE_RATE               USAGE_RATE
                       , days_mid.USAGE_RATE1              USAGE_RATE1
                       , days_mid.USAGE_RATE2              USAGE_RATE2
                       , days_mid.USAGE_RATE3              USAGE_RATE3

                       , days_mid.ONE_RESOURCE_HOURS               SUM_ONE_HOURS
                       , sum(days_mid.TWO_RESOURCE_HOURS )                 SUM_TWO_HOURS
                       , sum(  days_mid.THREE_RESOURCE_HOURS            )           SUM_THREE_HOURS
                       , sum(  days_mid.FOUR_RESOURCE_HOURS             )           SUM_FOUR_HOURS
					   
                       , days_mid.ONE_CUMMULATIVE_QUANTITY           SUM_ONE_CUMMULATIVE_QUANTITY
                       , sum(days_mid.TWO_CUMMULATIVE_QUANTITY)        sSUM_TWO_CUMMULATIVE_QUANTITY
                       , sum(    days_mid.THREE_CUMMULATIVE_QUANTITY      )         SUM_THREE_CUMMULATIVE_QUANTITY
                       , sum(    days_mid.FOUR_CUMMULATIVE_QUANTITY       )         SUM_FOUR_CUMMULATIVE_QUANTITY


                FROM days_mid

                GROUP BY
                        days_mid.INVENTORY_ITEM_ID
                       ,days_mid.DESCRIPTION 
                       ,days_mid.ITEM_ORG
                       ,days_mid.MRP_ITEM_ID
                       ,days_mid.MRP_ITEM_ORG
                       ,days_mid.ITEM_NUMBER
                       ,days_mid.UOM
                       ,days_mid.RESOURCE_ID
                 , days_mid.ATTRIBUTE_NUMBER2
                , days_mid.ATTRIBUTE5       
                , days_mid.PRODUCT_CODE  
				, days_mid.USAGE_RATE               
                       , days_mid.USAGE_RATE1             
                       , days_mid.USAGE_RATE2            
                       , days_mid.USAGE_RATE3 
					   , days_mid.ONE_RESOURCE_HOURS
					   , days_mid.ONE_CUMMULATIVE_QUANTITY
        ),

        mid_tab
        --创建中间表
        AS
        (
                SELECT
                        real_tab1.*
                FROM real_tab1


        ),

        cat_tab
        --物料筛选
        as
        (
                SELECT
                        mid_tab.*
       , work_hours.ATTRIBUTE_NUMBER1  AS HOURS_NUM 
	   , re_id_parent.NAME 

       , (SUM(mid_tab.SUM_ONE_HOURS)      over( order by  mid_tab.RESOURCE_ID, mid_tab.ATTRIBUTE_NUMBER2, mid_tab.PRODUCT_CODE, mid_tab.ATTRIBUTE5,mid_tab.INVENTORY_ITEM_ID ) ) -  mid_tab.SUM_ONE_HOURS  ONE_RUNNING

                FROM mid_tab
	     , MSC_DIM_RESOURCE_V         re_id_parent
         , WIS_WORK_CENTERS_VL        work_hours
                where
        re_id_parent.id =   mid_tab.RESOURCE_ID
                        AND re_id_parent.PARENT_ID =  work_hours.WORK_CENTER_ID
        )

--最后输出
SELECT
        cat_tab.*
        , CASE      WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 0 AND 0 = :P_DAYS-1 ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 0 AND 0 < :P_DAYS-1 )
                     THEN  cat_tab.SUM_ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_ONE
          , CASE      WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 1 AND 1 = :P_DAYS-1 ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 1 AND 1 < :P_DAYS-1 )
--
                     THEN  cat_tab.SUM_ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_TWO
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 2 AND 2 = :P_DAYS-1 ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 2 AND 2 < :P_DAYS-1 )
--
                     THEN  cat_tab.SUM_ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_THREE
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 3 AND 3 = :P_DAYS-1 ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 3 AND 3 < :P_DAYS-1 )
--
                     THEN  cat_tab.SUM_ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_FOUR
                   , CASE      WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 4 AND 4 = :P_DAYS-1 ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 4 AND 4 < :P_DAYS-1 )
--
                     THEN  cat_tab.SUM_ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_FIVE
                   , CASE       WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 5 AND 5 = :P_DAYS-1 ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 5 AND 5 < :P_DAYS-1 )
--
                     THEN  cat_tab.SUM_ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_SIX
                   , CASE     WHEN ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)  > = 6 AND 6 = :P_DAYS-1 ) OR
                ( FLOOR(NVL(cat_tab.ONE_RUNNING,0) / cat_tab.HOURS_NUM)    = 6 AND 6 < :P_DAYS-1 )
--
                     THEN  cat_tab.SUM_ONE_CUMMULATIVE_QUANTITY
                     ELSE  null
           END  AS ONE_SEVEN

FROM cat_tab
order  by cat_tab.RESOURCE_ID, cat_tab.ONE_RUNNING




----------------------------------------------------------------------------------

SELECT
        item_info.INVENTORY_ITEM_ID                                INVENTORY_ITEM_ID
        , item_info.DESCRIPTION                                      DESCRIPTION 
        , item_info.ORGANIZATION_ID                                  ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                 MRP_ITEM_ID
        , mrp_item.ORGANIZATION_ID                                   MRP_ITEM_ORG
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM

        -- , item_info.ATTRIBUTE6                                          ATTRIBUTE6 --这里取口味
        -- , item_info.ATTRIBUTE7                                          ATTRIBUTE7 --规格
        -- , item_info.ATTRIBUTE_NUMBER1                                   ATTRIBUTE_NUMBER1 --自定义
        -- , item_info.ATTRIBUTE2                                          ATTRIBUTE2 --外包装

        , item_info.ATTRIBUTE_NUMBER2                                   ATTRIBUTE_NUMBER2
        , item_info.ATTRIBUTE5                                          ATTRIBUTE5
        , itemEffB.ATTRIBUTE_CHAR6                                      PRODUCT_CODE

FROM


        EGP_SYSTEM_ITEMS_V                           item_info
                , (select *
        from MSC_SYSTEM_ITEMS_V
        where PLAN_ID = -1  )                     mrp_item
                , MSC_AP_ITEM_CATEGORIES_V                   item_cat
                , EGO_ITEM_EFF_B                             itemEffB
                , INV_ORG_PARAMETERS                       item_store_org


WHERE
                                mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
        AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
        AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID
        AND item_info.INVENTORY_ITEM_ID = itemEffB.INVENTORY_ITEM_ID(+)

---    second part   order schedule order  onhand------------
SELECT
        item_info.INVENTORY_ITEM_ID                                INVENTORY_ITEM_ID
        , item_info.DESCRIPTION                                      DESCRIPTION 
        , item_info.ORGANIZATION_ID                                  ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                 MRP_ITEM_ID
        , mrp_item.ORGANIZATION_ID                                   MRP_ITEM_ORG
        , item_info.ITEM_NUMBER                                      ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                 UOM
        , item_cate_name.CATEGORY_NAME                               CATEGORY_NAME

        , orders.ORDER_QUANTITY                                      onhand_qty
                        


FROM
        EGP_SYSTEM_ITEMS_V                            item_info          -- system item table
                , (select *
        from MSC_SYSTEM_ITEMS_V
        where PLAN_ID = -1  )                        mrp_item          -- mrp module item table
                , MSC_AP_ITEM_CATEGORIES_V                      item_cat          -- item categories 
                -- , EGO_ITEM_EFF_B                                itemEffB
		, INV_ORG_PARAMETERS                            item_store_org    -- item org

                , MSC_ANALYTIC_FACT_ORD_V                       orders           --  mrp  original  orders  (not  manufacture)

		, MSC_AP_CATALOG_CATEGORIES_V                   item_cate_name

WHERE 
        mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
        AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
        AND item_info.ORGANIZATION_ID    =  item_store_org.ORGANIZATION_ID

        -- 关联物料与类别
        AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
        AND item_cat.ORGANIZATION_ID   =   item_info.ORGANIZATION_ID
        AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))

        --取Order
        AND orders.INVENTORY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
        AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID

        --- get item category name
        AND item_cat.CATEGORY_ID = item_cate_name.CATEGORY_ID
        -- order type = onhand  
        AND orders.ORDER_TYPE  = 18
        --  fileter  schedule name 
        -- AND orders.SCHEDULE_NAME  = :P_SCHEDULE_NAME  

        AND orders.PLAN_ID    = -1 ---- hard codding
---    second part   order schedule order  forcast two  months------------
SELECT
        item_info.INVENTORY_ITEM_ID                                INVENTORY_ITEM_ID
        , item_info.DESCRIPTION                                      DESCRIPTION 
        , item_info.ORGANIZATION_ID                                  ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                 MRP_ITEM_ID
        , mrp_item.ORGANIZATION_ID                                   MRP_ITEM_ORG
        , item_info.ITEM_NUMBER                                      ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                 UOM
        , item_cate_name.CATEGORY_NAME                               CATEGORY_NAME

                      
               , CASE WHEN  orders.SUGGESTED_DUE_DATE BETWEEN  trunc(sysdate, 'mm')  AND  LAST_DAY(TRUNC(SYSDATE))+1-1/86400 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0                                           
                END    as   forcast_one_qty             ---- this is  forcast_qty this month 
                        , 
                CASE WHEN  orders.SUGGESTED_DUE_DATE BETWEEN  trunc(ADD_MONTHS(SYSDATE, 1), 'mm')  AND   LAST_DAY(TRUNC(ADD_MONTHS(SYSDATE,1)))+1-1/86400 
                     THEN  orders.ORDER_QUANTITY
                     ELSE  0
                END   as   forcast_two_qty              --- this is  forcast_qty nest month 

FROM
        EGP_SYSTEM_ITEMS_V                            item_info          -- system item table
                , (select *
        from MSC_SYSTEM_ITEMS_V
        where PLAN_ID = -1  )                        mrp_item          -- mrp module item table
                , MSC_AP_ITEM_CATEGORIES_V                      item_cat          -- item categories 
                -- , EGO_ITEM_EFF_B                                itemEffB
		, INV_ORG_PARAMETERS                            item_store_org    -- item org

                , MSC_ANALYTIC_FACT_ORD_V                       orders           --  mrp  original  orders  (not  manufacture)

		, MSC_AP_CATALOG_CATEGORIES_V                   item_cate_name

WHERE 
        mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
        AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
        AND item_info.ORGANIZATION_ID    =  item_store_org.ORGANIZATION_ID

        -- 关联物料与类别
        AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
        AND item_cat.ORGANIZATION_ID   =   item_info.ORGANIZATION_ID
        AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))

        --取Order
        AND orders.INVENTORY_ITEM_ID =  mrp_item.INVENTORY_ITEM_ID
        AND orders.ORGANIZATION_ID   =  mrp_item.ORGANIZATION_ID

        --- get item category name
        AND item_cat.CATEGORY_ID = item_cate_name.CATEGORY_ID
        -- order type = onhand  
        AND orders.ORDER_TYPE  = 1029
        --  fileter  schedule name 
        -- AND orders.SCHEDULE_NAME  = :P_SCHEDULE_NAME  

        AND orders.PLAN_ID    = -1 ---- hard codding
