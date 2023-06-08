declare @dbid    int
declare @maxdbid int
declare @string  nvarchar(4000)
declare @dbname  sysname 

DROP TABLE IF EXISTS #dbinfo_table
DROP TABLE IF EXISTS #dbinfo_2000

create table  #dbinfo_table (server_name   nvarchar(255), 
                           instance_name nvarchar(255), 
                           database_name nvarchar(255), 
                           database_id   int, 
                           value         nvarchar(255))

create table #dbinfo_2000(ParentObject  varchar(255),
                              Object        varchar(255),
                              Field         varchar(255),
                              value         varchar(255))

		  set quoted_identifier off
          set nocount on 

          set @dbid    = 1
          set @maxdbid = (select max(dbid) from master..sysdatabases)

          while @dbid <= @maxdbid
                begin
                     if  null = (select db_name(@dbid))
                         set @dbid = @dbid + 1
                     else if lower(db_name(@dbid)) = N'tempdb'
						 set @dbid = @dbid + 1
                     else if N'ONLINE' <> (select state_desc from sys.databases where database_id = @dbid)
                         set @dbid = @dbid + 1
                     else 
                         begin 
                              set @dbname = db_name(@dbid)

                              set @string = "INSERT INTO #dbinfo_2000 EXEC('DBCC DBINFO(''" + rtrim(ltrim(@dbname)) + "'') WITH TABLERESULTS, NO_INFOMSGS')";
 
                              execute sp_executesql @string

                              insert into #dbinfo_table
                              select distinct  
                                     convert(sysname,(serverproperty('machinename'))),
                                     isnull((convert(sysname,(serverproperty('instancename')))),convert(sysname,(serverproperty('machinename')))),
                                     db_name(@dbid),
                                     @dbid,
                                     value
                                from #dbinfo_2000
                               where Field = 'dbi_dbccLastKnownGood'

                              delete from #dbinfo_2000

							  set @dbid = @dbid + 1

                         end
                end

                select server_name                      as 'Server',                                           
                       instance_name                    as 'Instance', 
                       database_name                    as 'DBname',
                       database_id                      as 'DBID',
                       CASE value
						WHEN N'1900-01-01 00:00:00.000' THEN 'Never'
						ELSE value
                       END								as 'Date of last DBCC CHECKDB',
                       CASE value
						WHEN N'1900-01-01 00:00:00.000' THEN 'Never'
                        ELSE CONVERT(nvarchar(10),DATEDIFF(day,convert(datetime,([value])),GETDATE()))
					   END								as 'Days Since Last DBCC CHECKDB'
                  from #dbinfo_table
                 where DATEDIFF(day,convert(datetime,([value])),GETDATE()) > 0
                 order by 'Server','Instance','DBname'

                set quoted_identifier on

DROP TABLE IF EXISTS #dbinfo_table
DROP TABLE IF EXISTS #dbinfo_2000
