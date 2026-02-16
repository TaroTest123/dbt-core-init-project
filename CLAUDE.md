# CLAUDE.md

dbt-core + Snowflake プロジェクト。設定詳細は @README.md を参照。

## ビルド・検証コマンド

```bash
# 環境変数の設定 (ローカル環境のみ、devcontainer では不要)
export DBT_PROFILES_DIR=.
source .env && export $(cut -d= -f1 .env)

# パッケージインストール (初回・packages.yml 変更時)
dbt deps

# プロジェクト検証
dbt debug        # 接続設定の検証
dbt parse        # モデルの構文チェック (Snowflake 接続不要)

# 実行
dbt build        # run + test を一括実行
dbt run -s model_name        # 単一モデル実行
dbt run -s +model_name       # 上流含めて実行
dbt test -s model_name       # 単一モデルのテスト
```

## モデル命名規則

- IMPORTANT: staging モデルは `stg_<source>__<table>` (アンダースコア 2 つで source と table を区切る)
- marts のファクトテーブルは `fct_<entity>`、ディメンションは `dim_<entity>`

## SQL スタイル

- インデント: 4 スペース
- キーワード: 小文字 (`select`, `from`, `where`)
- CTE を積極的に使い、サブクエリは避ける
- `select *` は CTE の最終 select のみ許可。途中の CTE では明示的にカラムを列挙する

## dbt 固有ルール

- IMPORTANT: ソーステーブルの参照には必ず `{{ source() }}` を使う。ハードコードしない
- モデル間の参照には必ず `{{ ref() }}` を使う
- staging モデルのみが `source()` を使う。marts は `ref()` のみ
- 新しいソーステーブルを追加する場合は `models/staging/_sources.yml` に定義を追加する
- 環境変数は `{{ env_var('VAR_NAME') }}` で参照する

## Git

- IMPORTANT: コミットメッセージは Conventional Commits に従う (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`)
- スコープは任意 (例: `feat(models): add dim_customers`)

## materialization

- `models/staging/`: view (デフォルト設定済み)
- `models/marts/`: table (デフォルト設定済み)
- 変更が必要な場合はモデルファイル内の `config()` で個別に上書きする
