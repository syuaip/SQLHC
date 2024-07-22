--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
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
           
