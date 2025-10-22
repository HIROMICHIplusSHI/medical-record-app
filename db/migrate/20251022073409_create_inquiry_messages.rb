class CreateInquiryMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :inquiry_messages do |t|
      t.references :inquiry, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false, limit: 2000

      t.timestamps
    end

    add_index :inquiry_messages, :created_at
  end
end
