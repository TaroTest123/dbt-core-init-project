# dbt + Snowflake プロジェクトを新規作成するガイド

Snowflake をデータウェアハウスとして使用する dbt-core プロジェクトを、devcontainer 対応でゼロから構築する手順です。

## 前提条件

- Snowflake アカウントと認証情報
- Docker + VS Code（Dev Containers 拡張機能）
- Git

## 1. プロジェクトディレクトリの作成

```bash
mkdir my-analytics && cd my-analytics
git init
```

## 2. Python 依存パッケージの定義

`requirements.txt` を作成:

```
dbt-core==1.9.*
dbt-snowflake==1.9.*
```

## 3. devcontainer の設定

`.devcontainer/devcontainer.json` を作成:

```json
{
  "name": "dbt-snowflake",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11"
    }
  },
  "postCreateCommand": "pip install -r requirements.txt",
  "containerEnv": {
    "DBT_PROFILES_DIR": "${containerWorkspaceFolder}"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "innoverio.vscode-dbt-power-user",
        "bastienboutonnet.vscode-dbt",
        "ms-python.python",
        "redhat.vscode-yaml",
        "snowflake.snowflake-vsc"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/usr/local/bin/python"
      }
    }
  }
}
```

ポイント:
- `postCreateCommand` でコンテナ起動時に dbt を自動インストール
- `containerEnv` で `DBT_PROFILES_DIR` をワークスペース直下に設定（`profiles.yml` をリポジトリ内で管理するため）

## 4. dbt プロジェクトの初期化

VS Code のコマンドパレットから `Dev Containers: Reopen in Container` を実行してコンテナを起動した後:

```bash
dbt init my_project
```

対話的にプロジェクト名や接続先を聞かれますが、後から設定ファイルを直接編集するため、ここでは任意の値で構いません。

生成されたファイルをプロジェクトルートに移動して整理:

```bash
mv my_project/* .
rm -rf my_project
```

最終的に以下の構成になります:

```
.
├── .devcontainer/
│   └── devcontainer.json
├── models/
│   └── example/          # サンプルモデル（不要なら削除）
├── analyses/
├── macros/
├── seeds/
├── snapshots/
├── tests/
├── dbt_project.yml
├── profiles.yml          # 次のステップで作成
├── packages.yml          # 次のステップで作成
└── requirements.txt
```

## 5. Snowflake 接続設定

### 5-1. 環境変数テンプレートの作成

`.env.example` を作成:

```
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_ROLE=your_role
SNOWFLAKE_DATABASE=your_database
SNOWFLAKE_WAREHOUSE=your_warehouse
```

実際の認証情報を入力した `.env` を作成:

```bash
cp .env.example .env
# .env を編集して認証情報を入力
```

| 変数 | 説明 | 例 |
|------|------|-----|
| `SNOWFLAKE_ACCOUNT` | アカウント識別子 | `xy12345.ap-northeast-1.aws` |
| `SNOWFLAKE_USER` | ログインユーザー名 | `DBT_USER` |
| `SNOWFLAKE_PASSWORD` | パスワード | - |
| `SNOWFLAKE_ROLE` | 使用するロール | `TRANSFORMER` |
| `SNOWFLAKE_DATABASE` | 対象データベース | `ANALYTICS` |
| `SNOWFLAKE_WAREHOUSE` | 使用するウェアハウス | `TRANSFORMING` |

### 5-2. profiles.yml の作成

`profiles.yml` をプロジェクトルートに作成:

```yaml
my_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      schema: public
      threads: 4
```

> `my_project` の部分は `dbt_project.yml` の `profile:` と一致させてください。

### 5-3. dbt_project.yml の編集

`dbt_project.yml` の `profile` が `profiles.yml` のキーと一致していることを確認し、モデルの materialization を設定:

```yaml
name: my_project
version: "1.0.0"

profile: my_project

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

clean-targets:
  - target
  - dbt_packages

models:
  my_project:
    staging:
      +materialized: view
    marts:
      +materialized: table
```

## 6. dbt パッケージの設定

`packages.yml` を作成:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: ">=1.0.0"
```

インストール:

```bash
dbt deps
```

## 7. .gitignore の設定

`.gitignore` を作成:

```gitignore
# dbt
target/
dbt_packages/
logs/
.user.yml

# Python
.venv/
venv/
__pycache__/
*.pyc

# Environment
.env

# IDE
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
```

> `.env` は認証情報を含むため、必ず gitignore に含めてください。`.env.example` のみコミットします。

## 8. モデルディレクトリの整理

```bash
rm -rf models/example
mkdir -p models/staging models/marts
```

ソース定義ファイル `models/staging/_sources.yml` を作成:

```yaml
version: 2

sources:
  - name: my_source
    description: "データソースの説明"
    database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
    schema: raw
    tables:
      - name: my_table
        description: "テーブルの説明"
```

## 9. 接続確認

```bash
source .env && export $(cut -d= -f1 .env)
dbt debug
```

以下のように表示されれば成功です:

```
Connection test: OK connection ok
```

## 10. 初回コミット

```bash
git add -A
git commit -m "feat: initialize dbt + Snowflake project"
```

## トラブルシューティング

| 症状 | 原因と対処 |
|------|-----------|
| `dbt debug` で接続エラー | `.env` の値を確認。特に `SNOWFLAKE_ACCOUNT` のフォーマット（`<account>.<region>.<cloud>`） |
| `env_var('...') is undefined` | `source .env && export $(cut -d= -f1 .env)` を再実行 |
| `profiles.yml` が見つからない | devcontainer 外の場合は `export DBT_PROFILES_DIR=.` を実行 |
| `dbt deps` でエラー | ネットワーク接続を確認。プロキシ環境の場合は `HTTP_PROXY` を設定 |
| devcontainer で dbt が見つからない | コンテナを Rebuild して `postCreateCommand` を再実行 |
