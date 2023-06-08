--- to verify ghost records thread is running/progressing
--- fields to check from time to time: cpu-time, reads, writes, logical_reads, --> wait and blocking
SELECT * INTO #myexecrequests FROM sys.dm_exec_requests WHERE 1 = 0;
SET NOCOUNT ON;
DECLARE @a INT
SELECT @a = 0;
WHILE (@a < 1)
BEGIN
    INSERT INTO #myexecrequests SELECT * FROM sys.dm_exec_requests WHERE command LIKE '%ghost%'
    SELECT @a = COUNT (*) FROM #myexecrequests
END;
SELECT * FROM #myexecrequests;
DROP TABLE #myexecrequests;
