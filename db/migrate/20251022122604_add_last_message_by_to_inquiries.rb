class AddLastMessageByToInquiries < ActiveRecord::Migration[7.2]
  def change
    add_column :inquiries, :last_message_by, :integer, default: 0, null: false, comment: '最後にメッセージを送った人 (0: user, 1: admin)'
  end
end
