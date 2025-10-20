class AddRoleToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :role, :integer, default: 0, null: false

    # 既存ユーザーのroleをuserに設定（安全のため明示的に実行）
    reversible do |dir|
      dir.up do
        User.update_all(role: 0)
      end
    end
  end
end
