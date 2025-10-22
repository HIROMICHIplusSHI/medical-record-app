class AddCategoryToInquiries < ActiveRecord::Migration[7.2]
  def change
    add_column :inquiries, :category, :integer, default: 0, null: false
  end
end
