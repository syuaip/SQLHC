         select distinct serverproperty('machinename')                               as 'Server',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance',
                db_name(database_id)                                                 as 'DBname',
                file_id                                                              as 'File Id',
                page_id                                                              as 'Page Id',
                CASE event_type
                    WHEN 1 THEN '823 or non-specific 824 error'
                    WHEN 2 THEN 'Bad checksum'
                    WHEN 3 THEN 'Torn page'
                    ELSE NULL
                END                                                                  as 'Event Type',
                error_count                                                          as 'Error Count',
                last_update_date                                                     as 'Last Update Date'
           from msdb..suspect_pages
           where event_type in (1,2,3) 
           
