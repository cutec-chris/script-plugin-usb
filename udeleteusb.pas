unit uDeleteUSB;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SetupAPI, Windows, JwaWinUser, uMSCOMDB,registry;

function DeleteDevice(GUID : TGUID;Port : string) : Boolean;

const
  cComPortGuid : TGUID = '{86E0D1E0-8089-11D0-9CE4-08003E301F73}';


implementation

function GetRegistryPropertyString(PnPHandle: HDEVINFO; const DevData: PSP_DEVINFO_DATA; Prop: DWORD): shortstring;
var
  RegDataType:   DWORD;
  Buffer:        array [0..256] of Char;
  aBytesReturned: Integer;
begin
  aBytesReturned := 0;
  RegDataType   := 0;
  Buffer[0]     := #0;
  SetupDiGetDeviceRegistryPropertyA(PnPHandle, DevData, Prop, @RegDataType, PBYTE(@Buffer[0]), SizeOf(Buffer), @aBytesReturned);
  Result := PChar(Buffer);
end;

function CM_Get_Child(var dnChildInst: DWord;dnDevInst: DWord;ulFlags: LongWord): DWord; stdcall; external 'CFGMGR32';

function DeleteDevice(GUID : TGUID;Port : string) : Boolean;
var
  PnPHandle: HDEVINFO;
  DevData: SP_DEVINFO_DATA;
  DeviceInterfaceData: SP_DEVICE_INTERFACE_DATA;
  FunctionClassDeviceData: ^SP_DEVICE_INTERFACE_DETAIL_DATA_A;
  Success: LongBool;
  Devn: Integer;
  tmp: String;
  Flags: LongWord;
  FUSBSerialPort: String;
  aBytesReturned: Integer;
  ChildInst : DWORD;
  ComDB : LongWord;
  Bindata : array[0..$20] of byte;
  Reg : TRegistry;
  TheKey : string;
  i : Integer;
begin
  Result := False;
  PnPHandle := SetupDiGetClassDevsA(@Guid, nil, 0,DIGCF_PRESENT or DIGCF_DEVICEINTERFACE);
  if PnPHandle = Pointer(INVALID_HANDLE_VALUE) then
    Exit;
  Devn := 0;
  repeat
    DeviceInterfaceData.cbSize := SizeOf(SP_DEVICE_INTERFACE_DATA);
    Success := SetupDiEnumDeviceInterfaces(PnPHandle, nil, @Guid, Devn, @DeviceInterfaceData);
    if Success then
      begin
        DevData.cbSize := SizeOf(DevData);
        aBytesReturned  := 0;
        SetupDiGetDeviceInterfaceDetailA(PnPHandle, @DeviceInterfaceData, nil, 0, @aBytesReturned, @DevData);
        if (aBytesReturned <> 0) and (GetLastError = ERROR_INSUFFICIENT_BUFFER) then
          begin
            FunctionClassDeviceData := AllocMem(aBytesReturned);
            FunctionClassDeviceData^.cbSize := 5;
            if SetupDiGetDeviceInterfaceDetailA(PnPHandle, @DeviceInterfaceData, FunctionClassDeviceData, aBytesReturned, @aBytesReturned, @DevData) then
              begin
                if CM_Get_Child(ChildInst,DevData.DevInst,0) <> {CR_SUCCESS}0 then
                  ChildInst := 0;
                FUSBSerialPort := GetRegistryPropertyString(PnPHandle,@DevData,SPDRP_FRIENDLYNAME);
                if pos('COM',FUSBSerialPort) > 0 then
                  begin
                    ChildInst := 0;
                    if pos('(COM',FUSBSerialPort) > 0 then
                      begin
                        FUSBSerialPort := copy(FUSBSerialPort,pos('(COM',FUSBSerialPort)+1,length(FUSBSerialPort));
                        FUSBSerialPort := copy(FUSBSerialPort,0,pos(')',FUSBSerialPort)-1);
                      end;
                  end;
                if FUSBSerialPort = Port then
                  begin
                    if ComDBOpen(@ComDB) = ERROR_SUCCESS then
                      begin
                        Result := ComDBReleasePort(ComDB,StrToInt(copy(FUSBSerialPort,4,length(FUSBSerialPort)))) = ERROR_SUCCESS;
                        ComDBClose(ComDB);
                        if Result then
                          Result := SetupDiRemoveDevice(PnPHandle,@DevData);
                      end;
                  end;
              end;
            FreeMem(FunctionClassDeviceData);
          end;
        Inc(Devn);
      end;
  until not Success;
  SetupDiDestroyDeviceInfoList(PnPHandle);
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  TheKey := 'SYSTEM\CurrentControlSet\Control\COM Name Arbiter';
  if Reg.OpenKey(TheKey, False) then
    begin
      Reg.ReadBinaryData('ComDB',Bindata[0],$20);
      for i := 7 to $20 do
        BinData[i] := 0;
      Reg.WriteBinaryData('ComDB',Bindata[0],$20);
    end;
  Reg.CloseKey;
  Reg.Free;
end;

end.

