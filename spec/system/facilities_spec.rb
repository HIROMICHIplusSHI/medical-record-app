require 'rails_helper'

RSpec.describe 'Facilities', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe '施設管理', js: true do
    context '新規作成' do
      it '施設を作成できる' do
        visit new_facility_path

        fill_in '施設名', with: 'テスト施設'
        fill_in '住所', with: '東京都渋谷区1-1-1'
        fill_in '電話番号', with: '03-1234-5678'

        click_button '保存'

        expect(page).to have_content('施設が正常に作成されました')
        expect(page).to have_content('テスト施設')
      end
    end

    context '編集' do
      let!(:facility) { create(:facility, user: user, name: '既存施設') }

      it '施設を編集できる' do
        visit edit_facility_path(facility)

        fill_in '施設名', with: '更新された施設'
        click_button '保存'

        expect(page).to have_content('施設が正常に更新されました')
        expect(page).to have_content('更新された施設')
      end
    end
  end

  describe '医師情報の動的フォーム', js: true do
    context '新規作成時' do
      it '医師を動的に追加できる' do
        visit new_facility_path

        fill_in '施設名', with: 'テスト施設'

        # 最初は医師フィールドが0件
        expect(page).to have_selector('.facility-doctor-row', count: 0)

        # 医師を追加
        click_button '医師を追加'
        expect(page).to have_selector('.facility-doctor-row', count: 1)

        # 医師情報を入力
        within all('.facility-doctor-row').last do
          fill_in '医師名', with: '山田太郎'
          fill_in '医師免許番号', with: 'DOC001'
          fill_in '専門分野', with: '美容外科'
        end

        # もう1人追加
        click_button '医師を追加'
        expect(page).to have_selector('.facility-doctor-row', count: 2)

        within all('.facility-doctor-row').last do
          fill_in '医師名', with: '佐藤花子'
        end

        # 保存
        click_button '保存'

        expect(page).to have_content('施設が正常に作成されました')

        # 医師が保存されたことを確認
        facility = Facility.last
        expect(facility.facility_doctors.count).to eq(2)
        expect(facility.facility_doctors.pluck(:name)).to include('山田太郎', '佐藤花子')
      end

      it '追加した医師フィールドを削除できる' do
        visit new_facility_path

        fill_in '施設名', with: 'テスト施設'

        # 医師を2人追加
        click_button '医師を追加'
        click_button '医師を追加'

        expect(page).to have_selector('.facility-doctor-row', count: 2)

        # 1人目を削除
        within all('.facility-doctor-row').first do
          find('button[data-action="click->nested-form#removeItem"]').click
        end

        # 削除後は1件のみ表示
        expect(page).to have_selector('.facility-doctor-row:not([style*="display: none"])', count: 1)
      end
    end

    context '編集時' do
      let!(:facility) do
        create(:facility, user: user, name: '既存施設').tap do |f|
          create(:facility_doctor, facility: f, name: '既存医師1')
          create(:facility_doctor, facility: f, name: '既存医師2')
        end
      end

      it '既存の医師情報が表示される' do
        visit edit_facility_path(facility)

        expect(page).to have_selector('.facility-doctor-row', count: 2)
        expect(page).to have_field('医師名', with: '既存医師1')
        expect(page).to have_field('医師名', with: '既存医師2')
      end

      it '既存医師を更新し、新規医師を追加できる' do
        visit edit_facility_path(facility)

        # 既存医師を更新
        within all('.facility-doctor-row').first do
          fill_in '医師名', with: '更新された医師1'
        end

        # 新規医師を追加
        click_button '医師を追加'
        expect(page).to have_selector('.facility-doctor-row', count: 3)

        within all('.facility-doctor-row').last do
          fill_in '医師名', with: '新規医師3'
          fill_in '医師免許番号', with: 'DOC003'
        end

        click_button '保存'

        expect(page).to have_content('施設が正常に更新されました')

        facility.reload
        expect(facility.facility_doctors.count).to eq(3)
        expect(facility.facility_doctors.pluck(:name)).to include('更新された医師1', '既存医師2', '新規医師3')
      end

      it '既存医師を削除できる' do
        visit edit_facility_path(facility)

        expect(page).to have_selector('.facility-doctor-row', count: 2)

        # 1人目を削除
        within all('.facility-doctor-row').first do
          find('button[data-action="click->nested-form#removeItem"]').click
        end

        # 削除後は非表示
        expect(page).to have_selector('.facility-doctor-row:not([style*="display: none"])', count: 1)

        click_button '保存'

        expect(page).to have_content('施設が正常に更新されました')

        facility.reload
        expect(facility.facility_doctors.count).to eq(1)
        expect(facility.facility_doctors.first.name).to eq('既存医師2')
      end
    end
  end
end
