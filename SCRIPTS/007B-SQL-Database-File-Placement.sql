--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
select distinct serverproperty('machinename') as 'Server',                                           
       isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance', 
       db_name(a.database_id) as 'DBname',
       a.database_id  as 'DBID',
           (case a.type
                 when 0 then 'Data File'
                 when 1 then 'Log File'
                 when 4 then 'Full Text Catalog File'
                 else null
            end)  as 'File Type',
       a.physical_name  as 'File Physical Location',
       ltrim(str((convert (dec (15,2),a.size)) * 8192 / 1048576,15,2) + ' MB') as 'File Size'
 from master.sys.master_files a
       where lower(db_name(a.database_id)) not in (N'master', N'msdb', N'model', N'pubs')
       order by 'DBname', 'File Type', 'File Physical Location'
