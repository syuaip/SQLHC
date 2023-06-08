	select  distinct serverproperty('machinename') as 'Server',                                           
    isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance',
	 'tempdb' as 'DBname',name as 'Logical Name', physical_name as 'Physical path',(size*8/1024) as 'Size in MB' from sys.master_files [files]
	where database_id =2 and 1024 >= 
	(select sum(size) from sys.master_files 
	where  database_id =2 and type=0)
