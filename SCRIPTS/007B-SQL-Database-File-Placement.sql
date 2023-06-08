select distinct serverproperty('machinename') as 'Server',                                           
       isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance', 
       db_name(a.database_id) as 'DBname',
       a.database_id  as 'DBID',
           (case a.type
                 when 0 then 'Data File'
                 when 1 then 'Log File'
                 when 4 then 'Full Text Catalog File'
                 else null
            end)  as 'File Type',
       a.physical_name  as 'File Physical Location',
       ltrim(str((convert (dec (15,2),a.size)) * 8192 / 1048576,15,2) + ' MB') as 'File Size'
 from master.sys.master_files a
       where lower(db_name(a.database_id)) not in (N'master', N'msdb', N'model', N'pubs')
       order by 'DBname', 'File Type', 'File Physical Location'
