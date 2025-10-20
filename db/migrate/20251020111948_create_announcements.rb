class CreateAnnouncements < ActiveRecord::Migration[7.2]
  def change
    create_table :announcements do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false, limit: 100
      t.text :body, null: false, limit: 1000
      t.integer :status, default: 0, null: false
      t.integer :severity, default: 0, null: false
      t.datetime :published_at
      t.datetime :expires_at
      t.integer :display_order, default: 0, null: false

      t.timestamps
    end

    # インデックス追加（検索性能向上）
    add_index :announcements, :status
    add_index :announcements, :published_at
    add_index :announcements, :expires_at
    add_index :announcements, %i[status published_at expires_at], name: 'index_announcements_on_active'
  end
end
