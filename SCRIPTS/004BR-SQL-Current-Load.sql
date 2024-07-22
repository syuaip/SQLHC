--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
-- SQL Query Info
SELECT     sessions.session_id
			, sessions.login_name
			, sessions.program_name
			, sessions.status AS session_status
			, requests.status AS request_status
			, CASE sessions.transaction_isolation_level
					WHEN 0 THEN 'Unspecified'
					WHEN 1 THEN 'ReadUncomitted'
					WHEN 2 THEN 'ReadCommitted'
					WHEN 3 THEN 'Repeatable'
					WHEN 4 THEN 'Serializable'
					WHEN 5 THEN 'Snapshot'
					ELSE 'UNKNOWN'
				END AS session_transaction_isolation_level
			, CASE requests.transaction_isolation_level
					WHEN 0 THEN 'Unspecified'
					WHEN 1 THEN 'ReadUncomitted'
					WHEN 2 THEN 'ReadCommitted'
					WHEN 3 THEN 'Repeatable'
					WHEN 4 THEN 'Serializable'
					WHEN 5 THEN 'Snapshot'
					ELSE 'UNKNOWN'
				END AS request_transaction_isolation_level
			, requests.blocking_session_id
			, requests.wait_resource
			, querytext.text AS batch_text
			, SUBSTRING(querytext.text
						, requests.statement_start_offset / 2 + 1
						, CASE requests.statement_end_offset
							WHEN - 1 THEN DATALENGTH(querytext.text)
							ELSE (requests.statement_end_offset - requests.statement_start_offset) / 2
						END) AS statement
			, stats.last_logical_reads
			, stats.last_logical_writes
			, (stats.total_logical_reads + stats.total_logical_writes) / stats.execution_count as averageIO
			---, planxml.query_plan
FROM         sys.dm_exec_sessions AS sessions
				INNER JOIN sys.dm_exec_requests AS requests
					ON sessions.session_id = requests.session_id
				INNER JOIN sys.dm_exec_query_stats AS stats
					ON requests.sql_handle = stats.sql_handle
				CROSS APPLY sys.dm_exec_sql_text(requests.sql_handle) AS querytext
				CROSS APPLY sys.dm_exec_query_plan(requests.plan_handle) AS planxml
WHERE		sessions.is_user_process = 1
--			AND NOT sessions.program_name = N'Microsoft SQL Server Management Studio'
---			AND querytext.text NOT LIKE N'-- SQL Query Info%'
ORDER BY	averageIO DESC


