select distinct serverproperty('machinename') as 'Server',                                           
       isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance',  
       pc.cntr_value as 'Total Deadlocks'
   from master.sys.dm_os_performance_counters pc
       where pc.counter_name  = 'Number of Deadlocks/sec'
          and pc.instance_name = '_Total'
          and pc.cntr_value >= 1  
