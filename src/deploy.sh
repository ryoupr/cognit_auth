#!/bin/bash

# エラーが発生した場合にスクリプトを終了
set -e

# デフォルト値
STACK_NAME="cognito-auth-stack"
TEMPLATE_FILE="src/templates/cognito.yaml"
PARAMETERS_FILE="src/templates/parameters.json"
OUTPUT_FILE="src/outputs/stack-outputs.json"

# ヘルプメッセージ
function show_help {
  echo "使用方法: $0 [オプション]"
  echo ""
  echo "オプション:"
  echo "  -s, --stack-name NAME     CloudFormationスタック名 (デフォルト: $STACK_NAME)"
  echo "  -t, --template FILE       CloudFormationテンプレートファイルのパス (デフォルト: $TEMPLATE_FILE)"
  echo "  -p, --parameters FILE     パラメーターJSONファイルのパス (デフォルト: $PARAMETERS_FILE)"
  echo "  -o, --output FILE         スタック出力を保存するJSONファイルのパス (デフォルト: $OUTPUT_FILE)"
  echo "  -h, --help                このヘルプメッセージを表示"
  echo ""
  echo "例:"
  echo "  $0 --stack-name my-cognito-stack --parameters custom-params.json"
  echo "  $0 --output my-outputs.json"
}

# コマンドライン引数の解析
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -s|--stack-name)
      STACK_NAME="$2"
      shift 2
      ;;
    -t|--template)
      TEMPLATE_FILE="$2"
      shift 2
      ;;
    -p|--parameters)
      PARAMETERS_FILE="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "エラー: 不明なオプション '$1'"
      show_help
      exit 1
      ;;
  esac
done

# ファイルの存在確認
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "エラー: テンプレートファイル '$TEMPLATE_FILE' が見つかりません"
  exit 1
fi

if [ ! -f "$PARAMETERS_FILE" ]; then
  echo "エラー: パラメーターファイル '$PARAMETERS_FILE' が見つかりません"
  exit 1
fi

# 出力ディレクトリの作成
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

echo "=== AWS Cognito デプロイスクリプト ==="
echo "スタック名: $STACK_NAME"
echo "テンプレートファイル: $TEMPLATE_FILE"
echo "パラメーターファイル: $PARAMETERS_FILE"
echo "出力ファイル: $OUTPUT_FILE"
echo ""

# デプロイの確認
read -p "デプロイを開始しますか？ (y/n): " confirm
if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
  echo "デプロイをキャンセルしました"
  exit 0
fi

echo "CloudFormationスタックをデプロイしています..."

# CloudFormationスタックのデプロイ
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --parameter-overrides file://"$PARAMETERS_FILE" \
  --capabilities CAPABILITY_IAM

# デプロイ成功時の処理
if [ $? -eq 0 ]; then
  echo "デプロイが完了しました！"
  
  # スタックの出力を表示
  echo ""
  echo "=== スタック出力 ==="
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs' \
    --output table
  
  # スタックの出力をJSONファイルに保存
  echo "スタック出力を $OUTPUT_FILE に保存しています..."
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs' \
    --output json > "$OUTPUT_FILE"
  
  # 出力ファイルを整形して保存（より読みやすい形式に変換）
  TMP_FILE=$(mktemp)
  jq '
    reduce .[] as $item ({}; 
      . + {($item.OutputKey): {
        "Value": $item.OutputValue, 
        "Description": $item.Description, 
        "ExportName": $item.ExportName
      }}
    )
  ' "$OUTPUT_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$OUTPUT_FILE"
  
  echo "出力ファイルが保存されました: $OUTPUT_FILE"
else
  echo "デプロイに失敗しました。"
  exit 1
fi
