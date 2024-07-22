--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
USE tempDB; 

WITH Objs (
    ObjectName,
    ObjectID,
    IndexID,
    AU_ID,
    used_pages,
    AU_Type)
AS (SELECT OBJECT_NAME(object_id) AS ObjectName,
        object_id,
        index_id,
        allocation_unit_id,
        used_pages,
        AU.type_desc
    FROM sys.allocation_units AS AU
    INNER JOIN sys.partitions AS P
        ON AU.container_id = P.hobt_id
            -- IN_ROW_DATA and ROW_OVERFLOW_DATA
            AND AU.type In (1, 3)
    UNION ALL
    SELECT OBJECT_NAME(object_id) AS ObjectName,
        object_id,
        index_id,
        allocation_unit_id,
        used_pages,
        AU.type_desc
    FROM sys.allocation_units AS AU
    INNER JOIN sys.partitions AS P
        ON AU.container_id = P.partition_id
            -- LOB_DATA
            AND AU.type = 2
    )
SELECT ObjectName,
    AU_Type,
    IndexID,
    MAX(used_pages) PagesOnDisk,
    COUNT(*) PagesInCache,
    MAX(used_pages) - COUNT(*) PageAllocationDiff
FROM sys.dm_os_buffer_descriptors AS BD
LEFT JOIN Objs O
    ON BD.allocation_unit_id = O.AU_ID
WHERE database_id = DB_ID()
AND ObjectPropertyEx(ObjectID, 'IsUserTable') = 1
GROUP BY ObjectName, AU_Type, IndexID , used_pages
ORDER BY O.ObjectName, O.AU_Type;
