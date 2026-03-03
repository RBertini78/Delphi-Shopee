unit uShopeeAPI;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.NetEncoding,
  uShopeeAuth, uShopeeModels, uShopeeOAuth, Net.HttpClient, System.Generics.Collections;

type
  TShopeeAPI = class
  private
    FBaseURL: string;
    FPartnerID: string;
    FPartnerKey: string;
    FAccessToken: string;
    FShopID: string;
    FRefreshToken: string;
    FExpiresAt: Int64;
    FHTTP: THTTPClient;
    FOnTokensRefreshed: TProc<string, string, Int64>;
    function BuildURL(const APath: string; const AExtraParams: array of TPair<string, string>): string;
    function DoGET(const APath: string; const AExtraParams: array of TPair<string, string>): string;
    function DoPOST(const APath: string; const ABody: TJSONObject): string;
    procedure EnsureValidToken;
    function ParseItemFromJSON(AItem: TJSONObject): TShopeeItem;
    function ParseOrderFromJSON(AOrder: TJSONObject): TShopeeOrderSummary;
  public
    constructor Create;
    destructor Destroy; override;
    function GetItemList: TShopeeItemList;
    function UpdatePrice(AItemID: Int64; APrice: Double; AModelID: Int64 = 0): Boolean;
    function UpdateStock(AItemID: Int64; AStock: Int64; AModelID: Int64 = 0): Boolean;
    function GetOrderList(ADaysBack: Integer = 30): TShopeeOrderList;
    function GetOrderDetail(const AOrderSN: string): TShopeeOrderDetail;
    property BaseURL: string read FBaseURL write FBaseURL;
    property PartnerID: string read FPartnerID write FPartnerID;
    property PartnerKey: string read FPartnerKey write FPartnerKey;
    property AccessToken: string read FAccessToken write FAccessToken;
    property ShopID: string read FShopID write FShopID;
    property RefreshToken: string read FRefreshToken write FRefreshToken;
    property ExpiresAt: Int64 read FExpiresAt write FExpiresAt;
    property OnTokensRefreshed: TProc<string, string, Int64> read FOnTokensRefreshed write FOnTokensRefreshed;
  end;

implementation

uses
  System.DateUtils, System.Net.URLClient, System.NetConsts;

function JStr(O: TJSONObject; const Key: string; const Def: string = ''): string;
var V: TJSONValue;
begin
  Result := Def;
  if O = nil then Exit;
  V := O.GetValue(Key);
  if (V <> nil) and (V is TJSONString) then Result := (V as TJSONString).Value;
end;

function JInt64(O: TJSONObject; const Key: string; Def: Int64 = 0): Int64;
var V: TJSONValue;
begin
  Result := Def;
  if O = nil then Exit;
  V := O.GetValue(Key);
  if V = nil then Exit;
  if V is TJSONNumber then Result := (V as TJSONNumber).AsInt64 else Result := StrToInt64Def(V.Value, Def);
end;

function JInt(O: TJSONObject; const Key: string; Def: Integer = 0): Integer;
var V: TJSONValue;
begin
  Result := Def;
  if O = nil then Exit;
  V := O.GetValue(Key);
  if V = nil then Exit;
  if V is TJSONNumber then Result := (V as TJSONNumber).AsInt else Result := StrToIntDef(V.Value, Def);
end;

function JDouble(O: TJSONObject; const Key: string; Def: Double = 0): Double;
var V: TJSONValue;
begin
  Result := Def;
  if O = nil then Exit;
  V := O.GetValue(Key);
  if (V <> nil) and (V is TJSONNumber) then Result := (V as TJSONNumber).AsDouble;
end;

function JBool(O: TJSONObject; const Key: string; Def: Boolean = False): Boolean;
var V: TJSONValue;
begin
  Result := Def;
  if O = nil then Exit;
  V := O.GetValue(Key);
  if V = nil then Exit;
  if V is TJSONTrue then Result := True else if V is TJSONFalse then Result := False;
end;

function JObj(O: TJSONObject; const Key: string): TJSONObject;
var V: TJSONValue;
begin
  Result := nil;
  if O = nil then Exit;
  V := O.GetValue(Key);
  if (V <> nil) and (V is TJSONObject) then Result := V as TJSONObject;
end;

function JArr(O: TJSONObject; const Key: string): TJSONArray;
var V: TJSONValue;
begin
  Result := nil;
  if O = nil then Exit;
  V := O.GetValue(Key);
  if (V <> nil) and (V is TJSONArray) then Result := V as TJSONArray;
end;

const
  PATH_GET_ITEM_LIST = '/api/v2/product/get_item_list';
  PATH_UPDATE_PRICE = '/api/v2/product/update_price';
  PATH_UPDATE_STOCK = '/api/v2/product/update_stock';
  PATH_GET_ORDER_LIST = '/api/v2/order/get_order_list';
  PATH_GET_ORDER_DETAIL = '/api/v2/order/get_order_detail';

{ TShopeeAPI }

constructor TShopeeAPI.Create;
begin
  inherited Create;
  FBaseURL := 'https://partner.shopeemobile.com';
  FHTTP := THTTPClient.Create;
  FHTTP.ContentType := 'application/json';
  FHTTP.AcceptEncoding := 'utf-8';
end;

destructor TShopeeAPI.Destroy;
begin
  FHTTP.Free;
  inherited;
end;

const
  TOKEN_EXPIRE_MARGIN_SEC = 300;

procedure TShopeeAPI.EnsureValidToken;
var
  NowUnix: Int64;
  TokenResult: TShopeeTokenResult;
begin
  if FRefreshToken = '' then Exit;
  NowUnix := DateTimeToUnix(Now, False);
  if FExpiresAt > 0 then
    if NowUnix + TOKEN_EXPIRE_MARGIN_SEC < FExpiresAt then Exit;
  if not RefreshAccessToken(FBaseURL, FPartnerID, FPartnerKey, FShopID, FRefreshToken, TokenResult) then
    raise Exception.Create('Token expirado. Use Configuração > Conectar com Shopee para autorizar novamente.');
  FAccessToken := TokenResult.AccessToken;
  FExpiresAt := TokenResult.ExpiresAt;
  if TokenResult.RefreshToken <> '' then
    FRefreshToken := TokenResult.RefreshToken;
  if Assigned(FOnTokensRefreshed) then
    FOnTokensRefreshed(FAccessToken, FRefreshToken, FExpiresAt);
end;

function TShopeeAPI.BuildURL(const APath: string; const AExtraParams: array of TPair<string, string>): string;
var
  Q: string;
begin
  Q := BuildShopeeQueryParams(FPartnerID, FPartnerKey, FAccessToken, FShopID, APath, AExtraParams);
  Result := FBaseURL + APath + '?' + Q;
end;

function TShopeeAPI.DoGET(const APath: string; const AExtraParams: array of TPair<string, string>): string;
var
  URL: string;
  Resp: IHTTPResponse;
begin
  EnsureValidToken;
  URL := BuildURL(APath, AExtraParams);
  Resp := FHTTP.Get(URL);
  Result := Resp.ContentAsString;
  if Resp.StatusCode <> 200 then
    raise Exception.Create(Format('HTTP %d: %s', [Resp.StatusCode, Result]));
end;

function TShopeeAPI.DoPOST(const APath: string; const ABody: TJSONObject): string;
var
  URL: string;
  Q: string;
  BodyStr: string;
  Stream: TStringStream;
  Resp: IHTTPResponse;
begin
  EnsureValidToken;
  Q := BuildShopeeQueryParams(FPartnerID, FPartnerKey, FAccessToken, FShopID, APath, []);
  URL := FBaseURL + APath + '?' + Q;
  BodyStr := ABody.ToJSON;
  Stream := TStringStream.Create(BodyStr, TEncoding.UTF8);
  try
    Resp := FHTTP.Post(URL, Stream);
    Result := Resp.ContentAsString;
    if Resp.StatusCode <> 200 then
      raise Exception.Create(Format('HTTP %d: %s', [Resp.StatusCode, Result]));
  finally
    Stream.Free;
  end;
end;

function TShopeeAPI.ParseItemFromJSON(AItem: TJSONObject): TShopeeItem;
var
  O: TJSONObject;
  Arr: TJSONArray;
  i: Integer;
  StockVal: Int64;
  M: TShopeeItemModel;
  V: TJSONValue;
begin
  Result := TShopeeItem.Create;
  try
    Result.ItemID := JInt64(AItem, 'item_id');
    Result.ItemName := JStr(AItem, 'item_name');
    Result.Status := JStr(AItem, 'status');
    Result.SKU := JStr(AItem, 'item_sku');
    if Result.SKU = '' then Result.SKU := JStr(AItem, 'sku');

    O := JObj(AItem, 'price_info');
    if O <> nil then
    begin
      Arr := JArr(O, 'current_price');
      if (Arr <> nil) and (Arr.Count > 0) then
      begin
        V := Arr.Items[0];
        if V is TJSONNumber then
          Result.Price := (V as TJSONNumber).AsDouble;
      end
      else
        Result.Price := JDouble(O, 'current_price');
    end;

    O := JObj(AItem, 'stock_info');
    if O <> nil then
    begin
      Arr := JArr(O, 'stock_list');
      if Arr <> nil then
      begin
        Result.Stock := 0;
        for i := 0 to Arr.Count - 1 do
        begin
          if Arr.Items[i] is TJSONObject then
            StockVal := JInt64(Arr.Items[i] as TJSONObject, 'normal_stock')
          else if Arr.Items[i] is TJSONNumber then
            StockVal := (Arr.Items[i] as TJSONNumber).AsInt64
          else
            StockVal := 0;
          Result.Stock := Result.Stock + StockVal;
        end;
      end;
      if Result.Stock = 0 then
        Result.Stock := JInt64(O, 'total_reserved_stock');
      if Result.Stock = 0 then
        Result.Stock := JInt64(O, 'summary_total_stock');
    end;

    Arr := JArr(AItem, 'model');
    if Arr <> nil then
      for i := 0 to Arr.Count - 1 do
        if Arr.Items[i] is TJSONObject then
        begin
          O := Arr.Items[i] as TJSONObject;
          M := TShopeeItemModel.Create;
          M.ModelID := JInt64(O, 'model_id');
          M.ModelSKU := JStr(O, 'model_sku');
          Result.Models.Add(M);
        end;
  except
    Result.Free;
    raise;
  end;
end;

function TShopeeAPI.GetItemList: TShopeeItemList;
var
  Resp: string;
  Root, JResp: TJSONObject;
  Arr: TJSONArray;
  HasNext: Boolean;
  Offset, PageSize: Integer;
  i: Integer;
  Item: TShopeeItem;
begin
  Result := TShopeeItemList.Create(True);
  Offset := 0;
  PageSize := 100;
  HasNext := True;
  while HasNext do
  begin
    Resp := DoGET(PATH_GET_ITEM_LIST, [
      TPair<string, string>.Create('offset', IntToStr(Offset)),
      TPair<string, string>.Create('page_size', IntToStr(PageSize))
    ]);
    Root := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Root = nil then Exit;
    try
      if JStr(Root, 'error') <> '' then
        raise Exception.Create(JStr(Root, 'message', JStr(Root, 'error', 'Unknown error')));
      JResp := JObj(Root, 'response');
      if JResp = nil then Break;
      Arr := JArr(JResp, 'item_list');
      if Arr = nil then Break;
      for i := 0 to Arr.Count - 1 do
        if Arr.Items[i] is TJSONObject then
        begin
          Item := ParseItemFromJSON(Arr.Items[i] as TJSONObject);
          Result.Add(Item);
        end;
      HasNext := JBool(JResp, 'has_next_page');
      if HasNext then
        Offset := JInt(JResp, 'next_offset');
    finally
      Root.Free;
    end;
  end;
end;

function TShopeeAPI.UpdatePrice(AItemID: Int64; APrice: Double; AModelID: Int64): Boolean;
var
  Body: TJSONObject;
  Resp: string;
  Root: TJSONObject;
  Err: string;
begin
  Body := TJSONObject.Create;
  try
    Body.AddPair('item_id', TJSONNumber.Create(AItemID));
    Body.AddPair('price', TJSONNumber.Create(APrice));
    if AModelID <> 0 then
      Body.AddPair('model_id', TJSONNumber.Create(AModelID));
    Resp := DoPOST(PATH_UPDATE_PRICE, Body);
    Root := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Root = nil then
      Exit(False);
    try
      Err := JStr(Root, 'error');
      Result := Err = '';
      if not Result then
        raise Exception.Create(JStr(Root, 'message', Err));
    finally
      Root.Free;
    end;
  finally
    Body.Free;
  end;
end;

function TShopeeAPI.UpdateStock(AItemID: Int64; AStock: Int64; AModelID: Int64): Boolean;
var
  Body: TJSONObject;
  StockArr: TJSONArray;
  StockObj: TJSONObject;
  Resp: string;
  Root: TJSONObject;
  Err: string;
begin
  Body := TJSONObject.Create;
  try
    Body.AddPair('item_id', TJSONNumber.Create(AItemID));
    StockArr := TJSONArray.Create;
    StockObj := TJSONObject.Create;
    StockObj.AddPair('model_id', TJSONNumber.Create(AModelID));
    StockObj.AddPair('normal_stock', TJSONNumber.Create(AStock));
    StockArr.AddElement(StockObj);
    Body.AddPair('stock_list', StockArr);
    Resp := DoPOST(PATH_UPDATE_STOCK, Body);
    Root := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Root = nil then
      Exit(False);
    try
      Err := JStr(Root, 'error');
      Result := Err = '';
      if not Result then
        raise Exception.Create(JStr(Root, 'message', Err));
    finally
      Root.Free;
    end;
  finally
    Body.Free;
  end;
end;

function TShopeeAPI.ParseOrderFromJSON(AOrder: TJSONObject): TShopeeOrderSummary;
var
  O: TJSONObject;
  T: Int64;
  D: TDateTime;
begin
  Result := TShopeeOrderSummary.Create;
  Result.OrderSN := JStr(AOrder, 'order_sn');
  Result.OrderStatus := JStr(AOrder, 'order_status');
  O := JObj(AOrder, 'total_amount');
  if O <> nil then
    Result.TotalAmount := JDouble(O, 'value');
  Result.TotalAmountFormatted := FormatFloat('0.00', Result.TotalAmount);
  T := JInt64(AOrder, 'create_time');
  if T <> 0 then
  begin
    Result.CreateTime := T;
    D := UnixToDateTime(T, False);
    Result.CreateTimeFormatted := FormatDateTime('dd/mm/yyyy hh:nn', D);
  end;
  Result.BuyerUserName := JStr(AOrder, 'buyer_user_name');
  Result.ItemCount := JInt(AOrder, 'item_count');
end;

function TShopeeAPI.GetOrderList(ADaysBack: Integer): TShopeeOrderList;
var
  Resp: string;
  Root, JResp: TJSONObject;
  Arr: TJSONArray;
  HasNext: Boolean;
  Cursor: string;
  TimeFrom, TimeTo: Int64;
  i: Integer;
  Ord: TShopeeOrderSummary;
begin
  Result := TShopeeOrderList.Create(True);
  TimeTo := DateTimeToUnix(Now, False);
  TimeFrom := TimeTo - (ADaysBack * 24 * 3600);
  Cursor := '';
  HasNext := True;
  while HasNext do
  begin
    Resp := DoGET(PATH_GET_ORDER_LIST, [
      TPair<string, string>.Create('time_range_field', 'create_time'),
      TPair<string, string>.Create('time_from', IntToStr(TimeFrom)),
      TPair<string, string>.Create('time_to', IntToStr(TimeTo)),
      TPair<string, string>.Create('page_size', '100'),
      TPair<string, string>.Create('cursor', Cursor)
    ]);
    Root := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
    if Root = nil then Exit;
    try
      if JStr(Root, 'error') <> '' then
        raise Exception.Create(JStr(Root, 'message', JStr(Root, 'error', 'Unknown error')));
      JResp := JObj(Root, 'response');
      if JResp = nil then Break;
      Arr := JArr(JResp, 'order_list');
      if Arr = nil then Break;
      for i := 0 to Arr.Count - 1 do
        if Arr.Items[i] is TJSONObject then
        begin
          Ord := ParseOrderFromJSON(Arr.Items[i] as TJSONObject);
          Result.Add(Ord);
        end;
      HasNext := JBool(JResp, 'more');
      if HasNext then
        Cursor := JStr(JResp, 'next_cursor');
    finally
      Root.Free;
    end;
  end;
end;

function TShopeeAPI.GetOrderDetail(const AOrderSN: string): TShopeeOrderDetail;
var
  Resp: string;
  Root, JResp: TJSONObject;
  Arr: TJSONArray;
  O: TJSONObject;
  i: Integer;
  OI: TShopeeOrderItem;
  AddrObj: TJSONObject;
  T: Int64;
  D: TDateTime;
begin
  Result := nil;
  Resp := DoGET(PATH_GET_ORDER_DETAIL, [
    TPair<string, string>.Create('order_sn_list', AOrderSN)
  ]);
  Root := TJSONObject.ParseJSONValue(Resp) as TJSONObject;
  if Root = nil then Exit;
  try
    if JStr(Root, 'error') <> '' then
      raise Exception.Create(JStr(Root, 'message', JStr(Root, 'error', 'Unknown error')));
    JResp := JObj(Root, 'response');
    if JResp = nil then Exit;
    Arr := JArr(JResp, 'order_list');
    if (Arr = nil) or (Arr.Count = 0) then Exit;
    O := Arr.Items[0] as TJSONObject;
    Result := TShopeeOrderDetail.Create;
    Result.OrderSN := JStr(O, 'order_sn');
    Result.OrderStatus := JStr(O, 'order_status');
    O := JObj(Arr.Items[0] as TJSONObject, 'total_amount');
    if O <> nil then
      Result.TotalAmount := JDouble(O, 'value');
    Result.TotalAmountFormatted := FormatFloat('0.00', Result.TotalAmount);
    T := JInt64(Arr.Items[0] as TJSONObject, 'create_time');
    if T <> 0 then
    begin
      Result.CreateTime := T;
      D := UnixToDateTime(T, False);
      Result.CreateTimeFormatted := FormatDateTime('dd/mm/yyyy hh:nn', D);
    end;
    Result.BuyerUserName := JStr(Arr.Items[0] as TJSONObject, 'buyer_user_name');
    AddrObj := JObj(Arr.Items[0] as TJSONObject, 'recipient_address');
    if AddrObj <> nil then
      Result.RecipientAddress := JStr(AddrObj, 'full_address');
    Arr := JArr(Arr.Items[0] as TJSONObject, 'item_list');
    if Arr <> nil then
      for i := 0 to Arr.Count - 1 do
        if Arr.Items[i] is TJSONObject then
        begin
          O := Arr.Items[i] as TJSONObject;
          OI := TShopeeOrderItem.Create;
          OI.ItemID := JInt64(O, 'item_id');
          OI.ItemName := JStr(O, 'item_name');
          OI.ModelID := JInt64(O, 'model_id');
          OI.ModelName := JStr(O, 'model_name');
          OI.Quantity := JInt(O, 'quantity');
          O := JObj(O, 'model_quantity_purchased');
          if O <> nil then
            OI.Quantity := JInt(O, 'quantity');
          O := JObj(Arr.Items[i] as TJSONObject, 'model_discounted_price');
          if O <> nil then
            OI.Price := JDouble(O, 'value');
          OI.PriceFormatted := FormatFloat('0.00', OI.Price);
          Result.Items.Add(OI);
        end;
  finally
    Root.Free;
  end;
end;

end.
