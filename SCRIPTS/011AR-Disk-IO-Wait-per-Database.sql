--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
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
