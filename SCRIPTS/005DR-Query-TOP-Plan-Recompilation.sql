---Top 100 high total Plan Generation Queries
SELECT TOP 100 creation_time, last_execution_time, total_worker_time,
total_worker_time/execution_count AS [Avg CPU Time], last_worker_time,
execution_count, plan_generation_num, plan_handle, query_hash, query_plan_hash, (SELECT SUBSTRING(text, statement_start_offset/2,
(CASE WHEN statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max),
text)) * 2 
ELSE statement_end_offset END - statement_start_offset)/2)
FROM sys.dm_exec_sql_text(sql_handle)) AS query_text
FROM sys.dm_exec_query_stats 
ORDER BY [plan_generation_num] DESC;
