--bpool usage per db in kb:
select db_name(database_id) as database_name, count(page_id)*8 as kb_usage from sys.dm_os_buffer_descriptors where database_id !=32767 group by database_id order by kb_usage desc 
