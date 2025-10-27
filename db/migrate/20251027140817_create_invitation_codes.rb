class CreateInvitationCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :invitation_codes do |t|
      t.string :code, null: false
      t.integer :max_uses
      t.integer :used_count, default: 0, null: false
      t.datetime :expires_at
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0, null: false
      t.text :memo

      t.timestamps
    end
    add_index :invitation_codes, :code, unique: true
    add_index :invitation_codes, :status
    add_index :invitation_codes, :expires_at
  end
end
