unit uShopeeModels;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TShopeeItemModel = class
  public
    ModelID: Int64;
    TierIndex: TArray<Integer>;
    ModelSKU: string;
    PriceInfo: TArray<Double>;
    StockInfo: TArray<Int64>;
    procedure Assign(ASource: TShopeeItemModel);
    function Clone: TShopeeItemModel;
  end;

  TShopeeItem = class
  private
    FItemID: Int64;
    FItemName: string;
    FPrice: Double;
    FStock: Int64;
    FStatus: string;
    FSKU: string;
    FModels: TObjectList<TShopeeItemModel>;
    function GetPriceFormatted: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TShopeeItem);
    function Clone: TObject;
    property ItemID: Int64 read FItemID write FItemID;
    property ItemName: string read FItemName write FItemName;
    property Price: Double read FPrice write FPrice;
    property Stock: Int64 read FStock write FStock;
    property Status: string read FStatus write FStatus;
    property SKU: string read FSKU write FSKU;
    property Models: TObjectList<TShopeeItemModel> read FModels;
    property PriceFormatted: string read GetPriceFormatted;
  end;

  TShopeeItemList = class(TObjectList<TShopeeItem>)
  public
    function FindByItemID(AItemID: Int64): TShopeeItem;
  end;

  TShopeeOrderSummary = class
  public
    OrderSN: string;
    OrderStatus: string;
    TotalAmount: Double;
    TotalAmountFormatted: string;
    CreateTime: Int64;
    CreateTimeFormatted: string;
    BuyerUserName: string;
    ItemCount: Integer;
  end;

  TShopeeOrderList = class(TObjectList<TShopeeOrderSummary>)
  end;

  TShopeeOrderItem = class
  public
    ItemID: Int64;
    ItemName: string;
    ModelID: Int64;
    ModelName: string;
    Quantity: Integer;
    Price: Double;
    PriceFormatted: string;
  end;

  TShopeeOrderDetail = class
  public
    OrderSN: string;
    OrderStatus: string;
    TotalAmount: Double;
    TotalAmountFormatted: string;
    CreateTime: Int64;
    CreateTimeFormatted: string;
    BuyerUserName: string;
    RecipientAddress: string;
    Items: TObjectList<TShopeeOrderItem>;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TShopeeItemModel }

procedure TShopeeItemModel.Assign(ASource: TShopeeItemModel);
begin
  if ASource = nil then Exit;
  ModelID := ASource.ModelID;
  TierIndex := ASource.TierIndex;
  ModelSKU := ASource.ModelSKU;
  PriceInfo := ASource.PriceInfo;
  StockInfo := ASource.StockInfo;
end;

function TShopeeItemModel.Clone: TShopeeItemModel;
begin
  Result := TShopeeItemModel.Create;
  Result.Assign(Self);
end;

{ TShopeeItem }

constructor TShopeeItem.Create;
begin
  inherited Create;
  FModels := TObjectList<TShopeeItemModel>.Create(True);
end;

destructor TShopeeItem.Destroy;
begin
  FModels.Free;
  inherited;
end;

function TShopeeItem.GetPriceFormatted: string;
begin
  Result := FormatFloat('0.00', FPrice);
end;

procedure TShopeeItem.Assign(ASource: TShopeeItem);
var
  M: TShopeeItemModel;
begin
  if ASource = nil then Exit;
  FItemID := ASource.FItemID;
  FItemName := ASource.FItemName;
  FPrice := ASource.FPrice;
  FStock := ASource.FStock;
  FStatus := ASource.FStatus;
  FSKU := ASource.FSKU;
  FModels.Clear;
  for M in ASource.FModels do
    FModels.Add(M.Clone);
end;

function TShopeeItem.Clone: TObject;
var
  C: TShopeeItem;
begin
  C := TShopeeItem.Create;
  C.Assign(Self);
  Result := C;
end;

{ TShopeeItemList }

function TShopeeItemList.FindByItemID(AItemID: Int64): TShopeeItem;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
    if Items[i].ItemID = AItemID then
      Exit(Items[i]);
end;

{ TShopeeOrderDetail }

constructor TShopeeOrderDetail.Create;
begin
  inherited Create;
  Items := TObjectList<TShopeeOrderItem>.Create(True);
end;

destructor TShopeeOrderDetail.Destroy;
begin
  Items.Free;
  inherited;
end;

end.
