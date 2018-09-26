Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Text.Encoding
Imports System.IO.TextWriter
Imports System.IO
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

        Console.WriteLine("SQL Health-Check Data Collector - headmechanics@sqlgarage.org")
        Console.WriteLine("")

        Dim objIniFile As New IniFile(Directory.GetCurrentDirectory() + "\SQLHC.ini")
        'objIniFile.WriteString("Target", "Server", "HOSTNAME\instancename")
        'objIniFile.WriteString("Target", "Auth", "SQL")
        'objIniFile.WriteString("Target", "User", "sa")
        'objIniFile.WriteString("Target", "Password", "password")
        'objIniFile.WriteString("Target", "Debug", "Off")

        Console.Write("Loading configuration... ")

        Dim strServer As String = objIniFile.GetString("Target", "Server", "(none)")
        'Console.WriteLine("Server is : " & strServer)
        Dim strAuth As String = objIniFile.GetString("Target", "Auth", "(none)")
        'Console.WriteLine("Auth is : " & strAuth)
        Dim strUser As String = objIniFile.GetString("Target", "User", "(none)")
        'Console.WriteLine("User is : " & strUser)
        Dim strPassword As String = objIniFile.GetString("Target", "Password", "(none)")
        'Console.WriteLine("Password is : " & strPassword)
        Dim connString As String
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

        Console.WriteLine("Collection started...")
        Console.WriteLine("")

        ' Loop starts here

        queryName = "Active processes"
        queryString = "SELECT @@ServerName AS ServerName,* FROM sys.sysprocesses ORDER BY cpu DESC"
        queryResultFile = "A0001_sysprocesses.csv"

        Console.WriteLine("Fetching " & queryName & " onto " & queryResultFile & "... ")

        Dim command As New SqlCommand(queryString)
        Dim dt As DataTable = GetData(connString, command)
        Try
            Using writer As StreamWriter = New StreamWriter(queryResultFile, False, Text.Encoding.UTF8)
                Rfc4180Writer.WriteDataTable(dt, writer, True)
            End Using
        Catch ex As Exception
            ' Throw ex
            Console.WriteLine("Got an error: " & ex.Message)
        Finally
            command.Dispose()
            dt.Dispose()
        End Try

        ' Loop ends here

        Console.WriteLine("")
        Console.WriteLine("Finished!")

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

End Module
