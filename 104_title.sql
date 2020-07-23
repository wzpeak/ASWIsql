
---- get  the date add one by one ------------

  select    WEEK_START_DATE
           ,WEEK_START_DATE + 1
           ,WEEK_START_DATE + 2
           ,WEEK_START_DATE + 3
           ,WEEK_START_DATE + 4
           ,WEEK_START_DATE + 5
           ,WEEK_START_DATE + 6
           ,WEEK_START_DATE + 7
           ,WEEK_START_DATE + 8
           ,WEEK_START_DATE + 9
           ,WEEK_START_DATE + 10
           ,WEEK_START_DATE + 11
           ,WEEK_START_DATE + 12
           ,WEEK_START_DATE + 13
           ,WEEK_START_DATE + 14
           ,WEEK_START_DATE + 15
           ,WEEK_START_DATE + 16
           ,WEEK_START_DATE + 17
           ,WEEK_START_DATE + 18
           ,WEEK_START_DATE + 19
           ,WEEK_START_DATE + 20
           ,WEEK_START_DATE + 21
           ,WEEK_START_DATE + 22
           ,WEEK_START_DATE + 23
           ,WEEK_START_DATE + 24
           ,WEEK_START_DATE + 25
           ,WEEK_START_DATE + 26
           ,WEEK_START_DATE + 27
            from MSC_ANALYTIC_CALENDARS_V
            where CALENDAR_DATE = :P_DATE
