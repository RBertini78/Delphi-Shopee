unit uDetalheOrdem;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, uShopeeModels;

type
  TfrmDetalheOrdem = class(TForm)
    pnlTop: TPanel;
    MemoDetalhe: TMemo;
    btnFechar: TButton;
    procedure btnFecharClick(Sender: TObject);
  private
  public
    procedure Exibir(ADetalhe: TShopeeOrderDetail);
  end;

var
  frmDetalheOrdem: TfrmDetalheOrdem;

implementation

{$R *.dfm}

procedure TfrmDetalheOrdem.Exibir(ADetalhe: TShopeeOrderDetail);
var
  i: Integer;
  OI: TShopeeOrderItem;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('Order SN: ' + ADetalhe.OrderSN);
    SL.Add('Status: ' + ADetalhe.OrderStatus);
    SL.Add('Total: ' + ADetalhe.TotalAmountFormatted);
    SL.Add('Data: ' + ADetalhe.CreateTimeFormatted);
    SL.Add('Comprador: ' + ADetalhe.BuyerUserName);
    SL.Add('Endereço: ' + ADetalhe.RecipientAddress);
    SL.Add('');
    SL.Add('--- Itens ---');
    for i := 0 to ADetalhe.Items.Count - 1 do
    begin
      OI := ADetalhe.Items[i];
      SL.Add(Format('%s x %d = %s', [OI.ItemName, OI.Quantity, OI.PriceFormatted]));
      if OI.ModelName <> '' then
        SL.Add('  Modelo: ' + OI.ModelName);
    end;
    MemoDetalhe.Lines.Assign(SL);
  finally
    SL.Free;
  end;
  Caption := 'Detalhes da Ordem ' + ADetalhe.OrderSN;
end;

procedure TfrmDetalheOrdem.btnFecharClick(Sender: TObject);
begin
  Close;
end;

end.
