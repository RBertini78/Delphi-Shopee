object frmEditProduto: TfrmEditProduto
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Editar Produto'
  ClientHeight = 180
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 15
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 180
    Align = alClient
    TabOrder = 0
    object lblNome: TLabel
      Left = 16
      Top = 16
      Width = 33
      Height = 15
      Caption = 'Nome'
    end
    object lblPreco: TLabel
      Left = 16
      Top = 66
      Width = 30
      Height = 15
      Caption = 'Pre'#231'o'
    end
    object lblEstoque: TLabel
      Left = 160
      Top = 66
      Width = 42
      Height = 15
      Caption = 'Estoque'
    end
    object edtNome: TEdit
      Left = 16
      Top = 35
      Width = 360
      Height = 23
      TabOrder = 0
    end
    object edtPreco: TEdit
      Left = 16
      Top = 85
      Width = 120
      Height = 23
      TabOrder = 1
    end
    object edtEstoque: TEdit
      Left = 160
      Top = 85
      Width = 120
      Height = 23
      TabOrder = 2
    end
    object btnSalvar: TButton
      Left = 208
      Top = 136
      Width = 80
      Height = 28
      Caption = 'Salvar'
      TabOrder = 3
      OnClick = btnSalvarClick
    end
    object btnCancelar: TButton
      Left = 296
      Top = 136
      Width = 80
      Height = 28
      Caption = 'Cancelar'
      TabOrder = 4
      OnClick = btnCancelarClick
    end
  end
end
