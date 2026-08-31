require 'rails_helper'

# クロステナント境界の検証。
#
# このアプリは Pundit を管理者ロールの判定に使い、テナント分離は current_user スコープで行う。
# ただし「user_id だけを current_user に束縛し、他の外部キーは params から素通し」という
# パターンが各所にあり、リクエストボディ経由で他ユーザーの資源を掴めてしまう経路があった。
#
# 杭（実装開始後に変更しない不変条件）:
#   杭A: 施術記録の user / patient / facility / tag / cost_sheet は同一ユーザーに属する
#   杭B: 請求書の facility は作成者に属する
#   杭C: 他ユーザーが作成したレコードは、自分の画面に現れない（逆方向の汚染をしない）
#   杭D: 選択肢（セレクトボックス）に他ユーザーの資源を並べない
RSpec.describe 'クロステナント境界', type: :request do
  let(:attacker) { create(:user) }
  let(:victim) { create(:user) }
  let(:attacker_patient) { create(:patient, user: attacker) }
  let(:attacker_facility) { create(:facility, user: attacker) }
  let(:victim_patient) { create(:patient, user: victim, name: '被害者の患者') }
  let(:victim_facility) { create(:facility, user: victim, name: '被害者クリニック') }
  let(:victim_tag) { create(:tag, user: victim, name: '被害者タグ') }
  let(:victim_cost_sheet) { create(:cost_sheet, user: victim) }

  let(:valid_record_params) do
    { patient_id: attacker_patient.id, facility_id: attacker_facility.id,
      visit_date: Date.current, treatment_content: '正常な施術', }
  end

  before { sign_in attacker }

  describe '施術記録の作成' do
    # 杭A
    it '他ユーザーの患者IDでは作成できない' do
      expect do
        post medical_records_path,
             params: { medical_record: valid_record_params.merge(patient_id: victim_patient.id) }
      end.not_to change(MedicalRecord, :count)
    end

    # 杭A
    it '他ユーザーの施設IDでは作成できない' do
      expect do
        post medical_records_path,
             params: { medical_record: valid_record_params.merge(facility_id: victim_facility.id) }
      end.not_to change(MedicalRecord, :count)
    end

    # 杭A: 他ユーザーのタグを掴むと、被害者側がそのタグを削除できなくなる（片方向DoS）
    it '他ユーザーのタグIDは紐づかない' do
      post medical_records_path,
           params: { medical_record: valid_record_params.merge(tag_ids: [victim_tag.id]) }

      expect(MedicalRecord.last&.tag_ids || []).not_to include(victim_tag.id)
    end

    # 杭A: CostSheet は dependent: :nullify のため、被害者の削除で攻撃者の明細が書き換わる
    it '他ユーザーのコストシートIDは紐づかない' do
      post medical_records_path, params: {
        medical_record: valid_record_params.merge(
          cost_items_attributes: [{ cost_sheet_id: victim_cost_sheet.id, item_name: '項目',
                                    quantity: 1, unit_price: 1000, }]
        ),
      }

      expect(CostItem.last&.cost_sheet_id).not_to eq(victim_cost_sheet.id)
    end
  end

  describe '施術記録の更新' do
    let(:record) do
      create(:medical_record, user: attacker, patient: attacker_patient, facility: attacker_facility)
    end

    # 杭A
    it '他ユーザーの患者へ付け替えられない' do
      patch medical_record_path(record), params: { medical_record: { patient_id: victim_patient.id } }

      expect(record.reload.patient_id).to eq(attacker_patient.id)
    end

    # 杭A
    it '他ユーザーの施設へ付け替えられない' do
      patch medical_record_path(record), params: { medical_record: { facility_id: victim_facility.id } }

      expect(record.reload.facility_id).to eq(attacker_facility.id)
    end
  end

  describe '請求書' do
    # 杭D: ID の推測すら不要で全テナントの施設名が読めてしまう経路
    it '新規作成フォームに他ユーザーの施設が並ばない' do
      victim_facility

      get new_invoice_path

      expect(response.body).not_to include('被害者クリニック')
    end

    # 杭B
    it '他ユーザーの施設では作成できない' do
      expect do
        post invoices_path, params: {
          invoice: { facility_id: victim_facility.id,
                     billing_period_start: Date.current.beginning_of_month,
                     billing_period_end: Date.current.end_of_month, },
        }
      end.not_to change(Invoice, :count)
    end
  end

  describe '施術記録フォームの選択肢' do
    # 杭D
    it '他ユーザーの患者・施設・タグが選択肢に並ばない' do
      victim_patient
      victim_facility
      victim_tag

      get new_medical_record_path

      expect(response.body).not_to include('被害者の患者')
      expect(response.body).not_to include('被害者クリニック')
      expect(response.body).not_to include('被害者タグ')
    end
  end

  # 多層防御の確認。
  # モデルのバリデーションを入れた今、越境レコードは新規には作れない（上記のとおり）。
  # ただしバリデーション導入前に作られた既存データは DB に残りうるため、
  # 表示側も current_user でスコープされていることを独立して固定する。
  describe '逆方向の汚染（被害者側から見た混入）' do
    # バリデーションを迂回して、過去に作られた越境レコードを再現する
    def create_legacy_cross_tenant_record
      record = MedicalRecord.new(user: attacker, patient: victim_patient,
                                 facility: attacker_facility,
                                 visit_date: Date.current, treatment_content: '注入された内容')
      record.save(validate: false)
      record
    end

    # 杭C
    it '他ユーザーが作成した施術記録が患者詳細に出ない' do
      create_legacy_cross_tenant_record

      sign_out attacker
      sign_in victim
      get patient_path(victim_patient)

      expect(response.body).not_to include('注入された内容')
    end

    # 杭C: 患者スコープの一覧も同様
    it '他ユーザーが作成した施術記録が患者スコープの一覧に出ない' do
      create_legacy_cross_tenant_record

      sign_out attacker
      sign_in victim
      get patient_medical_records_path(victim_patient)

      expect(response.body).not_to include('注入された内容')
    end

    # 杭C: 越境レコードが残っていても、被害者が自分の患者を削除できなくならない…
    # わけではない（dependent: :restrict_with_error のため）。現状の挙動を明示的に記録する。
    it '越境レコードが残っていると患者を削除できない（既知の制約）' do
      create_legacy_cross_tenant_record

      sign_out attacker
      sign_in victim

      expect { delete patient_path(victim_patient) }.not_to change(Patient, :count)
    end
  end
end
