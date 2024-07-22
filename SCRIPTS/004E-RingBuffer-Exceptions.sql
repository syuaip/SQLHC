--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
--RB exceptions 
SELECT CONVERT (varchar(30), GETDATE(), 121) as [RunTime],
dateadd (ms, (rbf.[timestamp] - tme.ms_ticks), GETDATE()) as Time_Stamp,
cast(record as xml).value('(//Exception//Error)[1]', 'varchar(255)') as [Error],
cast(record as xml).value('(//Exception/Severity)[1]', 'varchar(255)') as [Severity],
cast(record as xml).value('(//Exception/State)[1]', 'varchar(255)') as [State],
msg.description,
cast(record as xml).value('(//Exception/UserDefined)[1]', 'int') AS [isUserDefinedError],
cast(record as xml).value('(//Record/@id)[1]', 'bigint') AS [Record Id],
cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') AS [Type],
cast(record as xml).value('(//Record/@time)[1]', 'bigint') AS [Record Time],
tme.ms_ticks as [Current Time]
from sys.dm_os_ring_buffers rbf
cross join sys.dm_os_sys_info tme
cross join sys.sysmessages msg
where rbf.ring_buffer_type = 'RING_BUFFER_EXCEPTION' --and (cast(record as xml).value('(//SPID)[1]', 'int') <> 0 --in (122,90,161,179)
and msg.error = cast(record as xml).value('(//Exception//Error)[1]', 'varchar(500)') and msg.msglangid = 1033 --and [Error] = 4002
ORDER BY rbf.timestamp ASC

 
