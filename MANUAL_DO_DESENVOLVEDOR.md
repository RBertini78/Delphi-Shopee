# Manual do Desenvolvedor — Shopee (Delphi/VCL)

Este documento descreve como **compilar**, **executar**, **configurar**, **depurar** e **estender** o projeto de integração com a Shopee Open Platform v2.

## Visão geral

- **Tipo de app**: VCL (Delphi 12), alvo **Win32**.
- **Funcionalidades atuais**:
  - Listar produtos (preço/estoque) e permitir atualização de preço/estoque.
  - Listar ordens (últimos N dias) e exibir detalhes (itens/endereço/total).
- **Endoints usados (v2)**:
  - `GET /api/v2/product/get_item_list`
  - `POST /api/v2/product/update_price`
  - `POST /api/v2/product/update_stock`
  - `GET /api/v2/order/get_order_list`
  - `GET /api/v2/order/get_order_detail`
- **Documentação oficial**: `https://open.shopee.com/documents/v2/`

## Estrutura do projeto (mapa rápido)

- `Shopee.dpr`: ponto de entrada do app e criação dos forms principais.
- `Shopee.dproj`: configurações do projeto (Debug/Release, Win32).
- `uMain.pas/.dfm`: form principal (abas Produtos/Ordens), grids e interação com API.
- `uConfig.pas/.dfm`: form de configuração e persistência em INI.
- `uShopeeAPI.pas`: cliente HTTP, construção de URL, GET/POST, paginação e parse JSON.
- `uShopeeAuth.pas`: assinatura HMAC-SHA256 e montagem de query string (partner_id/timestamp/sign/...); assinatura para endpoints de auth (sem access_token na base).
- `uShopeeOAuth.pas`: URL de autorização, troca de code por token (`auth/token/get`), refresh (`auth/access_token/get`).
- `uShopeeModels.pas`: modelos (`TShopeeItem`, `TShopeeOrderSummary`, `TShopeeOrderDetail` etc).
- `uEditProduto.pas/.dfm`: tela para editar preço/estoque de um item.
- `uDetalheOrdem.pas/.dfm`: tela de exibição de detalhes do pedido.

## Requisitos

- **Delphi**: RAD Studio / Delphi 12.
- **Bibliotecas**:
  - `Net.HttpClient` (HTTP), `System.JSON` (JSON)
  - Indy (para HMAC SHA-256 via OpenSSL; usado em `uShopeeAuth.pas`)
- **OpenSSL**:
  - O projeto chama `LoadOpenSSLLibrary` (Indy) e valida disponibilidade de SHA-256.
  - Se ocorrer erro como “SHA256 not available. Ensure OpenSSL is loaded.”, é indicação de que as DLLs do OpenSSL não estão disponíveis no ambiente de execução (ou incompatíveis).

## Como compilar e executar

1. Abra o projeto no Delphi 12 (`Shopee.dproj` ou `Shopee.dpr`).
2. Selecione **Win32** e **Debug** (ou **Release**).
3. Compile:
   - **Build All** (menu Project) ou `Shift+F9`.
4. Execute:
   - Dentro da IDE (Run) ou pelo executável gerado em `.\Win32\Debug\` / `.\Win32\Release\` (dependendo da configuração).

## Configuração (credenciais e ambiente)

### Tela de configuração

No app, clique em **Configuração** e preencha:

- **Base URL**
  - Produção: `https://partner.shopeemobile.com`
  - Teste (conforme docs do parceiro): `https://partner.test-stable.shopeemobile.com`
- **Partner ID** e **Partner Key**
  - Obtidos no Partner Center.
- **Shop ID**
  - Pode ser preenchido manualmente ou obtido automaticamente após autorizar no callback OAuth.
- **Conectar com Shopee**
  - Botão que inicia o fluxo OAuth: abre o navegador na URL de autorização da Shopee; após o vendedor autorizar, a Shopee redireciona para `http://127.0.0.1:8765/callback` com `code` e `shop_id`. O app captura esse callback (listener HTTP local na porta 8765), troca o code por `access_token` e `refresh_token`, persiste no INI e exibe "Conectado com sucesso." O **Access Token** não é mais digitado manualmente; é obtido apenas por autenticação.

### Onde a configuração é salva

As credenciais são persistidas em um INI no **Documents** do usuário:

- Caminho: `%USERPROFILE%\Documents\ShopeeConfig.ini`
- Seção: `[Shopee]`
- Chaves: `BaseURL`, `PartnerID`, `PartnerKey`, `AccessToken`, `ShopID`, `RefreshToken`, `ExpiresAt`

### Redirect URI no Partner Center

Para o fluxo OAuth funcionar, cadastre no Partner Center da Shopee a seguinte URL de callback:

- **Redirect URI**: `http://127.0.0.1:8765/callback`

O app sobe um servidor HTTP temporário na porta **8765** ao clicar em "Conectar com Shopee"; após o redirect da Shopee com `code` e `shop_id`, o app troca o code por tokens e encerra o listener.

### Boas práticas (segurança)

- **Não** versionar `ShopeeConfig.ini`.
- **Não** compartilhar `PartnerKey` (equivalente a segredo).
- Se o projeto evoluir para armazenar tokens/refresh token, considere **armazenamento seguro** (ex.: DPAPI/Windows Credential Manager) em vez de INI puro.

## Fluxo de execução do app (alto nível)

1. `uMain` cria `TShopeeAPI`.
2. Ao abrir o app, se faltar credenciais, abre a tela `uConfig`.
3. Para cada ação (listar produtos/ordens, etc.), `uMain` preenche as propriedades da API:
   - `BaseURL`, `PartnerID`, `PartnerKey`, `AccessToken`, `ShopID`, `RefreshToken`, `ExpiresAt`
4. `TShopeeAPI` em cada `DoGET`/`DoPOST` chama `EnsureValidToken`:
   - Se o token estiver expirado (ou próximo, margem de 5 min), chama o endpoint de refresh e atualiza tokens (e persiste via `OnTokensRefreshed`).
5. Em seguida monta URL com `BuildShopeeQueryParams(...)` (inclui `sign`), faz request com `THTTPClient`, e trata erros como antes.

## Assinatura (HMAC-SHA256) e query params

### O que é assinado

O código atual monta a base string como:

`partner_id + api_path + timestamp + access_token + shop_id`

E calcula:

`sign = HMAC_SHA256(base_string, partner_key)`

Depois envia na query:

- `partner_id`
- `timestamp`
- `sign`
- `access_token`
- `shop_id`
- + parâmetros extras do endpoint (`offset`, `page_size`, `cursor`, etc.)

### Pontos de atenção

- Para **endpoints de negócio** (produto, ordem), a base do sign é `partner_id + path + timestamp + access_token + shop_id`.
- Para **endpoints de autenticação** (`auth/token/get`, `auth/access_token/get`) a base é apenas `partner_id + path + timestamp` (sem access_token); o projeto usa `GetShopeeAuthSign` em `uShopeeAuth.pas` para isso.
- `timestamp` é gerado com `DateTimeToUnix(Now, False)`.
- A dependência de OpenSSL fica em runtime (Indy).

## Endpoints implementados e paginação

### Produtos: `get_item_list`

- Método: `TShopeeAPI.GetItemList`
- Paginação: `offset` + `page_size` com `has_next_page`/`next_offset`.
- Observação: o parse tenta ser tolerante a variações de formato em `price_info` e `stock_info`.

### Ordens: `get_order_list`

- Método: `TShopeeAPI.GetOrderList(ADaysBack)`
- Intervalo: calcula `time_from/time_to` (Unix) com base em `Now` e `ADaysBack`.
- Paginação: `cursor` com `more`/`next_cursor`.

### Detalhe da ordem: `get_order_detail`

- Método: `TShopeeAPI.GetOrderDetail(order_sn)`
- O método atual pede `order_sn_list` com um único `order_sn` e lê o primeiro item de `order_list`.

## Como estender (novos endpoints)

### Checklist rápido

- **Adicionar o path** como constante em `uShopeeAPI.pas` (perto das existentes).
- **Criar método público** em `TShopeeAPI` (ex.: `GetSomething(...)`).
- Usar `DoGET` (query params extras) ou `DoPOST` (body JSON).
- **Parsear** o JSON com os helpers (`JStr`, `JInt64`, `JArr`, etc.) e mapear para um model em `uShopeeModels.pas` (se necessário).
- Ajustar a UI em `uMain` (ou criar um novo form) para exibir/editar os dados.

### Padrão de implementação

- GET:
  - `Resp := DoGET(PATH_..., [TPair.Create('param','value'), ...]);`
  - `Root := TJSONObject.ParseJSONValue(Resp) as TJSONObject;`
  - Verificar `error/message` e usar `response`.
- POST:
  - Criar `TJSONObject` com o body.
  - `Resp := DoPOST(PATH_..., Body);`
  - Verificar `error/message`.

## Tratamento de erros e depuração

### Erros comuns

- **HTTP != 200**: o código levanta `Exception` com corpo da resposta (útil para depurar).
- **Erro lógico da Shopee**: quando o JSON vem com `error` preenchido, o código levanta exception usando `message` (quando existe).
- **OpenSSL/SHA256** indisponível: indica dependência de runtime faltando.

### Dicas de depuração na prática

- Coloque breakpoints em:
  - `TShopeeAPI.DoGET`, `TShopeeAPI.DoPOST`
  - `BuildShopeeQueryParams` / `ShopeeSign`
- Inspecione:
  - URL final gerada (inclui query e `sign`)
  - Corpo do POST (`ABody.ToJSON`)
  - Resposta completa (`Resp.ContentAsString`)

## OAuth / Refresh Token (implementado)

O app implementa o fluxo OAuth da Shopee Open Platform v2 para obter e renovar o Access Token.

### Fluxo implementado

1. **Autorização**
   - Na tela de Configuração, o usuário preenche Base URL, Partner ID e Partner Key e clica em **Conectar com Shopee**.
   - O app sobe um listener HTTP em `http://127.0.0.1:8765/callback` e abre no navegador a URL de autorização (`/api/v2/shop/auth_partner?partner_id=...&redirect=...`).
2. **Callback**
   - Após o vendedor autorizar, a Shopee redireciona para a redirect_uri com `code` e `shop_id`. O listener captura esses parâmetros.
3. **Troca de code por token**
   - O app chama `POST /api/v2/auth/token/get` com `partner_id`, `code`, `shop_id`, `sign`, `timestamp` (sign com base `partner_id + path + timestamp`). Recebe `access_token` (c. 4h) e `refresh_token` (c. 30 dias).
4. **Persistência**
   - Os valores são gravados no INI: `AccessToken`, `RefreshToken`, `ExpiresAt` (timestamp Unix). O Shop ID é atualizado quando vindo do callback.
5. **Refresh automático**
   - Antes de cada `DoGET`/`DoPOST`, `TShopeeAPI.EnsureValidToken` verifica se o token está válido (agora + 5 min < ExpiresAt). Se expirado ou próximo, chama `POST /api/v2/auth/access_token/get` com `refresh_token`, atualiza Access Token e ExpiresAt e persiste via callback `OnTokensRefreshed`. Se o refresh falhar, é exibida mensagem para o usuário usar novamente "Conectar com Shopee".

### Redirect URI

- Cadastre no Partner Center: **`http://127.0.0.1:8765/callback`**
- A porta 8765 é fixa no código (`uConfig.pas` / constante no `btnConectarClick`).

### O que mudou no código

- **uShopeeAuth.pas**: adicionada `GetShopeeAuthSign(APartnerID, APartnerKey, APath; out ASign; out ATimestamp)` para assinatura dos endpoints de auth.
- **uShopeeOAuth.pas**: `BuildAuthorizationURL`, `ExchangeCodeForToken`, `RefreshAccessToken`; constantes de path e porta.
- **uConfig**: botão "Conectar com Shopee", listener `TIdHTTPServer` na porta 8765, persistência de `RefreshToken` e `ExpiresAt`, método `SaveTokens` para atualizar INI após refresh.
- **uShopeeAPI**: propriedades `RefreshToken`, `ExpiresAt`, `OnTokensRefreshed`; método `EnsureValidToken` chamado no início de `DoGET` e `DoPOST`.
- **uMain**: repasse de RefreshToken/ExpiresAt para a API e atribuição de `OnTokensRefreshed` para chamar `frmConfig.SaveTokens`. Critério de credenciais: Partner ID, Partner Key, Shop ID e (Access Token ou Refresh Token).

## Checklist de release (rápido)

- Build **Release/Win32**.

- Smoke test:
  - Listar produtos
  - Atualizar preço/estoque de um item de teste
  - Listar ordens (últimos 30 dias)
  - Abrir detalhe de uma ordem
- Validar ambiente com OpenSSL (assinatura funcionando).
- Validar OAuth: Configuração > Conectar com Shopee (redirect_uri cadastrada no Partner Center).

