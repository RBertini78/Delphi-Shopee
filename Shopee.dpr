program Shopee;

uses
  System.SysUtils,
  System.Classes,
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  uShopeeAuth in 'uShopeeAuth.pas',
  uShopeeOAuth in 'uShopeeOAuth.pas',
  uShopeeAPI in 'uShopeeAPI.pas',
  uShopeeModels in 'uShopeeModels.pas',
  uConfig in 'uConfig.pas' {frmConfig};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Shopee - Produtos e Ordens';
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmConfig, frmConfig);
  Application.Run;
end.
