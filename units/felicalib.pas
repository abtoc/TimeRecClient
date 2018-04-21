unit felicalib;

interface

uses SysUtils;

const
  felicalib_dll = 'felicalib.dll';
  POLLING_ANY   = $FFFF;

type
  PIDm = ^TIDM;
  TIDm = array [0..7] of Byte;
  PPMm = ^TPMm;
  TPMm = array [0..7] of Byte;

function  pasori_open(P: Pointer): Pointer; cdecl; external felicalib_dll name 'pasori_open';
procedure pasori_close(P: Pointer); cdecl;         external felicalib_dll name 'pasori_close';
function  pasori_init(P: Pointer): Integer; cdecl; external felicalib_dll name 'pasori_init';
function  felica_polling(P: Pointer; SC: Integer; RFU,TS: Byte): Pointer; cdecl;
                                                   external felicalib_dll name 'felica_polling';
procedure felica_free(P: Pointer); cdecl;          external felicalib_dll name 'felica_free';

function felica_getidm(P: Pointer): string;
function felica_getpmm(P: Pointer): string;

implementation

procedure felica_getidm_dll(P: Pointer; var IDm: TIDm); cdecl;
                                                   external felicalib_dll name 'felica_getidm';
procedure felica_getpmm_dll(P: Pointer; var PMm: TPMm); cdecl;
                                                   external felicalib_dll name 'felica_getpmm';

function IdToStr(P: PByte): string;
var
  I: Integer;
begin
  Result := '';
  for I:=0 to 7 do
  begin
    Result := Result + IntToHex(P^, 2);
    Inc(P);
  end;
end;

function felica_getidm(P: Pointer): string;
var
  IDm: TIDm;
begin
  Result := '';
  if P <> nil then
  begin
    felica_getidm_dll(P, IDm);
    Result := IdToStr(@IDm[0]);
  end;
end;

function felica_getpmm(P: Pointer): string;
var
  PMm: TPMm;
begin
  Result := '';
  if P <> nil then
  begin
    felica_getpmm_dll(P, PMm);
    Result := IdToStr(@PMm[0]);
  end;
end;

end.
