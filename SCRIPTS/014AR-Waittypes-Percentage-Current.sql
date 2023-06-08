SELECT
wait_type,
waiting_tasks_count,
max_wait_time_ms,
resource_wait_time_ms = (wait_time_ms - signal_wait_time_ms),
PercentOfAllResourceWaitTime =
(cast((wait_time_ms - signal_wait_time_ms) as decimal(19,2)) /
(select sum((wait_time_ms - signal_wait_time_ms)) from sys.dm_os_wait_stats))
* 100
FROM sys.dm_os_wait_stats
ORDER BY PercentOfAllResourceWaitTime DESC
