class CreateFacilities < ActiveRecord::Migration[7.1]
  def change
    create_table :facilities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :address
      t.string :phone
      t.string :email
      t.text :notes

      t.timestamps
    end

    add_index :facilities, [:user_id, :name]
  end
end
