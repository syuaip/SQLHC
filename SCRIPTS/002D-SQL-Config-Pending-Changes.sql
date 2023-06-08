         select  serverproperty('machinename') as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 a.name as 'Configuration Name',                                                                                  
                 a.value as 'Configured Value',                                                                                 
                 a.value_in_use as 'Run Value'                                                             
           from  master.sys.configurations a
          where  a.value != a.value_in_use
            and  a.is_dynamic = 0 
            
