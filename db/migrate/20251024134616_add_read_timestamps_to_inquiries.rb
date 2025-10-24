class AddReadTimestampsToInquiries < ActiveRecord::Migration[7.2]
  def change
    add_column :inquiries, :admin_read_at, :datetime
    add_column :inquiries, :user_read_at, :datetime
  end
end
