unit uEditProduto;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, uShopeeModels, uShopeeAPI;

type
  TfrmEditProduto = class(TForm)
    pnlMain: TPanel;
    lblNome: TLabel;
    edtNome: TEdit;
    lblPreco: TLabel;
    edtPreco: TEdit;
    lblEstoque: TLabel;
    edtEstoque: TEdit;
    btnSalvar: TButton;
    btnCancelar: TButton;
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FItem: TShopeeItem;
    FAPI: TShopeeAPI;
  public
    procedure Carregar(AItem: TShopeeItem; AAPI: TShopeeAPI);
  end;

var
  frmEditProduto: TfrmEditProduto;

implementation

{$R *.dfm}

procedure TfrmEditProduto.Carregar(AItem: TShopeeItem; AAPI: TShopeeAPI);
begin
  FItem := AItem;
  FAPI := AAPI;
  Caption := 'Editar: ' + AItem.ItemName;
  edtNome.Text := AItem.ItemName;
  edtNome.ReadOnly := True;
  edtPreco.Text := FormatFloat('0.00', AItem.Price);
  edtEstoque.Text := IntToStr(AItem.Stock);
end;

procedure TfrmEditProduto.btnSalvarClick(Sender: TObject);
var
  P: Double;
  S: Int64;
begin
  if not TryStrToFloat(edtPreco.Text, P) or (P < 0) then
  begin
    ShowMessage('Informe um preço válido.');
    edtPreco.SetFocus;
    Exit;
  end;
  if not TryStrToInt64(edtEstoque.Text, S) or (S < 0) then
  begin
    ShowMessage('Informe um estoque válido.');
    edtEstoque.SetFocus;
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    try
      if not FAPI.UpdatePrice(FItem.ItemID, P, 0) then
        Exit;
      if not FAPI.UpdateStock(FItem.ItemID, S, 0) then
        Exit;
      ModalResult := mrOk;
      Close;
    except
      on E: Exception do
        ShowMessage('Erro: ' + E.Message);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmEditProduto.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  Close;
end;

end.
