class AddCompanyInfoToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :company_name, :string
    add_column :users, :company_postal, :string
    add_column :users, :company_address, :text
    add_column :users, :company_phone, :string
    add_column :users, :company_email, :string
    add_column :users, :bank_info, :text
  end
end
