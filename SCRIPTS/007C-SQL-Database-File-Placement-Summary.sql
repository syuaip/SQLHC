select serverproperty('machinename')    as 'Server',                                           
       isnull(serverproperty('instancename'),serverproperty('machinename'))  as 'Instance', 
       drive_letter   as 'Drive Letter',
       Message
        from
        (
        (
			select distinct 
		           UPPER(LEFT(LTRIM(physical_name),2)) AS drive_letter,
				   N'Device holds both tempdb and user database objects'   as 'Message',
				   1 AS OrderBy
			from master.sys.master_files
			where lower(db_name(database_id)) = 'tempdb'
			and UPPER(LEFT(LTRIM(physical_name),2)) in
				(
				select UPPER(LEFT(LTRIM(physical_name),2))
				from master.sys.master_files
				where lower(db_name(database_id)) not in (N'tempdb', N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
				)
		 )
         union
         (
			select drive_letter,
				   N'Device holds both data and log objects'   as 'Message',
				   2 AS OrderBy
			from
				(
				select drive_letter
				from 
					(
					select distinct UPPER(LEFT(LTRIM(physical_name),2)) AS drive_letter, type
					from master.sys.master_files
					where lower(db_name(database_id)) not in (N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
                    ) a
	            group by drive_letter
	            having count(1) >= 2
			    ) b
		)
		) a
		ORDER BY OrderBy, drive_letter
