-----Sample code for exploring RPDCLI / Performance Counters / Performance Insight
--This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
--This posting is provided "AS IS" with no warranties, and confers no rights. 

--- USE DB
DECLARE @IPageCnt INT
DECLARE @IMinFragmentation INT
DECLARE @IsMaintenanceDay INT

SET @IPageCnt = 8;
SET @IMinFragmentation = 10;
SET @IsMaintenanceDay = 7;

SELECT
    OBJECT_SCHEMA_NAME(FRAG.[object_id]) + '.' + OBJECT_NAME(FRAG.[object_id]) AS TableName,
    SIX.[name] As IndexName,
	index_type_desc, 
    FRAG.avg_fragmentation_in_percent,
    FRAG.page_count
FROM
    sys.dm_db_index_physical_stats 
    (
        DB_ID(),    --use the currently connected database
        0,          --Parameter for object_id.
        DEFAULT,    --Parameter for index_id.
        0,          --Parameter for partition_number.
        DEFAULT     --Scanning mode. Default to "LIMITED", which is good enough
    ) FRAG
    JOIN
    sys.indexes SIX ON FRAG.[object_id] = SIX.[object_id] AND FRAG.index_id = SIX.index_id
WHERE
    --don't bother with heaps, if we have these anyway outside staging tables.
    FRAG.index_type_desc <> 'HEAP' AND
    (
    --Either consider only those indexes that need treatment
    (FRAG.page_count > @IPageCnt AND FRAG.avg_fragmentation_in_percent > @IMinFragmentation)
    OR
    --or do everything when it is MaintenanceDay
    @IsMaintenanceDay = 1
    )
ORDER BY
    FRAG.avg_fragmentation_in_percent DESC;


