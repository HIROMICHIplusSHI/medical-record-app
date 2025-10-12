# Phase 2: 患者管理 + 問診票機能

## 概要
Phase 2では、患者管理システムと問診票機能を実装します。患者はユーザー（施設利用者）に紐づき、複数の施設での施術履歴を一元管理できる構造とします。

## 実装機能

### 1. 患者管理（Patient）

#### 基本情報（暗号化対象）
- 氏名
- 生年月日
- 性別
- 電話番号
- メールアドレス
- 住所
- 緊急連絡先

#### 機能
- ✅ 患者のCRUD操作
- ✅ 個人情報の暗号化（Active Record Encryption）
- ✅ ユーザーごとの患者管理
- ✅ 検索機能（氏名、電話番号）
- ✅ 患者一覧・詳細表示

### 2. 問診票（Questionnaire）

#### 問診内容
- **個人情報入力**
  - 氏名
  - 生年月日
  - 連絡先（電話番号、メールアドレス）
  - 住所

- **医療情報**
  - 既往歴（アレルギー、持病等）
  - 現在の服薬状況
  - 施術希望部位
  - 気になる症状
  - その他自由記述

#### 機能
- ✅ 問診票入力フォーム
- ✅ 患者1人につき1つの問診票（has_one関係）
- ✅ 入力内容の暗号化
- ✅ カルテへの反映機能（Phase 3で実装）

## データモデル

### Patient（患者）
```ruby
belongs_to :user
has_one :questionnaire, dependent: :destroy
has_many :medical_records, dependent: :restrict_with_error

# 暗号化フィールド
encrypts :name
encrypts :date_of_birth
encrypts :phone
encrypts :email, deterministic: true  # 検索可能
encrypts :address
encrypts :emergency_contact
```

### Questionnaire（問診票）
```ruby
belongs_to :patient

# 暗号化フィールド
encrypts :medical_history        # 既往歴
encrypts :current_medication     # 服薬状況
encrypts :desired_treatment      # 施術希望部位
encrypts :concerns               # 気になる症状
encrypts :notes                  # 自由記述
```

## データ構造

```
User（施設利用者）
  ├─ Facility（施設情報）← Phase 1実装済み
  │
  └─ Patient（患者）← Phase 2
      ├─ 個人情報（暗号化）
      │
      └─ Questionnaire（問診票・初回のみ）← Phase 2
          ├─ 個人情報入力
          ├─ 既往歴
          ├─ 服薬状況
          └─ 施術希望内容
```

## 運用フロー

```
1. 患者情報事前登録
   ↓
2. 問診票記入（初回のみ）
   ↓
3. カルテへ反映（Phase 3で実装）
   ↓
4. カウンセリング・内容精査（Phase 3で実装）
   ↓
5. 同意書作成・署名（Phase 4で実装）
   ↓
6. PDF化・保存（Phase 4で実装）
```

## セキュリティ要件

### 暗号化
- **対象**: 患者の個人情報全般
- **方式**: Active Record Encryption（Rails 7標準）
- **アルゴリズム**: AES-256-GCM
- **キー管理**: Rails credentials（`config/credentials.yml.enc`）

### アクセス制御
- ユーザーは自分が管理する患者のみアクセス可能
- 認証必須（Devise）
- CRUD操作すべてに認可チェック

## テスト要件

### モデルスペック
- アソシエーションのテスト
- バリデーションのテスト
- 暗号化の動作確認
- スコープのテスト

### リクエストスペック
- 各HTTPメソッドの動作確認
- 認証・認可のテスト
- 暗号化データの正常な保存・取得
- エラーハンドリング

### すべてのテストを日本語で記述

## 技術スタック

### 暗号化
- Active Record Encryption（Rails 7.0+）

### UI/UX
- Tailwind CSS
- Hotwire（Turbo + Stimulus）
- レスポンシブデザイン（iPad対応）

### テスト
- RSpec
- FactoryBot
- shoulda-matchers

## 次フェーズへの準備

Phase 3（カルテ管理）で必要となる準備：
- 問診票データをカルテに反映する機能の実装準備
- MedicalRecordモデルとの連携設計
- 施設（Facility）との紐づけ設計

## 制約事項

### 問診票の制限
- 患者1人につき1つの問診票のみ
- 初回登録時に作成
- 後から編集可能（患者情報と同期）

### 施設との関係
- 患者はユーザーに紐づく（施設には紐づかない）
- どの施設で施術したかはカルテ（MedicalRecord）で管理
- 同じ患者が複数施設で施術を受けることを想定

## 実装の優先順位

1. **高**: Patient モデル + CRUD（暗号化含む）
2. **高**: Questionnaire モデル + 入力フォーム
3. **中**: 検索機能
4. **低**: エクスポート機能（将来的に検討）

## 成功基準

- ✅ すべてのテストがパス（日本語記述）
- ✅ CI/CDがグリーン
- ✅ RuboCop 0違反
- ✅ 個人情報が正しく暗号化されている
- ✅ iPad/PCで動作確認完了
