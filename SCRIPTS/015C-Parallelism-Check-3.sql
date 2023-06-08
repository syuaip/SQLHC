-- Tasks running in parallel (filtering out MARS requests below):
select * from sys.dm_os_tasks as t
 where t.session_id in (
   select t1.session_id
    from sys.dm_os_tasks as t1
   group by t1.session_id
  having count(*) > 1
  and min(t1.request_id) = max(t1.request_id));
