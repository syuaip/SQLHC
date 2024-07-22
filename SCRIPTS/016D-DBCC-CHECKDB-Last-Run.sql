--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
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
