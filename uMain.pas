unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, uShopeeAPI, uShopeeModels, Vcl.Grids;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    btnConfig: TButton;
    PageControl1: TPageControl;
    tabProdutos: TTabSheet;
    tabOrdens: TTabSheet;
    pnlProdutos: TPanel;
    btnAtualizarProdutos: TButton;
    btnEditarProduto: TButton;
    GridProdutos: TStringGrid;
    pnlOrdens: TPanel;
    btnAtualizarOrdens: TButton;
    btnDetalheOrdem: TButton;
    GridOrdens: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConfigClick(Sender: TObject);
    procedure btnAtualizarProdutosClick(Sender: TObject);
    procedure btnEditarProdutoClick(Sender: TObject);
    procedure GridProdutosDblClick(Sender: TObject);
    procedure btnAtualizarOrdensClick(Sender: TObject);
    procedure btnDetalheOrdemClick(Sender: TObject);
    procedure GridOrdensDblClick(Sender: TObject);
  private
    FAPI: TShopeeAPI;
    FLastItemList: TShopeeItemList;
    procedure ConfigurarGridProdutos;
    procedure ConfigurarGridOrdens;
    procedure CarregarProdutos;
    procedure CarregarOrdens;
    function ObterProdutoSelecionado: TShopeeItem;
    function ObterOrdemSelecionada: TShopeeOrderSummary;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uConfig, uEditProduto, uDetalheOrdem;

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FAPI := TShopeeAPI.Create;
  FLastItemList := nil;
  ConfigurarGridProdutos;
  ConfigurarGridOrdens;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  if not frmConfig.CredenciaisPreenchidas then
    btnConfigClick(nil);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if FLastItemList <> nil then
    FLastItemList.Free;
  FAPI.Free;
end;

procedure TfrmMain.ConfigurarGridProdutos;
begin
  GridProdutos.ColCount := 6;
  GridProdutos.Cells[0, 0] := 'Item ID';
  GridProdutos.Cells[1, 0] := 'Nome';
  GridProdutos.Cells[2, 0] := 'Preço';
  GridProdutos.Cells[3, 0] := 'Estoque';
  GridProdutos.Cells[4, 0] := 'Status';
  GridProdutos.Cells[5, 0] := 'SKU';
  GridProdutos.RowCount := 1;
  GridProdutos.FixedRows := 0;
end;

procedure TfrmMain.ConfigurarGridOrdens;
begin
  GridOrdens.ColCount := 6;
  GridOrdens.Cells[0, 0] := 'Order SN';
  GridOrdens.Cells[1, 0] := 'Status';
  GridOrdens.Cells[2, 0] := 'Valor';
  GridOrdens.Cells[3, 0] := 'Data';
  GridOrdens.Cells[4, 0] := 'Comprador';
  GridOrdens.Cells[5, 0] := 'Itens';
  GridOrdens.RowCount := 1;
  GridOrdens.FixedRows := 0;
end;

procedure TfrmMain.btnConfigClick(Sender: TObject);
begin
  frmConfig.ShowModal;
  FAPI.BaseURL := frmConfig.GetBaseURL;
  FAPI.PartnerID := frmConfig.GetPartnerID;
  FAPI.PartnerKey := frmConfig.GetPartnerKey;
  FAPI.AccessToken := frmConfig.GetAccessToken;
  FAPI.ShopID := frmConfig.GetShopID;
  FAPI.RefreshToken := frmConfig.GetRefreshToken;
  FAPI.ExpiresAt := frmConfig.GetExpiresAt;
  FAPI.OnTokensRefreshed := procedure(AAccessToken, ARefreshToken: string; AExpiresAt: Int64)
    begin
      frmConfig.SaveTokens(AAccessToken, ARefreshToken, AExpiresAt);
    end;
end;

procedure TfrmMain.CarregarProdutos;
var
  Lista: TShopeeItemList;
  i: Integer;
begin
  if not frmConfig.CredenciaisPreenchidas then
  begin
    ShowMessage('Configure as credenciais em Configuração e use Conectar com Shopee para autorizar.');
    Exit;
  end;
  FAPI.BaseURL := frmConfig.GetBaseURL;
  FAPI.PartnerID := frmConfig.GetPartnerID;
  FAPI.PartnerKey := frmConfig.GetPartnerKey;
  FAPI.AccessToken := frmConfig.GetAccessToken;
  FAPI.ShopID := frmConfig.GetShopID;
  FAPI.RefreshToken := frmConfig.GetRefreshToken;
  FAPI.ExpiresAt := frmConfig.GetExpiresAt;

  Lista := FAPI.GetItemList;
  try
    if FLastItemList <> nil then
      FLastItemList.Free;
    FLastItemList := Lista;
    GridProdutos.RowCount := Lista.Count + 1;
    for i := 0 to Lista.Count - 1 do
    begin
      GridProdutos.Cells[0, i + 1] := IntToStr(Lista[i].ItemID);
      GridProdutos.Cells[1, i + 1] := Lista[i].ItemName;
      GridProdutos.Cells[2, i + 1] := Lista[i].PriceFormatted;
      GridProdutos.Cells[3, i + 1] := IntToStr(Lista[i].Stock);
      GridProdutos.Cells[4, i + 1] := Lista[i].Status;
      GridProdutos.Cells[5, i + 1] := Lista[i].SKU;
    end;
  except
    if FLastItemList = Lista then
      FLastItemList := nil;
    Lista.Free;
    raise;
  end;
end;

procedure TfrmMain.btnAtualizarProdutosClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    CarregarProdutos;
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TfrmMain.ObterProdutoSelecionado: TShopeeItem;
var
  idx: Integer;
  ItemID: Int64;
begin
  Result := nil;
  idx := GridProdutos.Row;
  if idx < 1 then
    Exit;
  if not TryStrToInt64(GridProdutos.Cells[0, idx], ItemID) then
    Exit;
  if FLastItemList = nil then
    Exit;
  Result := FLastItemList.FindByItemID(ItemID);
  if Result <> nil then
    Result := TShopeeItem(Result.Clone);
end;

procedure TfrmMain.btnEditarProdutoClick(Sender: TObject);
var
  Item: TShopeeItem;
begin
  Item := ObterProdutoSelecionado;
  if Item = nil then
  begin
    ShowMessage('Selecione um produto na grade.');
    Exit;
  end;
  try
    frmEditProduto := TfrmEditProduto.Create(Application);
    try
      frmEditProduto.Carregar(Item, FAPI);
      if frmEditProduto.ShowModal = mrOk then
        CarregarProdutos;
    finally
      frmEditProduto.Free;
    end;
  finally
    Item.Free;
  end;
end;

procedure TfrmMain.GridProdutosDblClick(Sender: TObject);
begin
  btnEditarProdutoClick(Sender);
end;

procedure TfrmMain.CarregarOrdens;
var
  Lista: TShopeeOrderList;
  i: Integer;
begin
  if not frmConfig.CredenciaisPreenchidas then
  begin
    ShowMessage('Configure as credenciais em Configuração e use Conectar com Shopee para autorizar.');
    Exit;
  end;
  FAPI.BaseURL := frmConfig.GetBaseURL;
  FAPI.PartnerID := frmConfig.GetPartnerID;
  FAPI.PartnerKey := frmConfig.GetPartnerKey;
  FAPI.AccessToken := frmConfig.GetAccessToken;
  FAPI.ShopID := frmConfig.GetShopID;
  FAPI.RefreshToken := frmConfig.GetRefreshToken;
  FAPI.ExpiresAt := frmConfig.GetExpiresAt;

  Lista := FAPI.GetOrderList(30);
  try
    GridOrdens.RowCount := Lista.Count + 1;
    for i := 0 to Lista.Count - 1 do
    begin
      GridOrdens.Cells[0, i + 1] := Lista[i].OrderSN;
      GridOrdens.Cells[1, i + 1] := Lista[i].OrderStatus;
      GridOrdens.Cells[2, i + 1] := Lista[i].TotalAmountFormatted;
      GridOrdens.Cells[3, i + 1] := Lista[i].CreateTimeFormatted;
      GridOrdens.Cells[4, i + 1] := Lista[i].BuyerUserName;
      GridOrdens.Cells[5, i + 1] := IntToStr(Lista[i].ItemCount);
    end;
  finally
    Lista.Free;
  end;
end;

procedure TfrmMain.btnAtualizarOrdensClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    CarregarOrdens;
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TfrmMain.ObterOrdemSelecionada: TShopeeOrderSummary;
var
  idx: Integer;
begin
  Result := TShopeeOrderSummary.Create;
  idx := GridOrdens.Row;
  if idx < 1 then
  begin
    Result.Free;
    Exit(nil);
  end;
  Result.OrderSN := GridOrdens.Cells[0, idx];
  Result.OrderStatus := GridOrdens.Cells[1, idx];
  Result.TotalAmountFormatted := GridOrdens.Cells[2, idx];
  Result.CreateTimeFormatted := GridOrdens.Cells[3, idx];
  Result.BuyerUserName := GridOrdens.Cells[4, idx];
  if not TryStrToInt(GridOrdens.Cells[5, idx], Result.ItemCount) then
    Result.ItemCount := 0;
end;

procedure TfrmMain.btnDetalheOrdemClick(Sender: TObject);
var
  Ord: TShopeeOrderSummary;
  Detalhe: TShopeeOrderDetail;
begin
  Ord := ObterOrdemSelecionada;
  if Ord = nil then
  begin
    ShowMessage('Selecione uma ordem na grade.');
    Exit;
  end;
  try
    Detalhe := FAPI.GetOrderDetail(Ord.OrderSN);
    if Detalhe = nil then
    begin
      ShowMessage('Não foi possível obter detalhes da ordem.');
      Exit;
    end;
    try
      frmDetalheOrdem := TfrmDetalheOrdem.Create(Application);
      try
        frmDetalheOrdem.Exibir(Detalhe);
        frmDetalheOrdem.ShowModal;
      finally
        frmDetalheOrdem.Free;
      end;
    finally
      Detalhe.Free;
    end;
  finally
    Ord.Free;
  end;
end;

procedure TfrmMain.GridOrdensDblClick(Sender: TObject);
begin
  btnDetalheOrdemClick(Sender);
end;

end.
