object frmDetalheOrdem: TfrmDetalheOrdem
  Left = 0
  Top = 0
  Caption = 'Detalhes da Ordem'
  ClientHeight = 400
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 500
    Height = 41
    Align = alTop
    TabOrder = 0
    object btnFechar: TButton
      Left = 408
      Top = 8
      Width = 80
      Height = 28
      Caption = 'Fechar'
      TabOrder = 0
      OnClick = btnFecharClick
    end
  end
  object MemoDetalhe: TMemo
    Left = 0
    Top = 41
    Width = 500
    Height = 359
    Align = alClient
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
  end
end
