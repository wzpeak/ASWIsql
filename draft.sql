

SELECT distinct 
                                itemEffB.ATTRIBUTE_CHAR6 productCode
                  FROM EGP_SYSTEM_ITEMS_B_V  ItemBase,
                       EGP_SYSTEM_ITEMS_TL_V ItemTranslation,
                       EGO_ITEM_EFF_B        itemEffB
                 WHERE ItemBase.INVENTORY_ITEM_ID =
                       ItemTranslation.INVENTORY_ITEM_ID
                   AND ItemBase.ORGANIZATION_ID =
                       ItemTranslation.ORGANIZATION_ID
                   AND ItemTranslation.LANGUAGE = 'ZHS' /*USERENV('LANG')*/
                   and ItemBase.INVENTORY_ITEM_ID =
                       itemEffB.INVENTORY_ITEM_ID(+)
                   and 'ASWI_GZ_FG_SALES' = itemEffB.CONTEXT_CODE(+)


SELECT    itemEffB.ATTRIBUTE_CHAR6 productCode ,item_info.INVENTORY_ITEM_ID,item_info.ORGANIZATION_ID 
 FROM                  EGP_SYSTEM_ITEMS_V  item_info,
                       EGO_ITEM_EFF_B        itemEffB
WHERE     item_info.INVENTORY_ITEM_ID = itemEffB.INVENTORY_ITEM_ID(+)
      and item_info.ORGANIZATION_ID   = itemEffB.ORGANIZATION_ID(+)
      and 'ASWI_GZ_FG_SALES' = itemEffB.CONTEXT_CODE(+)


SELECT distinct 
                                itemEffB.Attribute_Char1 productCode
                  FROM EGP_SYSTEM_ITEMS_B_V  ItemBase,
                       EGP_SYSTEM_ITEMS_TL_V ItemTranslation,
                       EGO_ITEM_EFF_B        itemEffB
                 WHERE ItemBase.INVENTORY_ITEM_ID =
                       ItemTranslation.INVENTORY_ITEM_ID
                   AND ItemBase.ORGANIZATION_ID =
                       ItemTranslation.ORGANIZATION_ID
                   AND ItemTranslation.LANGUAGE = 'ZHS' /*USERENV('LANG')*/
                   and ItemBase.INVENTORY_ITEM_ID =
                       itemEffB.INVENTORY_ITEM_ID(+)
                   and 'ASWI_GZ_FG' = itemEffB.CONTEXT_CODE(+)




                   <?if:position() < last()?>