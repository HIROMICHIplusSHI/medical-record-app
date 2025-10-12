# Phase 2: 患者管理 + 問診票機能

## 概要
Phase 2では、患者管理システムと問診票機能を実装します。患者はユーザー（施設利用者）に紐づき、複数の施設での施術履歴を一元管理できる構造とします。

## 実装状況

### ✅ 完了（2025-10-12）
- [x] Patientモデルの実装
  - Active Record Encryptionによる暗号化設定
  - バリデーション（氏名、生年月日、電話番号、メール）
  - enum（性別管理）
  - スコープ（最新順）
  - 17テストケース（全て成功）
- [x] Questionnaireモデルの実装
  - すべての医療情報を暗号化
  - 患者とのユニークな紐付け
  - 6テストケース（全て成功）
- [x] Active Record Encryption設定
  - development/test環境の暗号化キー設定
  - credentials.yml.encへの安全な保存
- [x] データベースマイグレーション
  - patientsテーブル作成
  - questionnairesテーブル作成
- [x] Patientsコントローラーの実装
  - CRUD操作の完全実装
  - ユーザー認証とアクセス制御
  - 29リクエストスペック（全て成功）
- [x] Patientsビューの実装
  - 患者一覧（index）
  - 患者詳細（show）
  - 新規登録/編集フォーム（new/edit）
  - Tailwind CSSによるレスポンシブデザイン
- [x] 日本語対応
  - ja.ymlによる国際化
  - 性別enumの日本語ラベル

### 🚧 作業中
- [ ] Questionnairesコントローラーの実装
- [ ] ビュー（問診票フォーム）

### ⏳ 未着手
- [ ] 検索機能
- [ ] システムスペック（E2E）
- [ ] iPad/PCでの動作確認

### 📊 テストカバレッジ
- モデルテスト: 23/23 成功（Patient: 17, Questionnaire: 6）
- リクエストテスト: 29/29 成功（Patients: 29）
- 合計: 52テストケース 全て成功 ✅

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
has_many :medical_records, dependent: :restrict_with_error  # Phase 3で実装

# 暗号化フィールド
encrypts :name
encrypts :phone
encrypts :email, deterministic: true  # 検索可能
encrypts :address
encrypts :emergency_contact

# 注意: date_of_birthはdateカラムのため暗号化不可
# genderはenumで管理（unspecified: 0, male: 1, female: 2, other: 3）
```

### Questionnaire（問診票）
```ruby
belongs_to :patient

# 暗号化フィールド
encrypts :medical_history        # 既往歴
encrypts :current_medications    # 現在の服薬状況
encrypts :allergies              # アレルギー
encrypts :past_surgeries         # 過去の手術歴
encrypts :family_history         # 家族歴
encrypts :lifestyle_notes        # 生活習慣
encrypts :concerns               # 相談内容

# バリデーション
validates :patient, uniqueness: true  # 患者1人につき1つのみ
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
