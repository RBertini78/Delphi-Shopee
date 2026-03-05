unit uShopeeOAuth;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.NetEncoding,
  uShopeeAuth, Net.HttpClient;

const
  SANDBOX_AUTH_HOST = 'https://open.sandbox.test-stable.shopee.com';
  SANDBOX_API_HOST = 'https://openplatform.sandbox.test-stable.shopee.sg';
  PATH_AUTH_PARTNER = '/api/v2/shop/auth_partner';
  PATH_AUTH_TOKEN_GET = '/api/v2/auth/token/get';
  PATH_AUTH_ACCESS_TOKEN_GET = '/api/v2/auth/access_token/get';
  DEFAULT_CALLBACK_PORT = 8765;
  DEFAULT_REDIRECT_PATH = '/callback';

type
  TShopeeTokenResult = record
    AccessToken: string;
    RefreshToken: string;
    ExpireIn: Integer;
    ExpiresAt: Int64;
  end;

function BuildAuthorizationURL(const ABaseURL, APartnerID, APartnerKey, ARedirectURI: string;
  AIsSandbox: Boolean = False): string;
function ExchangeCodeForToken(const ABaseURL, APartnerID, APartnerKey, ACode, AShopID: string;
  out AResult: TShopeeTokenResult): Boolean;
function RefreshAccessToken(const ABaseURL, APartnerID, APartnerKey, AShopID, ARefreshToken: string;
  out AResult: TShopeeTokenResult): Boolean;

implementation

uses
  System.DateUtils, System.Net.URLClient, System.NetConsts;

function BuildAuthorizationURL(const ABaseURL, APartnerID, APartnerKey, ARedirectURI: string;
  AIsSandbox: Boolean = False): string;
var
  Base: string;
  Sign: string;
  Timestamp: Int64;
begin
  if AIsSandbox then
    Result := SANDBOX_AUTH_HOST + '/auth?auth_type=seller' +
      '&partner_id=' + TNetEncoding.URL.Encode(APartnerID) +
      '&redirect_uri=' + TNetEncoding.URL.Encode(ARedirectURI) +
      '&response_type=code'
  else
  begin
    GetShopeeAuthSign(APartnerID, APartnerKey, PATH_AUTH_PARTNER, Sign, Timestamp);
    Base := ExcludeTrailingPathDelimiter(ABaseURL);
    Result := Base + PATH_AUTH_PARTNER +
      '?partner_id=' + TNetEncoding.URL.Encode(APartnerID) +
      '&timestamp=' + IntToStr(Timestamp) +
      '&sign=' + TNetEncoding.URL.Encode(Sign) +
      '&redirect=' + TNetEncoding.URL.Encode(ARedirectURI);
  end;
end;

function JStr(O: TJSONObject; const Key: string; const Def: string = ''): string;
var
  V: TJSONValue;
begin
  Result := Def;
  if O = nil then Exit;
  V := O.GetValue(Key);
  if (V <> nil) and (V is TJSONString) then Result := (V as TJSONString).Value;
end;

function JInt(O: TJSONObject; const Key: string; Def: Integer = 0): Integer;
var
  V: TJSONValue;
begin
  Result := Def;
  if O = nil then Exit;
  V := O.GetValue(Key);
  if V = nil then Exit;
  if V is TJSONNumber then Result := (V as TJSONNumber).AsInt
  else Result := StrToIntDef(V.Value, Def);
end;

function JObj(O: TJSONObject; const Key: string): TJSONObject;
var
  V: TJSONValue;
begin
  Result := nil;
  if O = nil then Exit;
  V := O.GetValue(Key);
  if (V <> nil) and (V is TJSONObject) then Result := V as TJSONObject;
end;

function ParseTokenResult(Root: TJSONObject; out AResult: TShopeeTokenResult): Boolean;
var
  JResp: TJSONObject;
  V: TJSONValue;
begin
  AResult.AccessToken := '';
  AResult.RefreshToken := '';
  AResult.ExpireIn := 0;
  AResult.ExpiresAt := 0;
  Result := False;
  if Root = nil then Exit;
  AResult.AccessToken := JStr(Root, 'access_token');
  AResult.RefreshToken := JStr(Root, 'refresh_token');
  AResult.ExpireIn := JInt(Root, 'expire_in', 0);
  if AResult.ExpireIn = 0 then
    AResult.ExpireIn := JInt(Root, 'expires_in', 0);
  if AResult.AccessToken = '' then
  begin
    JResp := JObj(Root, 'response');
    if JResp <> nil then
    begin
      AResult.AccessToken := JStr(JResp, 'access_token');
      AResult.RefreshToken := JStr(JResp, 'refresh_token');
      AResult.ExpireIn := JInt(JResp, 'expire_in', 0);
      if AResult.ExpireIn = 0 then
        AResult.ExpireIn := JInt(JResp, 'expires_in', 0);
    end;
  end;
  if AResult.AccessToken <> '' then
  begin
    AResult.ExpiresAt := DateTimeToUnix(Now, False) + AResult.ExpireIn;
    Result := True;
  end;
end;

function ExchangeCodeForToken(const ABaseURL, APartnerID, APartnerKey, ACode, AShopID: string;
  out AResult: TShopeeTokenResult): Boolean;
var
  HTTP: THTTPClient;
  Body: TJSONObject;
  Sign: string;
  Timestamp: Int64;
  URL, BodyStr, Query: string;
  Stream: TStringStream;
  Resp: IHTTPResponse;
  Root: TJSONObject;
  Err: string;
begin
  Result := False;
  AResult.AccessToken := '';
  AResult.RefreshToken := '';
  AResult.ExpireIn := 0;
  AResult.ExpiresAt := 0;
  GetShopeeAuthSignWithShopID(APartnerID, APartnerKey, PATH_AUTH_TOKEN_GET, AShopID, Sign, Timestamp);
  Query := '?partner_id=' + TNetEncoding.URL.Encode(APartnerID) +
    '&timestamp=' + IntToStr(Timestamp) +
    '&sign=' + TNetEncoding.URL.Encode(Sign) +
    '&shop_id=' + TNetEncoding.URL.Encode(AShopID);
  Body := TJSONObject.Create;
  try
    Body.AddPair('code', TJSONString.Create(ACode));
    Body.AddPair('partner_id', TJSONString.Create(APartnerID));
    Body.AddPair('shop_id', TJSONString.Create(AShopID));
    BodyStr := Body.ToJSON;
  finally
    Body.Free;
  end;
  URL := ExcludeTrailingPathDelimiter(ABaseURL) + PATH_AUTH_TOKEN_GET + Query;
  HTTP := THTTPClient.Create;
  try
    HTTP.ContentType := 'application/json';
    Stream := TStringStream.Create(BodyStr, TEncoding.UTF8);
    try
      Resp := HTTP.Post(URL, Stream);
      if Resp.StatusCode <> 200 then
        raise Exception.Create(Format('HTTP %d: %s', [Resp.StatusCode, Resp.ContentAsString]));
      Root := TJSONObject.ParseJSONValue(Resp.ContentAsString) as TJSONObject;
      if Root = nil then Exit;
      try
        Err := JStr(Root, 'error');
        if Err <> '' then
          raise Exception.Create(JStr(Root, 'message', Err));
        if Root.GetValue('error') is TJSONNumber then
          if (Root.GetValue('error') as TJSONNumber).AsInt <> 0 then
            raise Exception.Create(JStr(Root, 'message', 'API error'));
        Result := ParseTokenResult(Root, AResult);
      finally
        Root.Free;
      end;
    finally
      Stream.Free;
    end;
  finally
    HTTP.Free;
  end;
end;

function RefreshAccessToken(const ABaseURL, APartnerID, APartnerKey, AShopID, ARefreshToken: string;
  out AResult: TShopeeTokenResult): Boolean;
var
  HTTP: THTTPClient;
  Body: TJSONObject;
  Sign: string;
  Timestamp: Int64;
  URL, BodyStr, Query: string;
  Stream: TStringStream;
  Resp: IHTTPResponse;
  Root: TJSONObject;
  Err: string;
begin
  Result := False;
  AResult.AccessToken := '';
  AResult.RefreshToken := ARefreshToken;
  AResult.ExpireIn := 0;
  AResult.ExpiresAt := 0;
  GetShopeeAuthSignWithShopID(APartnerID, APartnerKey, PATH_AUTH_ACCESS_TOKEN_GET, AShopID, Sign, Timestamp);
  Query := '?partner_id=' + TNetEncoding.URL.Encode(APartnerID) +
    '&timestamp=' + IntToStr(Timestamp) +
    '&sign=' + TNetEncoding.URL.Encode(Sign) +
    '&shop_id=' + TNetEncoding.URL.Encode(AShopID);
  Body := TJSONObject.Create;
  try
    Body.AddPair('shop_id', TJSONString.Create(AShopID));
    Body.AddPair('refresh_token', TJSONString.Create(ARefreshToken));
    Body.AddPair('partner_id', TJSONString.Create(APartnerID));
    BodyStr := Body.ToJSON;
  finally
    Body.Free;
  end;
  URL := ExcludeTrailingPathDelimiter(ABaseURL) + PATH_AUTH_ACCESS_TOKEN_GET + Query;
  HTTP := THTTPClient.Create;
  try
    HTTP.ContentType := 'application/json';
    Stream := TStringStream.Create(BodyStr, TEncoding.UTF8);
    try
      Resp := HTTP.Post(URL, Stream);
      if Resp.StatusCode <> 200 then
        raise Exception.Create(Format('HTTP %d: %s', [Resp.StatusCode, Resp.ContentAsString]));
      Root := TJSONObject.ParseJSONValue(Resp.ContentAsString) as TJSONObject;
      if Root = nil then Exit;
      try
        Err := JStr(Root, 'error');
        if Err <> '' then
          raise Exception.Create(JStr(Root, 'message', Err));
        if Root.GetValue('error') <> nil then
          if Root.GetValue('error') is TJSONNumber then
            if (Root.GetValue('error') as TJSONNumber).AsInt <> 0 then
              raise Exception.Create(JStr(Root, 'message', 'API error'));
        Result := ParseTokenResult(Root, AResult);
        if Result and (AResult.RefreshToken = '') then
          AResult.RefreshToken := ARefreshToken;
      finally
        Root.Free;
      end;
    finally
      Stream.Free;
    end;
  finally
    HTTP.Free;
  end;
end;

end.
