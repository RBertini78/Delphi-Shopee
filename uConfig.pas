unit uConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, System.IniFiles, IdHTTPServer, IdContext, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, IdCustomHTTPServer;

type
  TfrmConfig = class(TForm)
    pnlMain: TPanel;
    lblBaseURL: TLabel;
    edtBaseURL: TEdit;
    lblPartnerID: TLabel;
    edtPartnerID: TEdit;
    lblPartnerKey: TLabel;
    edtPartnerKey: TEdit;
    lblAccessToken: TLabel;
    edtAccessToken: TEdit;
    lblShopID: TLabel;
    edtShopID: TEdit;
    lblStatusOAuth: TLabel;
    btnConectar: TButton;
    btnSalvar: TButton;
    btnFechar: TButton;
    IdHTTP1: TIdHTTP;
    procedure FormCreate(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
  private
    FConfigPath: string;
    FAccessToken: string;
    FRefreshToken: string;
    FExpiresAt: Int64;
    FCallbackReceived: Boolean;
    FCallbackCode: string;
    FCallbackShopID: string;
    FServer: TIdHTTPServer;
    procedure Carregar;
    procedure Salvar;
    procedure DoOAuthCallbackReceived;
    procedure ServerCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
  public
    function CredenciaisPreenchidas: Boolean;
    function GetBaseURL: string;
    function GetPartnerID: string;
    function GetPartnerKey: string;
    function GetAccessToken: string;
    function GetShopID: string;
    function GetRefreshToken: string;
    function GetExpiresAt: Int64;
    procedure SaveTokens(const AAccessToken, ARefreshToken: string;
      AExpiresAt: Int64);
  end;

var
  frmConfig: TfrmConfig;

implementation

uses
  System.IOUtils, System.StrUtils, Winapi.ShellApi,
  System.NetEncoding,
  uShopeeOAuth;

{$R *.dfm}

procedure TfrmConfig.FormCreate(Sender: TObject);
begin
  FConfigPath := TPath.Combine(TPath.GetDocumentsPath, 'ShopeeConfig.ini');
  Carregar;
end;

procedure TfrmConfig.Carregar;
var
  Ini: TIniFile;
begin
  if not TFile.Exists(FConfigPath) then
  begin
    edtBaseURL.Text := 'https://partner.shopeemobile.com';
    Exit;
  end;
  Ini := TIniFile.Create(FConfigPath);
  try
    edtBaseURL.Text := Ini.ReadString('Shopee', 'BaseURL',
      'https://partner.shopeemobile.com');
    edtPartnerID.Text := Ini.ReadString('Shopee', 'PartnerID', '');
    edtPartnerKey.Text := Ini.ReadString('Shopee', 'PartnerKey', '');
    FAccessToken := Ini.ReadString('Shopee', 'AccessToken', '');
    edtShopID.Text := Ini.ReadString('Shopee', 'ShopID', '');
    FRefreshToken := Ini.ReadString('Shopee', 'RefreshToken', '');
    FExpiresAt := StrToInt64Def(Ini.ReadString('Shopee', 'ExpiresAt', '0'), 0);
  finally
    Ini.Free;
  end;
end;

procedure TfrmConfig.Salvar;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FConfigPath);
  try
    Ini.WriteString('Shopee', 'BaseURL', edtBaseURL.Text);
    Ini.WriteString('Shopee', 'PartnerID', edtPartnerID.Text);
    Ini.WriteString('Shopee', 'PartnerKey', edtPartnerKey.Text);
    Ini.WriteString('Shopee', 'AccessToken', FAccessToken);
    Ini.WriteString('Shopee', 'ShopID', edtShopID.Text);
    Ini.WriteString('Shopee', 'RefreshToken', FRefreshToken);
    Ini.WriteString('Shopee', 'ExpiresAt', IntToStr(FExpiresAt));
  finally
    Ini.Free;
  end;
end;

procedure TfrmConfig.btnSalvarClick(Sender: TObject);
begin
  Salvar;
  ModalResult := mrOk;
  Close;
end;

procedure TfrmConfig.btnFecharClick(Sender: TObject);
begin
  Close;
end;

function TfrmConfig.CredenciaisPreenchidas: Boolean;
begin
  Result := (Trim(edtPartnerID.Text) <> '') and (Trim(edtPartnerKey.Text) <> '')
    and (Trim(edtShopID.Text) <> '') and
    ((Trim(FAccessToken) <> '') or (Trim(FRefreshToken) <> ''));
end;

function TfrmConfig.GetBaseURL: string;
begin
  Result := edtBaseURL.Text;
end;

function TfrmConfig.GetPartnerID: string;
begin
  Result := edtPartnerID.Text;
end;

function TfrmConfig.GetPartnerKey: string;
begin
  Result := edtPartnerKey.Text;
end;

function TfrmConfig.GetAccessToken: string;
begin
  Result := FAccessToken;
end;

function TfrmConfig.GetShopID: string;
begin
  Result := edtShopID.Text;
end;

function TfrmConfig.GetRefreshToken: string;
begin
  Result := FRefreshToken;
end;

function TfrmConfig.GetExpiresAt: Int64;
begin
  Result := FExpiresAt;
end;

procedure TfrmConfig.SaveTokens(const AAccessToken, ARefreshToken: string;
  AExpiresAt: Int64);
begin
  FAccessToken := AAccessToken;
  FRefreshToken := ARefreshToken;
  FExpiresAt := AExpiresAt;
  Salvar;
end;

procedure TfrmConfig.btnConectarClick(Sender: TObject);
const
  CALLBACK_PORT = 8765;
  WAIT_TIMEOUT_MS = 300000;
var
  RedirectURI, AuthURL: string;
  WaitStart: Cardinal;
begin
  if (Trim(edtPartnerID.Text) = '') or (Trim(edtPartnerKey.Text) = '') or
    (Trim(edtBaseURL.Text) = '') then
  begin
    ShowMessage('Preencha Base URL, Partner ID e Partner Key.');
    Exit;
  end;
  RedirectURI := 'http://127.0.0.1:' + IntToStr(CALLBACK_PORT) +
    uShopeeOAuth.DEFAULT_REDIRECT_PATH;
  AuthURL := BuildAuthorizationURL(edtBaseURL.Text, Trim(edtPartnerID.Text),
    RedirectURI);
  FCallbackReceived := False;
  FCallbackCode := '';
  FCallbackShopID := '';
  FServer := TIdHTTPServer.Create(nil);
  try
    FServer.DefaultPort := CALLBACK_PORT;
    FServer.OnCommandGet := ServerCommandGet;
    FServer.Active := True;
    try
      ShellExecute(0, 'open', PChar(AuthURL), nil, nil, SW_SHOWNORMAL);
      lblStatusOAuth.Caption := 'Aguardando autorização no navegador...';
      WaitStart := GetTickCount;
      while not FCallbackReceived do
      begin
        Application.ProcessMessages;
        if GetTickCount - WaitStart > WAIT_TIMEOUT_MS then
        begin
          lblStatusOAuth.Caption := 'Tempo esgotado. Tente novamente.';
          Exit;
        end;
        Sleep(100);
      end;
    finally
      FServer.Active := False;
    end;
  finally
    FServer.Free;
    FServer := nil;
  end;
end;

function ParseQueryParam(const AQuery, AKey: string): string;
var
  List: TStringList;
  i: Integer;
  K, V: string;
  S: string;
begin
  Result := '';
  List := TStringList.Create;
  try
    List.Delimiter := '&';
    List.StrictDelimiter := True;
    List.DelimitedText := AQuery;
    for i := 0 to List.Count - 1 do
    begin
      S := List[i];
      if Pos('=', S) > 0 then
      begin
        K := TNetEncoding.URL.Decode(Trim(Copy(S, 1, Pos('=', S) - 1)));
        V := TNetEncoding.URL.Decode(Trim(Copy(S, Pos('=', S) + 1, Length(S))));
        if SameText(K, AKey) then
        begin
          Result := V;
          Exit;
        end;
      end;
    end;
  finally
    List.Free;
  end;
end;

procedure TfrmConfig.ServerCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  Doc: string;
  Q: string;
begin
  Doc := ARequestInfo.Document;
  if (Doc = '/callback') or (Doc = '/callback/') or (Pos('/callback', Doc) = 1)
  then
  begin
    if Pos('?', Doc) > 0 then
      Q := Copy(Doc, Pos('?', Doc) + 1, Length(Doc))
    else
      Q := ARequestInfo.UnparsedParams;
    FCallbackCode := ParseQueryParam(Q, 'code');
    FCallbackShopID := ParseQueryParam(Q, 'shop_id');
    AResponseInfo.ContentType := 'text/html; charset=utf-8';
    AResponseInfo.ContentText :=
      '<html><body><h1>Conectado!</h1><p>Pode fechar esta janela.</p></body></html>';
    TThread.Synchronize(nil, DoOAuthCallbackReceived);
    FCallbackReceived := True;
  end;
end;

procedure TfrmConfig.DoOAuthCallbackReceived;
var
  TokenResult: TShopeeTokenResult;
  ShopIDToUse: string;
begin
  if FCallbackCode = '' then
    Exit;
  ShopIDToUse := FCallbackShopID;
  if ShopIDToUse = '' then
    ShopIDToUse := Trim(edtShopID.Text);
  if ShopIDToUse = '' then
  begin
    lblStatusOAuth.Caption :=
      'Erro: shop_id não informado. Preencha Shop ID e tente novamente.';
    FCallbackReceived := True;
    Exit;
  end;
  if ExchangeCodeForToken(edtBaseURL.Text, Trim(edtPartnerID.Text),
    Trim(edtPartnerKey.Text), FCallbackCode, ShopIDToUse, TokenResult) then
  begin
    FAccessToken := TokenResult.AccessToken;
    FRefreshToken := TokenResult.RefreshToken;
    FExpiresAt := TokenResult.ExpiresAt;
    if FCallbackShopID <> '' then
      edtShopID.Text := FCallbackShopID;
    Salvar;
    lblStatusOAuth.Caption := 'Conectado com sucesso.';
  end
  else
    lblStatusOAuth.Caption := 'Falha ao obter token. Tente novamente.';
  if FServer <> nil then
    FServer.Active := False;
  FCallbackReceived := True;
end;

end.
