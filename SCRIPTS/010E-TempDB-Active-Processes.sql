;WITH s AS
(
    SELECT 
        s.session_id,
        [pages] = SUM(s.user_objects_alloc_page_count 
          + s.internal_objects_alloc_page_count) 
    FROM sys.dm_db_session_space_usage AS s
    GROUP BY s.session_id
    HAVING SUM(s.user_objects_alloc_page_count 
      + s.internal_objects_alloc_page_count) > 0
)
SELECT s.session_id, s.[pages], t.[text], 
  [statement] = COALESCE(NULLIF(
    SUBSTRING(
        t.[text], 
        r.statement_start_offset / 2, 
        CASE WHEN r.statement_end_offset < r.statement_start_offset 
        THEN 0 
        ELSE( r.statement_end_offset - r.statement_start_offset ) / 2 END
      ), ''
    ), t.[text])
FROM s
LEFT OUTER JOIN 
sys.dm_exec_requests AS r
ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
ORDER BY s.[pages] DESC;
