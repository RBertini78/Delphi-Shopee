unit uShopeeAuth;

interface

uses
  System.SysUtils, System.Generics.Collections, System.NetEncoding, System.DateUtils;

function ShopeeSign(const ABaseString, APartnerKey: string): string;
function ShopeeSignPartnerKey(const APartnerKey, AData: string): string;
procedure GetShopeeAuthSign(const APartnerID, APartnerKey, APath: string;
  out ASign: string; out ATimestamp: Int64);
procedure GetShopeeAuthSignWithShopID(const APartnerID, APartnerKey, APath, AShopID: string;
  out ASign: string; out ATimestamp: Int64);
function BuildShopeeQueryParams(
  const APartnerID, APartnerKey, AAccessToken, AShopID, AAPIPath: string;
  const AExtraParams: array of TPair<string, string>
): string;
function BuildShopeeQueryParamsForPost(
  const APartnerID, APartnerKey, AShopID, APath, ABodyJson: string): string;

implementation

uses
  System.Classes, System.Hash, System.Types;

function BytesToHex(const ABytes: TArray<Byte>): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Length(ABytes) - 1 do
    Result := Result + LowerCase(IntToHex(ABytes[i], 2));
end;

function IsHexString(const S: string): Boolean;
var
  i: Integer;
  C: Char;
begin
  for i := 1 to Length(S) do
  begin
    C := S[i];
    if not CharInSet(C, ['0'..'9', 'a'..'f', 'A'..'F']) then
      Exit(False);
  end;
  Result := True;
end;

function HexToBytes(const AHex: string): TArray<Byte>;
var
  i, L: Integer;
begin
  L := Length(AHex) div 2;
  SetLength(Result, L);
  for i := 0 to L - 1 do
    Result[i] := StrToInt('$' + Copy(AHex, i * 2 + 1, 2));
end;

function GetPartnerKeyBytes(const APartnerKey: string): TArray<Byte>;
var
  Hex: string;
begin
  if (Length(APartnerKey) > 4) and SameText(Copy(APartnerKey, 1, 4), 'shpk') then
  begin
    Hex := Copy(APartnerKey, 5, Length(APartnerKey));
    if (Length(Hex) mod 2 = 0) and IsHexString(Hex) then
    begin
      Result := HexToBytes(Hex);
      Exit;
    end;
  end;
  Result := TEncoding.UTF8.GetBytes(APartnerKey);
end;

function ShopeeSign(const ABaseString, APartnerKey: string): string;
var
  KeyBytes, DataBytes, HashBytes: TArray<Byte>;
begin
  KeyBytes := TEncoding.UTF8.GetBytes(APartnerKey);
  DataBytes := TEncoding.UTF8.GetBytes(ABaseString);
  HashBytes := THashSHA2.GetHMACAsBytes(DataBytes, KeyBytes);
  Result := BytesToHex(HashBytes);
end;

function ShopeeSignPartnerKey(const APartnerKey, AData: string): string;
var
  KeyBytes, DataBytes, HashBytes: TArray<Byte>;
begin
  KeyBytes := GetPartnerKeyBytes(APartnerKey);
  DataBytes := TEncoding.UTF8.GetBytes(AData);
  HashBytes := THashSHA2.GetHMACAsBytes(DataBytes, KeyBytes);
  Result := BytesToHex(HashBytes);
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

procedure GetShopeeAuthSignWithShopID(const APartnerID, APartnerKey, APath, AShopID: string;
  out ASign: string; out ATimestamp: Int64);
var
  BaseStr: string;
begin
  ATimestamp := DateTimeToUnix(TDateTime(Now), False);
  BaseStr := APartnerID + APath + IntToStr(ATimestamp) + AShopID;
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

function BuildShopeeQueryParamsForPost(
  const APartnerID, APartnerKey, AShopID, APath, ABodyJson: string): string;
var
  Timestamp: Int64;
  SignInput, Sign: string;
  Params: TStringList;
begin
  Timestamp := DateTimeToUnix(TDateTime(Now), False);
  SignInput := APartnerID + AShopID + APath + IntToStr(Timestamp) + ABodyJson;
  Sign := ShopeeSignPartnerKey(APartnerKey, SignInput);
  Params := TStringList.Create;
  try
    Params.Delimiter := '&';
    Params.StrictDelimiter := True;
    Params.Add('partner_id=' + TNetEncoding.URL.Encode(APartnerID));
    Params.Add('timestamp=' + IntToStr(Timestamp));
    Params.Add('sign=' + TNetEncoding.URL.Encode(Sign));
    Params.Add('shop_id=' + TNetEncoding.URL.Encode(AShopID));
    Result := Params.DelimitedText;
  finally
    Params.Free;
  end;
end;

end.
