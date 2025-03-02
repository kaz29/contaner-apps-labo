# Azure Container Apps with Private Endpoint 

Container AppsがPrivate Endpointをサポートしたので、bicepでのプロビジョニングの実験用リポジトリ

- [x] 2024/11/24 - ひとまず、Container AppsをPrivate Endpointありで作って、nginx:latestのアプリをあげるところまで
- [ ] Front Doorを入れてPrivate Endpoint経由でアクセスできるようにする

## メモ

- 2024/11時点ではパブリックプレビュー
  - 本番利用非推奨
  - プレビュー中は無料、GA時の料金未定
- `Microsoft.App/managedEnvironments@2024-08-02-preview` で `publicNetworkAccess` が追加になっている
	- `@2024-03-01` で実行するとporalで指定したpublicNetworkAccessが更新されてしまう
  - まだドキュメントは更新されていない
- zoneRedundantを指定するにはVnet統合を有効にしないといけないので、現状指定できなそう
  - 早く対応してほしいなぁ...
- pepのGroupIdは `managedEnvironments`

## provision

```
az deployment group what-if \
  --template-file ./bicep/provision.bicep \
  --name "provision-from-local-diff" \
  --mode Complete \
  --resource-group rg-labo

az deployment group create \
  --template-file ./bicep/provision.bicep \
  --name "provision-from-local" \
  --mode Complete \
  --resource-group rg-labo

# なぜかプライベートエンドポイントが3個できた...
## 最後のconnectionを有効にすると繋がる
## プライベートエンドポイントと仮想ネットワークは共存できるか？
# 下記のapproveを自動化できないか？

az network private-endpoint-connection list \
    --name 'cae-kaz29-labo' \
    --resource-group 'rg-labo' \
    --type Microsoft.App/managedEnvironments

az network private-endpoint-connection approve --id \
/subscriptions/ac25fc44-3b4d-4b2f-917e-672509e414ca/resourceGroups/rg-labo/providers/Microsoft.App/managedEnvironments/cae-kaz29-labo/privateEndpointConnections/3f883dff-5885-4c40-815c-02386044f96b-a3b9179a-cbbc-49aa-86c6-85b7087e23a1
```

## LINK

- [Azure Container Apps 環境でプライベート エンドポイントを使用する](https://learn.microsoft.com/ja-jp/azure/container-apps/how-to-use-private-endpoint?pivots=azure-portal)
- [Azure Front Door を使用して Azure Container App へのプライベート リンクを作成する (プレビュー)](https://learn.microsoft.com/ja-jp/azure/container-apps/how-to-integrate-with-azure-front-door)