300000003655571
AR_RECEIVABLE_APPLICATIONS_ALL


SELECT party_info.PARTY_NAME , party_info.PARTY_ID
FROM
     HZ_CUST_ACCOUNTS                       pty_act,
     HZ_PARTIES                             party_info
where  party_info.PARTY_ID = pty_act.PARTY_ID


trx  300000003668424 
     300000003655560
-- AND pty_act.PARTY_ID = :PARTY_ID

     300000003924782  trx——id
     300000003875510  18011


     CUSTOMER_TRX_ID
(300000003668702) 14000
24006  300000003903584
                    
                      300000003668758  11011





     cash re  300000003668912   	 test202007280002 
     cash re  300000003668901       TEST202007280001
     300000003884970      TEST0804001  300000003918335
                          TEST0804001
                          TEST0804001


     300000003668474  party_id

with
     work_info_tab
     as
     (

          SELECT
               V378971821.ORGANIZATION_CODE 
, V196696337.ITEM_NUMBER 
, V465050919.PLANNED_COMPLETION_DATE 
, V465050919.WORK_ORDER_NUMBER 
, V196696337.INVENTORY_ITEM_ID 
, V317794909.OP_IN_PROCESS_QUANTITY 
, V317794909.OP_COMPLETED_QUANTITY 
, V317794909.WO_OPERATION_ID 
, V378971821.ORGANIZATION_ID 
, V465050919.WORK_ORDER_ID
          FROM (SELECT WOOperationAnalyticsPEO.WO_OPERATION_ID, WOOperationAnalyticsPEO.COMPLETED_QUANTITY AS OP_COMPLETED_QUANTITY, WOOperationAnalyticsPEO.WORK_ORDER_ID AS OP_WORK_ORDER_ID, WOOperationAnalyticsPEO.IN_PROCESS_QUANTITY AS OP_IN_PROCESS_QUANTITY, WorkOrderAnalyticsPEO.INVENTORY_ITEM_ID AS WO_INVENTORY_ITEM_ID, WorkOrderAnalyticsPEO.ORGANIZATION_ID AS WO_ORGANIZATION_ID
               FROM WIE_WO_OPERATIONS_B WOOperationAnalyticsPEO, WIE_WORK_ORDERS_B WorkOrderAnalyticsPEO, WIS_WORK_METHODS_VL WorkMethodPEO
               WHERE (WOOperationAnalyticsPEO.WORK_ORDER_ID = WorkOrderAnalyticsPEO.WORK_ORDER_ID AND WorkOrderAnalyticsPEO.WORK_METHOD_ID = WorkMethodPEO.WORK_METHOD_ID) AND ( ( ( (WorkMethodPEO.WORK_METHOD_CODE <> 'MAINTENANCE' ) ) ) AND ((1=1)) )) V317794909, (SELECT ItemBasePEO.INVENTORY_ITEM_ID, ItemBasePEO.ITEM_NUMBER, ItemBasePEO.ORGANIZATION_ID AS ORGANIZATION_ID1596
               FROM EGP_SYSTEM_ITEMS_B_V ItemBasePEO
               WHERE  ( (ItemBasePEO.TEMPLATE_ITEM_FLAG <> 'Y' ) ) ) V196696337, (SELECT OrganizationParameterPEO.ORGANIZATION_CODE, OrganizationParameterPEO.ORGANIZATION_ID
               FROM INV_ORG_PARAMETERS OrganizationParameterPEO) V378971821,
               (SELECT WorkOrderAnalyticsPEO.PLANNED_COMPLETION_DATE, WorkOrderAnalyticsPEO.WORK_ORDER_ID, WorkOrderAnalyticsPEO.WORK_ORDER_NUMBER
               FROM WIE_WORK_ORDERS_B WorkOrderAnalyticsPEO ) V465050919
          WHERE V317794909.WO_INVENTORY_ITEM_ID = V196696337.INVENTORY_ITEM_ID(+) AND V317794909.WO_ORGANIZATION_ID = V196696337.ORGANIZATION_ID1596(+) AND V317794909.WO_ORGANIZATION_ID = V378971821.ORGANIZATION_ID(+) AND V317794909.OP_WORK_ORDER_ID = V465050919.WORK_ORDER_ID(+)
     )
SELECT
            work_info_tab.ORGANIZATION_CODE 
          , work_info_tab.ITEM_NUMBER 
          -- , work_info_tab.PLANNED_COMPLETION_DATE 
          -- , work_info_tab.WORK_ORDER_NUMBER 
          , work_info_tab.INVENTORY_ITEM_ID 
          -- , work_info_tab.WO_OPERATION_ID 
          , work_info_tab.ORGANIZATION_ID 
          -- , work_info_tab.WORK_ORDER_ID

           ,SUM( CASE WHEN  work_info_tab.PLANNED_COMPLETION_DATE  BETWEEN  trunc(sysdate, 'mm')  AND   sysdate
                     THEN  work_info_tab.OP_IN_PROCESS_QUANTITY 
                     ELSE  0
                END  ) as   process_one_qty             ----   IN_PROCESS_QUANTITY   this   month 

           ,SUM( CASE WHEN  work_info_tab.PLANNED_COMPLETION_DATE  BETWEEN  trunc(ADD_MONTHS(SYSDATE, 1), 'mm')  AND  
            trunc( LAST_DAY(ADD_MONTHS(SYSDATE, 1)) + 1 ,'dd' ) 
                     THEN  work_info_tab.OP_IN_PROCESS_QUANTITY 
                     ELSE  0
                END  )  as   process_two_qty             ----   IN_PROCESS_QUANTITY   next   month 
           ,SUM( CASE WHEN  work_info_tab.PLANNED_COMPLETION_DATE  BETWEEN  trunc(sysdate, 'mm')  AND   sysdate
                     THEN  work_info_tab.OP_COMPLETED_QUANTITY 
                     ELSE  0
                END )   as   completed_one_qty             ----   COMPLETED_QUANTITY   this   month 

           ,SUM( CASE WHEN  work_info_tab.PLANNED_COMPLETION_DATE  BETWEEN  trunc(ADD_MONTHS(SYSDATE, 1), 'mm')  AND  
            trunc( LAST_DAY(ADD_MONTHS(SYSDATE, 1)) + 1 ,'dd' ) 
                     THEN  work_info_tab.OP_COMPLETED_QUANTITY 
                     ELSE  0
                END  )  as   completed_two_qty             ----   COMPLETED_QUANTITY   next   month 



FROM work_info_tab
WHERE work_info_tab.PLANNED_COMPLETION_DATE  BETWEEN  trunc(sysdate, 'mm')  AND  trunc( LAST_DAY(ADD_MONTHS(SYSDATE, 1)) + 1 ,'dd' ) 
GROUP BY  
            work_info_tab.ORGANIZATION_CODE 
          , work_info_tab.ITEM_NUMBER 
          -- , work_info_tab.PLANNED_COMPLETION_DATE 
          -- , work_info_tab.WORK_ORDER_NUMBER 
          , work_info_tab.INVENTORY_ITEM_ID 
          -- , work_info_tab.WO_OPERATION_ID 
          , work_info_tab.ORGANIZATION_ID 
          -- , work_info_tab.WORK_ORDER_ID

--order by work_info_tab.PLANNED_COMPLETION_DATE desc






