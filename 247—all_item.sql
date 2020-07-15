-----------------------all--------item----
-- MSC_ASSIGNMENT_SETS  ,
SELECT
         item_info.INVENTORY_ITEM_ID
       , item_info.ITEM_NUMBER
       , item_info.ORGANIZATION_ID
       , percent_tab.SOURCE_PARTNER_ID                                   supplier
       , percent_tab.SOURCE_PARTNER_SITE_ID                              supplier_site
       , percent_tab.ALLOCATION_PERCENT                                  alc_percent
       ,mrp_item.ITEM_NAME


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


-- 300000004689459 = plan_id
-- ASSIGNMENT_SET_ID = '300000001867925'



