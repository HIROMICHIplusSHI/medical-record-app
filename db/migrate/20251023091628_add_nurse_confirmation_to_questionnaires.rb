class AddNurseConfirmationToQuestionnaires < ActiveRecord::Migration[7.2]
  def change
    add_column :questionnaires, :nurse_confirmed, :boolean, default: false, null: false
    add_column :questionnaires, :nurse_confirmed_at, :datetime
    add_column :questionnaires, :nurse_name, :string
  end
end
