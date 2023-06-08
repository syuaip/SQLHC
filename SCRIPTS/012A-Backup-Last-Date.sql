-----CHECK LAST BACKUP JOB
SELECT name,
MAX (backup_finish_date) as last_backup_date FROM
(SELECT * from master.sys.databases
WHERE state_desc !='OFFLINE'
AND name NOT IN (select secondary_database from msdb.dbo.log_shipping_secondary_databases)
AND name != 'tempdb') SD
LEFT OUTER JOIN
(SELECT database_name, backup_finish_date,is_snapshot from msdb..backupset where type = 'D') bs
ON bs.database_name = sd.name
WHERE BS.Is_Snapshot <> '1'
GROUP BY name
HAVING MAX(backup_finish_date) < GETDATE()
