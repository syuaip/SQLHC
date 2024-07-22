--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
select serverproperty('machinename')    as 'Server',                                           
       isnull(serverproperty('instancename'),serverproperty('machinename'))  as 'Instance', 
       drive_letter   as 'Drive Letter',
       Message
        from
        (
        (
			select distinct 
		           UPPER(LEFT(LTRIM(physical_name),2)) AS drive_letter,
				   N'Device holds both tempdb and user database objects'   as 'Message',
				   1 AS OrderBy
			from master.sys.master_files
			where lower(db_name(database_id)) = 'tempdb'
			and UPPER(LEFT(LTRIM(physical_name),2)) in
				(
				select UPPER(LEFT(LTRIM(physical_name),2))
				from master.sys.master_files
				where lower(db_name(database_id)) not in (N'tempdb', N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
				)
		 )
         union
         (
			select drive_letter,
				   N'Device holds both data and log objects'   as 'Message',
				   2 AS OrderBy
			from
				(
				select drive_letter
				from 
					(
					select distinct UPPER(LEFT(LTRIM(physical_name),2)) AS drive_letter, type
					from master.sys.master_files
					where lower(db_name(database_id)) not in (N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
                    ) a
	            group by drive_letter
	            having count(1) >= 2
			    ) b
		)
		) a
		ORDER BY OrderBy, drive_letter
