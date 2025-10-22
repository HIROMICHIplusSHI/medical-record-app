class CreateInquiries < ActiveRecord::Migration[7.2]
  def change
    create_table :inquiries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :subject, null: false, limit: 100
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :inquiries, :status
    add_index :inquiries, :updated_at
  end
end
