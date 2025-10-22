class AddCompositeIndexToInquiries < ActiveRecord::Migration[7.2]
  def change
    add_index :inquiries, [:status, :last_message_by],
              name: 'index_inquiries_on_status_and_last_message_by'
  end
end
