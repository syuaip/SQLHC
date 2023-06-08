DECLARE
	@SQLServerServiceAccount NVARCHAR(255),
	@SQLServerAgentServiceAccount NVARCHAR(255),
	@SQLServerServiceAccountRegString NVARCHAR(1000),
	@SQLServerAgentServiceAccountRegString NVARCHAR(1000),
	@StartupParametersRegstring NVARCHAR(1000),
	@sysadmin_onlyRegstring NVARCHAR(1000),
	@xp_cmdshell_enabled Bit,
	@sysadmin_only INT,
	@instanceregname NVARCHAR(128),
	@instancename NVARCHAR(128)


CREATE TABLE [dbo].[#tbl_TraceFlag] (
	[InstanceID] INT NOT NULL ,
	[TraceFlag] INT NULL 
) ON [PRIMARY]

CREATE TABLE [dbo].[#tbl_TraceFlagSet] (
	[TraceFlag] INT NULL ,
	[TraceFlagStatus] BIT NULL,
	[Global] INT NULL, 
	[session] INT NULL 
) ON [PRIMARY]

CREATE TABLE #tbl_StartupParameters_ALL
	(Value NVARCHAR(100),
	DATA NVARCHAR (300))
ON [PRIMARY]

CREATE TABLE #tbl_StartupParameters
	(DATA NVARCHAR (300))
ON [PRIMARY]

        dbcc traceon with no_infomsgs

		set @instancename=isnull(convert(NVARCHAR(128),SERVERPROPERTY('InstanceName')),'default')

		IF @instancename ='default'
		   BEGIN
			SELECT @SQLServerServiceAccountRegString='System\currentcontrolset\services\MsSQLServer'
			SELECT @SQLServerAgentServiceAccountRegString='System\currentcontrolset\services\SQLServerAgent'
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL',	N'MSSQLSERVER', @instanceregname OUTPUT
			SELECT @StartupParametersRegstring='SOFTWARE\Microsoft\Microsoft SQL Server\' + @instanceregname + '\MSSQLServer\Parameters'

		/*	SELECT @StartupParametersRegstring='SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\Parameters'*/
			/*SELECT @sysadmin_onlyRegstring=N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent'*/
			SELECT @sysadmin_onlyRegstring=N'SOFTWARE\Microsoft\Microsoft SQL Server\' + @instanceregname + '\SQLServerAgent'
		/*SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL.1\SQLServerAgent*/

		   END
		ELSE
		   BEGIN
			SELECT @SQLServerServiceAccountRegString='System\currentcontrolset\services\MsSQL$' + @instancename
			SELECT @SQLServerAgentServiceAccountRegString='System\currentcontrolset\services\SQLAgent$' + @instancename
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL',	@instancename, @instanceregname OUTPUT
			SELECT @StartupParametersRegstring='SOFTWARE\Microsoft\Microsoft SQL Server\' + @instanceregname + '\MSSQLServer\Parameters'
			SELECT @sysadmin_onlyRegstring=N'SOFTWARE\Microsoft\Microsoft SQL Server\' + @instanceregname + '\SQLServerAgent'
		   END

		INSERT INTO #tbl_StartupParameters_ALL
		EXECUTE master..xp_regenumvalues
		'HKEY_LOCAL_MACHINE',
		@StartupParametersRegstring

		/*remove correct default startup parameters*/
		DELETE FROM #tbl_StartupParameters_ALL WHERE DATA Like '-d%'
		DELETE FROM #tbl_StartupParameters_ALL WHERE DATA Like '-e%'
		DELETE FROM #tbl_StartupParameters_ALL WHERE DATA Like '-l%'

		INSERT INTO #tbl_StartupParameters
		SELECT DATA FROM #tbl_StartupParameters_ALL

		/*get trace flags enabled with dbcc*/
		insert into #tbl_TraceFlagSet (TraceFlag, TraceFlagStatus, [Global], [session])	
			exec ('dbcc tracestatus(-1) with NO_INFOMSGS')

		IF EXISTS(select * FROM #tbl_TraceFlagSet)
		   BEGIN
			  INSERT INTO
			#tbl_StartupParameters
			  SELECT 'DBCC TRACEON(' + CAST(TraceFlag as NVARCHAR(20)) + ')' FROM #tbl_TraceFlagSet WHERE NOT(TraceFlag IN (SELECT REPLACE(DATA,'-T','') FROM #tbl_StartupParameters))
		   END

		IF NOT EXISTS(SELECT * FROM #tbl_StartupParameters)
		   BEGIN
			  INSERT INTO
			#tbl_StartupParameters
			  VALUES
			(N'n/a')
		   END
          select distinct serverproperty('machinename')                               as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name', 
                 TraceFlag                                                            as 'Trace Flag',
                 TraceFlagStatus                                                      as 'Status',
                 [Global]                                                             as 'Global Flag',
                 session                                                              as 'Session Flag'
           from #tbl_TraceFlagSet
          order by 'Server Name','Instance Name','Trace Flag'
          
          dbcc traceoff with no_infomsgs
          
          drop table #tbl_TraceFlag
          drop table #tbl_TraceFlagSet
		  drop table #tbl_StartupParameters_ALL
		  drop table #tbl_StartupParameters
