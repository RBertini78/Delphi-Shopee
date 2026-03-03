unit uShopeeOAuth;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.NetEncoding,
  uShopeeAuth, Net.HttpClient;

const
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

function BuildAuthorizationURL(const ABaseURL, APartnerID, ARedirectURI: string): string;
function ExchangeCodeForToken(const ABaseURL, APartnerID, APartnerKey, ACode, AShopID: string;
  out AResult: TShopeeTokenResult): Boolean;
function RefreshAccessToken(const ABaseURL, APartnerID, APartnerKey, AShopID, ARefreshToken: string;
  out AResult: TShopeeTokenResult): Boolean;

implementation

uses
  System.DateUtils;

function BuildAuthorizationURL(const ABaseURL, APartnerID, ARedirectURI: string): string;
var
  Base: string;
begin
  Base := ExcludeTrailingPathDelimiter(ABaseURL);
  Result := Base + PATH_AUTH_PARTNER +
    '?partner_id=' + TNetEncoding.URL.Encode(APartnerID) +
    '&redirect=' + TNetEncoding.URL.Encode(ARedirectURI);
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

function ExchangeCodeForToken(const ABaseURL, APartnerID, APartnerKey, ACode, AShopID: string;
  out AResult: TShopeeTokenResult): Boolean;
var
  HTTP: THTTPClient;
  Body: TJSONObject;
  Sign: string;
  Timestamp: Int64;
  URL, BodyStr: string;
  Stream: TStringStream;
  Resp: IHTTPResponse;
  Root, JResp: TJSONObject;
  Err: string;
begin
  Result := False;
  AResult.AccessToken := '';
  AResult.RefreshToken := '';
  AResult.ExpireIn := 0;
  AResult.ExpiresAt := 0;
  GetShopeeAuthSign(APartnerID, APartnerKey, PATH_AUTH_TOKEN_GET, Sign, Timestamp);
  Body := TJSONObject.Create;
  try
    Body.AddPair('partner_id', TJSONString.Create(APartnerID));
    Body.AddPair('code', TJSONString.Create(ACode));
    Body.AddPair('shop_id', TJSONString.Create(AShopID));
    Body.AddPair('sign', TJSONString.Create(Sign));
    Body.AddPair('timestamp', TJSONNumber.Create(Timestamp));
    BodyStr := Body.ToJSON;
  finally
    Body.Free;
  end;
  URL := ExcludeTrailingPathDelimiter(ABaseURL) + PATH_AUTH_TOKEN_GET;
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
        JResp := JObj(Root, 'response');
        if JResp = nil then Exit;
        AResult.AccessToken := JStr(JResp, 'access_token');
        AResult.RefreshToken := JStr(JResp, 'refresh_token');
        AResult.ExpireIn := JInt(JResp, 'expire_in', 0);
        if AResult.ExpireIn = 0 then
          AResult.ExpireIn := JInt(JResp, 'expires_in', 0);
        if AResult.AccessToken <> '' then
        begin
          AResult.ExpiresAt := DateTimeToUnix(Now, False) + AResult.ExpireIn;
          Result := True;
        end;
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
  Root, JResp: TJSONObject;
  Err: string;
begin
  Result := False;
  AResult.AccessToken := '';
  AResult.RefreshToken := ARefreshToken;
  AResult.ExpireIn := 0;
  AResult.ExpiresAt := 0;
  GetShopeeAuthSign(APartnerID, APartnerKey, PATH_AUTH_ACCESS_TOKEN_GET, Sign, Timestamp);
  Query := '?partner_id=' + TNetEncoding.URL.Encode(APartnerID) +
    '&timestamp=' + IntToStr(Timestamp) +
    '&sign=' + TNetEncoding.URL.Encode(Sign);
  Body := TJSONObject.Create;
  try
    Body.AddPair('partner_id', TJSONString.Create(APartnerID));
    Body.AddPair('shop_id', TJSONString.Create(AShopID));
    Body.AddPair('refresh_token', TJSONString.Create(ARefreshToken));
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
        JResp := JObj(Root, 'response');
        if JResp = nil then Exit;
        AResult.AccessToken := JStr(JResp, 'access_token');
        AResult.ExpireIn := JInt(JResp, 'expire_in', 0);
        if AResult.ExpireIn = 0 then
          AResult.ExpireIn := JInt(JResp, 'expires_in', 0);
        if JStr(JResp, 'refresh_token') <> '' then
          AResult.RefreshToken := JStr(JResp, 'refresh_token');
        if AResult.AccessToken <> '' then
        begin
          AResult.ExpiresAt := DateTimeToUnix(Now, False) + AResult.ExpireIn;
          Result := True;
        end;
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
