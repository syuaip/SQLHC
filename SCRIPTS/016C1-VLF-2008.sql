--- THE SAMPLE CODE IS FOR NON-PRODUCTION USAGE ONLY
--- PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
--- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--- IN NO EVENT SHALL SENDER/CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
--- OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, 
--- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING 
--- IN ANY WAY OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
----
--- VLF pre-SQL2012
Create Table #stage(
    FileID      int
  , FileSize    bigint
  , StartOffset bigint
  , FSeqNo      bigint
  , [Status]    bigint
  , Parity      bigint
  , CreateLSN   numeric(38)
);
 
Create Table #results(
    Database_Name   sysname
  , VLF_count       int 
);
 
Exec sp_msforeachdb N'Use ?; 
            Insert Into #stage 
            Exec sp_executeSQL N''DBCC LogInfo(?)''; 
 
            Insert Into #results 
            Select DB_Name(), Count(*) 
            From #stage; 
 
            Truncate Table #stage;'
 
Select * 
From #results
Order By VLF_count Desc;
 
Drop Table #stage;
Drop Table #results;
