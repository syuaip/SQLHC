Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Text.Encoding
Imports System.IO.TextWriter
Imports System.IO
Imports System.IO.Compression
Imports System.Runtime.InteropServices

Module MainModule

    Public Class IniFile
        ' API functions
        Private Declare Ansi Function GetPrivateProfileString _
          Lib "kernel32.dll" Alias "GetPrivateProfileStringA" _
          (ByVal lpApplicationName As String, _
          ByVal lpKeyName As String, ByVal lpDefault As String, _
          ByVal lpReturnedString As System.Text.StringBuilder, _
          ByVal nSize As Integer, ByVal lpFileName As String) _
          As Integer
        Private Declare Ansi Function WritePrivateProfileString _
          Lib "kernel32.dll" Alias "WritePrivateProfileStringA" _
          (ByVal lpApplicationName As String, _
          ByVal lpKeyName As String, ByVal lpString As String, _
          ByVal lpFileName As String) As Integer
        Private Declare Ansi Function GetPrivateProfileInt _
          Lib "kernel32.dll" Alias "GetPrivateProfileIntA" _
          (ByVal lpApplicationName As String, _
          ByVal lpKeyName As String, ByVal nDefault As Integer, _
          ByVal lpFileName As String) As Integer
        Private Declare Ansi Function FlushPrivateProfileString _
          Lib "kernel32.dll" Alias "WritePrivateProfileStringA" _
          (ByVal lpApplicationName As Integer, _
          ByVal lpKeyName As Integer, ByVal lpString As Integer, _
          ByVal lpFileName As String) As Integer
        Dim strFilename As String

        ' Constructor, accepting a filename
        Public Sub New(ByVal Filename As String)
            strFilename = Filename
        End Sub

        ' Read-only filename property
        ReadOnly Property FileName() As String
            Get
                Return strFilename
            End Get
        End Property

        Public Function GetString(ByVal Section As String, _
          ByVal Key As String, ByVal [Default] As String) As String
            ' Returns a string from your INI file
            Dim intCharCount As Integer
            Dim objResult As New System.Text.StringBuilder(256)
            intCharCount = GetPrivateProfileString(Section, Key, _
               [Default], objResult, objResult.Capacity, strFilename)
            If intCharCount > 0 Then GetString = _
               Left(objResult.ToString, intCharCount)
        End Function

        Public Function GetInteger(ByVal Section As String, _
          ByVal Key As String, ByVal [Default] As Integer) As Integer
            ' Returns an integer from your INI file
            Return GetPrivateProfileInt(Section, Key, _
               [Default], strFilename)
        End Function

        Public Function GetBoolean(ByVal Section As String, _
          ByVal Key As String, ByVal [Default] As Boolean) As Boolean
            ' Returns a boolean from your INI file
            Return (GetPrivateProfileInt(Section, Key, _
               CInt([Default]), strFilename) = 1)
        End Function

        Public Sub WriteString(ByVal Section As String, _
          ByVal Key As String, ByVal Value As String)
            ' Writes a string to your INI file
            WritePrivateProfileString(Section, Key, Value, strFilename)
            Flush()
        End Sub

        Public Sub WriteInteger(ByVal Section As String, _
          ByVal Key As String, ByVal Value As Integer)
            ' Writes an integer to your INI file
            WriteString(Section, Key, CStr(Value))
            Flush()
        End Sub

        Public Sub WriteBoolean(ByVal Section As String, _
          ByVal Key As String, ByVal Value As Boolean)
            ' Writes a boolean to your INI file
            WriteString(Section, Key, CStr(CInt(Value)))
            Flush()
        End Sub

        Private Sub Flush()
            ' Stores all the cached changes to your INI file
            FlushPrivateProfileString(0, 0, 0, strFilename)
        End Sub

    End Class

    Private Function GetData(ByVal conn As String, ByVal cmd As SqlCommand) As DataTable
        Dim dt As New DataTable()
        Dim strConnString As String
        strConnString = conn
        Dim con As New SqlConnection(strConnString)
        Dim sda As New SqlDataAdapter()
        cmd.CommandType = CommandType.Text
        cmd.Connection = con
        Try
            con.Open()
            sda.SelectCommand = cmd
            sda.Fill(dt)
            Return dt
        Catch ex As Exception
            ' Throw ex
            Console.WriteLine(ex.Message)
        Finally
            con.Close()
            sda.Dispose()
            con.Dispose()
        End Try
        Return dt
    End Function

    Sub Main()

        Randomize()
        Dim rndKeyInt As Integer = Rnd() * 100000
        If rndKeyInt < 100 Then rndKeyInt = 100
        Dim rndKeyStr As String = Trim(Str(rndKeyInt))

        Console.WriteLine("SQL Health-check Data Collector - (c)2016, healthcheck@serverhealth.online ")
        Console.WriteLine("")

        If Not File.Exists(Directory.GetCurrentDirectory() + "\SQLHC.ini") Then
            Console.WriteLine("Configuration file is missing. Now creating a default configuration file (connection to default SQL server instance on local server)... ")
            Dim objIniFileMissing As New IniFile(Directory.GetCurrentDirectory() + "\SQLHC.ini")
            objIniFileMissing.WriteString("Customer", "CustomerID", "10000001")
            objIniFileMissing.WriteString("Customer", "CustomerName", "PT. Kupret Indonesia Sejati")
            objIniFileMissing.WriteString("Customer", "OrderNumber", "SRQ0000001")
            objIniFileMissing.WriteString("Target", "Instance", "Default")
            objIniFileMissing.WriteString("Target", "Server", "localhost")
            objIniFileMissing.WriteString("Target", "Instance", "Default")
            objIniFileMissing.WriteString("Target", "Auth", "Windows")
            objIniFileMissing.WriteString("Target", "User", "sa")
            objIniFileMissing.WriteString("Target", "Password", "password")
            objIniFileMissing.WriteString("Target", "ScanCycles", "2")
            objIniFileMissing.WriteString("Settings", "Debug", "Off")
            Console.WriteLine("")
            ' Console.WriteLine("Default configuration file has been created. Please try running this tool once again... ")
            ' Environment.Exit(9)
            System.Threading.Thread.Sleep(500)
        End If

        Dim objIniFile As New IniFile(Directory.GetCurrentDirectory() + "\SQLHC.ini")

        Console.Write("Loading configuration... ")

        Dim strServer As String = Trim(objIniFile.GetString("Target", "Server", "(none)"))
        'Console.WriteLine("Server is : " & strServer)
        Dim strAuth As String = Trim(objIniFile.GetString("Target", "Auth", "(none)"))
        'Console.WriteLine("Auth is : " & strAuth)
        Dim strUser As String = Trim(objIniFile.GetString("Target", "User", "(none)"))
        'Console.WriteLine("User is : " & strUser)
        Dim strPassword As String = Trim(objIniFile.GetString("Target", "Password", "(none)"))
        'Console.WriteLine("Password is : " & strPassword)
        Dim connString As String

        Dim dirout As String
        dirout = Directory.GetCurrentDirectory() + "\OUTPUT\"

        ' if not exist, create OUTPUT directory.. 
        Dim di As New DirectoryInfo(dirout)
        ' Create the directory only if it does not already exist.
        If di.Exists = False Then
            di.Create()

            If Not File.Exists(dirout + rndKeyStr + ".txt") Then
                ' Create a file to write to. 
                Using sw As StreamWriter = File.CreateText(dirout + rndKeyStr + ".txt")
                    sw.WriteLine("SQL Healthcheck")
                    sw.WriteLine(My.Computer.Name)
                    sw.WriteLine(Now)
                    sw.WriteLine("serverhealth.online")
                End Using
            End If

        End If

        If strAuth <> "SQL" Then
            ' --- connection using domain account
            connString = "data source=" + strServer + ";initial catalog=master;Trusted_Connection=Yes;"
        Else
            ' --- connection using SQL connection
            connString = "data source=" + strServer + ";initial catalog=master;user id=" + strUser + ";password=" + strPassword + ";"
        End If

        Console.WriteLine("Loaded!")
        Console.WriteLine("")

        Dim queryName As String
        Dim queryString As String
        Dim queryResultFile As String

        ' Setting up SQL_IIS_HC.xml using current directory as the output store
        Console.WriteLine("Data preparation...")
        CreatePerfmonXML(dirout)
        System.Threading.Thread.Sleep(30000)

        ' Run gather driver data
        Console.WriteLine("Drivers data collectors.. ")
        Process.Start("cmd", "/c echo Collecting data. Please wait.. & msinfo32 /nfo " + dirout + "msinfo32.nfo")
        System.Threading.Thread.Sleep(5000)

        ' Run import logman, save into dirout directory 
        Console.WriteLine("Setting up performance data collectors... ")
        Process.Start("cmd", "/c echo Perfmon setup. Please wait.. & logman import -n SQLIISHC -xml SQL_IIS_HC.xml > " + dirout + "logmancreate.txt")
        System.Threading.Thread.Sleep(30000)

        ' Run start logman
        Console.WriteLine("Starting performance data collection... ")
        Process.Start("cmd", "/c echo Starting Perfmon. Please wait.. & logman start SQLIISHC > " + dirout + "logmanstart.txt")
        System.Threading.Thread.Sleep(60000)

        ' run Healthcheck 'standard' queries 
        Console.WriteLine("Starting standard queries data collection... ")
        ' create an array of script title, script text 
        ' loop the array
        '   try, display the script title and run the script
        '   write script output to scripttitle.CSV file 
        ' end loop

        ' run Healthcheck additional queries 
        Console.WriteLine("Starting additional queries data collection... ")
        Dim dirScript As String
        dirScript = Directory.GetCurrentDirectory() + "\SCRIPTS\"
        Dim diScript As New DirectoryInfo(dirScript)
        ' Run additional queries only of the script exist.
        If diScript.Exists Then
            Try
                ' Only get files that has file extension of ".sql" (a.k.a. only SQL scripts) 
                Dim dirs As String() = Directory.GetFiles(Directory.GetCurrentDirectory() + "\SCRIPTS", "*.sql")
                Console.WriteLine("Found {0} additional scripts to execute...", dirs.Length)
                Dim dir As String
                For Each dir In dirs
                    ' Console.WriteLine(dir)
                    queryString = File.ReadAllText(dir)

                    ' Loop starts here

                    queryName = ""
                    ' queryResultFile = dir + ".csv"
                    queryResultFile = dirout + Path.GetFileName(dir) + ".csv"

                    Console.Write("Processing " & Path.GetFileName(dir) & "... ")

                    Dim command As New SqlCommand(queryString)
                    command.CommandTimeout = 1800 ' 30 minutes execution timeout
                    Dim dt As DataTable = GetData(connString, command)
                    Try
                        Using writer As StreamWriter = New StreamWriter(queryResultFile, False, Text.Encoding.UTF8)
                            Rfc4180Writer.WriteDataTable(dt, writer, True)
                        End Using
                    Catch ex As Exception
                        ' Throw ex
                        Console.Write("Got an error: " & ex.Message)
                    Finally
                        Console.WriteLine("Done!")
                        command.Dispose()
                        dt.Dispose()
                    End Try

                    System.Threading.Thread.Sleep(2000)
                    ' Loop ends here

                Next
            Catch e As Exception
                Console.WriteLine("The process failed: {0}", e.ToString())
            End Try
        End If
        Console.WriteLine("Flushing temp data... ")
        System.Threading.Thread.Sleep(30000)

        ' Run stop logman
        Console.WriteLine("Compiling performance data collection... ")
        Process.Start("cmd", "/c echo Stopping Perfmon. Please wait.. & logman stop SQLIISHC > " + dirout + "logmanstop.txt")
        System.Threading.Thread.Sleep(60000)

        ' Run delete logman
        Console.WriteLine("Removing performance data collectors... ")
        Process.Start("cmd", "/c echo Clearing Perfmon. Please wait.. & logman delete SQLIISHC > " + dirout + "logmandelete.txt")
        System.Threading.Thread.Sleep(15000)

        ' Run gather WMI data (CPU core, disk alignment)
        Console.WriteLine("WMI data collectors.. ")
        Process.Start("cmd", "/c echo Looking at CPU. Please wait.. & wmic cpu get NumberOfCores, NumberOfLogicalProcessors/Format:List > " + dirout + "wmiccpucores.txt")
        System.Threading.Thread.Sleep(500)
        Process.Start("cmd", "/c echo Looking at Disk(s). Please wait.. & wmic partition get BlockSize, StartingOffset, Name, Index > " + dirout + "wmicdiskalignment.txt")
        System.Threading.Thread.Sleep(500)

        ' Run gather Windows patches data
        Console.WriteLine("Installed KB data collectors.. ")
        Process.Start("cmd", "/c echo Looking at installed KBs. Please wait.. & wmic qfe list /format:csv > " + dirout + "kblistinstalled.txt")
        System.Threading.Thread.Sleep(500)

        ' Run gather driver data
        Console.WriteLine("Drivers data collectors.. ")
        Process.Start("cmd", "/c echo Looking at installed drivers. Please wait.. & driverquery /v >" + dirout + "driverquery.txt")
        System.Threading.Thread.Sleep(500)

        ' Run gather system uptime
        Console.WriteLine("Checking system information.. ")
        Process.Start("cmd", "/c echo Checking uptime. Please wait.. & net statistics server > " + dirout + "netstatssvr.txt")
        System.Threading.Thread.Sleep(500)
        Process.Start("cmd", "/c echo Checking system info. Please wait.. & systeminfo > " + dirout + "systeminfo.txt")
        System.Threading.Thread.Sleep(500)

        ' Run gather network setup data
        Console.WriteLine("Network setup data collectors.. ")
        Process.Start("cmd", "/c echo Looking at network interface(s). Please wait.. & ipconfig /all > " + dirout + "netipconfigall.txt")
        System.Threading.Thread.Sleep(500)
        Process.Start("cmd", "/c echo Looking at global NIC setup. Please wait.. & netsh interface show interface > " + dirout + "netshintshint.txt")
        System.Threading.Thread.Sleep(500)
        Process.Start("cmd", "/c echo Looking at global TCP setup. Please wait.. & netsh interface tcp show global > " + dirout + "netshinttcpshglorsschimney.txt")
        System.Threading.Thread.Sleep(500)

        ' Run gather memory dump data
        Console.WriteLine("Memory dump data collectors.. ")
        Process.Start("cmd", "/c echo Looking for memory dump file. Please wait.. & dir %systemroot%\memory.dmp > " + dirout + "memorydmp.txt")
        System.Threading.Thread.Sleep(500)
        Process.Start("cmd", "/c echo Looking for mini dump files. Please wait.. & dir %systemroot%\minidump\*.* > " + dirout + "meminidump.txt")
        System.Threading.Thread.Sleep(500)
        Process.Start("cmd", "/c echo Fetching mini dump files. Please wait.. & copy /Y /Z /B %systemroot%\minidump\*.* " + dirout + "")
        System.Threading.Thread.Sleep(2000)

        ' Run gather system event log data txt
        Console.WriteLine("System Eventlog text data collector... ")
        Process.Start("cmd", "/c echo Getting system log text files. Please wait.. & WEVTutil query-events System /count:30000 /rd:true /format:text > " + dirout + "evtsys.txt")
        System.Threading.Thread.Sleep(10000)

        ' Run gather system event log data xml
        Console.WriteLine("System Eventlog XML data collector... ")
        Process.Start("cmd", "/c echo Getting system log XML files. Please wait.. & WEVTutil query-events System /count:30000 /rd:true /format:XML > " + dirout + "evtsys.xml")
        System.Threading.Thread.Sleep(10000)

        ' Run gather apps event log data txt
        Console.WriteLine("Application Eventlog text data collector... ")
        Process.Start("cmd", "/c echo Getting application log text files. Please wait.. & WEVTutil query-events Application /count:30000 /rd:true /format:text > " + dirout + "evtapps.txt")
        System.Threading.Thread.Sleep(10000)

        ' Run gather apps event log data xml
        Console.WriteLine("Application Eventlog XML data collector... ")
        Process.Start("cmd", "/c echo Getting application log XML files. Please wait.. & WEVTutil query-events Application /count:30000 /rd:true /format:XML > " + dirout + "evtapps.xml")
        System.Threading.Thread.Sleep(10000)

        ' Run gather system event log data txt
        Console.WriteLine("System dump check data collector... ")
        Process.Start("cmd", "/c echo Checking system log for crash dump(s). Please wait.. & WEVTutil query-events System /count:3000 /rd:true /format:text /q:""Event[System[(EventID=1001)]]"" > " + dirout + "evtsys001001.txt")
        System.Threading.Thread.Sleep(2000)

        ' global wait, preparing for compression
        Console.Write("Waiting for any outstanding data collections... ")
        System.Threading.Thread.Sleep(20000) ' TODO: loop and check for all required data files existence and wait for total of 15 minutes
        Console.WriteLine("Moving on! ")

        Console.Write("Compressing temporary data... ")
        ' if exist, delete SQLHC output file
        If File.Exists(Directory.GetCurrentDirectory() + "\SQLHC_output.zip") Then File.Delete(Directory.GetCurrentDirectory() + "\SQLHC_output.zip")
        ' if exist, delete SQLHC temp file
        If File.Exists(Directory.GetCurrentDirectory() + "\SQLHC_temp.zip") Then File.Delete(Directory.GetCurrentDirectory() + "\SQLHC_temp.zip")

        Console.Write("Compressing all gathered data... ")
        Try
            ZipFile.CreateFromDirectory(dirout, "SQLHC_temp.zip")
        Catch e As Exception
            Console.WriteLine("The process failed: {0}", e.ToString())
        End Try
        System.Threading.Thread.Sleep(60000)

        ' put onto a passworded zip as encapsulator 
        Using Zip As New Ionic.Zip.ZipFile()
            Zip.Password = "p4s5w0rdhaha!" + rndKeyStr
            Zip.AddFile(Directory.GetCurrentDirectory() + "\SQL_IIS_HC.xml", "")
            Zip.Password = "p4s5w0rdhaha!"
            Zip.AddFile(Directory.GetCurrentDirectory() + "\SQLHC_temp.zip", "")

            If Not File.Exists(dirout + rndKeyStr + ".txt") Then
                ' Create a file to write to. 
                Using sw As StreamWriter = File.CreateText(dirout + rndKeyStr + ".txt")
                    sw.WriteLine("SQL Healthcheck")
                    sw.WriteLine(My.Computer.Name)
                    sw.WriteLine(Now)
                    sw.WriteLine("serverhealth.online")
                End Using
            End If

            Zip.Password = Nothing
            Zip.AddFile(dirout + rndKeyStr + ".txt", "")

            Zip.Save("SQLHC_output.zip")
        End Using
        System.Threading.Thread.Sleep(60000)

        ' if exist, delete SQLHC temp file
        If File.Exists(Directory.GetCurrentDirectory() + "\SQLHC_temp.zip") Then File.Delete(Directory.GetCurrentDirectory() + "\SQLHC_temp.zip")
        If File.Exists("SQL_IIS_HC.xml") Then File.Delete("SQL_IIS_HC.xml")

        ' if exist, delete content of OUTPUT directory, and delete the OUTPUT directory
        Try
            ' Only get files that has file extension of ".csv" (a.k.a. only SQL execution result) 
            ' Dim outputfiles As String() = Directory.GetFiles(Directory.GetCurrentDirectory() + "\OUTPUT", "*.csv")
            ' Console.WriteLine("Found {0} files to remove...", outputfiles.Length)
            ' Dim outputfile As String
            ' For Each outputfile In outputfiles
            '  File.Delete(outputfile)
            ' Next
            Directory.Delete(dirout, True)
            System.Threading.Thread.Sleep(2000)

        Catch e As Exception
            Console.WriteLine("The process failed: {0}", e.ToString())
        End Try

        Console.WriteLine("Finished!")
        Console.WriteLine("")
        Console.WriteLine("Please send the SQLHC_output.zip file to this email address:")
        Console.WriteLine("")
        Console.WriteLine("analysis@serverhealth.online")

    End Sub

    Public Class Rfc4180Writer
        Public Shared Sub WriteDataTable(ByVal sourceTable As DataTable, _
         ByVal writer As TextWriter, ByVal includeHeaders As Boolean)
            If (includeHeaders) Then
                Dim headerValues As IEnumerable(Of String) = sourceTable.Columns.OfType(Of DataColumn)().Select(Function(column) QuoteValue(column.ColumnName))
                writer.WriteLine(String.Join(",", headerValues))
            End If

            Dim items As IEnumerable(Of String) = Nothing
            Dim enc8 As Text.Encoding = UTF8
            For Each row As DataRow In sourceTable.Rows
                ' items = row.ItemArray.Select(Function(obj) QuoteValue(obj.ToString()))
                items = row.ItemArray.Select(Function(obj) QuoteValue(obj))
                writer.WriteLine(String.Join(",", items))
            Next

            writer.Flush()
        End Sub

        Private Shared Function ResponseToString(ByVal obj) As String
            Dim Response As String
            Response = ""
            For Each Item As Byte In obj
                Response = Response & Chr(Item)
            Next

            Return Response
        End Function

        ' Private Shared Function QuoteValue(ByVal value As String) As String
        Private Shared Function QuoteValue(ByVal value) As String
            ' Dim str = Text.ASCIIEncoding.GetString(value)
            Dim str As String
            If value.ToString = "System.Byte[]" Then
                ' str = System.Text.Encoding.UTF8.GetString(value)
                ' str = ResponseToString(value)
                str = "0x" + BitConverter.ToString(value).Replace("-", String.Empty)
            Else
                str = value.ToString
            End If
            Return String.Concat("""", str.Replace("""", """"""), """")
        End Function


    End Class

    Private Sub CreatePerfmonXML(ByVal vdirout As String)
        If File.Exists("SQL_IIS_HC.xml") Then File.Delete("SQL_IIS_HC.xml")
        System.Threading.Thread.Sleep(5000)
        If Not File.Exists("SQL_IIS_HC.xml") Then
            ' Create a file to write to. 
            Using sw As StreamWriter = File.CreateText("SQL_IIS_HC.xml")
                sw.WriteLine("<?xml version=""1.0"" encoding=""UTF-8""?>")
                sw.WriteLine("<DataCollectorSet>")
                sw.WriteLine("<Status>1</Status>")
                sw.WriteLine("<Duration>0</Duration>")
                sw.WriteLine("<Description>")
                sw.WriteLine("</Description>")
                sw.WriteLine("<DescriptionUnresolved>")
                sw.WriteLine("</DescriptionUnresolved>")
                sw.WriteLine("<DisplayName>")
                sw.WriteLine("</DisplayName>")
                sw.WriteLine("<DisplayNameUnresolved>")
                sw.WriteLine("</DisplayNameUnresolved>")
                sw.WriteLine("<SchedulesEnabled>-1</SchedulesEnabled>")
                sw.WriteLine("<LatestOutputLocation>" + vdirout + "</LatestOutputLocation>")
                sw.WriteLine("<Name>SQL_IIS_HC</Name>")
                sw.WriteLine("<OutputLocation>" + vdirout + "</OutputLocation>")
                sw.WriteLine("<RootPath>" + vdirout + "</RootPath>")
                sw.WriteLine("<Segment>-1</Segment>")
                sw.WriteLine("<SegmentMaxDuration>86400</SegmentMaxDuration>")
                sw.WriteLine("<SegmentMaxSize>0</SegmentMaxSize>")
                sw.WriteLine("<SerialNumber>1</SerialNumber>")
                sw.WriteLine("<Server>")
                sw.WriteLine("</Server>")
                sw.WriteLine("<Subdirectory>")
                sw.WriteLine("</Subdirectory>")
                sw.WriteLine("<SubdirectoryFormat>1</SubdirectoryFormat>")
                sw.WriteLine("<SubdirectoryFormatPattern>")
                sw.WriteLine("</SubdirectoryFormatPattern>")
                sw.WriteLine("<Task>")
                sw.WriteLine("</Task>")
                sw.WriteLine("<TaskRunAsSelf>0</TaskRunAsSelf>")
                sw.WriteLine("<TaskArguments>")
                sw.WriteLine("</TaskArguments>")
                sw.WriteLine("<TaskUserTextArguments>")
                sw.WriteLine("</TaskUserTextArguments>")
                sw.WriteLine("<UserAccount>SYSTEM</UserAccount>")
                sw.WriteLine("<Security>O:BAG:S-1-5-21-2952966170-3714788709-2525979044-513D:AI(A;;FA;;;SY)(A;;FA;;;BA)(A;;FR;;;LU)(A;;0x1301ff;;;S-1-5-80-2661322625-712705077-2999183737-3043590567-590698655)(A;ID;FA;;;SY)(A;ID;FA;;;BA)(A;ID;0x1200ab;;;LU)(A;ID;FR;;;AU)(A;ID;FR;;;LS)(A;ID;FR;;;NS)</Security>")
                sw.WriteLine("<StopOnCompletion>0</StopOnCompletion>")
                sw.WriteLine("<PerformanceCounterDataCollector>")
                sw.WriteLine("<DataCollectorType>0</DataCollectorType>")
                sw.WriteLine("<Name>HealthCheck</Name>")
                sw.WriteLine("<FileName>Perfmon</FileName>")
                sw.WriteLine("<FileNameFormat>3</FileNameFormat>")
                sw.WriteLine("<FileNameFormatPattern>yyyyMMdd\_HHmm\_N</FileNameFormatPattern>")
                sw.WriteLine("<LogAppend>0</LogAppend>")
                sw.WriteLine("<LogCircular>0</LogCircular>")
                sw.WriteLine("<LogOverwrite>0</LogOverwrite>")
                sw.WriteLine("<LatestOutputLocation>" + vdirout + "1.blg</LatestOutputLocation>")
                sw.WriteLine("<DataSourceName>")
                sw.WriteLine("</DataSourceName>")
                sw.WriteLine("<SampleInterval>15</SampleInterval>")
                sw.WriteLine("<SegmentMaxRecords>0</SegmentMaxRecords>")
                sw.WriteLine("<LogFileFormat>3</LogFileFormat>")
                sw.WriteLine("<Counter>\.NET CLR Exceptions(*)\# of Exceps Thrown / sec</Counter>")
                sw.WriteLine("<Counter>\.NET CLR Memory(_Global_)\% Time in GC</Counter>")
                sw.WriteLine("<Counter>\Active Server Pages\Errors/Sec</Counter>")
                sw.WriteLine("<Counter>\Active Server Pages\Request Execution Time</Counter>")
                sw.WriteLine("<Counter>\Active Server Pages\Request Wait Time</Counter>")
                sw.WriteLine("<Counter>\Active Server Pages\Requests Executing</Counter>")
                sw.WriteLine("<Counter>\Active Server Pages\Requests Queued</Counter>")
                sw.WriteLine("<Counter>\Active Server Pages\Requests Timed Out</Counter>")
                sw.WriteLine("<Counter>\Active Server Pages\Requests/Sec</Counter>")
                sw.WriteLine("<Counter>\ASP.NET\Applications Running</Counter>")
                sw.WriteLine("<Counter>\ASP.NET\Error Events Raised</Counter>")
                sw.WriteLine("<Counter>\ASP.NET\Request Execution Time</Counter>")
                sw.WriteLine("<Counter>\ASP.NET\Request Wait Time</Counter>")
                sw.WriteLine("<Counter>\ASP.NET\Requests Current</Counter>")
                sw.WriteLine("<Counter>\ASP.NET\Requests Queued</Counter>")
                sw.WriteLine("<Counter>\Processor(*)\*</Counter>")
                sw.WriteLine("<Counter>\Processor Performance(*)\*</Counter>")
                sw.WriteLine("<Counter>\PhysicalDisk(*)\% Idle Time</Counter>")
                sw.WriteLine("<Counter>\PhysicalDisk(*)\Avg. Disk Queue Length</Counter>")
                sw.WriteLine("<Counter>\PhysicalDisk(*)\Avg. Disk Read Queue Length</Counter>")
                sw.WriteLine("<Counter>\PhysicalDisk(*)\Avg. Disk sec/Read</Counter>")
                sw.WriteLine("<Counter>\PhysicalDisk(*)\Avg. Disk sec/Write</Counter>")
                sw.WriteLine("<Counter>\PhysicalDisk(*)\Avg. Disk Write Queue Length</Counter>")
                sw.WriteLine("<Counter>\PhysicalDisk(*)\Disk Read Bytes/sec</Counter>")
                sw.WriteLine("<Counter>\PhysicalDisk(*)\Disk Write Bytes/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Wait Statistics\*</Counter>")
                sw.WriteLine("<Counter>\System\Context Switches/sec</Counter>")
                sw.WriteLine("<Counter>\System\Processor Queue Length</Counter>")
                sw.WriteLine("<Counter>\Process(*)\% Privileged Time</Counter>")
                sw.WriteLine("<Counter>\Process(*)\% Processor Time</Counter>")
                sw.WriteLine("<Counter>\Process(*)\Elapsed Time</Counter>")
                sw.WriteLine("<Counter>\Process(*)\IO Data Operations/sec</Counter>")
                sw.WriteLine("<Counter>\Process(*)\IO Other Operations/sec</Counter>")
                sw.WriteLine("<Counter>\Process(*)\IO Read Operations/sec</Counter>")
                sw.WriteLine("<Counter>\Process(*)\IO Write Operations/sec</Counter>")
                sw.WriteLine("<Counter>\Process(*)\Private Bytes</Counter>")
                sw.WriteLine("<Counter>\Process(*)\Thread Count</Counter>")
                sw.WriteLine("<Counter>\Process(*)\Virtual Bytes</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Access Methods\FreeSpace Scans/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Access Methods\Full Scans/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Access Methods\Index Searches/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Access Methods\Probe Scans/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Access Methods\Range Scans/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Access Methods\Scan Point Revalidations/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Access Methods\Table Lock Escalations/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Access Methods\Workfiles Created/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Access Methods\Worktables Created/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Buffer Manager\Buffer cache hit ratio</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Buffer Manager\Database pages</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Buffer Manager\Lazy writes/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Buffer Manager\Page life expectancy</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Databases(*)\Active Transactions</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Databases(*)\Data File(s) Size (KB)</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Databases(*)\Log File(s) Size (KB)</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Databases(*)\Log File(s) Used Size (KB)</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Databases(*)\Percent Log Used</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Databases(*)\Transactions/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Latches\Average Latch Wait Time (ms)</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Latches\Total Latch Wait Time (ms)</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Locks(_Total)\Average Wait Time (ms)</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Locks(_Total)\Lock Requests/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Locks(_Total)\Lock Timeouts/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Locks(_Total)\Lock Wait Time (ms)</Counter>")
                sw.WriteLine("<Counter>\SQLServer:Locks(_Total)\Number of Deadlocks/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:SQL Statistics\Batch Requests/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:SQL Statistics\SQL Attention rate</Counter>")
                sw.WriteLine("<Counter>\SQLServer:SQL Statistics\SQL Compilations/sec</Counter>")
                sw.WriteLine("<Counter>\SQLServer:SQL Statistics\SQL Re-Compilations/sec</Counter>")
                sw.WriteLine("<Counter>\Memory\% Committed Bytes In Use</Counter>")
                sw.WriteLine("<Counter>\Memory\Available MBytes</Counter>")
                sw.WriteLine("<Counter>\Memory\Commit Limit</Counter>")
                sw.WriteLine("<Counter>\Memory\Committed Bytes</Counter>")
                sw.WriteLine("<Counter>\Memory\Page Faults/sec</Counter>")
                sw.WriteLine("<Counter>\Memory\Page Reads/sec</Counter>")
                sw.WriteLine("<Counter>\Memory\Page Writes/sec</Counter>")
                sw.WriteLine("<Counter>\Memory\Pages Input/sec</Counter>")
                sw.WriteLine("<Counter>\Memory\Pages Output/sec</Counter>")
                sw.WriteLine("<Counter>\Memory\Pages/sec</Counter>")
                sw.WriteLine("<Counter>\Paging File\*</Counter>")
                sw.WriteLine("<CounterDisplayName>\.NET CLR Exceptions(*)\# of Exceps Thrown / sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\.NET CLR Memory(_Global_)\% Time in GC</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Active Server Pages\Errors/Sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Active Server Pages\Request Execution Time</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Active Server Pages\Request Wait Time</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Active Server Pages\Requests Executing</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Active Server Pages\Requests Queued</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Active Server Pages\Requests Timed Out</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Active Server Pages\Requests/Sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\ASP.NET\Applications Running</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\ASP.NET\Error Events Raised</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\ASP.NET\Request Execution Time</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\ASP.NET\Request Wait Time</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\ASP.NET\Requests Current</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\ASP.NET\Requests Queued</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Processor(*)\*</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Processor Performance(*)\*</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\PhysicalDisk(*)\% Idle Time</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\PhysicalDisk(*)\Avg. Disk Queue Length</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\PhysicalDisk(*)\Avg. Disk Read Queue Length</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\PhysicalDisk(*)\Avg. Disk sec/Read</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\PhysicalDisk(*)\Avg. Disk sec/Write</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\PhysicalDisk(*)\Avg. Disk Write Queue Length</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\PhysicalDisk(*)\Disk Read Bytes/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\PhysicalDisk(*)\Disk Write Bytes/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Wait Statistics\*</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\System\Context Switches/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\System\Processor Queue Length</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Process(*)\% Privileged Time</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Process(*)\% Processor Time</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Process(*)\Elapsed Time</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Process(*)\IO Data Operations/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Process(*)\IO Other Operations/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Process(*)\IO Read Operations/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Process(*)\IO Write Operations/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Process(*)\Private Bytes</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Process(*)\Thread Count</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Process(*)\Virtual Bytes</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Access Methods\FreeSpace Scans/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Access Methods\Full Scans/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Access Methods\Index Searches/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Access Methods\Probe Scans/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Access Methods\Range Scans/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Access Methods\Scan Point Revalidations/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Access Methods\Table Lock Escalations/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Access Methods\Workfiles Created/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Access Methods\Worktables Created/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Buffer Manager\Buffer cache hit ratio</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Buffer Manager\Database pages</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Buffer Manager\Lazy writes/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Buffer Manager\Page life expectancy</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Databases(*)\Active Transactions</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Databases(*)\Data File(s) Size (KB)</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Databases(*)\Log File(s) Size (KB)</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Databases(*)\Log File(s) Used Size (KB)</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Databases(*)\Percent Log Used</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Databases(*)\Transactions/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Latches\Average Latch Wait Time (ms)</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Latches\Total Latch Wait Time (ms)</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Locks(_Total)\Average Wait Time (ms)</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Locks(_Total)\Lock Requests/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Locks(_Total)\Lock Timeouts/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Locks(_Total)\Lock Wait Time (ms)</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:Locks(_Total)\Number of Deadlocks/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:SQL Statistics\Batch Requests/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:SQL Statistics\SQL Attention rate</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:SQL Statistics\SQL Compilations/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\SQLServer:SQL Statistics\SQL Re-Compilations/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Memory\% Committed Bytes In Use</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Memory\Available MBytes</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Memory\Commit Limit</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Memory\Committed Bytes</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Memory\Page Faults/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Memory\Page Reads/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Memory\Page Writes/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Memory\Pages Input/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Memory\Pages Output/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Memory\Pages/sec</CounterDisplayName>")
                sw.WriteLine("<CounterDisplayName>\Paging File\*</CounterDisplayName>")
                sw.WriteLine("</PerformanceCounterDataCollector>")
                sw.WriteLine("<Schedule>")
                sw.WriteLine("	<StartDate>8/17/2014</StartDate>")
                sw.WriteLine("	<EndDate>")
                sw.WriteLine("	</EndDate>")
                sw.WriteLine("	<StartTime>")
                sw.WriteLine("	</StartTime>")
                sw.WriteLine("	<Days>127</Days>")
                sw.WriteLine("</Schedule>")
                sw.WriteLine("<Schedule>")
                sw.WriteLine("	<StartDate>8/17/2014</StartDate>")
                sw.WriteLine("	<EndDate>")
                sw.WriteLine("	</EndDate>")
                sw.WriteLine("	<StartTime>12:00:00 PM</StartTime>")
                sw.WriteLine("	<Days>127</Days>")
                sw.WriteLine("</Schedule>")
                sw.WriteLine("<DataManager>")
                sw.WriteLine("	<Enabled>-1</Enabled>")
                sw.WriteLine("	<CheckBeforeRunning>-1</CheckBeforeRunning>")
                sw.WriteLine("	<MinFreeDisk>0</MinFreeDisk>")
                sw.WriteLine("	<MaxSize>3000</MaxSize>")
                sw.WriteLine("	<MaxFolderCount>0</MaxFolderCount>")
                sw.WriteLine("	<ResourcePolicy>1</ResourcePolicy>")
                sw.WriteLine("	<ReportFileName>report.html</ReportFileName>")
                sw.WriteLine("	<RuleTargetFileName>report.xml</RuleTargetFileName>")
                sw.WriteLine("	<EventsFileName>")
                sw.WriteLine("	</EventsFileName>")
                sw.WriteLine("	<FolderAction>")
                sw.WriteLine("		<Size>3000</Size>")
                sw.WriteLine("		<Age>21</Age>")
                sw.WriteLine("		<Actions>18</Actions>")
                sw.WriteLine("		<SendCabTo>")
                sw.WriteLine("		</SendCabTo>")
                sw.WriteLine("	</FolderAction>")
                sw.WriteLine("</DataManager>")
                sw.WriteLine("</DataCollectorSet>")

            End Using
        End If
    End Sub

End Module

