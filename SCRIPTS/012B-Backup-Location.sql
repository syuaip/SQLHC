-- Get Backup Location
select * from msdb.dbo.backupmediafamily
where charindex(':',physical_device_name) = 2
order by physical_device_name
