	select distinct serverproperty('machinename') as 'Server',                                           
    isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance',
	t.[database_name] as 'DBname',t.[Logical_Name] as 'Logical Name', t.NextGrowthSize as 'Next Growth MB',
	t.[is_read_only] as 'Read Only' from
	(

	SELECT
	db_name([files].[database_id]) as [database_name],
	[files].[name] as [Logical_Name],NextGrowthSize=
	case [is_percent_growth]
		when 1 then convert(numeric(18,2),(((convert(Numeric,size)*growth)/100)*8)/1024)
		when 0 then convert(numeric(18,2),(convert(numeric,[growth])*8)/1024)
	end ,
	is_read_only=
	case [is_read_only]
		when 1 then 'Yes'
		when 0 then 'No'
	end
	FROM
	sys.master_files [files]
	WHERE 
	[files].[type] in(0,1) AND                    -- data and log files check
	[files].growth != 0 AND	                  -- autogrow enabled check
  
	  lower(db_name(database_id))  NOT IN (N'master', N'tempdb', N'model', N'msdb', N'pubs', N'northwind', N'adventureworks', N'adventureworksdw')
    ) t  
	where t.NextGrowthSize >=1024
	order by [Server],[Instance],[DBname],[Next Growth MB],[Read Only]
