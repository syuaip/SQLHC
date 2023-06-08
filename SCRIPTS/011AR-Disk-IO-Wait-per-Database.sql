--- 'I/O waits per database and file type'
SELECT db.name AS database_name
	, mf.type_desc AS file_type
	, SUM(num_of_bytes_read) AS bytes_read 
	, CAST(SUM(CAST(io_stall_read_ms AS FLOAT)) / NULLIF(SUM(num_of_reads), 0) AS DECIMAL(16,3))  AS avg_latency_read_ms
	, SUM(num_of_bytes_read) / NULLIF(SUM(num_of_reads),0) / 1000 AS avg_block_size_read_kb
	, SUM(num_of_bytes_written) AS bytes_written
	, CAST(SUM(CAST(io_stall_write_ms AS FLOAT)) / NULLIF(SUM(num_of_writes), 0) AS DECIMAL(16,3))  AS avg_latency_write_ms
	, SUM(num_of_bytes_written) / NULLIF(SUM(num_of_writes),0) / 1000 AS avg_block_size_write_kb
FROM sys.dm_io_virtual_file_stats(NULL, NULL) vfs
JOIN sys.databases db ON vfs.database_id = db.database_id
JOIN sys.master_files mf ON vfs.file_id = mf.file_id AND vfs.database_id = mf.database_id
GROUP BY db.name, mf.type_desc
ORDER BY db.name, mf.type_desc
