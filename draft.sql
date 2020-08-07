SELECT
    base_account.account_code                               AS "ACCOUNT_CODE"      -- 科目コード
  , base_account.account_name                               AS "ACCOUNT_NAME"      -- 科目名称
  , department_amount.sub_account_code                      AS "SUB_ACCOUNT_CODE"  -- 補助科目コード
  , department_amount.sub_account_name                      AS "SUB_ACCOUNT_NAME"  -- 補助科目
  , COALESCE(department_amount.current_month_amount, 0)     AS "CURRENT_MONTH"     -- 当月
  , COALESCE(department_amount.last_year_amount, 0)         AS "LAST_YEAR"         -- 前年同月
  , COALESCE(department_amount.variance, 0)                 AS "VARIANCE"          -- 当月増減
  , COALESCE(department_amount.var_per, 0)                  AS "VAR_PER"           -- 当月増減率
  , COALESCE(department_amount.ratio, 0)                    AS "RATIO"             -- 当月構成率
  , COALESCE(department_amount.ytd_current_month_amount, 0) AS "YTD_CURRENT_MONTH" -- 当年累計
  , COALESCE(department_amount.ytd_last_year_amount, 0)     AS "YTD_LAST_YEAR"     -- 前年累計
  , COALESCE(department_amount.ytd_variance, 0)             AS "YTD_VARIANCE"      -- 累計増減
  , COALESCE(department_amount.ytd_var_per, 0)              AS "YTD_VAR_PER"       -- 累計増減率
  , COALESCE(department_amount.ytd_ratio, 0)                AS "YTD_RATIO"         -- 累計構成率
  , base_account.account_code                               AS "sort_key"          -- ソートキー
  , department_amount.sub_account_code                      AS "sort_key2"         -- ソートキー2
  , base_account.function_currency                          AS "FUNCTION_CURRENCY"     -- 機能通貨
FROM (
    SELECT
        fvvb_seg5.value AS account_code
      , fvvt_seg5.description AS account_name
      , gl.currency_code AS function_currency
    FROM
        fnd_vs_values_b fvvb_seg5
    INNER JOIN
        fnd_vs_value_sets fvvs_seg5
     ON
        fvvb_seg5.value_set_id = fvvs_seg5.value_set_id
    AND 
        fvvs_seg5.value_set_code = 'XXGL_ACCOUNT'
    INNER JOIN
        fnd_vs_values_tl fvvt_seg5
     ON
        fvvb_seg5.value_id = fvvt_seg5.value_id
    AND
        fvvt_seg5.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
    INNER JOIN
        gl_ledgers gl
     ON
        gl.name = :LEDGER
    WHERE
        fvvb_seg5.value LIKE '95%'
    AND 
        SUBSTR(fvvb_seg5.value, -2) <> '00'
) base_account
INNER JOIN (
    SELECT
        department_detail.account_code -- 科目コード
      , department_detail.sub_account_code -- 補助科目コード
      , department_detail.sub_account_name -- 補助科目名
      , department_detail.current_month_amount -- 当月
      , department_detail.last_year_amount -- 前年同月
      , department_detail.current_month_amount - department_detail.last_year_amount AS variance -- 当月増減
      , CASE WHEN
            department_detail.last_year_amount = 0
        THEN
            0
        ELSE
            TRUNC(
                (
                    department_detail.current_month_amount
                    /
                    department_detail.last_year_amount - 1
                )
                * 100, 2
            )
        END AS var_per -- 当月増減率
      , CASE WHEN
            department_all.current_month_all_amount = 0
        THEN
            0
        ELSE
            TRUNC(
                department_detail.current_month_amount
                /
                department_all.current_month_all_amount
                * 100, 2
            )
        END AS ratio -- 当月構成率
      , department_detail.ytd_current_month_amount -- 当年累計
      , department_detail.ytd_last_year_amount -- 前年累計
      , department_detail.ytd_current_month_amount
        -
        department_detail.ytd_last_year_amount AS ytd_variance -- 累計増減
      , CASE WHEN
            department_detail.ytd_last_year_amount = 0
        THEN
            0
        ELSE
            TRUNC(
                (
                    department_detail.ytd_current_month_amount
                    /
                    department_detail.ytd_last_year_amount - 1
                )
                * 100, 2
            )
        END AS ytd_var_per -- 累計増減率
      , CASE WHEN
            department_all.ytd_current_month_all_amount = 0
        THEN
            0
        ELSE
            TRUNC(
                department_detail.ytd_current_month_amount
                /
                department_all.ytd_current_month_all_amount
                * 100, 2
            )
        END AS ytd_ratio -- 累計構成率
    FROM (
        SELECT
            gcc.segment5 AS account_code
          , gcc.segment6 AS sub_account_code
          , fvvt_seg6.description AS sub_account_name
          , SUM(
                CASE WHEN
                        gp.period_name = period.period_name
                    AND
                        gp.period_set_name = period.period_set_name
                THEN
                    gb.period_net_dr - gb.period_net_cr
                ELSE
                    0
                END
            ) AS current_month_amount -- 当月分金額
          , SUM(
                CASE WHEN
                        gp.end_date = ADD_MONTHS(period.end_date, -12)
                    AND
                        gp.adjustment_period_flag = period.adjustment_period_flag
                THEN
                    gb.period_net_dr - gb.period_net_cr
                ELSE
                    0
                END
            ) AS last_year_amount -- 前年同月分金額
          , SUM(
                CASE WHEN
                        gp.period_year = period.period_year
                    AND
                        gp.period_num <= period.period_num
                THEN
                    gb.period_net_dr - gb.period_net_cr
                ELSE
                    0
                END
            ) AS ytd_current_month_amount -- 当年度累計分金額
          , SUM(
                CASE WHEN
                        gp.period_year = period.period_year - 1
                    AND
                        gp.period_num <= period.period_num
                THEN
                    gb.period_net_dr - gb.period_net_cr
                ELSE
                    0
                END
            ) AS ytd_last_year_amount -- 前年度累計分金額
        FROM
            gl_balances gb
        INNER JOIN
            gl_code_combinations gcc
         ON
            gb.code_combination_id = gcc.code_combination_id
        INNER JOIN
            fnd_vs_values_b fvvb_seg5
         ON
            gcc.segment5 = fvvb_seg5.value
        INNER JOIN 
            fnd_vs_value_sets fvvs_seg5
         ON 
            fvvb_seg5.value_set_id = fvvs_seg5.value_set_id
        AND 
            fvvs_seg5.value_set_code = 'XXGL_ACCOUNT'
        INNER JOIN
            fnd_vs_values_tl fvvt_seg5
         ON
            fvvb_seg5.value_id = fvvt_seg5.value_id
        AND
            fvvt_seg5.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
        INNER JOIN 
            fnd_vs_values_b fvvb_seg6
         ON 
            gcc.segment6 = fvvb_seg6.value
        INNER JOIN
            fnd_vs_value_sets fvvs_seg6
         ON
            fvvb_seg6.value_set_id = fvvs_seg6.value_set_id
        AND
            fvvs_seg6.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_SUB_ACCOUNT'
        INNER JOIN 
            fnd_vs_values_tl fvvt_seg6
         ON 
            fvvb_seg6.value_id = fvvt_seg6.value_id
        AND 
            fvvt_seg6.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
        INNER JOIN
            gl_periods gp
         ON
            gb.period_name = gp.period_name
        INNER JOIN
            fnd_vs_values_b fvvb_seg4
         ON
            gcc.segment4 = fvvb_seg4.value
        AND
            fvvb_seg4.attribute1 = '3' -- 直間販区分：販管部門
        INNER JOIN 
            fnd_vs_value_sets fvvs_seg4
         ON 
            fvvb_seg4.value_set_id = fvvs_seg4.value_set_id
        AND 
            fvvs_seg4.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_DEPARTMENT'
        INNER JOIN (
            SELECT
                gp.period_name
              , gp.period_set_name
              , gp.end_date
              , gp.period_year
              , gp.period_num
              , gp.adjustment_period_flag
            FROM
                gl_periods gp
            WHERE
                gp.period_name = :PERIOD
            AND
                gp.period_set_name = (
                                         SELECT
                                             gl.period_set_name
                                         FROM
                                             gl_ledgers gl
                                         WHERE
                                             gl.name = :LEDGER
                                     )
        ) period
         ON
            1 = 1
        WHERE
            gcc.segment5 LIKE '95%'
        AND
            EXISTS (
                SELECT 
                    1
                FROM 
                    gl_ledgers gl
                WHERE 
                    gl.name = :LEDGER
                AND 
                    gl.period_set_name = gp.period_set_name
                AND 
                    gl.ledger_id = gb.ledger_id
                AND 
                    gl.currency_code = gb.currency_code
            )
        AND
            (
                 gb.period_net_dr <> 0
              OR
                 gb.period_net_cr <> 0
            )
        AND
            (
                (
                    gp.period_name = period.period_name
                AND
                    gp.period_set_name = period.period_set_name
                )
                OR
                (
                    gp.end_date = ADD_MONTHS(period.end_date, -12)
                AND
                    gp.adjustment_period_flag = period.adjustment_period_flag
                )
                OR
                (
                    gp.period_year = period.period_year
                AND
                    gp.period_num <= period.period_num
                )
                OR
                (
                    gp.period_year = period.period_year - 1
                AND
                    gp.period_num <= period.period_num
                )
            )
            
        GROUP BY
            gcc.segment5
          , fvvt_seg5.description
          , gcc.segment6
          , fvvt_seg6.description
    ) department_detail
    INNER JOIN (
        SELECT
            SUM(
                CASE WHEN
                        gp.period_name = period.period_name
                    AND
                        gp.period_set_name = period.period_set_name
                THEN
                    gb.period_net_dr - gb.period_net_cr
                ELSE
                    0
                END
            ) AS current_month_all_amount -- 部門費全体当月分金額
          , SUM(
                CASE WHEN
                        gp.period_year = period.period_year
                    AND
                        gp.period_num <= period.period_num
                THEN
                    gb.period_net_dr - gb.period_net_cr
                ELSE
                    0
                END
            ) AS ytd_current_month_all_amount -- 部門費全体当年度累計分金額
        FROM
            gl_balances gb
        INNER JOIN
            gl_code_combinations gcc
         ON
            gb.code_combination_id = gcc.code_combination_id
        INNER JOIN
            gl_periods gp
         ON
            gb.period_name = gp.period_name
        INNER JOIN
            fnd_vs_values_b fvvb_seg4
         ON
            gcc.segment4 = fvvb_seg4.value
        AND
            fvvb_seg4.attribute1 = '3' -- 直間販区分：販管部門
        INNER JOIN 
            fnd_vs_value_sets fvvs_seg4
         ON 
            fvvb_seg4.value_set_id = fvvs_seg4.value_set_id
        AND 
            fvvs_seg4.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_DEPARTMENT'
        INNER JOIN (
            SELECT
                gp.period_name
              , gp.period_set_name
              , gp.end_date
              , gp.period_year
              , gp.period_num
              , gp.adjustment_period_flag
            FROM
                gl_periods gp
            WHERE
                gp.period_name = :PERIOD
            AND
                gp.period_set_name = (
                                         SELECT
                                             gl.period_set_name
                                         FROM
                                             gl_ledgers gl
                                         WHERE
                                             gl.name = :LEDGER
                                     )
        ) period
         ON
            1 = 1
        WHERE
            gcc.segment5 LIKE '95%'
        AND
            EXISTS (
                SELECT 
                    1
                FROM 
                    gl_ledgers gl
                WHERE 
                    gl.name = :LEDGER
                AND 
                    gl.period_set_name = gp.period_set_name
                AND 
                    gl.ledger_id = gb.ledger_id
                AND 
                    gl.currency_code = gb.currency_code
            )
    ) department_all
     ON
        1 = 1
) department_amount
 ON
    base_account.account_code = department_amount.account_code
    
UNION ALL

SELECT
    '支出总额'                                                       AS "account_code"      -- 科目コード
  , ''                                                                    AS "account_name"      -- 科目名称
  , ''                                                                    AS "sub_account_code"  -- 補助科目コード
  , ''                                                                    AS "sub_account_name"  -- 補助科目
  , COALESCE(department_detail.current_month, 0)                          AS "current_month"     -- 当月
  , COALESCE(department_detail.last_year, 0)                              AS "last_year"         -- 前年同月
  , COALESCE(
        department_detail.current_month - department_detail.last_year, 0
    )                                                                     AS "variance"          -- 当月増減
  , COALESCE(
        CASE WHEN
            department_detail.last_year = 0
        THEN
            0
        ELSE
            TRUNC((department_detail.current_month / department_detail.last_year - 1) * 100, 2)
        END
        , 0
    )                                                                     AS "var_per"           -- 当月増減率
  , COALESCE(
        CASE WHEN
            department_all.current_month_sum_all = 0
        THEN
            0
        ELSE
            TRUNC(department_detail.current_month / department_all.current_month_sum_all * 100, 2)
        END
        , 0
    )                                                                     AS "ratio"             -- 当月構成率
  , COALESCE(department_detail.ytd_current_month, 0)                      AS "ytd_current_month" -- 当年累計
  , COALESCE(department_detail.ytd_last_year, 0)                          AS "ytd_last_year"     -- 前年累計
  , COALESCE(
        department_detail.ytd_current_month - department_detail.ytd_last_year, 0
    )                                                                     AS "ytd_variance"      -- 累計増減
  , COALESCE(
        CASE WHEN
            department_detail.ytd_last_year = 0
        THEN
            0
        ELSE
            TRUNC((department_detail.ytd_current_month / department_detail.ytd_last_year - 1) * 100, 2)
        END
        , 0
    )                                                                     AS "ytd_var_per"       -- 累計増減率
  , COALESCE(
        CASE WHEN
            department_all.ytd_current_month_sum_all = 0
        THEN
            0
        ELSE
            TRUNC(department_detail.ytd_current_month / department_all.ytd_current_month_sum_all * 100, 2)
        END
        , 0
    )                                                                     AS "ytd_ratio"         -- 累計構成率
  , '9519999999'                                                          AS "sort_key"          -- ソートキー
  , ''                                                                    AS "sort_key2"         -- ソートキー2
  , (SELECT gl.currency_code FROM gl_ledgers gl WHERE gl.name = :LEDGER)  AS "function_currency" -- 機能通貨
FROM (
    SELECT
        SUM(
            CASE WHEN
                    gp.period_name = period.period_name
                AND
                    gp.period_set_name = period.period_set_name
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS current_month -- 当月分金額
      , SUM(
            CASE WHEN
                    gp.end_date = ADD_MONTHS(period.end_date, -12)
                AND
                    gp.adjustment_period_flag = period.adjustment_period_flag
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS last_year -- 前年同月分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_current_month -- 当年度累計分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year - 1
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_last_year -- 前年度累計分金額
    FROM
        gl_balances gb
    INNER JOIN
        gl_code_combinations gcc
     ON
        gb.code_combination_id = gcc.code_combination_id
    INNER JOIN
        fnd_vs_values_b fvvb_seg5
     ON
        gcc.segment5 = fvvb_seg5.value
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg5
     ON 
        fvvb_seg5.value_set_id = fvvs_seg5.value_set_id
    AND 
        fvvs_seg5.value_set_code = 'XXGL_ACCOUNT'
    INNER JOIN
        fnd_vs_values_tl fvvt_seg5
     ON
        fvvb_seg5.value_id = fvvt_seg5.value_id
    AND
        fvvt_seg5.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
    INNER JOIN 
        fnd_vs_values_b fvvb_seg6
     ON 
        gcc.segment6 = fvvb_seg6.value
    INNER JOIN
        fnd_vs_value_sets fvvs_seg6
     ON
        fvvb_seg6.value_set_id = fvvs_seg6.value_set_id
    AND
        fvvs_seg6.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_SUB_ACCOUNT'
    INNER JOIN 
        fnd_vs_values_tl fvvt_seg6
     ON 
        fvvb_seg6.value_id = fvvt_seg6.value_id
    AND 
        fvvt_seg6.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
    INNER JOIN
        gl_periods gp
     ON
        gb.period_name = gp.period_name
    INNER JOIN
        fnd_vs_values_b fvvb_seg4
     ON
        gcc.segment4 = fvvb_seg4.value
    AND
        fvvb_seg4.attribute1 = '3' -- 直間販区分：販管部門
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg4
     ON 
        fvvb_seg4.value_set_id = fvvs_seg4.value_set_id
    AND 
        fvvs_seg4.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_DEPARTMENT'
    INNER JOIN (
        SELECT
            gp.period_name
          , gp.period_set_name
          , gp.end_date
          , gp.period_year
          , gp.period_num
          , gp.adjustment_period_flag
        FROM
            gl_periods gp
        WHERE
            gp.period_name = :PERIOD
        AND
            gp.period_set_name = (
                                     SELECT
                                         gl.period_set_name
                                     FROM
                                         gl_ledgers gl
                                     WHERE
                                         gl.name = :LEDGER
                                 )
    ) period
     ON
        1 = 1
    WHERE
        gcc.segment5 LIKE '951%'
    AND
        EXISTS (
            SELECT 
                1
            FROM 
                gl_ledgers gl
            WHERE 
                gl.name = :LEDGER
            AND 
                gl.period_set_name = gp.period_set_name
            AND 
                gl.ledger_id = gb.ledger_id
            AND 
                gl.currency_code = gb.currency_code
        )
) department_detail
INNER JOIN (
    SELECT
        SUM(
            CASE WHEN
                    gp.period_name = period.period_name
                AND
                    gp.period_set_name = period.period_set_name
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS current_month_sum_all -- 部門費全体当月分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_current_month_sum_all -- 部門費全体当年度累計分金額
    FROM
        gl_balances gb
    INNER JOIN
        gl_code_combinations gcc
     ON
        gb.code_combination_id = gcc.code_combination_id
    INNER JOIN
        gl_periods gp
     ON
        gb.period_name = gp.period_name
    INNER JOIN
        fnd_vs_values_b fvvb_seg4
     ON
        gcc.segment4 = fvvb_seg4.value
    AND
        fvvb_seg4.attribute1 = '3' -- 直間販区分：販管部門
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg4
     ON 
        fvvb_seg4.value_set_id = fvvs_seg4.value_set_id
    AND 
        fvvs_seg4.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_DEPARTMENT'
    INNER JOIN (
        SELECT
            gp.period_name
          , gp.period_set_name
          , gp.end_date
          , gp.period_year
          , gp.period_num
          , gp.adjustment_period_flag
        FROM
            gl_periods gp
        WHERE
            gp.period_name = :PERIOD
        AND
            gp.period_set_name = (
                                     SELECT
                                         gl.period_set_name
                                     FROM
                                         gl_ledgers gl
                                     WHERE
                                         gl.name = :LEDGER
                                 )
    ) period
     ON
        1 = 1
    WHERE
        gcc.segment5 LIKE '95%'
    AND
        EXISTS (
            SELECT 
                1
            FROM 
                gl_ledgers gl
            WHERE 
                gl.name = :LEDGER
            AND 
                gl.period_set_name = gp.period_set_name
            AND 
                gl.ledger_id = gb.ledger_id
            AND 
                gl.currency_code = gb.currency_code
        )
) department_all
 ON
    1 = 1
UNION ALL
SELECT
    '劳务总额'                                                    AS "account_code"      -- 科目コード
  , ''                                                                    AS "account_name"      -- 科目名称
  , ''                                                                    AS "sub_account_code"  -- 補助科目コード
  , ''                                                                    AS "sub_account_name"  -- 補助科目
  , COALESCE(department_detail.current_month, 0)                          AS "current_month"     -- 当月
  , COALESCE(department_detail.last_year, 0)                              AS "last_year"         -- 前年同月
  , COALESCE(
        department_detail.current_month - department_detail.last_year, 0
    )                                                                     AS "variance"          -- 当月増減
  , COALESCE(
        CASE WHEN
            department_detail.last_year = 0
        THEN
            0
        ELSE
            TRUNC((department_detail.current_month / department_detail.last_year - 1) * 100, 2)
        END
        , 0
    )                                                                     AS "var_per"           -- 当月増減率
  , COALESCE(
        CASE WHEN
            department_all.current_month_sum_all = 0
        THEN
            0
        ELSE
            TRUNC(department_detail.current_month / department_all.current_month_sum_all * 100, 2)
        END
        , 0
    )                                                                     AS "ratio"             -- 当月構成率
  , COALESCE(department_detail.ytd_current_month, 0)                      AS "ytd_current_month" -- 当年累計
  , COALESCE(department_detail.ytd_last_year, 0)                          AS "ytd_last_year"     -- 前年累計
  , COALESCE(
        department_detail.ytd_current_month - department_detail.ytd_last_year, 0
    )                                                                     AS "ytd_variance"      -- 累計増減
  , COALESCE(
        CASE WHEN
            department_detail.ytd_last_year = 0
        THEN
            0
        ELSE
            TRUNC((department_detail.ytd_current_month / department_detail.ytd_last_year - 1) * 100, 2)
        END
        , 0
    )                                                                     AS "ytd_var_per"       -- 累計増減率
  , COALESCE(
        CASE WHEN
            department_all.ytd_current_month_sum_all = 0
        THEN
            0
        ELSE
            TRUNC(department_detail.ytd_current_month / department_all.ytd_current_month_sum_all * 100, 2)
        END
        , 0
    )                                                                     AS "ytd_ratio"         -- 累計構成率
  , '9539999999'                                                          AS "sort_key"          -- ソートキー
  , ''                                                                    AS "sort_key2"         -- ソートキー2
  , (SELECT gl.currency_code FROM gl_ledgers gl WHERE gl.name = :LEDGER)  AS "function_currency" -- 機能通貨
FROM (
    SELECT
        SUM(
            CASE WHEN
                    gp.period_name = period.period_name
                AND
                    gp.period_set_name = period.period_set_name
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS current_month -- 当月分金額
      , SUM(
            CASE WHEN
                    gp.end_date = ADD_MONTHS(period.end_date, -12)
                AND
                    gp.adjustment_period_flag = period.adjustment_period_flag
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS last_year -- 前年同月分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_current_month -- 当年度累計分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year - 1
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_last_year -- 前年度累計分金額
    FROM
        gl_balances gb
    INNER JOIN
        gl_code_combinations gcc
     ON
        gb.code_combination_id = gcc.code_combination_id
    INNER JOIN
        fnd_vs_values_b fvvb_seg5
     ON
        gcc.segment5 = fvvb_seg5.value
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg5
     ON 
        fvvb_seg5.value_set_id = fvvs_seg5.value_set_id
    AND 
        fvvs_seg5.value_set_code = 'XXGL_ACCOUNT'
    INNER JOIN
        fnd_vs_values_tl fvvt_seg5
     ON
        fvvb_seg5.value_id = fvvt_seg5.value_id
    AND
        fvvt_seg5.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
    INNER JOIN 
        fnd_vs_values_b fvvb_seg6
     ON 
        gcc.segment6 = fvvb_seg6.value
    INNER JOIN
        fnd_vs_value_sets fvvs_seg6
     ON
        fvvb_seg6.value_set_id = fvvs_seg6.value_set_id
    AND
        fvvs_seg6.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_SUB_ACCOUNT'
    INNER JOIN 
        fnd_vs_values_tl fvvt_seg6
     ON 
        fvvb_seg6.value_id = fvvt_seg6.value_id
    AND 
        fvvt_seg6.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
    INNER JOIN
        gl_periods gp
     ON
        gb.period_name = gp.period_name
    INNER JOIN
        fnd_vs_values_b fvvb_seg4
     ON
        gcc.segment4 = fvvb_seg4.value
    AND
        fvvb_seg4.attribute1 = '3' -- 直間販区分：販管部門
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg4
     ON 
        fvvb_seg4.value_set_id = fvvs_seg4.value_set_id
    AND 
        fvvs_seg4.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_DEPARTMENT'
    INNER JOIN (
        SELECT
            gp.period_name
          , gp.period_set_name
          , gp.end_date
          , gp.period_year
          , gp.period_num
          , gp.adjustment_period_flag
        FROM
            gl_periods gp
        WHERE
            gp.period_name = :PERIOD
        AND
            gp.period_set_name = (
                                     SELECT
                                         gl.period_set_name
                                     FROM
                                         gl_ledgers gl
                                     WHERE
                                         gl.name = :LEDGER
                                 )
    ) period
     ON
        1 = 1
    WHERE
        gcc.segment5 LIKE '953%'
    AND
        EXISTS (
            SELECT 
                1
            FROM 
                gl_ledgers gl
            WHERE 
                gl.name = :LEDGER
            AND 
                gl.period_set_name = gp.period_set_name
            AND 
                gl.ledger_id = gb.ledger_id
            AND 
                gl.currency_code = gb.currency_code
        )
) department_detail
INNER JOIN (
    SELECT
        SUM(
            CASE WHEN
                    gp.period_name = period.period_name
                AND
                    gp.period_set_name = period.period_set_name
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS current_month_sum_all -- 部門費全体当月分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_current_month_sum_all -- 部門費全体当年度累計分金額
    FROM
        gl_balances gb
    INNER JOIN
        gl_code_combinations gcc
     ON
        gb.code_combination_id = gcc.code_combination_id
    INNER JOIN
        gl_periods gp
     ON
        gb.period_name = gp.period_name
    INNER JOIN
        fnd_vs_values_b fvvb_seg4
     ON
        gcc.segment4 = fvvb_seg4.value
    AND
        fvvb_seg4.attribute1 = '3' -- 直間販区分：販管部門
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg4
     ON 
        fvvb_seg4.value_set_id = fvvs_seg4.value_set_id
    AND 
        fvvs_seg4.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_DEPARTMENT'
    INNER JOIN (
        SELECT
            gp.period_name
          , gp.period_set_name
          , gp.end_date
          , gp.period_year
          , gp.period_num
          , gp.adjustment_period_flag
        FROM
            gl_periods gp
        WHERE
            gp.period_name = :PERIOD
        AND
            gp.period_set_name = (
                                     SELECT
                                         gl.period_set_name
                                     FROM
                                         gl_ledgers gl
                                     WHERE
                                         gl.name = :LEDGER
                                 )
    ) period
     ON
        1 = 1
    WHERE
        gcc.segment5 LIKE '95%'
    AND
        EXISTS (
            SELECT 
                1
            FROM 
                gl_ledgers gl
            WHERE 
                gl.name = :LEDGER
            AND 
                gl.period_set_name = gp.period_set_name
            AND 
                gl.ledger_id = gb.ledger_id
            AND 
                gl.currency_code = gb.currency_code
        )
) department_all
 ON
    1 = 1
UNION ALL
SELECT
    '折旧总额'                                                  AS "account_code"      -- 科目コード
  , ''                                                                    AS "account_name"      -- 科目名称
  , ''                                                                    AS "sub_account_code"  -- 補助科目コード
  , ''                                                                    AS "sub_account_name"  -- 補助科目
  , COALESCE(department_detail.current_month, 0)                          AS "current_month"     -- 当月
  , COALESCE(department_detail.last_year, 0)                              AS "last_year"         -- 前年同月
  , COALESCE(
        department_detail.current_month - department_detail.last_year, 0
    )                                                                     AS "variance"          -- 当月増減
  , COALESCE(
        CASE WHEN
            department_detail.last_year = 0
        THEN
            0
        ELSE
            TRUNC((department_detail.current_month / department_detail.last_year - 1) * 100, 2)
        END
        , 0
    )                                                                     AS "var_per"           -- 当月増減率
  , COALESCE(
        CASE WHEN
            department_all.current_month_sum_all = 0
        THEN
            0
        ELSE
            TRUNC(department_detail.current_month / department_all.current_month_sum_all * 100, 2)
        END
        , 0
    )                                                                     AS "ratio"             -- 当月構成率
  , COALESCE(department_detail.ytd_current_month, 0)                      AS "ytd_current_month" -- 当年累計
  , COALESCE(department_detail.ytd_last_year, 0)                          AS "ytd_last_year"     -- 前年累計
  , COALESCE(
        department_detail.ytd_current_month - department_detail.ytd_last_year, 0
    )                                                                     AS "ytd_variance"      -- 累計増減
  , COALESCE(
        CASE WHEN
            department_detail.ytd_last_year = 0
        THEN
            0
        ELSE
            TRUNC((department_detail.ytd_current_month / department_detail.ytd_last_year - 1) * 100, 2)
        END
        , 0
    )                                                                     AS "ytd_var_per"       -- 累計増減率
  , COALESCE(
        CASE WHEN
            department_all.ytd_current_month_sum_all = 0
        THEN
            0
        ELSE
            TRUNC(department_detail.ytd_current_month / department_all.ytd_current_month_sum_all * 100, 2)
        END
        , 0
    )                                                                     AS "ytd_ratio"         -- 累計構成率
  , '9559999999'                                                          AS "sort_key"          -- ソートキー
  , ''                                                                    AS "sort_key2"         -- ソートキー2
  , (SELECT gl.currency_code FROM gl_ledgers gl WHERE gl.name = :LEDGER)  AS "function_currency" -- 機能通貨
FROM (
    SELECT
        SUM(
            CASE WHEN
                    gp.period_name = period.period_name
                AND
                    gp.period_set_name = period.period_set_name
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS current_month -- 当月分金額
      , SUM(
            CASE WHEN
                    gp.end_date = ADD_MONTHS(period.end_date, -12)
                AND
                    gp.adjustment_period_flag = period.adjustment_period_flag
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS last_year -- 前年同月分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_current_month -- 当年度累計分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year - 1
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_last_year -- 前年度累計分金額
    FROM
        gl_balances gb
    INNER JOIN
        gl_code_combinations gcc
     ON
        gb.code_combination_id = gcc.code_combination_id
    INNER JOIN
        fnd_vs_values_b fvvb_seg5
     ON
        gcc.segment5 = fvvb_seg5.value
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg5
     ON 
        fvvb_seg5.value_set_id = fvvs_seg5.value_set_id
    AND 
        fvvs_seg5.value_set_code = 'XXGL_ACCOUNT'
    INNER JOIN
        fnd_vs_values_tl fvvt_seg5
     ON
        fvvb_seg5.value_id = fvvt_seg5.value_id
    AND
        fvvt_seg5.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
    INNER JOIN 
        fnd_vs_values_b fvvb_seg6
     ON 
        gcc.segment6 = fvvb_seg6.value
    INNER JOIN
        fnd_vs_value_sets fvvs_seg6
     ON
        fvvb_seg6.value_set_id = fvvs_seg6.value_set_id
    AND
        fvvs_seg6.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_SUB_ACCOUNT'
    INNER JOIN 
        fnd_vs_values_tl fvvt_seg6
     ON 
        fvvb_seg6.value_id = fvvt_seg6.value_id
    AND 
        fvvt_seg6.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
    INNER JOIN
        gl_periods gp
     ON
        gb.period_name = gp.period_name
    INNER JOIN
        fnd_vs_values_b fvvb_seg4
     ON
        gcc.segment4 = fvvb_seg4.value
    AND
        fvvb_seg4.attribute1 = '3' -- 直間販区分：販管部門
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg4
     ON 
        fvvb_seg4.value_set_id = fvvs_seg4.value_set_id
    AND 
        fvvs_seg4.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_DEPARTMENT'
    INNER JOIN (
        SELECT
            gp.period_name
          , gp.period_set_name
          , gp.end_date
          , gp.period_year
          , gp.period_num
          , gp.adjustment_period_flag
        FROM
            gl_periods gp
        WHERE
            gp.period_name = :PERIOD
        AND
            gp.period_set_name = (
                                     SELECT
                                         gl.period_set_name
                                     FROM
                                         gl_ledgers gl
                                     WHERE
                                         gl.name = :LEDGER
                                 )
    ) period
     ON
        1 = 1
    WHERE
        gcc.segment5 LIKE '955%'
    AND
        EXISTS (
            SELECT 
                1
            FROM 
                gl_ledgers gl
            WHERE 
                gl.name = :LEDGER
            AND 
                gl.period_set_name = gp.period_set_name
            AND 
                gl.ledger_id = gb.ledger_id
            AND 
                gl.currency_code = gb.currency_code
        )
) department_detail
INNER JOIN (
    SELECT
        SUM(
            CASE WHEN
                    gp.period_name = period.period_name
                AND
                    gp.period_set_name = period.period_set_name
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS current_month_sum_all -- 部門費全体当月分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_current_month_sum_all -- 部門費全体当年度累計分金額
    FROM
        gl_balances gb
    INNER JOIN
        gl_code_combinations gcc
     ON
        gb.code_combination_id = gcc.code_combination_id
    INNER JOIN
        gl_periods gp
     ON
        gb.period_name = gp.period_name
    INNER JOIN
        fnd_vs_values_b fvvb_seg4
     ON
        gcc.segment4 = fvvb_seg4.value
    AND
        fvvb_seg4.attribute1 = '3' -- 直間販区分：販管部門
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg4
     ON 
        fvvb_seg4.value_set_id = fvvs_seg4.value_set_id
    AND 
        fvvs_seg4.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_DEPARTMENT'
    INNER JOIN (
        SELECT
            gp.period_name
          , gp.period_set_name
          , gp.end_date
          , gp.period_year
          , gp.period_num
          , gp.adjustment_period_flag
        FROM
            gl_periods gp
        WHERE
            gp.period_name = :PERIOD
        AND
            gp.period_set_name = (
                                     SELECT
                                         gl.period_set_name
                                     FROM
                                         gl_ledgers gl
                                     WHERE
                                         gl.name = :LEDGER
                                 )
    ) period
     ON
        1 = 1
    WHERE
        gcc.segment5 LIKE '95%'
    AND
        EXISTS (
            SELECT 
                1
            FROM 
                gl_ledgers gl
            WHERE 
                gl.name = :LEDGER
            AND 
                gl.period_set_name = gp.period_set_name
            AND 
                gl.ledger_id = gb.ledger_id
            AND 
                gl.currency_code = gb.currency_code
        )
) department_all
 ON
    1 = 1
UNION ALL
SELECT
    '汇总'                                                               AS "account_code"      -- 科目コード
  , ''                                                                    AS "account_name"      -- 科目名称
  , ''                                                                    AS "sub_account_code"  -- 補助科目コード
  , ''                                                                    AS "sub_account_name"  -- 補助科目
  , COALESCE(department_detail.current_month, 0)                          AS "current_month"     -- 当月
  , COALESCE(department_detail.last_year, 0)                              AS "last_year"         -- 前年同月
  , COALESCE(
        department_detail.current_month - department_detail.last_year, 0
    )                                                                     AS "variance"          -- 当月増減
  , COALESCE(
        CASE WHEN
            department_detail.last_year = 0
        THEN
            0
        ELSE
            TRUNC((department_detail.current_month / department_detail.last_year - 1) * 100, 2)
        END
        , 0
    )                                                                     AS "var_per"           -- 当月増減率
  , COALESCE(
        CASE WHEN
            department_detail.current_month = 0
        THEN
            0
        ELSE
            100
        END
        , 0
    )                                                                     AS "ratio"             -- 当月構成率
  , COALESCE(department_detail.ytd_current_month, 0)                      AS "ytd_current_month" -- 当年累計
  , COALESCE(department_detail.ytd_last_year, 0)                          AS "ytd_last_year"     -- 前年累計
  , COALESCE(
        department_detail.ytd_current_month - department_detail.ytd_last_year, 0
    )                                                                     AS "ytd_variance"      -- 累計増減
  , CASE WHEN
        department_detail.ytd_last_year = 0
    THEN
        0
    ELSE
        TRUNC((department_detail.ytd_current_month / department_detail.ytd_last_year - 1) * 100, 2)
    END                                                                   AS "ytd_var_per"       -- 累計増減率
  , CASE WHEN
        department_detail.ytd_current_month = 0
    THEN
        0
    ELSE
        100
    END                                                                   AS "ytd_ratio"         -- 累計構成率
  , '9999999999'                                                          AS "sort_key"          -- ソートキー
  , ''                                                                    AS "sort_key2"         -- ソートキー2
  , (SELECT gl.currency_code FROM gl_ledgers gl WHERE gl.name = :LEDGER)  AS "function_currency" -- 機能通貨
FROM (
    SELECT
        SUM(
            CASE WHEN
                    gp.period_name = period.period_name
                AND
                    gp.period_set_name = period.period_set_name
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS current_month -- 当月分金額
      , SUM(
            CASE WHEN
                    gp.end_date = ADD_MONTHS(period.end_date, -12)
                AND
                    gp.adjustment_period_flag = period.adjustment_period_flag
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS last_year -- 前年同月分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_current_month -- 当年度累計分金額
      , SUM(
            CASE WHEN
                    gp.period_year = period.period_year - 1
                AND
                    gp.period_num <= period.period_num
            THEN
                gb.period_net_dr - gb.period_net_cr
            ELSE
                0
            END
        ) AS ytd_last_year -- 前年度累計分金額
    FROM
        gl_balances gb
    INNER JOIN
        gl_code_combinations gcc
     ON
        gb.code_combination_id = gcc.code_combination_id
    INNER JOIN
        fnd_vs_values_b fvvb_seg5
     ON
        gcc.segment5 = fvvb_seg5.value
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg5
     ON 
        fvvb_seg5.value_set_id = fvvs_seg5.value_set_id
    AND 
        fvvs_seg5.value_set_code = 'XXGL_ACCOUNT'
    INNER JOIN
        fnd_vs_values_tl fvvt_seg5
     ON
        fvvb_seg5.value_id = fvvt_seg5.value_id
    AND
        fvvt_seg5.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
    INNER JOIN 
        fnd_vs_values_b fvvb_seg6
     ON 
        gcc.segment6 = fvvb_seg6.value
    INNER JOIN
        fnd_vs_value_sets fvvs_seg6
     ON
        fvvb_seg6.value_set_id = fvvs_seg6.value_set_id
    AND
        fvvs_seg6.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_SUB_ACCOUNT'
    INNER JOIN 
        fnd_vs_values_tl fvvt_seg6
     ON 
        fvvb_seg6.value_id = fvvt_seg6.value_id
    AND 
        fvvt_seg6.language = (SELECT language_code FROM fnd_languages_b WHERE language_tag = FND_GLOBAL.LANGUAGE)
    INNER JOIN
        gl_periods gp
     ON
        gb.period_name = gp.period_name
    INNER JOIN
        fnd_vs_values_b fvvb_seg4
     ON
        gcc.segment4 = fvvb_seg4.value
    AND
        fvvb_seg4.attribute1 = '3' -- 直間販区分：販管部門
    INNER JOIN 
        fnd_vs_value_sets fvvs_seg4
     ON 
        fvvb_seg4.value_set_id = fvvs_seg4.value_set_id
    AND 
        fvvs_seg4.value_set_code = 'XXGL_' || SUBSTR(:LEDGER, 1, 5) || '_DEPARTMENT'
    INNER JOIN (
        SELECT
            gp.period_name
          , gp.period_set_name
          , gp.end_date
          , gp.period_year
          , gp.period_num
          , gp.adjustment_period_flag
        FROM
            gl_periods gp
        WHERE
            gp.period_name = :PERIOD
        AND
            gp.period_set_name = (
                                     SELECT
                                         gl.period_set_name
                                     FROM
                                         gl_ledgers gl
                                     WHERE
                                         gl.name = :LEDGER
                                 )
    ) period
     ON
        1 = 1
    WHERE
        gcc.segment5 LIKE '95%'
    AND
        EXISTS (
            SELECT 
                1
            FROM 
                gl_ledgers gl
            WHERE 
                gl.name = :LEDGER
            AND 
                gl.period_set_name = gp.period_set_name
            AND 
                gl.ledger_id = gb.ledger_id
            AND 
                gl.currency_code = gb.currency_code
        )
) department_detail
ORDER BY
    "sort_key"
  , "sort_key2"