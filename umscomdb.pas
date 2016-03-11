unit uMSCOMDB;

{$mode objfpc}{$H+}

interface

uses
  Classes;

const
  CDB_REPORT_BITS = 0;
  DB_REPORT_BYTES = 1;
  msports = 'msports.dll';

function ComDBOpen(PHComDB: PLongWord): Longint; stdcall; external msports name 'ComDBOpen';
function ComDBClose(HComDB: LongWord): Longint; stdcall; external msports name 'ComDBClose';
function ComDBGetCurrentPortUsage(HCOMDB: LongWord;
  Buffer: Pointer; BufferSize: LongWord; ReportType: LongInt;
  MaxPortsReported: PLongWord): Longint; stdcall; external msports name 'ComDBGetCurrentPortUsage';
function ComDBReleasePort(HComDB: LongWord;ComNumber : DWORD) : Longint; stdcall; external msports name 'ComDBReleasePort';

procedure GetCOMList(List: TStrings);

implementation

uses
  SysUtils, Windows;

procedure GetCOMList(List: TStrings);
var
  ComDB: LongWord;
  Buffer: array of Byte;
  BufferSize: LongWord;
  I: Integer;
begin
  if ComDBOpen(@ComDB) <> ERROR_SUCCESS then RaiseLastOSError;
  try
    ComDBGetCurrentPortUsage(ComDB, nil, 0, DB_REPORT_BYTES, @BufferSize);
    SetLength(Buffer, BufferSize);
    ComDBGetCurrentPortUsage(ComDB, @Buffer, BufferSize, DB_REPORT_BYTES, @BufferSize);
  finally
    ComDBClose(ComDB);
  end;
  List.Clear;
  for I := 0 to BufferSize - 1 do
    if Buffer[I] = 1 then List.Add('COM' + IntToStr(I + 1));
end;

end.

