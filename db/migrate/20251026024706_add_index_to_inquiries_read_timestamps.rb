class AddIndexToInquiriesReadTimestamps < ActiveRecord::Migration[7.2]
  def change
    add_index :inquiries, :admin_read_at
    add_index :inquiries, :user_read_at
  end
end
