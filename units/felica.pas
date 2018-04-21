unit felica;

interface

uses SysUtils, Classes, felicalib;

type
  TFelicaThread = class(TThread)
  private
    P: Pointer;
    FIDm: string;
    FConn: Boolean;
    FOnConnected: TNotifyEvent;
    FOnDisconnected: TNotifyEvent;
  protected
    procedure DoConnected;
    procedure DoDisconnected;
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
    property IDm: string read FIDm;
    property OnConnected: TNotifyEvent read FOnConnected write FOnConnected;
    property OnDisconnected: TNotifyEvent read FOnDisconnected write FOnDisconnected;
  end;

implementation

uses sqldb;

constructor TFelicaThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FConn := False;
  P     := pasori_open(nil);
  if P = nil then
  	raise Exception.Create('PaSoRi open failed.');
  pasori_init(P);
end;

destructor TFelicaThread.Destroy;
begin
  if P <> nil then pasori_close(P);
  inherited Destroy;
end;

procedure TFelicaThread.DoConnected;
begin
  if Assigned(FOnConnected) then
    FOnConnected(Self);
end;

procedure TFelicaThread.DoDisconnected;
begin
  if Assigned(FOnDisconnected) then
    FOnDisconnected(Self);
end;

procedure TFelicaThread.Execute;
var
  F: Pointer;
  ID: string;
begin
  while not Terminated do
  begin
    F := felica_polling(p, POLLING_ANY, 0, 0);
    if F = nil then
    begin
      if FConn then Synchronize(@DoDisconnected);
      FIDm  := '';
      FConn := False;
      Continue;
    end;
    try
      ID := felica_getidm(F);
      if (ID <> '') and (ID <> FIDm) and (not FConn) then
      begin
        FIDm := ID;
        Synchronize(@DoConnected);
        FConn := True;
      end;
    finally
      felica_free(F);
    end;
    Sleep(100);
  end;
end;

end.
