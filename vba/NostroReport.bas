Option Explicit

Sub UpdateNostroReport()

    Dim reportPath As String
    Dim reportWB   As Workbook
    Dim dataWB     As Workbook
    Dim rptSheet   As Worksheet
    Dim datSheet   As Worksheet
    Dim i          As Integer

    reportPath = PickSingleFile("Select the EXISTING Nostro Report workbook")
    If reportPath = "" Then
        MsgBox "No report file selected. Macro cancelled.", vbExclamation
        Exit Sub
    End If

    Dim dataFiles As FileDialog
    Set dataFiles = Application.FileDialog(msoFileDialogFilePicker)
    With dataFiles
        .Title = "Select one or more NEW Data files"
        .Filters.Clear
        .Filters.Add "Excel Files", "*.xlsx; *.xlsm; *.xls; *.xlsb"
        .AllowMultiSelect = True
        If .Show = False Then
            MsgBox "No data files selected. Macro cancelled.", vbExclamation
            Exit Sub
        End If
    End With

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual

    Set reportWB = Workbooks.Open(reportPath)

    Dim matchedSheets As New Collection
    For i = 1 To dataFiles.SelectedItems.Count
        Dim dataPath As String
        dataPath = dataFiles.SelectedItems(i)

        Dim fileName As String
        fileName = GetFileNameNoExt(dataPath)

        Set rptSheet = Nothing
        On Error Resume Next
        Set rptSheet = reportWB.Worksheets(fileName)
        On Error GoTo 0

        If rptSheet Is Nothing Then
            MsgBox "No worksheet named '" & fileName & "' found in the report. Skipping this file.", vbInformation
        Else
            Set dataWB = Workbooks.Open(dataPath, ReadOnly:=True)
            Set datSheet = dataWB.Worksheets(1)
            Call ProcessSheet(rptSheet, datSheet)
            dataWB.Close SaveChanges:=False
            matchedSheets.Add fileName
        End If
    Next i

    Dim ws         As Worksheet
    Dim wasMatched As Boolean
    Dim m          As Variant
    Dim clearDate  As String
    clearDate = Format(Date - 1, "DDMMYYYY")

    For Each ws In reportWB.Worksheets
        wasMatched = False
        For Each m In matchedSheets
            If ws.Name = CStr(m) Then
                wasMatched = True
                Exit For
            End If
        Next m

        If Not wasMatched Then
            ' If no new file was uploaded for this worksheet,
            ' explicitly highlight and stamp the sheet.
            Call ApplyNoUploadMessage(ws, clearDate)
        End If
    Next ws

    reportWB.Save

    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True

    MsgBox "Nostro report updated successfully!", vbInformation

End Sub

Private Sub ApplyNoUploadMessage(ws As Worksheet, clearDate As String)

    On Error Resume Next
    ws.Range("A2:N5").MergeCells = False
    On Error GoTo 0

    ws.Range("A2:N5").ClearContents
    ws.Range("A2:N5").Interior.Color = RGB(255, 199, 206)
    ws.Range("A2:N5").Merge

    ws.Range("A2").Value = "No new file uploaded - All cleared till " & clearDate
    ws.Range("A2").Font.Bold = True
    ws.Range("A2").Font.Size = 12
    ws.Range("A2").HorizontalAlignment = xlCenter
    ws.Range("A2").VerticalAlignment = xlCenter

End Sub

Private Sub ApplyClearedMessage(ws As Worksheet, clearDate As String)

    ws.Range("A2:N5").ClearContents
    ws.Range("A2:N5").Interior.Color = RGB(255, 255, 0)
    ws.Range("A2:N5").MergeCells = False
    ws.Range("A2:N5").Merge
    ws.Range("A2").Value = "All cleared till " & clearDate
    ws.Range("A2").Font.Bold = True
    ws.Range("A2").Font.Size = 12
    ws.Range("A2").HorizontalAlignment = xlCenter
    ws.Range("A2").VerticalAlignment = xlCenter

End Sub

Private Sub ProcessSheet(rptWS As Worksheet, datWS As Worksheet)

    Const RPT_ID_COL    As Integer = 4
    Const DAT_ID_COL    As Integer = 5
    Const RPT_DATA_COLS As Integer = 10
    Const DAT_COL_START As Integer = 2
    Const COL_K         As Integer = 11
    Const COL_L         As Integer = 12
    Const COL_M         As Integer = 13
    Const COL_N         As Integer = 14
    Const DATA_START    As Integer = 2

    ' Always unmerge and clear any existing status message before writing data
    On Error Resume Next
    rptWS.Range("A2:N5").MergeCells = False
    On Error GoTo 0
    Dim topVal As String
    topVal = Trim(CStr(rptWS.Range("A2").Value))
    If InStr(1, topVal, "All cleared till", vbTextCompare) > 0 _
       Or InStr(1, topVal, "No new file uploaded", vbTextCompare) > 0 Then
        rptWS.Range("A2:N5").ClearContents
        rptWS.Range("A2:N5").Interior.ColorIndex = xlNone
    End If

    Dim oldKLM As Object
    Set oldKLM = CreateObject("Scripting.Dictionary")

    Dim rptLastRow As Long
    rptLastRow = LastDataRow(rptWS, RPT_ID_COL)

    Dim r  As Long
    Dim id As String

    For r = DATA_START To rptLastRow
        id = Trim(CStr(rptWS.Cells(r, RPT_ID_COL).Value))
        If id <> "" Then
            oldKLM(id) = Array( _
                rptWS.Cells(r, COL_K).Value, _
                rptWS.Cells(r, COL_L).Value, _
                rptWS.Cells(r, COL_M).Value  _
            )
        End If
    Next r

    Dim newRows  As Object
    Set newRows = CreateObject("Scripting.Dictionary")

    Dim rowOrder As New Collection

    Dim datLastRow As Long
    datLastRow = LastDataRow(datWS, DAT_ID_COL)

    Dim d As Long
    Dim c As Integer
    Dim j As Integer

    For d = DATA_START To datLastRow
        id = Trim(CStr(datWS.Cells(d, DAT_ID_COL).Value))
        If id <> "" And Not newRows.Exists(id) Then
            Dim tmpArr(1 To 10) As Variant
            For j = 1 To RPT_DATA_COLS
                tmpArr(j) = datWS.Cells(d, DAT_COL_START + j - 1).Value
            Next j
            newRows(id) = tmpArr
            rowOrder.Add id
        End If
    Next d

    If rptLastRow >= DATA_START Then
        rptWS.Range("A" & DATA_START & ":N" & rptLastRow).ClearContents
    End If

    Dim writeRow As Long
    writeRow = DATA_START

    Dim key  As Variant
    Dim vals As Variant
    Dim klm  As Variant

    For Each key In rowOrder
        id = CStr(key)
        vals = newRows(id)

        For c = 1 To RPT_DATA_COLS
            rptWS.Cells(writeRow, c).Value = vals(c)
        Next c

        If oldKLM.Exists(id) Then
            klm = oldKLM(id)
            rptWS.Cells(writeRow, COL_K).Value = klm(0)
            rptWS.Cells(writeRow, COL_L).Value = klm(1)
            rptWS.Cells(writeRow, COL_M).Value = klm(2)

            If Trim(CStr(klm(1))) <> "" Or Trim(CStr(klm(2))) <> "" Then
                rptWS.Cells(writeRow, COL_N).Value = Date
                rptWS.Cells(writeRow, COL_N).NumberFormat = "DD/MM/YYYY"
            Else
                rptWS.Cells(writeRow, COL_N).Value = ""
            End If
        Else
            rptWS.Cells(writeRow, COL_K).Value = ""
            rptWS.Cells(writeRow, COL_L).Value = ""
            rptWS.Cells(writeRow, COL_M).Value = ""
            rptWS.Cells(writeRow, COL_N).Value = ""
        End If

        writeRow = writeRow + 1
    Next key

End Sub

Private Function LastDataRow(ws As Worksheet, colIndex As Integer) As Long
    LastDataRow = ws.Cells(ws.Rows.Count, colIndex).End(xlUp).Row
End Function

Private Function PickSingleFile(prompt As String) As String
    With Application.FileDialog(msoFileDialogFilePicker)
        .Title = prompt
        .Filters.Clear
        .Filters.Add "Excel Files", "*.xlsx; *.xlsm; *.xls; *.xlsb"
        .AllowMultiSelect = False
        If .Show = True Then
            PickSingleFile = .SelectedItems(1)
        Else
            PickSingleFile = ""
        End If
    End With
End Function

Private Function GetFileNameNoExt(fullPath As String) As String
    Dim fileName As String
    fileName = Mid(fullPath, InStrRev(fullPath, "\\") + 1)
    GetFileNameNoExt = Left(fileName, InStrRev(fileName, ".") - 1)
End Function
