SELECT
  item_info.INVENTORY_ITEM_ID                                INVENTORY_ITEM_ID
        , item_info.DESCRIPTION                                      DESCRIPTION 
        , item_info.ORGANIZATION_ID                                  ITEM_ORG
        , mrp_item.INVENTORY_ITEM_ID                                 MRP_ITEM_ID
        , mrp_item.ORGANIZATION_ID                                   MRP_ITEM_ORG
        , item_info.ITEM_NUMBER                                         ITEM_NUMBER
        , item_info.PRIMARY_UOM_CODE                                    UOM
          , item_cate_name.CATEGORY_NAME                               CATEGORY_NAME

-- , item_info.ATTRIBUTE6                                          ATTRIBUTE6 --这里取口味
-- , item_info.ATTRIBUTE7                                          ATTRIBUTE7 --规格
-- , item_info.ATTRIBUTE_NUMBER1                                   ATTRIBUTE_NUMBER1 --自定义
-- , item_info.ATTRIBUTE2                                          ATTRIBUTE2 --外包装


FROM


  EGP_SYSTEM_ITEMS_V                           item_info
                , (select *
  from MSC_SYSTEM_ITEMS_V
  where PLAN_ID = -1  )                     mrp_item
                , MSC_AP_ITEM_CATEGORIES_V                   item_cat
                -- , EGO_ITEM_EFF_B                             itemEffB
				, INV_ORG_PARAMETERS                       item_store_org
        , MSC_AP_CATALOG_CATEGORIES_V                   item_cate_name


WHERE
                                mrp_item.ITEM_NAME           =  item_info.ITEM_NUMBER
  AND mrp_item.ORGANIZATION_CODE   =  item_store_org.ORGANIZATION_CODE
  AND item_info.ORGANIZATION_ID   =  item_store_org.ORGANIZATION_ID
  -- AND item_info.INVENTORY_ITEM_ID = itemEffB.INVENTORY_ITEM_ID(+)
  -- and item_info.ORGANIZATION_ID   = itemEffB.ORGANIZATION_ID(+)
  -- and 'ASWI_GZ_FG_SALES' = itemEffB.CONTEXT_CODE(+)



  --- get item category name
  AND item_cat.CATEGORY_ID = item_cate_name.CATEGORY_ID


  -- 关联物料与类别
  AND item_cat.INVENTORY_ITEM_ID =   item_info.INVENTORY_ITEM_ID
  AND item_cat.ORGANIZATION_ID   =   item_info.ORGANIZATION_ID
  AND (item_cat.CATEGORY_ID  IN (:P_ITEM_CATE) OR 'val' IN (:P_ITEM_CATE || 'val'))

--没问题，已经去重

-- Mast_item.item_code
-- Mast_item.item_org




-- select DISTINCT PAPER_DOCUMENT_NUMBER
-- from IBY_PAYMENTS_ALL
-- where   IBY_PAYMENTS_ALL .PAPER_DOCUMENT_NUMBER is  not null


LEGAL_ENTITY_ID (300000001629074)
--  find  entity  address

select REGISTERED_NAME, REGISTRATION_NUMBER,
  ADDRESS1, ADDRESS2, ADDRESS3, ADDRESS4,
  CITY, STATE, PROVINCE, COUNTY, ADDRESS_STYLE,
  ADDRESS_LINES_PHONETIC, COUNTRY, POSTAL_CODE
from xle_registrations a1,
  xle_entity_profiles a2,
  HZ_LOCATIONS A3
where 1=1
  and a2.legal_entity_id=a1.source_id
  and source_table='XLE_ENTITY_PROFILES'
  and a1.location_id=a3.location_id

  and a2.LEGAL_ENTITY_ID = 300000001629074



  select  *  from  XLE_ENTITY_PROFILES   where   LEGAL_ENTITY_ID = 300000001629074