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
