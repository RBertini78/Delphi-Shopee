object frmConfig: TfrmConfig
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Configura'#231#227'o Shopee'
  ClientHeight = 300
  ClientWidth = 450
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 450
    Height = 300
    Align = alClient
    TabOrder = 0
    object lblBaseURL: TLabel
      Left = 16
      Top = 16
      Width = 48
      Height = 15
      Caption = 'Base URL'
    end
    object lblPartnerID: TLabel
      Left = 16
      Top = 68
      Width = 52
      Height = 15
      Caption = 'Partner ID'
    end
    object lblPartnerKey: TLabel
      Left = 16
      Top = 118
      Width = 60
      Height = 15
      Caption = 'Partner Key'
    end
    object lblAccessToken: TLabel
      Left = 16
      Top = 168
      Width = 71
      Height = 15
      Caption = 'Access Token'
      Visible = False
    end
    object lblStatusOAuth: TLabel
      Left = 16
      Top = 168
      Width = 216
      Height = 15
      Caption = 'Conecte com Shopee para obter o token.'
    end
    object lblShopID: TLabel
      Left = 16
      Top = 228
      Width = 41
      Height = 15
      Caption = 'Shop ID'
    end
    object edtBaseURL: TEdit
      Left = 16
      Top = 35
      Width = 410
      Height = 23
      TabOrder = 0
      Text = 'https://partner.shopeemobile.com'
    end
    object edtPartnerID: TEdit
      Left = 16
      Top = 87
      Width = 410
      Height = 23
      TabOrder = 1
    end
    object edtPartnerKey: TEdit
      Left = 16
      Top = 137
      Width = 410
      Height = 23
      PasswordChar = '*'
      TabOrder = 2
    end
    object edtAccessToken: TEdit
      Left = 16
      Top = 187
      Width = 410
      Height = 23
      TabOrder = 3
      Visible = False
    end
    object btnConectar: TButton
      Left = 16
      Top = 187
      Width = 150
      Height = 28
      Caption = 'Conectar com Shopee'
      TabOrder = 7
      OnClick = btnConectarClick
    end
    object edtShopID: TEdit
      Left = 16
      Top = 247
      Width = 200
      Height = 23
      TabOrder = 4
    end
    object btnSalvar: TButton
      Left = 248
      Top = 248
      Width = 85
      Height = 28
      Caption = 'Salvar'
      TabOrder = 5
      OnClick = btnSalvarClick
    end
    object btnFechar: TButton
      Left = 341
      Top = 248
      Width = 85
      Height = 28
      Caption = 'Fechar'
      TabOrder = 6
      OnClick = btnFecharClick
    end
  end
  object IdHTTP1: TIdHTTP
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentRangeInstanceLength = -1
    Request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoForceEncodeParams]
    Left = 408
    Top = 224
  end
end
