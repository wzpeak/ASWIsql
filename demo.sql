-- ('I')
WITH

temp_tabl  AS(
    SELECT
        --     gcc.segment1         company_code
        --    ,flv_1.DESCRIPTION         company_desc
        gcc.segment2         portfolio_code             --        1
   , flv_2.DESCRIPTION         portfolio_desc
   , gcc.segment3         business_seg               --        1
   , flv_3.DESCRIPTION         business_seg_desc
   , gcc.segment4         account_code                  --    1
   , flv_4.DESCRIPTION         account_desc
   , gcc.segment5         poj_code                    --       1
   , flv_5.DESCRIPTION         poj_desc
   , gcc.segment6         prt_code                 --           1
   , flv_6.DESCRIPTION         prt_desc
   , gcc.segment7        dept_code               --        1
   , flv_7.DESCRIPTION         dept_desc
   , gcc.segment8         inc_code            ---            1
   , flv_8.DESCRIPTION         inc_desc
   , gb.CURRENCY_CODE          account_cu_code
   , SUM(gb.BEGIN_BALANCE_DR_BEQ - gb.BEGIN_BALANCE_CR_BEQ )  beg_balance

   , 0    debit
   , 0    credit
   , 0    ent_debit
   , 0    ent_credit
   , 0    ent_beg
   , 0    act_unpost
--    , entity.name               lg_entity_name
--    , gb.PERIOD_NAME           account_period
--    , gjl.CURRENCY_CODE         enter_cu_code             ---    1
--    ,gcc.ACCOUNT_TYPE          account_type



    FROM
        gl_code_combinations            gcc,
        -- GL_PERIODS                      gp,
        gl_balances                     gb,
        -- fnd_flex_values_vl              flv_1,
        -- fnd_flex_value_sets             fls_1,
        fnd_flex_values_vl              flv_2,
        fnd_flex_value_sets             fls_2,
        fnd_flex_values_vl              flv_3,
        fnd_flex_value_sets             fls_3,
        fnd_flex_values_vl              flv_4,
        fnd_flex_value_sets             fls_4,
        fnd_flex_values_vl              flv_5,
        fnd_flex_value_sets             fls_5,
        fnd_flex_values_vl              flv_6,
        fnd_flex_value_sets             fls_6,
        fnd_flex_values_vl              flv_7,
        fnd_flex_value_sets             fls_7,
        fnd_flex_values_vl              flv_8,
        fnd_flex_value_sets             fls_8
    -- fnd_flex_values_vl              flv_9,
    -- fnd_flex_value_sets             fls_9,
    -- fnd_flex_values_vl              flv_10,
    -- fnd_flex_value_sets             fls_10

    WHERE

    gb.code_combination_id = gcc.code_combination_id
        -- and (flv_1.flex_value_set_id = fls_1.flex_value_set_id and gcc.segment1 = flv_1.flex_value and  fls_1.flex_value_set_name = 'Company WL_LEDGER' )
        and (flv_2.flex_value_set_id = fls_2.flex_value_set_id and gcc.segment2 = flv_2.flex_value and fls_2.flex_value_set_name = 'Portfolio WL_LEDGER' )
        and (flv_3.flex_value_set_id = fls_3.flex_value_set_id and gcc.segment3 = flv_3.flex_value and fls_3.flex_value_set_name = 'Business Segment WL_LEDGER' )
        and (flv_4.flex_value_set_id = fls_4.flex_value_set_id and gcc.segment4 = flv_4.flex_value and fls_4.flex_value_set_name = 'Account WL_LEDGER' )
        and (flv_5.flex_value_set_id = fls_5.flex_value_set_id and gcc.segment5 = flv_5.flex_value and fls_5.flex_value_set_name = 'Project WL_LEDGER' )
        and (flv_6.flex_value_set_id = fls_6.flex_value_set_id and gcc.segment6 = flv_6.flex_value and fls_6.flex_value_set_name = 'Property Type WL_LEDGER' )
        and (flv_7.flex_value_set_id = fls_7.flex_value_set_id and gcc.segment7 = flv_7.flex_value and fls_7.flex_value_set_name = 'Department WL_LEDGER' )
        and (flv_8.flex_value_set_id = fls_8.flex_value_set_id and gcc.segment8 = flv_8.flex_value and fls_8.flex_value_set_name = 'Intercompany WL_LEDGER' )


        and gcc.segment1   = :P_COMPANY_CODE

        -- and gb.PERIOD_NAME = :P_PERIOD
        -- and gb.PERIOD_NAME = 'Jan-2020'
        -- and gb.CURRENCY_CODE = 'HKD'
        and (gb.PERIOD_YEAR = (Select to_number(to_char(:P_DATE,'yyyy'))
        from dual ) and gb.PERIOD_NUM = 1)



        and gb.LEDGER_ID = :P_LEDGER

    GROUP BY
            -- gcc.segment1
            -- ,flv_1.DESCRIPTION
            -- ,gjl.JE_HEADER_ID
            gcc.segment2
            ,flv_2.DESCRIPTION
            ,gcc.segment3
            ,flv_3.DESCRIPTION
            ,gcc.segment4
            ,flv_4.DESCRIPTION
            ,gcc.segment5
            ,flv_5.DESCRIPTION
            ,gcc.segment6
            ,flv_6.DESCRIPTION
            ,gcc.segment7
            ,flv_7.DESCRIPTION
            ,gcc.segment8
            ,flv_8.DESCRIPTION
            ,gb.CURRENCY_CODE


UNION ALL

    SELECT
        -- gb.LEDGER_ID,
        gcc.segment2         portfolio_code             --        1
   , flv_2.DESCRIPTION         portfolio_desc
   , gcc.segment3         business_seg               --        1
   , flv_3.DESCRIPTION         business_seg_desc
   , gcc.segment4         account_code                  --    1
   , flv_4.DESCRIPTION         account_desc
   , gcc.segment5         poj_code                    --       1
   , flv_5.DESCRIPTION         poj_desc
   , gcc.segment6         prt_code                 --           1
   , flv_6.DESCRIPTION         prt_desc
   , gcc.segment7        dept_code               --        1
   , flv_7.DESCRIPTION         dept_desc
   , gcc.segment8         inc_code            ---            1
   , flv_8.DESCRIPTION         inc_desc
   , gjl.CURRENCY_CODE         account_cu_code
-- , (gb.BEGIN_BALANCE_DR_BEQ - BEGIN_BALANCE_CR_BEQ )  beg_balance
-- , gb.PERIOD_NET_DR                       debits
-- , gb.PERIOD_NET_CR                        credits
-- , gb.BEGIN_BALANCE_DR_BEQ+gb.PERIOD_NET_DR-gb.BEGIN_BALANCE_CR_BEQ-gb.PERIOD_NET_CR  end_balance

, 0    beg_balance
, SUM( nvl(gjl.ACCOUNTED_DR, 0))  debit
, SUM( nvl(gjl.ACCOUNTED_CR, 0))  credit

   , 0    ent_debit
   , 0    ent_credit
   , 0    ent_beg

  , sum(
    case
                when gjl.STATUS = 'U'
                    then  nvl(gjl.ACCOUNTED_DR,0) - nvl(gjl.ACCOUNTED_CR,0  )
                else  0
    end

   )    as  act_unpost

    FROM
        gl_je_lines                     gjl,
        gl_je_headers                   gjh,
        -- gl_ledgers                      gl,
        gl_code_combinations            gcc,
        -- GL_PERIODS                      gp,
        -- gl_balances                     gb,

        fnd_flex_values_vl              flv_2,
        fnd_flex_value_sets             fls_2,
        fnd_flex_values_vl              flv_3,
        fnd_flex_value_sets             fls_3,
        fnd_flex_values_vl              flv_4,
        fnd_flex_value_sets             fls_4,
        fnd_flex_values_vl              flv_5,
        fnd_flex_value_sets             fls_5,
        fnd_flex_values_vl              flv_6,
        fnd_flex_value_sets             fls_6,
        fnd_flex_values_vl              flv_7,
        fnd_flex_value_sets             fls_7,
        fnd_flex_values_vl              flv_8,
        fnd_flex_value_sets             fls_8

        ,GL_JE_BATCHES                   gl_batch
    WHERE
        -- gl.ledger_id = gb.ledger_id
          gjh.je_header_id = gjl.je_header_id
        --   update 20200706---- add   batches  status---
        and gl_batch.JE_BATCH_ID = gjh.JE_BATCH_ID

        and gjl.code_combination_id = gcc.code_combination_id
        and (flv_2.flex_value_set_id = fls_2.flex_value_set_id and gcc.segment2 = flv_2.flex_value and fls_2.flex_value_set_name = 'Portfolio WL_LEDGER' )
        and (flv_3.flex_value_set_id = fls_3.flex_value_set_id and gcc.segment3 = flv_3.flex_value and fls_3.flex_value_set_name = 'Business Segment WL_LEDGER' )
        and (flv_4.flex_value_set_id = fls_4.flex_value_set_id and gcc.segment4 = flv_4.flex_value and fls_4.flex_value_set_name = 'Account WL_LEDGER' )
        and (flv_5.flex_value_set_id = fls_5.flex_value_set_id and gcc.segment5 = flv_5.flex_value and fls_5.flex_value_set_name = 'Project WL_LEDGER' )
        and (flv_6.flex_value_set_id = fls_6.flex_value_set_id and gcc.segment6 = flv_6.flex_value and fls_6.flex_value_set_name = 'Property Type WL_LEDGER' )
        and (flv_7.flex_value_set_id = fls_7.flex_value_set_id and gcc.segment7 = flv_7.flex_value and fls_7.flex_value_set_name = 'Department WL_LEDGER' )
        and (flv_8.flex_value_set_id = fls_8.flex_value_set_id and gcc.segment8 = flv_8.flex_value and fls_8.flex_value_set_name = 'Intercompany WL_LEDGER' )
        and gcc.segment1   = :P_COMPANY_CODE
        and gjl.STATUS IN ('U','P')
        -- and gjl.CURRENCY_CODE = 'HKD'
        and (gjl.EFFECTIVE_DATE   BETWEEN  (select distinct YEAR_START_DATE
        from gl_periods
        where :P_DATE   BETWEEN  START_DATE and   END_DATE and PERIOD_SET_NAME = 'WL_LEDGER' and ADJUSTMENT_PERIOD_FLAG = 'N')  AND :P_DATE)

        and gjl.LEDGER_ID = :P_LEDGER
-- update  20200607   add  batches  status  fileter  approve status  in 3  status
        and gl_batch.APPROVAL_STATUS_CODE IN ('Z','I','A')
        -- exclude   error  and  incompleted
        and gl_batch.STATUS  IN ('p','P','U','S','I')

    GROUP BY
   gjl.LEDGER_ID,
            gcc.segment2
            ,flv_2.DESCRIPTION
            ,gcc.segment3
            ,flv_3.DESCRIPTION
            ,gcc.segment4
            ,flv_4.DESCRIPTION
            ,gcc.segment5
            ,flv_5.DESCRIPTION
            ,gcc.segment6
            ,flv_6.DESCRIPTION
            ,gcc.segment7
            ,flv_7.DESCRIPTION
            ,gcc.segment8
            ,flv_8.DESCRIPTION
            , gjl.CURRENCY_CODE

UNION ALL

    SELECT
        -- gb.LEDGER_ID,
        gcc.segment2         portfolio_code             --        1
   , flv_2.DESCRIPTION         portfolio_desc
   , gcc.segment3         business_seg               --        1
   , flv_3.DESCRIPTION         business_seg_desc
   , gcc.segment4         account_code                  --    1
   , flv_4.DESCRIPTION         account_desc
   , gcc.segment5         poj_code                    --       1
   , flv_5.DESCRIPTION         poj_desc
   , gcc.segment6         prt_code                 --           1
   , flv_6.DESCRIPTION         prt_desc
   , gcc.segment7        dept_code               --        1
   , flv_7.DESCRIPTION         dept_desc
   , gcc.segment8         inc_code            ---            1
   , flv_8.DESCRIPTION         inc_desc
   , gjl.CURRENCY_CODE         account_cu_code
-- , (gb.BEGIN_BALANCE_DR_BEQ - BEGIN_BALANCE_CR_BEQ )  beg_balance
-- , gb.PERIOD_NET_DR                       debits
-- , gb.PERIOD_NET_CR                        credits
-- , gb.BEGIN_BALANCE_DR_BEQ+gb.PERIOD_NET_DR-gb.BEGIN_BALANCE_CR_BEQ-gb.PERIOD_NET_CR  end_balance
   , 0    beg_balance
   , 0    debit
   , 0    credit
, SUM( nvl(gjl.ENTERED_DR, 0))  ent_debit
, SUM( nvl(gjl.ENTERED_CR, 0))  ent_credit
   , 0    ent_beg
   , 0    act_unpost


    FROM
        gl_je_lines                     gjl,
        gl_je_headers                   gjh,
        -- gl_ledgers                      gl,
        gl_code_combinations            gcc,
        -- GL_PERIODS                      gp,
        -- gl_balances                     gb,

        fnd_flex_values_vl              flv_2,
        fnd_flex_value_sets             fls_2,
        fnd_flex_values_vl              flv_3,
        fnd_flex_value_sets             fls_3,
        fnd_flex_values_vl              flv_4,
        fnd_flex_value_sets             fls_4,
        fnd_flex_values_vl              flv_5,
        fnd_flex_value_sets             fls_5,
        fnd_flex_values_vl              flv_6,
        fnd_flex_value_sets             fls_6,
        fnd_flex_values_vl              flv_7,
        fnd_flex_value_sets             fls_7,
        fnd_flex_values_vl              flv_8,
        fnd_flex_value_sets             fls_8

          ,GL_JE_BATCHES                   gl_batch
    WHERE
        -- gl.ledger_id = gb.ledger_id
          gjh.je_header_id = gjl.je_header_id

                  --   update 20200706---- add   batches  status---
        and gl_batch.JE_BATCH_ID = gjh.JE_BATCH_ID
        and gjl.code_combination_id = gcc.code_combination_id
        and (flv_2.flex_value_set_id = fls_2.flex_value_set_id and gcc.segment2 = flv_2.flex_value and fls_2.flex_value_set_name = 'Portfolio WL_LEDGER' )
        and (flv_3.flex_value_set_id = fls_3.flex_value_set_id and gcc.segment3 = flv_3.flex_value and fls_3.flex_value_set_name = 'Business Segment WL_LEDGER' )
        and (flv_4.flex_value_set_id = fls_4.flex_value_set_id and gcc.segment4 = flv_4.flex_value and fls_4.flex_value_set_name = 'Account WL_LEDGER' )
        and (flv_5.flex_value_set_id = fls_5.flex_value_set_id and gcc.segment5 = flv_5.flex_value and fls_5.flex_value_set_name = 'Project WL_LEDGER' )
        and (flv_6.flex_value_set_id = fls_6.flex_value_set_id and gcc.segment6 = flv_6.flex_value and fls_6.flex_value_set_name = 'Property Type WL_LEDGER' )
        and (flv_7.flex_value_set_id = fls_7.flex_value_set_id and gcc.segment7 = flv_7.flex_value and fls_7.flex_value_set_name = 'Department WL_LEDGER' )
        and (flv_8.flex_value_set_id = fls_8.flex_value_set_id and gcc.segment8 = flv_8.flex_value and fls_8.flex_value_set_name = 'Intercompany WL_LEDGER' )
        and gcc.segment1   = :P_COMPANY_CODE

        -- and gjl.CURRENCY_CODE = 'HKD'
        and (gjl.EFFECTIVE_DATE   BETWEEN  (select distinct YEAR_START_DATE
        from gl_periods
        where :P_DATE   BETWEEN  START_DATE and   END_DATE and PERIOD_SET_NAME = 'WL_LEDGER' and ADJUSTMENT_PERIOD_FLAG = 'N')  AND :P_DATE)

        and gjl.LEDGER_ID = :P_LEDGER
        -- update  20200607   add  batches  status  fileter  approve status  in 3  status
        and gl_batch.APPROVAL_STATUS_CODE IN ('Z','I','A')
          -- exclude   error  and  incompleted
        and gl_batch.STATUS  IN ('p','P','U','S','I')

    GROUP BY
   gjl.LEDGER_ID,
            gcc.segment2
            ,flv_2.DESCRIPTION
            ,gcc.segment3
            ,flv_3.DESCRIPTION
            ,gcc.segment4
            ,flv_4.DESCRIPTION
            ,gcc.segment5
            ,flv_5.DESCRIPTION
            ,gcc.segment6
            ,flv_6.DESCRIPTION
            ,gcc.segment7
            ,flv_7.DESCRIPTION
            ,gcc.segment8
            ,flv_8.DESCRIPTION
            , gjl.CURRENCY_CODE

UNION ALL




    SELECT
        --     gcc.segment1         company_code
        --    ,flv_1.DESCRIPTION         company_desc
        gcc.segment2         portfolio_code             --        1
   , flv_2.DESCRIPTION         portfolio_desc
   , gcc.segment3         business_seg               --        1
   , flv_3.DESCRIPTION         business_seg_desc
   , gcc.segment4         account_code                  --    1
   , flv_4.DESCRIPTION         account_desc
   , gcc.segment5         poj_code                    --       1
   , flv_5.DESCRIPTION         poj_desc
   , gcc.segment6         prt_code                 --           1
   , flv_6.DESCRIPTION         prt_desc
   , gcc.segment7        dept_code               --        1
   , flv_7.DESCRIPTION         dept_desc
   , gcc.segment8         inc_code            ---            1
   , flv_8.DESCRIPTION         inc_desc
, gb.CURRENCY_CODE          account_cu_code
   , 0    beg_balance

   , 0    debit
   , 0    credit
     , 0    ent_debit
   , 0    ent_credit
   , SUM(gb.BEGIN_BALANCE_DR - BEGIN_BALANCE_CR )  ent_beg
   , 0    act_unpost
--    , entity.name               lg_entity_name
--    , gjl.PERIOD_NAME           account_period
--    , gjl.CURRENCY_CODE         enter_cu_code             ---    1
--    ,gcc.ACCOUNT_TYPE          account_type
--    ,gl.CURRENCY_CODE          account_cu_code



    FROM
        gl_code_combinations            gcc,
        -- GL_PERIODS                      gp,
        gl_balances                     gb,
        -- fnd_flex_values_vl              flv_1,
        -- fnd_flex_value_sets             fls_1,
        fnd_flex_values_vl              flv_2,
        fnd_flex_value_sets             fls_2,
        fnd_flex_values_vl              flv_3,
        fnd_flex_value_sets             fls_3,
        fnd_flex_values_vl              flv_4,
        fnd_flex_value_sets             fls_4,
        fnd_flex_values_vl              flv_5,
        fnd_flex_value_sets             fls_5,
        fnd_flex_values_vl              flv_6,
        fnd_flex_value_sets             fls_6,
        fnd_flex_values_vl              flv_7,
        fnd_flex_value_sets             fls_7,
        fnd_flex_values_vl              flv_8,
        fnd_flex_value_sets             fls_8
    -- fnd_flex_values_vl              flv_9,
    -- fnd_flex_value_sets             fls_9,
    -- fnd_flex_values_vl              flv_10,
    -- fnd_flex_value_sets             fls_10

    WHERE

    gb.code_combination_id = gcc.code_combination_id
        -- and (flv_1.flex_value_set_id = fls_1.flex_value_set_id and gcc.segment1 = flv_1.flex_value and  fls_1.flex_value_set_name = 'Company WL_LEDGER' )
        and (flv_2.flex_value_set_id = fls_2.flex_value_set_id and gcc.segment2 = flv_2.flex_value and fls_2.flex_value_set_name = 'Portfolio WL_LEDGER' )
        and (flv_3.flex_value_set_id = fls_3.flex_value_set_id and gcc.segment3 = flv_3.flex_value and fls_3.flex_value_set_name = 'Business Segment WL_LEDGER' )
        and (flv_4.flex_value_set_id = fls_4.flex_value_set_id and gcc.segment4 = flv_4.flex_value and fls_4.flex_value_set_name = 'Account WL_LEDGER' )
        and (flv_5.flex_value_set_id = fls_5.flex_value_set_id and gcc.segment5 = flv_5.flex_value and fls_5.flex_value_set_name = 'Project WL_LEDGER' )
        and (flv_6.flex_value_set_id = fls_6.flex_value_set_id and gcc.segment6 = flv_6.flex_value and fls_6.flex_value_set_name = 'Property Type WL_LEDGER' )
        and (flv_7.flex_value_set_id = fls_7.flex_value_set_id and gcc.segment7 = flv_7.flex_value and fls_7.flex_value_set_name = 'Department WL_LEDGER' )
        and (flv_8.flex_value_set_id = fls_8.flex_value_set_id and gcc.segment8 = flv_8.flex_value and fls_8.flex_value_set_name = 'Intercompany WL_LEDGER' )


        and gcc.segment1   = :P_COMPANY_CODE

        -- and gb.PERIOD_NAME = :P_PERIOD
        -- and gb.PERIOD_NAME = 'Jan-2020'
        -- and gb.CURRENCY_CODE = 'HKD'
        and (gb.PERIOD_YEAR = (Select to_number(to_char(:P_DATE,'yyyy'))
        from dual ) and gb.PERIOD_NUM = 1)



        and gb.LEDGER_ID = :P_LEDGER

    GROUP BY
            -- gcc.segment1
            -- ,flv_1.DESCRIPTION
            -- ,gjl.JE_HEADER_ID
            gcc.segment2
            ,flv_2.DESCRIPTION
            ,gcc.segment3
            ,flv_3.DESCRIPTION
            ,gcc.segment4
            ,flv_4.DESCRIPTION
            ,gcc.segment5
            ,flv_5.DESCRIPTION
            ,gcc.segment6
            ,flv_6.DESCRIPTION
            ,gcc.segment7
            ,flv_7.DESCRIPTION
            ,gcc.segment8
            ,flv_8.DESCRIPTION
            ,gb.CURRENCY_CODE  ),

tab_layout  AS (
            SELECT
              temp_tabl.portfolio_code
  ,temp_tabl.portfolio_desc
  ,temp_tabl.business_seg
  ,temp_tabl.business_seg_desc
  ,temp_tabl.account_code
  ,temp_tabl.account_desc
  ,temp_tabl.poj_code
  ,temp_tabl.poj_desc
  ,temp_tabl.prt_code
  ,temp_tabl.prt_desc
  ,temp_tabl.dept_code
  ,temp_tabl.dept_desc
  ,temp_tabl.inc_code
  ,temp_tabl.inc_desc
  ,temp_tabl.account_cu_code

-- ,activity.debits   act_debits
-- ,activity.credits   act_credits
-- ,activity.act_unpost
-- ,enter_beg.beg_balance   enter_beg
-- ,enter_act.debits         enter_debits
-- ,enter_act.credits        enter_credits

  ,SUM(temp_tabl.beg_balance)     beg_balance
  ,SUM(temp_tabl.debit)           act_debits
  ,SUM(temp_tabl.credit)          act_credits
  ,SUM(temp_tabl.ent_debit)       enter_debits
  ,SUM(temp_tabl.ent_credit)      enter_credits
  ,SUM(temp_tabl.ent_beg)         enter_beg
  ,SUM(temp_tabl.act_unpost)      act_unpost


  ,nvl(SUM(temp_tabl.beg_balance),0)+nvl(SUM(temp_tabl.debit),0)- nvl(SUM(temp_tabl.credit),0)       base_end
,nvl(SUM(temp_tabl.ent_beg),0)+nvl(SUM(temp_tabl.ent_debit),0)- nvl(SUM(temp_tabl.ent_credit) ,0)       enter_end



            FROM
            temp_tabl

            GROUP BY
   temp_tabl.portfolio_code
  ,temp_tabl.portfolio_desc
  ,temp_tabl.business_seg
  ,temp_tabl.business_seg_desc
  ,temp_tabl.account_code
  ,temp_tabl.account_desc
  ,temp_tabl.poj_code
  ,temp_tabl.poj_desc
  ,temp_tabl.prt_code
  ,temp_tabl.prt_desc
  ,temp_tabl.dept_code
  ,temp_tabl.dept_desc
  ,temp_tabl.inc_code
  ,temp_tabl.inc_desc
  ,temp_tabl.account_cu_code

     order by temp_tabl.account_code
            ,temp_tabl.portfolio_code
            ,temp_tabl.business_seg
            ,temp_tabl.poj_code
            ,temp_tabl.prt_code
            ,temp_tabl.dept_code
            ,temp_tabl.inc_code
            ,temp_tabl.account_cu_code  )

       SELECT  *
       FROM  tab_layout
       WHERE
             NOT (tab_layout.beg_balance  = 0
                and tab_layout.act_debits   = 0
                and tab_layout.act_credits   = 0
                and tab_layout.enter_debits   = 0
                and tab_layout.enter_credits   = 0
                and tab_layout.act_unpost   = 0
                and tab_layout.base_end   = 0
                and tab_layout.enter_end   = 0 )





NOT(G_1.BEG_BALANCE==0 AND G_1.ACT_DEBITS==0 AND G_1.ACT_CREDITS ==0  AND G_1.ACT_UNPOST == 0
AND G_1.ENTER_DEBITS==0 AND G_1.ENTER_CREDITS ==0 AND G_1.BASE_END == 0 AND G_1.ENTER_END == 0 )

            where
                    (temp_tabl.beg_balance  = 0
                and temp_tabl.act_debits   = 0
                and temp_tabl.act_credits   = 0
                and temp_tabl.enter_debits   = 0
                and temp_tabl.enter_credits   = 0
                and temp_tabl.act_unpost   = 0
                and temp_tabl.base_end   = 0
                and temp_tabl.enter_end   = 0 )
