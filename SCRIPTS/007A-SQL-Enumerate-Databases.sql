select  [name]                              AS [DBname],
        suser_name(owner_sid)               AS [Owner],
        [compatibility_level]               AS [CompatibilityLevel],
        serverproperty('productversion')    AS [SQLServerVersion], * 
        from master.sys.databases
        ---where   state_desc = N'ONLINE'
		order by create_date desc
