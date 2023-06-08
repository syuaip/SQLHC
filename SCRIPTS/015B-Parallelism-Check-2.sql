-- Requests running in parallel:
 select *
   from sys.dm_exec_requests as r
   join (
           select t1.session_id, min(t1.request_id)
          from sys.dm_os_tasks as t1
         group by t1.session_id
        having count(*) > 1
           and min(t1.request_id) = max(t1.request_id)
      ) as t(session_id, request_id)
     on r.session_id = t.session_id
    and r.request_id = t.request_id;
