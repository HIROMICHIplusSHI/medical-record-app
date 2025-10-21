# Phase 8: 実務フロー想定の機能統合

**作成日**: 2025-10-21
**最終更新**: 2025-10-21
**目標**: 実際の施術業務フローを想定した機能拡張と完成度向上

**前提**: Phase 7（認証・登録周り統合）完了後に実施

---

## 🎯 Phase 8の目的

Phase 5-Cで実装した同意書機能の拡張、カルテ業務フローの改善など、実務で必要となる機能を統合する。

### 主な機能
1. **看護師確認機能**: 同意書の看護師確認フィールド追加（Phase 6-A-3から移行）
2. **カルテ承認フロー**: 施術記録の確認・承認プロセス
3. **施術記録の補足機能**: メモ・注意事項の追加
4. **その他実務で必要な機能**: ユーザーヒアリングに基づく追加機能

---

## 📋 実装予定（工数: 3-5日）

### Phase 8-A: 看護師確認機能（Phase 5-C拡張）（1-2日）

**実装内容**:
- 同意書の看護師確認フィールド追加
- 確認ステータス管理（未確認・確認済み・要修正）
- カルテ一覧への確認状態表示
- 看護師ロールの追加検討（User enumに追加）

**データモデル**:
```ruby
# patient_consents テーブルに追加
add_column :patient_consents, :nurse_confirmed_at, :datetime
add_column :patient_consents, :nurse_confirmed_by_id, :references
add_column :patient_consents, :confirmation_status, :integer, default: 0
add_index :patient_consents, :confirmation_status
```

**テスト**:
- Model Spec（確認ステータス）
- Request Spec（確認アクション）
- System Spec（確認フロー）

---

### Phase 8-B: カルテ承認フロー（1.5-2日）

**実装内容**:
- カルテ承認ステータス管理（下書き・確認待ち・承認済み）
- 承認者・承認日時の記録
- 承認ワークフローUI

**データモデル**:
```ruby
# medical_records テーブルに追加
add_column :medical_records, :approval_status, :integer, default: 0
add_column :medical_records, :approved_at, :datetime
add_column :medical_records, :approved_by_id, :references
add_index :medical_records, :approval_status
```

**テスト**:
- Model Spec（承認ステータス）
- Request Spec（承認アクション）
- System Spec（承認フロー）

---

### Phase 8-C: 施術記録の補足機能（0.5-1日）

**実装内容**:
- カルテにメモ・注意事項フィールド追加
- タイムライン表示（作成・更新履歴）
- コメント機能（オプション）

**データモデル**:
```ruby
# medical_records テーブルに追加
add_column :medical_records, :internal_notes, :text
add_column :medical_records, :cautions, :text
```

**テスト**:
- Model Spec（メモ・注意事項）
- Request Spec（更新）
- System Spec（表示確認）

---

## 🎯 マイルストーン達成条件

### 機能面
- [ ] 看護師確認機能実装完了
- [ ] カルテ承認フロー実装完了
- [ ] 施術記録の補足機能実装完了
- [ ] ユーザーヒアリングに基づく追加機能実装完了（該当する場合）

### 品質面
- [ ] テストカバレッジ 80%以上維持
- [ ] RuboCop違反 0件
- [ ] Brakeman警告 0件
- [ ] 全E2Eテストパス

### 実務適合性
- [ ] 実際の業務フローに沿った動作確認
- [ ] ユーザビリティテスト実施
- [ ] フィードバック収集・反映

---

## 📝 検討事項

### 看護師ロールの追加
- User enumに `nurse: 2` を追加するか検討
- 権限管理（Pundit）の拡張
- 看護師専用画面の必要性

### カルテ承認フロー
- 誰が誰を承認するか（医師→看護師、看護師→医師など）
- 承認なしでも施術記録を確定できるか
- 承認後の修正可否

### その他
- 実務でのユーザビリティ確認
- 追加で必要な機能のヒアリング

---

**次のステップ**: Phase 7完了後、Phase 8-Aから実装開始

**作成者**: Claude
**最終更新**: 2025-10-21
