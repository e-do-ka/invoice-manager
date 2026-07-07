# 📄 請求書管理システム（Invoice Manager)

フリーランス・小規模事業者向けの請求書管理 Web アプリです。
顧客管理から請求書の発行・送付・入金管理までを一元管理し、
インボイス制度（適格請求書）の記載要件に対応した請求書を出力できます。

![CI](https://github.com/e-do-ka/invoice-manager/actions/workflows/ci.yml/badge.svg)
![Ruby](https://img.shields.io/badge/Ruby-3.3-red)
![Rails](https://img.shields.io/badge/Rails-7.2-CC0000)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)

## 主な機能

### 📊 ダッシュボード
- 今月の売上・未入金額・期限超過件数をひと目で把握
- 直近6ヶ月の月別売上グラフ
- 期限超過の請求書アラート（ワンクリックで入金済みに更新）

### 🧾 請求書管理
- 明細行の動的追加・削除、金額のリアルタイム自動計算（Stimulus）
- 請求書番号の自動採番（`INV-YYYYMM-001` 形式）
- ステータス管理（下書き → 送付済 → 入金済）と期限超過の自動検知
- ステータス・顧客・キーワードでの絞り込み検索
- **印刷用レイアウト** … ブラウザの印刷機能でそのまま PDF 保存可能。
  適格請求書の記載要件（登録番号・税率ごとの対価/消費税額）に対応

### 🏢 顧客管理
- 顧客ごとの請求書履歴・累計請求額・未入金額を表示
- 請求書が紐づく顧客の誤削除を防止

### ⚙️ 自社情報
- 発行者情報・適格請求書発行事業者の登録番号・振込先を設定

> **Note** 本アプリは1事業者が自分の請求書を管理する想定のシングルユーザー構成です（ログイン認証なし）。
> 複数ユーザーでの利用や外部公開時には認証の追加が必要です。

## 技術スタック

| レイヤー | 技術 |
|---|---|
| バックエンド | Ruby 3.3 / Ruby on Rails 7.2 |
| データベース | PostgreSQL 16 |
| フロントエンド | Hotwire (Turbo / Stimulus) + Import maps |
| インフラ | Docker / Docker Compose |

## 起動方法

### 1. リポジトリをクローン

```bash
git clone https://github.com/your-username/invoice-manager.git
cd invoice-manager
```

### 2. 環境変数を設定

```bash
cp .env.example .env
```

### 3. 起動

```bash
docker compose up --build
```

初回起動時に DB の作成・マイグレーション・サンプルデータ投入まで自動で行われます。

### 4. ブラウザでアクセス

http://localhost:3000

## 環境変数

| 変数名 | 説明 | デフォルト |
|---|---|---|
| `POSTGRES_USER` | PostgreSQL のユーザー名 | `postgres` |
| `POSTGRES_PASSWORD` | PostgreSQL のパスワード | `password` |

## ディレクトリ構成

```
invoice-manager/
├── app/
│   ├── controllers/   # ダッシュボード / 請求書 / 顧客 / 自社情報
│   ├── models/        # Invoice, InvoiceItem, Client, CompanySetting
│   ├── views/         # ERB テンプレート（印刷用レイアウト含む）
│   └── javascript/    # Stimulus コントローラ（明細行の動的操作）
├── db/
│   ├── migrate/       # マイグレーション
│   └── seeds.rb       # デモ用サンプルデータ
├── docker-compose.yml # web (Rails) + db (PostgreSQL)
└── Dockerfile
```

## 設計メモ

- **消費税計算** … 適格請求書の要件に合わせ、明細ごとではなく税率ごとに1回の端数処理（切り捨て）
- **期限超過** … DB に持たせず「送付済かつ支払期限超過」から導出し、状態の二重管理を回避
- **明細フォーム** … `accepts_nested_attributes_for` + Stimulus で行の追加・削除・論理削除（`_destroy`）を実装
