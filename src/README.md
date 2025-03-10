# AWS Cognito 認証設定

このプロジェクトは、AWS Cognito ユーザープールとID プールを設定するためのCloudFormation テンプレートを提供します。

## テンプレートの概要

`src/templates/cognito.yaml` は以下のリソースを作成します：

1. **Cognito ユーザープール** - ユーザー認証を管理
   - 電子メールをユーザー名として使用
   - 電子メールによる自動検証機能
   - 安全なパスワードポリシーの設定
   - リソース名の末尾にAWSアカウントIDを付加

2. **ユーザープールクライアント** - アプリケーションがユーザープールと通信するための設定

3. **Cognito IDプール** - 認証されたユーザーに一時的なAWSクレデンシャルを提供
   - 認証済み・未認証ユーザー向けのロールマッピング
   - 必要に応じて未認証アクセスを許可する設定オプション

4. **IAMロール** - 認証済みおよび未認証ユーザー用のアクセス権限を定義
   - 基本的なS3読み取りアクセス権限が付与されるデフォルト設定

## デプロイ方法

### 前提条件

- AWSアカウント
- AWS CLIがインストールされ設定済み
- 適切なIAM権限（CloudFormationスタックを作成する権限、Cognito・IAMリソースを作成する権限）

### デプロイスクリプトの使用

このプロジェクトには、デプロイを簡単に行うためのシェルスクリプト `src/deploy.sh` が含まれています。

```bash
# スクリプトに実行権限を付与（初回のみ）
chmod +x src/deploy.sh

# デフォルト設定でデプロイ
./src/deploy.sh

# カスタムスタック名でデプロイ
./src/deploy.sh --stack-name my-cognito-stack

# カスタムパラメーターファイルでデプロイ
./src/deploy.sh --parameters path/to/custom-parameters.json

# カスタム出力ファイルを指定
./src/deploy.sh --output path/to/outputs.json
```

デプロイスクリプトは、スタックの出力値を自動的にJSONファイルに保存します。デフォルトでは `src/outputs/stack-outputs.json` に保存されますが、`--output` オプションで保存先を変更できます。

出力ファイルの例：
```json
{
  "UserPoolId": {
    "Value": "us-east-1_abcdefghi",
    "Description": "ID of the Cognito User Pool",
    "ExportName": "cognito-auth-stack-UserPoolId"
  },
  "UserPoolClientId": {
    "Value": "1234567890abcdefghij",
    "Description": "ID of the Cognito User Pool Client",
    "ExportName": "cognito-auth-stack-UserPoolClientId"
  },
  ...
}
```

この出力ファイルは、フロントエンドアプリケーションの設定ファイルを生成する際などに利用できます。

### パラメーターファイルのカスタマイズ

デプロイパラメーターは `src/templates/parameters.json` ファイルで定義されています。必要に応じてこのファイルを編集するか、カスタムパラメーターファイルを作成してください：

```json
[
  {
    "ParameterKey": "UserPoolName",
    "ParameterValue": "MyCustomUserPool"
  },
  {
    "ParameterKey": "IdentityPoolName",
    "ParameterValue": "MyCustomIdentityPool"
  },
  {
    "ParameterKey": "AllowUnauthenticatedIdentities",
    "ParameterValue": "true"
  }
]
```

### 手動でのデプロイ（スクリプトを使用しない場合）

スクリプトを使用せずに直接AWS CLIでデプロイすることもできます：

```bash
# デフォルトパラメータでデプロイ
aws cloudformation deploy \
  --template-file src/templates/cognito.yaml \
  --stack-name cognito-auth-stack \
  --capabilities CAPABILITY_IAM

# パラメーターファイルを使用してデプロイ
aws cloudformation deploy \
  --template-file src/templates/cognito.yaml \
  --stack-name cognito-auth-stack \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides file://src/templates/parameters.json
```

### 出力の確認

デプロイ後、スクリプトは自動的にスタックの出力を表示し、JSONファイルに保存します。手動で確認する場合は以下のコマンドを使用できます：

```bash
# テーブル形式で表示
aws cloudformation describe-stacks \
  --stack-name cognito-auth-stack \
  --query 'Stacks[0].Outputs' \
  --output table

# JSONファイルに保存
aws cloudformation describe-stacks \
  --stack-name cognito-auth-stack \
  --query 'Stacks[0].Outputs' \
  --output json > outputs.json
```

## 主な出力値

デプロイ後、以下の情報が出力されます：

- **UserPoolId**: Cognito ユーザープールのID
- **UserPoolClientId**: ユーザープールクライアントのID
- **IdentityPoolId**: Cognito IDプールのID
- **AuthenticatedRoleArn**: 認証済みユーザー用IAMロールのARN
- **UnauthenticatedRoleArn**: 未認証ユーザー用IAMロールのARN

これらの値は、フロントエンドアプリケーションでAWS Amplify などを設定する際に必要になります。

## カスタマイズ

テンプレートは以下のパラメータを使用してカスタマイズできます：

- **UserPoolName**: ユーザープールの名前
- **IdentityPoolName**: IDプールの名前
- **AllowUnauthenticatedIdentities**: 未認証アクセスを許可するかどうか（'true' または 'false'）

必要に応じて、テンプレートを修正してさらにカスタマイズすることも可能です：
- パスワードポリシーの変更
- 追加の属性スキーマの定義
- MFAの設定
- メール設定のカスタマイズ
- IAMポリシーの追加／変更
