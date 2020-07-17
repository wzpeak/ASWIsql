
SELECT
FROM
       MSC_DIM_RESOURCE_V         re_id_parent
      ,WIS_WORK_CENTERS_VL        work_hours

WHERE
        re_id_parent.id =   resource_id
    AND re_id_parent.PARENT_ID =  work_hours.WORK_CENTER_ID





ATTRIBUTE_NUMBER1


-- select  parent_id ,id ,
--        sum(ID )  over( partition by parent_id  order by  ID  )
-- from   MSC_DIM_RESOURCE_V