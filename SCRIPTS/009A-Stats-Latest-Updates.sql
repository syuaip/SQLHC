SELECT name AS index_name, type_desc, 
STATS_DATE(OBJECT_ID, index_id) AS StatsUpdated, * 
FROM sys.indexes
ORDER BY StatsUpdated DESC
