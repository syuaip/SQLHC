---Top 100 high total Physical Reads Queries
SELECT TOP 100
'High Physical Reads' as Type,
serverproperty('machinename')                                        as 'Server',                                           
isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance',
qs.sql_handle, qs.plan_handle,  qs.query_hash, qs.query_plan_hash, 
SUBSTRING(qt.text,qs.statement_start_offset/2, 
                  (case when qs.statement_end_offset = -1 
                  then len(convert(nvarchar(max), qt.text)) * 2 
                  else qs.statement_end_offset end -qs.statement_start_offset)/2) 
            as query_text,--qp.query_plan,
        qs.execution_count as [Execution Count],
	qs.total_worker_time/1000 as [Total CPU Time],
	(qs.total_worker_time/1000)/qs.execution_count as [Avg CPU Time],
	qs.total_elapsed_time/1000 as [Total Duration],
	(qs.total_elapsed_time/1000)/qs.execution_count as [Avg Duration],
	qs.total_physical_reads as [Total Physical Reads],
	qs.total_physical_reads/qs.execution_count as [Avg Physical Reads],
	 qs.total_logical_reads as [Total Logical Reads],
	qs.total_logical_reads/qs.execution_count as [Avg Logical Reads],
        COALESCE(DB_NAME(qt.dbid),
                DB_NAME(CAST(pa.value as int)), 
                'Resource') AS DBname
	FROM sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
	outer apply sys.dm_exec_query_plan (qs.plan_handle) qp
	outer APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
	where attribute = 'dbid'   
	ORDER BY 
	[Total Physical Reads] DESC
	

