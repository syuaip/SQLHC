--RB connectivity
SELECT CONVERT (varchar(30), GETDATE(), 121) as [RunTime],
dateadd (ms, (rbf.[timestamp] - tme.ms_ticks), GETDATE()) as Time_Stamp,
cast(record as xml).value('(//Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(50)') AS [Action],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/RecordSource)[1]', 'varchar(50)') AS [Source],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/Spid)[1]', 'int') AS [SPID],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/RemoteHost)[1]', 'varchar(100)') AS [RemoteHost],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/RemotePort)[1]', 'varchar(25)') AS [RemotePort],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/LocalPort)[1]', 'varchar(25)') AS [LocalPort],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferError)[1]', 'varchar(25)') AS [TdsInputBufferError],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsOutputBufferError)[1]', 'varchar(25)') AS [TdsOutputBufferError],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferBytes)[1]', 'varchar(25)') AS [TdsInputBufferBytes],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/PhysicalConnectionIsKilled)[1]', 'int') AS [isPhysConnKilled],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/DisconnectDueToReadError)[1]', 'int') AS [DisconnectDueToReadError],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NetworkErrorFoundInInputStream)[1]', 'int') AS [NetworkErrorFound],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/ErrorFoundBeforeLogin)[1]', 'int') AS [ErrorBeforeLogin],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/SessionIsKilled)[1]', 'int') AS [isSessionKilled],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalDisconnect)[1]', 'int') AS [NormalDisconnect],
cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalLogout)[1]', 'int') AS [NormalLogout],
cast(record as xml).value('(//Record/@id)[1]', 'bigint') AS [Record Id],
cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') AS [Type],
cast(record as xml).value('(//Record/@time)[1]', 'bigint') AS [Record Time],
tme.ms_ticks as [Current Time]
FROM sys.dm_os_ring_buffers rbf
cross join sys.dm_os_sys_info tme
where rbf.ring_buffer_type = 'RING_BUFFER_CONNECTIVITY' and cast(record as xml).value('(//Record/ConnectivityTraceRecord/Spid)[1]', 'int') <> 0
ORDER BY rbf.timestamp ASC 
