library usb;

{$mode objfpc}{$H+}

uses
  Classes,sysutils,setupapi,uDeleteUSB
  {$IFDEF WINDOWS}
  ,Windows
  {$ENDIF}
  ;

function ListUSBDevices : PChar;stdcall;
var
  aDevs : string;
begin
  aDevs := '';
  Result := PChar(aDevs);
end;

function DeleteComPort(aPort : PChar) : Boolean;stdcall;
begin
  Result := DeleteDevice(cComPortGuid,aPort);
end;

function ScriptDefinition : PChar;stdcall;
begin
  Result := 'function ListUSBDevices : PChar;stdcall;'
       +#10+'function DeleteComPort(aPort : PChar) : Boolean;stdcall;'
       ;
end;

procedure ScriptCleanup;stdcall;
begin

end;

exports
  DeleteComPort,
  ListUSBDevices,
  ScriptDefinition,
  ScriptCleanup;

end.
