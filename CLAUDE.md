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
- IMPORTANT: コミットメッセージ、PRタイトル・本文はすべて日本語で記述する（プレフィックスは英語の Conventional Commits 形式を維持）
- IMPORTANT: 開発は `development` ブランチで行い、`main` へは PR 経由でのみマージする
- `main` への直接 push は禁止

## CI/CD (GitHub Actions + Snowflake CLI)

- `.github/workflows/dbt-deploy.yml` で Snowflake CLI (`snow dbt`) を使い dev/prod デプロイを自動化
- `development` ブランチへの push → `snow dbt deploy` + `snow dbt execute build --target snowflake_dev`
- `main` ブランチへの push → `snow dbt deploy` + `snow dbt execute build --target snowflake_prod`
- Snowflake 認証情報は GitHub Secrets に設定が必要:
  `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`

## dbt Docs (GitHub Pages)

- `.github/workflows/dbt-docs.yml` で `main` ブランチへの push 時にドキュメントを自動生成・デプロイ
- `dbt docs generate --target snowflake_prod` で本番データベースのカラムメタデータを含むドキュメントを生成
- `actions/deploy-pages` で GitHub Pages にデプロイ
- `prod` GitHub Environment の既存シークレットを再利用（追加設定不要）
- 初回のみ GitHub リポジトリの **Settings > Pages > Source** で **GitHub Actions** を選択する必要あり

## Snowflake-native dbt (定期実行)

- 各環境に `TOKYOPOWER_TRANSFORM` (dbt プロジェクト)、`DAILY_DBT_BUILD` (Task) を配置
- `TOKYOPOWER_ANALYTICS.PUBLIC` (dev): `snowflake_dev` ターゲット
- `TOKYOPOWER_ANALYTICS_PROD.PUBLIC` (prod): `snowflake_prod` ターゲット
- 両環境とも毎日 JST 00:35 に `dbt build` を自動実行
- コード更新は GitHub Actions の `snow dbt deploy --force` で自動反映される

## 環境 (dev / prod)

- デフォルトターゲットは `snowflake_dev` (`profiles.yml` の `target: snowflake_dev`)
- 本番実行: `dbt run --target snowflake_prod` / `dbt build --target snowflake_prod`
- ソースデータベースとモデル出力先データベースは分離する:
  - ソース (参照のみ): `TOKYOPOWER` (dev) / `TOKYOPOWER_PROD` (prod) — `_sources.yml` で `target.name` により自動切り替え
  - モデル出力先: `TOKYOPOWER_ANALYTICS` (dev) / `TOKYOPOWER_ANALYTICS_PROD` (prod) — `profiles.yml` の `database` で設定

## ドキュメントとテストの品質基準

- IMPORTANT: すべてのモデル・ソースに日本語の description を必ず定義する（モデルレベル + カラムレベル）
- IMPORTANT: 新しいモデルやカラムを追加したら、対応する `_models.yml` / `_sources.yml` に description とテストを同時に追加する
- テストの最低基準:
  - 全カラムに `not_null` テスト（NULL を許容するカラムは staging でフィルタまたは変換して除外する）
  - テーブルの粒度（grain）を表すカラムの組み合わせに `dbt_utils.unique_combination_of_columns` テスト
  - ソーステーブルのカラムにも `not_null` テストを定義する
- staging モデルではソースデータの不正値（NULL 行など）をフィルタし、下流に流さない
- `_models.yml` の配置: `models/staging/_models.yml`、`models/marts/_models.yml`
- ドキュメント・テストの変更後は `dbt parse` で構文検証を行う

## materialization

- `models/staging/`: view (デフォルト設定済み)
- `models/marts/`: table (デフォルト設定済み)
- 変更が必要な場合はモデルファイル内の `config()` で個別に上書きする
