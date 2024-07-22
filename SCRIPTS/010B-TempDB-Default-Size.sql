--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
	select  distinct serverproperty('machinename') as 'Server',                                           
    isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance',
	 'tempdb' as 'DBname',name as 'Logical Name', physical_name as 'Physical path',(size*8/1024) as 'Size in MB' from sys.master_files [files]
	where database_id =2 and 1024 >= 
	(select sum(size) from sys.master_files 
	where  database_id =2 and type=0)
