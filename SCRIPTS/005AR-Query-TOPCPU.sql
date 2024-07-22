--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
---Top 100 high total CPU Queries
SELECT TOP 100
'High CPU' as Type,
serverproperty('machinename')                                        as 'Server',                                           
isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance',
qs.sql_handle, qs.plan_handle,  qs.query_hash, qs.query_plan_hash, 
SUBSTRING(qt.text,qs.statement_start_offset/2, 
                  (case when qs.statement_end_offset = -1 
                  then len(convert(nvarchar(max), qt.text)) * 2 
                  else qs.statement_end_offset end -qs.statement_start_offset)/2) 
            as query_text,--qp.query_plan,
        qs.execution_count as [Execution Count],
	qs.total_worker_time/1000 as [Total CPU Time],
	(qs.total_worker_time/1000)/qs.execution_count as [Avg CPU Time],
	qs.total_elapsed_time/1000 as [Total Duration],
	(qs.total_elapsed_time/1000)/qs.execution_count as [Avg Duration],
	qs.total_physical_reads as [Total Physical Reads],
	qs.total_physical_reads/qs.execution_count as [Avg Physical Reads],
      qs.total_logical_reads as [Total Logical Reads],
	qs.total_logical_reads/qs.execution_count as [Avg Logical Reads],
        COALESCE(DB_NAME(qt.dbid),
                DB_NAME(CAST(pa.value as int)), 
                'Resource') AS DBname
             
           
	FROM sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
	outer apply sys.dm_exec_query_plan (qs.plan_handle) qp
	outer APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
	where attribute = 'dbid'   
	ORDER BY 
        [Total CPU Time] DESC
        

