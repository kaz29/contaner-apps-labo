# Container App Jobsのプロビジョニング

## 設定が必要な環境変数

- RESOURCE_GROUP_NAME - リソースグループ名
- CONTAINER_IMAGE_NAME - デプロイするコンテナ名

```bash
az deployment group create \
    --template-file ./bicep/provision.bicep \
    --name "provision-queue-job-example" \
    --mode Complete \
    --resource-group $RESOURCE_GROUP_NAME \
    --parameters \
        containerImageName=$CONTAINER_IMAGE_NAME
```

