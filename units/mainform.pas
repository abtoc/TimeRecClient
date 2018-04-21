unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    EditIDM: TEdit;
    Label1: TLabel;
    LabelIn: TLabel;
    LabelName: TLabel;
    LabelOut: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FIDM: string;
    FEndPoint: string;
    FFelica: TThread;
    procedure Connected(Sender: TObject);
    procedure Disconnected(Sender: TObject);
  public

  end;

var
  Form1: TForm1;

implementation

uses fphttpclient, fpjson, jsonparser, IniFiles, felica;

{$R *.lfm}

{ TForm1 }

procedure TForm1.Connected(Sender: TObject);
var
  AURL: string;
  AResponse: string;
  AJSon: TJSONData;
begin
  FIDM := TFelicaThread(FFelica).IDm;
  EditIDM.Text := FIDM;
  LabelIn.Caption   := '--:--';
  LabelOut.Caption  := '--:--';

  AURL := FEndPoint + FIDM;
  with TFPHTTPClient.Create(Self) do
  try
    AResponse := Get(AUrl);
    if ResponseStatusCode <> 200 then
    begin
      LabelName.Caption := '該当者無し';
      FIDM := '';
    end;
    Free;
  except
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
  if FIDM = '' then Exit;

  AURL := FEndPoint + FIDM;
  with TFPHTTPClient.Create(Self) do
  try
    AResponse := Post(AUrl);
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
  AJSon := GetJSON(AResponse);
  LabelIn.Caption  := AJson.FindPath('work_in').AsString;
  LabelOut.Caption := AJson.FindPath('work_out').AsString;
  FIDM := '';
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName,'.ini')) do
  try
    FEndPoint := ReadString('EndPoints', 'URL', '');
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

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FFelica.Terminate;
  FFelica.WaitFor;
  FFelica.Free;
end;

end.

