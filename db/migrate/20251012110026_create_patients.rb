class CreatePatients < ActiveRecord::Migration[7.1]
  def change
    create_table :patients do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.date :date_of_birth
      t.integer :gender, default: 0
      t.string :phone
      t.string :email
      t.text :address
      t.string :emergency_contact

      t.timestamps
    end

    add_index :patients, :email
    add_index :patients, :created_at
  end
end
