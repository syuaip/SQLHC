--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
    select  serverproperty('machinename') as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 a.name as 'Configuration Name',                                                                                  
                 a.value as 'Configured Value',                                                                                 
                 a.value_in_use as 'Run Value'                                                             
           from  master.sys.configurations a
          where  a.value != a.value_in_use
            and  a.is_dynamic = 0 
            
