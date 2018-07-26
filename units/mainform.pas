unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    ChkPost: TCheckBox;
    EditIDM: TEdit;
    Label1: TLabel;
    LabelIn: TLabel;
    LabelName: TLabel;
    LabelOut: TLabel;
    procedure ChkPostChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FIDM: string;
    FEndPoint: string;
    FUsername: string;
    FPassword: string;
    FFelica: TThread;
    procedure Connected(Sender: TObject);
    procedure Disconnected(Sender: TObject);
  public

  end;

var
  Form1: TForm1;

implementation

uses Windows,fphttpclient, fpjson, jsonparser, IniFiles, felica;

{$R *.lfm}

{ TForm1 }

procedure SetForeground(H: HWND);
var
  FTID: DWORD;
begin
  FTID := GetWindowThreadProcessId(GetForegroundWindow, nil);
  AttachThreadInput(GetCurrentThreadId, FTID, True);
  SetForegroundWindow(H);
end;

procedure TForm1.Connected(Sender: TObject);
var
  AURL: string;
  AResponse: string;
  AJSon: TJSONData;
begin
  SetForeground(Handle);

  FIDM := TFelicaThread(FFelica).IDm;
  EditIDM.Text := FIDM;
  LabelIn.Caption   := '--:--';
  LabelOut.Caption  := '--:--';

  AURL := FEndPoint + FIDM;
  with TFPHTTPClient.Create(Self) do
  try
    Username  := FUsername;
    Password  := FPassword;
    AResponse := Get(AUrl);
    if ResponseStatusCode <> 200 then
    begin
      LabelName.Caption := '該当者無し';
      FIDM := '';
    end;
    Free;
  except
    on E: Exception do
    begin
      FIDM := '';
      LabelName.Caption := '該当者無し';
      Free;
      ShowMessage(E.Message);
    end
    else
      LabelName.Caption := '該当者無し';
      FIDM := '';
      Free;
  end;
  if FIDM = '' then Exit;

  AJSon := GetJSON(AResponse);
  LabelName.Caption := UTF8Decode(AJson.FindPath('name').AsString);
end;

procedure TForm1.Disconnected(Sender: TObject);
var
  AURL: string;
  AResponse: string;
  AJSon: TJSONData;
begin
  SetForeground(Handle);

  if FIDM = '' then
  begin
    ChkPost.Checked:=True;
    Exit;
  end;

  AURL := FEndPoint + FIDM;
  with TFPHTTPClient.Create(Self) do
  try
    if ChkPost.Checked then
    begin
      Username  := FUsername;
      Password  := FPassword;
      AResponse := Post(AUrl)
    end else
    begin
      AResponse:='{}';
      Delete(AUrl);
    end;
    if not(ResponseStatusCode in [200,201]) then
    begin
      LabelName.Caption := '該当者無し';
      LabelIn.Caption   := '--:--';
      LabelOut.Caption  := '--:--';
      FIDM := '';
    end;
  finally
    Free;
  end;
  if FIDM = '' then Exit;
  if ChkPost.Checked then
  begin
    AJSon := GetJSON(AResponse);
    LabelIn.Caption  := AJson.FindPath('work_in').AsString;
    LabelOut.Caption := AJson.FindPath('work_out').AsString;
    FIDM := '';
  end;
  ChkPost.Checked := True;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName,'.ini')) do
  try
    FEndPoint := ReadString('EndPoints', 'URL', '');
    FUsername := ReadString('EndPoints', 'Username', '');
    FPassword := ReadString('EndPoints', 'Password', '');
  finally
    Free;
  end;
  //FEndPoint := 'http://logger01:5000/api/idm/';
  FFelica := TFelicaThread.Create(False);
  with TFelicaThread(FFelica) do
  begin
    OnConnected    := @Connected;
    OnDisconnected := @Disconnected;
    Start;
  end;
end;

procedure TForm1.ChkPostChange(Sender: TObject);
begin

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FFelica.Terminate;
  FFelica.WaitFor;
  FFelica.Free;
end;

end.

