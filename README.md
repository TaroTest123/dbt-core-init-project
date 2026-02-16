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

## 命名規則

| レイヤー | プレフィックス | 例 |
|---------|-------------|-----|
| staging | `stg_<source>__<table>` | `stg_sample__orders` |
| marts   | `fct_` / `dim_`        | `fct_orders`, `dim_customers` |
