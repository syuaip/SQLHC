SELECT objtype AS [Cache Store Type],
	COUNT_BIG(*) AS [Total Num Of Plans],
	SUM(CAST(size_in_bytes as decimal(14,2))) / 1048576 AS [Total Size In MB],
	AVG(usecounts) AS [All Plans - Ave Use Count],
	SUM(CAST((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(14,2)))/ 1048576 AS [Size in MB of plans with a Use count = 1],
	SUM(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Number of of plans with a Use count = 1]
	FROM sys.dm_exec_cached_plans
	GROUP BY objtype
	ORDER BY [Size in MB of plans with a Use count = 1] DESC
  
