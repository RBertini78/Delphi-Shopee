object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Shopee - Produtos e Ordens'
  ClientHeight = 500
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 49
    Align = alTop
    TabOrder = 0
    object btnConfig: TButton
      Left = 8
      Top = 10
      Width = 100
      Height = 28
      Caption = 'Configura'#231#227'o'
      TabOrder = 0
      OnClick = btnConfigClick
    end
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 49
    Width = 800
    Height = 451
    ActivePage = tabProdutos
    Align = alClient
    TabOrder = 1
    object tabProdutos: TTabSheet
      Caption = 'Produtos'
      object pnlProdutos: TPanel
        Left = 0
        Top = 0
        Width = 792
        Height = 41
        Align = alTop
        TabOrder = 0
        object btnAtualizarProdutos: TButton
          Left = 8
          Top = 8
          Width = 100
          Height = 28
          Caption = 'Atualizar'
          TabOrder = 0
          OnClick = btnAtualizarProdutosClick
        end
        object btnEditarProduto: TButton
          Left = 114
          Top = 8
          Width = 120
          Height = 28
          Caption = 'Editar Pre'#231'o/Estoque'
          TabOrder = 1
          OnClick = btnEditarProdutoClick
        end
      end
      object GridProdutos: TStringGrid
        Left = 0
        Top = 41
        Width = 792
        Height = 380
        Align = alClient
        ColCount = 6
        DefaultRowHeight = 20
        FixedCols = 0
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
        TabOrder = 1
        OnDblClick = GridProdutosDblClick
      end
    end
    object tabOrdens: TTabSheet
      Caption = 'Ordens'
      ImageIndex = 1
      object pnlOrdens: TPanel
        Left = 0
        Top = 0
        Width = 792
        Height = 41
        Align = alTop
        TabOrder = 0
        object btnAtualizarOrdens: TButton
          Left = 8
          Top = 8
          Width = 100
          Height = 28
          Caption = 'Atualizar'
          TabOrder = 0
          OnClick = btnAtualizarOrdensClick
        end
        object btnDetalheOrdem: TButton
          Left = 114
          Top = 8
          Width = 100
          Height = 28
          Caption = 'Ver Detalhes'
          TabOrder = 1
          OnClick = btnDetalheOrdemClick
        end
      end
      object GridOrdens: TStringGrid
        Left = 0
        Top = 41
        Width = 792
        Height = 380
        Align = alClient
        ColCount = 6
        DefaultRowHeight = 20
        FixedCols = 0
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
        TabOrder = 1
        OnDblClick = GridOrdensDblClick
      end
    end
  end
end
