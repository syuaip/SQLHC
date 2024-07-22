--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
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
