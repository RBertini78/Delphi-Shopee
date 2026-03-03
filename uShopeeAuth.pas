unit uShopeeAuth;

interface

uses
  System.SysUtils, System.Generics.Collections, System.NetEncoding, System.DateUtils;

function ShopeeSign(const ABaseString, APartnerKey: string): string;
procedure GetShopeeAuthSign(const APartnerID, APartnerKey, APath: string;
  out ASign: string; out ATimestamp: Int64);
function BuildShopeeQueryParams(
  const APartnerID, APartnerKey, AAccessToken, AShopID, AAPIPath: string;
  const AExtraParams: array of TPair<string, string>
): string;

implementation

uses
  System.Classes,
  IdGlobal, IdHashSHA, IdHMAC, IdSSLOpenSSL, IdHMACSHA1, IdException;

function BytesToHex(const ABytes: TIdBytes): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Length(ABytes) - 1 do
    Result := Result + IntToHex(ABytes[i], 2);
end;

function ShopeeSign(const ABaseString, APartnerKey: string): string;
var
  HMAC: TIdHMACSHA256;
  HashBytes: TIdBytes;
  KeyBytes: TIdBytes;
  DataBytes: TIdBytes;
begin
  LoadOpenSSLLibrary;
  if not TIdHashSHA256.IsAvailable then
    raise EIdException.Create('SHA256 not available. Ensure OpenSSL is loaded.');
  KeyBytes := ToBytes(APartnerKey, IndyTextEncoding_UTF8);
  DataBytes := ToBytes(ABaseString, IndyTextEncoding_UTF8);
  HMAC := TIdHMACSHA256.Create;
  try
    HMAC.Key := KeyBytes;
    HashBytes := HMAC.HashValue(DataBytes);
    Result := BytesToHex(HashBytes);
  finally
    HMAC.Free;
  end;
end;

procedure GetShopeeAuthSign(const APartnerID, APartnerKey, APath: string;
  out ASign: string; out ATimestamp: Int64);
var
  BaseStr: string;
begin
  ATimestamp := DateTimeToUnix(TDateTime(Now), False);
  BaseStr := APartnerID + APath + IntToStr(ATimestamp);
  ASign := ShopeeSign(BaseStr, APartnerKey);
end;

function BuildShopeeQueryParams(
  const APartnerID, APartnerKey, AAccessToken, AShopID, AAPIPath: string;
  const AExtraParams: array of TPair<string, string>
): string;
var
  TimeStamp: Int64;
  BaseStr, Sign: string;
  i: Integer;
  Params: TStringList;
begin
  TimeStamp := DateTimeToUnix(TDateTime(Now), False);
  BaseStr := APartnerID + AAPIPath + IntToStr(TimeStamp) + AAccessToken + AShopID;
  Sign := ShopeeSign(BaseStr, APartnerKey);

  Params := TStringList.Create;
  try
    Params.Delimiter := '&';
    Params.StrictDelimiter := True;
    Params.Add('partner_id=' + TNetEncoding.URL.Encode(APartnerID));
    Params.Add('timestamp=' + IntToStr(TimeStamp));
    Params.Add('sign=' + Sign);
    Params.Add('access_token=' + TNetEncoding.URL.Encode(AAccessToken));
    Params.Add('shop_id=' + TNetEncoding.URL.Encode(AShopID));
    for i := Low(AExtraParams) to High(AExtraParams) do
      Params.Add(AExtraParams[i].Key + '=' + TNetEncoding.URL.Encode(AExtraParams[i].Value));
    Result := Params.DelimitedText;
  finally
    Params.Free;
  end;
end;

end.
