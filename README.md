# analytics — dbt + Snowflake プロジェクト

Snowflake をデータウェアハウスとして使用する dbt-core プロジェクトです。devcontainer に対応しており、どの環境でもすぐに開発を始められます。

## ディレクトリ構成

```
.
├── models/
│   ├── staging/    # ソースデータの整形 (view)
│   └── marts/      # ビジネスロジック集約 (table)
├── macros/         # カスタムマクロ
├── seeds/          # CSV シードデータ
├── snapshots/      # SCD スナップショット
├── tests/          # カスタムテスト
├── analyses/       # 分析クエリ
├── dbt_project.yml # プロジェクト設定
├── profiles.yml    # 接続設定
└── packages.yml    # dbt パッケージ
```

## セットアップ

### devcontainer (推奨)

1. VS Code で **Dev Containers: Reopen in Container** を実行
2. `.env.example` をコピーして `.env` を作成し、Snowflake 認証情報を設定

```bash
cp .env.example .env
# .env を編集して認証情報を入力
```

3. 環境変数を読み込み、接続を確認

```bash
source .env && export $(cut -d= -f1 .env)
dbt debug
```

### ローカル環境

1. Python 3.11 をインストール
2. 依存パッケージをインストール

```bash
pip install -r requirements.txt
```

3. `.env.example` をコピーして `.env` を作成し、Snowflake 認証情報を設定

```bash
cp .env.example .env
# .env を編集して認証情報を入力
```

4. 環境変数を読み込み、接続を確認

```bash
export DBT_PROFILES_DIR=.
source .env && export $(cut -d= -f1 .env)
dbt debug
```

## よく使うコマンド

```bash
dbt deps          # パッケージインストール
dbt debug         # 接続確認
dbt run           # モデル実行
dbt test          # テスト実行
dbt build         # run + test
dbt compile       # SQL コンパイル
dbt docs generate # ドキュメント生成
dbt docs serve    # ドキュメント閲覧
```

## CI/CD (GitHub Actions)

`development` ブランチへの push で dev 環境、`main` へのマージで prod 環境に自動デプロイされます。

### GitHub Secrets の設定

リポジトリの **Settings > Secrets and variables > Actions** で以下のシークレットを登録してください。

| シークレット名 | 説明 | 例 |
|---|---|---|
| `SNOWFLAKE_ACCOUNT` | Snowflake アカウント識別子 | `xy12345.ap-northeast-1.aws` |
| `SNOWFLAKE_USER` | Snowflake ユーザー名 | `DBT_USER` |
| `SNOWFLAKE_PASSWORD` | Snowflake パスワード | — |
| `SNOWFLAKE_ROLE` | 使用するロール | `TRANSFORMER` |
| `SNOWFLAKE_WAREHOUSE` | 使用するウェアハウス | `TRANSFORMING` |
| `SNOWFLAKE_DATABASE` | dev 用データベース | `ANALYTICS` |
| `SNOWFLAKE_DATABASE_PROD` | prod 用データベース | `ANALYTICS_PROD` |

> `.env` ファイルに設定しているものと同じ値を登録すれば OK です。

### デプロイフロー

1. `development` ブランチに push → `dbt build --target dev` が実行される
2. `main` ブランチに PR をマージ → `dbt build --target prod` が実行される

## 命名規則

| レイヤー | プレフィックス | 例 |
|---------|-------------|-----|
| staging | `stg_<source>__<table>` | `stg_sample__orders` |
| marts   | `fct_` / `dim_`        | `fct_orders`, `dim_customers` |
