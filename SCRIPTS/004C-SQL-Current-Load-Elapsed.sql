SELECT   qt.TEXT query_name,
         dm_tran_active_snapshot_database_transactions.transaction_id,
         transaction_sequence_num,
         elapsed_time_seconds, sys.dm_exec_requests.session_id
FROM     sys.dm_tran_active_snapshot_database_transactions,
         sys.dm_tran_session_transactions,
         sys.dm_exec_requests
         OUTER APPLY sys.Dm_exec_sql_text(sql_handle) qt
WHERE    sys.dm_tran_active_snapshot_database_transactions.transaction_id = sys.dm_tran_session_transactions.transaction_id
         AND sys.dm_exec_requests.session_id = sys.dm_tran_session_transactions.session_id
ORDER BY elapsed_time_seconds DESC
