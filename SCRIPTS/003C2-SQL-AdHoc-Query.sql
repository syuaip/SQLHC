DECLARE @AdHocSizeInMB decimal (14,2), @TotalSizeInMB decimal (14,2)

SELECT @AdHocSizeInMB = SUM(CAST((CASE WHEN usecounts = 1 AND LOWER(objtype) = 'adhoc' THEN size_in_bytes ELSE 0 END) as decimal(14,2))) / 1048576,
	@TotalSizeInMB = SUM (CAST (size_in_bytes as decimal (14,2))) / 1048576
	FROM sys.dm_exec_cached_plans 

SELECT @AdHocSizeInMB as [Current memory occupied by adhoc plans only used once (MB)],
	 @TotalSizeInMB as [Total cache plan size (MB)],
	 CAST((@AdHocSizeInMB / @TotalSizeInMB) * 100 as decimal(14,2)) as [% of total cache plan occupied by adhoc plans only used once]
