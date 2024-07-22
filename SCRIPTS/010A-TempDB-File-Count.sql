--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
 create table #msver_info(ID              int,  
                           Name            sysname, 
                           Internal_Value  int, 
                           Value           nvarchar(512))
 insert #msver_info exec master.dbo.xp_msver

          select distinct serverproperty('machinename')                                               as 'Server',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename'))        as 'Instance', 
                 db_name(a.database_id)														 as 'DBname',
                 a.database_id                                                               as 'DBID',
                 (select Internal_Value from #msver_info where Name = N'ProcessorCount')    as 'Processor Count',
                 (select count(b.physical_name) 
                    from master.sys.master_files b 
                   where b.type = 0
                     and b.database_id = 2)                                                  as 'File Count',
                  case  
                        when (select count(c.physical_name) 
                              from master.sys.master_files c 
                              where c.type = 0
                              and c.database_id = 2)
                            < 
                            (select Internal_Value 
                             from #msver_info 
                             where Name = N'ProcessorCount')
                        then 'Fewer tempdb data device files than processors'
                        when 1 = (select count(1) from                     
                        (
                            select  c.size, count(1) as counter
                            from    master.sys.master_files c
                            where   c.type = 0
                            and c.database_id = 2
                            group by c.size
                        ) as c)
                        then 'All tempdb data device files sized identically'
                        else 'Different sized tempdb data device files detected'
                        end                                                                  as 'Tempdb Data Device Filecount/Size Message'
           from master.sys.master_files a
          where a.type = 0
            and a.database_id = 2
            and (
                (select count(c.physical_name) 
                    from master.sys.master_files c 
                   where c.type = 0
                     and c.database_id = 2) <= (select Internal_Value 
                                                  from #msver_info 
                                                 where Name = N'ProcessorCount')
                 or
                 1 <> (select count(1) from                     
                        (
                            select  c.size, count(1) as counter
                            from    master.sys.master_files c
                            where   c.type = 0
                            and c.database_id = 2
                            group by c.size
                        ) as c)
                )
 drop table #msver_info;

