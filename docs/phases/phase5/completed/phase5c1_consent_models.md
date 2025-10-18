# Phase 5-C-1: データモデル基盤（同意書機能） - 完了報告

**実装期間**: 2025-10-19
**担当**: Claude Code + AI開発
**PR**: #19 - https://github.com/HIROMICHIplusSHI/medical-record-app/pull/19
**ステータス**: ✅ 完了（セキュリティレビュー対応済み）

---

## 📋 実装サマリー

Phase 5-C（同意書機能）の第1段階として、データモデル基盤を実装しました。

### 新規モデル（5つ）

1. **FacilityDoctor** - 施設に紐づく医師情報
2. **ConsentFormTemplate** - カスタマイズ可能な同意書テンプレート
3. **ConsentFormItem** - 動的に追加/削除可能なチェック項目
4. **PatientConsent** - 患者署名入り同意書（Canvas署名対応）
5. **ConsentItemResponse** - チェック項目への患者回答

### 主要機能

- ✅ Canvas手書き署名データの保存（Base64エンコード）
- ✅ Active Record Encryption（署名、施術者名、施設情報、医師免許番号）
- ✅ 施設情報のスナップショット（監査証跡）
- ✅ カスタマイズ可能な同意書テンプレート
- ✅ 必須/任意チェック項目の管理
- ✅ 複数同意書テンプレートの選択対応

---

## 🗄️ データモデル詳細

### 1. FacilityDoctor（施設医師）

**テーブル**: `facility_doctors`

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| facility_id | bigint | FK, NOT NULL | 施設ID |
| name | string | NOT NULL | 医師名 |
| medical_license_number | string | 暗号化（deterministic） | 医師免許番号 |
| specialization | string | | 専門分野 |
| created_at | datetime | | |
| updated_at | datetime | | |

**インデックス**:
- `[facility_id, medical_license_number]` - UNIQUE（施設内で医師免許番号がユニーク）

**暗号化**:
```ruby
encrypts :medical_license_number, deterministic: true
```

**メソッド**:
- `display_name`: 名前と医師免許番号を組み合わせた表示名

---

### 2. ConsentFormTemplate（同意書テンプレート）

**テーブル**: `consent_form_templates`

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| user_id | bigint | FK, NOT NULL | ユーザーID |
| title | string | NOT NULL | テンプレート名 |
| description | text | | 説明 |
| is_active | boolean | NOT NULL, default: true | 使用中フラグ |
| created_at | datetime | | |
| updated_at | datetime | | |

**インデックス**:
- `[user_id, title]` - UNIQUE（ユーザー内でタイトルがユニーク）

**スコープ**:
- `.active`: 使用中のテンプレートのみ
- `.recent`: 作成日時の降順

**ネストフォーム**:
```ruby
accepts_nested_attributes_for :consent_form_items,
                              allow_destroy: true,
                              reject_if: :all_blank
```

---

### 3. ConsentFormItem（チェック項目）

**テーブル**: `consent_form_items`

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| consent_form_template_id | bigint | FK, NOT NULL | テンプレートID |
| content | text | NOT NULL | 項目内容 |
| position | integer | NOT NULL | 表示順序 |
| is_required | boolean | NOT NULL, default: true | 必須フラグ |
| created_at | datetime | | |
| updated_at | datetime | | |

**インデックス**:
- `[consent_form_template_id, position]`

**デフォルトスコープ**:
```ruby
default_scope { order(:position) }
```

---

### 4. PatientConsent（患者同意書）

**テーブル**: `patient_consents`

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| patient_id | bigint | FK, NOT NULL | 患者ID |
| consent_form_template_id | bigint | FK, NOT NULL | テンプレートID |
| medical_record_id | bigint | FK, NOT NULL | カルテID |
| facility_doctor_id | bigint | FK, NOT NULL | 医師ID |
| user_id | bigint | FK, NOT NULL | ユーザーID |
| agreed_at | datetime | NOT NULL | 同意日時 |
| signature_data | text | 暗号化 | Canvas署名データ（Base64） |
| practitioner_name | text | 暗号化 | 施術者名（スナップショット） |
| facility_name | text | 暗号化 | 施設名（スナップショット） |
| facility_address | text | 暗号化 | 施設住所（スナップショット） |
| facility_phone | text | 暗号化 | 施設電話番号（スナップショット） |
| signed_ip | string | | 署名時のIPアドレス |
| signed_user_agent | text | | 署名時のUser-Agent |
| created_at | datetime | | |
| updated_at | datetime | | |

**インデックス**:
- `[medical_record_id, consent_form_template_id]` - 複合インデックス
- `agreed_at` - 日時検索用

**暗号化**:
```ruby
encrypts :signature_data
encrypts :practitioner_name
encrypts :facility_name
encrypts :facility_address
encrypts :facility_phone
```

**コールバック**:
```ruby
before_create :snapshot_facility_info
```

施設情報変更後も同意書に記録された情報を保持（監査証跡）。

**カスタムバリデーション**:
```ruby
validate :all_required_items_checked, on: :create
```

必須項目がすべてチェックされていることを検証。

**スコープ**:
- `.recent`: 同意日時の降順
- `.for_patient(patient_id)`: 指定患者の同意書
- `.for_medical_record(record_id)`: 指定カルテの同意書

---

### 5. ConsentItemResponse（項目回答）

**テーブル**: `consent_item_responses`

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| patient_consent_id | bigint | FK, NOT NULL | 同意書ID |
| consent_form_item_id | bigint | FK, NOT NULL | 項目ID |
| checked | boolean | NOT NULL, default: false | チェック状態 |
| created_at | datetime | | |
| updated_at | datetime | | |

**インデックス**:
- `[patient_consent_id, consent_form_item_id]` - UNIQUE（同一同意書内で項目回答がユニーク）

---

## 🔒 セキュリティ実装

### Active Record Encryption

**暗号化フィールド（6フィールド）**:

| モデル | フィールド | 暗号化タイプ | 理由 |
|--------|-----------|-------------|------|
| PatientConsent | signature_data | 通常 | Canvas署名データ（個人情報） |
| PatientConsent | practitioner_name | 通常 | 施術者名（スナップショット） |
| PatientConsent | facility_name | 通常 | 施設名（スナップショット） |
| PatientConsent | facility_address | 通常 | 施設住所（スナップショット） |
| PatientConsent | facility_phone | 通常 | 施設電話番号（スナップショット） |
| FacilityDoctor | medical_license_number | **deterministic** | 医師免許番号（要配慮個人情報） |

**deterministic暗号化の効果**:
- 同じ値は同じ暗号化結果
- ユニーク制約が機能
- 検索が可能

### セキュリティレビュー対応

**実施日**: 2025-10-19
**エージェント**: security-engineer
**総合評価**: 95/100（A+評価）

#### 修正項目

**Warning-1: SQLインジェクション対策** ✅
```ruby
# Before（危険）
raw_value = ActiveRecord::Base.connection.execute(
  "SELECT signature_data FROM patient_consents WHERE id = #{consent.id}"
).first['signature_data']

# After（安全）
sql = ActiveRecord::Base.sanitize_sql_array([
  'SELECT signature_data FROM patient_consents WHERE id = ?',
  consent.id,
])
raw_value = ActiveRecord::Base.connection.execute(sql).first['signature_data']
```

**Warning-2: 医師免許番号の暗号化** ✅
```ruby
class FacilityDoctor < ApplicationRecord
  # 要配慮個人情報のため暗号化
  encrypts :medical_license_number, deterministic: true
end
```

#### セキュリティベストプラクティス

- ✅ 外部キー制約による参照整合性
- ✅ 複合ユニーク制約（レースコンディション防止）
- ✅ dependent: :restrict_with_error（法的証拠保全）
- ✅ スナップショットパターン（監査証跡）
- ✅ Ransack検索対象の適切な制限
- ✅ Brakeman静的解析パス（0 warnings）

---

## 🧪 テスト結果

### テストカバレッジ

**総テスト数**: 59 examples, 0 failures

| モデル | テスト数 | 内容 |
|--------|---------|------|
| FacilityDoctor | 10 | associations, validations, encryption, display_name |
| ConsentFormTemplate | 9 | uniqueness, scopes, nested forms |
| ConsentFormItem | 7 | default scope, required flags |
| PatientConsent | 24 | encryption, callbacks, custom validations |
| ConsentItemResponse | 9 | uniqueness, defaults |

### テスト種別

| 種別 | テスト数 |
|------|---------|
| アソシエーション | 10 |
| バリデーション | 15 |
| 暗号化 | 5 |
| コールバック | 2 |
| カスタムバリデーション | 3 |
| スコープ | 6 |
| メソッド | 3 |
| デフォルト値 | 3 |

### 実行結果

```
Finished in 0.95223 seconds (files took 1.04 seconds to load)
59 examples, 0 failures
```

---

## 📝 マイグレーション

**作成数**: 6ファイル

1. `20251018221354_create_facility_doctors.rb`
2. `20251018221421_create_consent_form_templates.rb`
3. `20251018221443_create_consent_form_items.rb`
4. `20251018221501_create_patient_consents.rb`
5. `20251018221536_create_consent_item_responses.rb`
6. `20251018225004_encrypt_facility_doctor_medical_license_number.rb`

**適用状況**:
- ✅ 開発環境: 適用済み
- ✅ テスト環境: 適用済み

---

## 📦 Factory定義

**作成数**: 5ファイル

1. `spec/factories/facility_doctors.rb`
   - デフォルト: 山田太郎医師、医師免許番号あり
   - Trait: なし

2. `spec/factories/consent_form_templates.rb`
   - デフォルト: タイトル、説明、is_active: true
   - Trait: `:inactive`, `:with_items`

3. `spec/factories/consent_form_items.rb`
   - デフォルト: 同意項目、position、is_required: true
   - Trait: `:optional`

4. `spec/factories/patient_consents.rb`
   - デフォルト: 全関連、Base64署名データ、IP/User-Agent
   - Trait: `:with_responses`

5. `spec/factories/consent_item_responses.rb`
   - デフォルト: checked: true
   - Trait: `:unchecked`

---

## 🔧 コード品質

### RuboCop

```
97 files inspected, no offenses detected
```

### Brakeman

```
== Overview ==
Security Warnings: 0

== Warning Types ==
No warnings found
```

---

## 📊 コミット履歴

**総コミット数**: 11件

1. `5368922` - feat(migration): 5つのマイグレーション
2. `c1551a2` - feat(model): FacilityDoctor
3. `5927642` - feat(model): Template/Item
4. `863b160` - feat(model): PatientConsent（暗号化）
5. `db4007a` - feat(model): Response
6. `1af88dc` - feat(model): 既存モデル拡張
7. `48a815b` - test(consent): Factory 5ファイル
8. `a519266` - test(consent): Spec 57テスト
9. `f507866` - chore(db): schema更新
10. `b8fe1be` - fix(security): SQLインジェクション対策
11. `a815f63` - feat(security): 医師免許番号暗号化

**コミット方針**: Conventional Commits形式、論理的な単位で分割

---

## ⏭️ 次のステップ

### Phase 5-C-2: 施設医師・テンプレート管理UI（4-5日）

**実装内容**:
- Facilityフォーム拡張（nested doctor fields）
- ConsentFormTemplate CRUD
- Stimulus controllers（動的フォーム）
- Sortable.js（ドラッグ&ドロップ）

**ブランチ**: `feature/p5c2-consent-ui`

---

## 📚 参考ドキュメント

- **実装計画**: `docs/phases/phase5/phase5c_consent_forms.md`
- **データモデル設計**: `docs/02_data_model.md`（更新予定）
- **セキュリティレビュー**: PR #19コメント
- **PR**: https://github.com/HIROMICHIplusSHI/medical-record-app/pull/19

---

## ✅ 完了チェックリスト

- [x] 5つの新規モデル実装
- [x] 6つのマイグレーション作成・適用
- [x] Active Record Encryption実装（6フィールド）
- [x] スナップショットコールバック実装
- [x] カスタムバリデーション実装
- [x] Factory定義作成（5ファイル）
- [x] Model Spec作成（59テスト）
- [x] セキュリティレビュー実施
- [x] Warning-1修正（SQLインジェクション）
- [x] Warning-2修正（医師免許番号暗号化）
- [x] RuboCop違反0件
- [x] Brakeman警告0件
- [x] 全テストパス（59 examples, 0 failures）
- [x] 完了報告ドキュメント作成

---

**実装完了日**: 2025-10-19
**次回作業**: Phase 5-C-2（施設医師・テンプレート管理UI）
**ステータス**: ✅ マージ準備完了
