# Shopee - Integração Delphi 12

Aplicação VCL em Delphi 12 para integrar com a Shopee Open Platform v2: listar produtos (estoque e preço), atualizar preço/estoque e listar ordens com detalhes.

## Manual do Desenvolvedor

Veja o manual completo (setup, arquitetura, depuração e extensão): `MANUAL_DO_DESENVOLVEDOR.md`.

## Requisitos

- Delphi 12 (RAD Studio 12)
- Indy (incluído no Delphi)
- OpenSSL (para HMAC-SHA256; as DLLs do Indy costumam incluir)

## Como compilar

1. Abra o projeto no Delphi 12: `Shopee.dpr`
2. Compile com **Project > Build All** ou **Shift+F9**
3. O executável será gerado na pasta do projeto ou em `.\Win32\Debug` / `.\Win32\Release`

## Configuração

1. Execute o programa e clique em **Configuração**
2. Preencha:
   - **Base URL**: `https://partner.shopeemobile.com` (produção) ou `https://partner.test-stable.shopeemobile.com` (testes)
   - **Partner ID** e **Partner Key**: obtidos no [Shopee Partner Center](https://partner.shopeemobile.com)
   - **Access Token** e **Shop ID**: obtidos após autorização OAuth da loja (ou token de teste conforme documentação)
3. Clique em **Salvar**. As credenciais são gravadas em `Documents\ShopeeConfig.ini`

## Uso

- **Produtos**: aba Produtos > **Atualizar** para carregar a lista. Selecione um produto e **Editar Preço/Estoque** (ou duplo clique) para alterar preço e estoque.
- **Ordens**: aba Ordens > **Atualizar** para listar pedidos dos últimos 30 dias. Selecione uma ordem e **Ver Detalhes** (ou duplo clique) para ver itens, endereço e totais.

## Estrutura do projeto

| Arquivo        | Descrição |
|----------------|-----------|
| `uShopeeAuth.pas` | Assinatura HMAC-SHA256 e parâmetros de query da API |
| `uShopeeAPI.pas`   | Cliente HTTP e chamadas à API (produtos, ordens, update) |
| `uShopeeModels.pas` | Modelos de dados (item, ordem, detalhe) |
| `uConfig.pas/dfm`  | Tela de configuração e persistência em INI |
| `uEditProduto.pas/dfm` | Tela de edição de preço e estoque |
| `uDetalheOrdem.pas/dfm` | Tela de detalhes do pedido |
| `uMain.pas/dfm`   | Formulário principal com abas Produtos e Ordens |

## API Shopee

Endpoints utilizados:

- `GET /api/v2/product/get_item_list` – listar produtos (paginado)
- `POST /api/v2/product/update_price` – atualizar preço
- `POST /api/v2/product/update_stock` – atualizar estoque
- `GET /api/v2/order/get_order_list` – listar ordens
- `GET /api/v2/order/get_order_detail` – detalhe do pedido

Documentação: [Shopee Open Platform](https://open.shopee.com/documents/v2/)
