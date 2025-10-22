namespace :data do
  desc 'Backfill last_message_by for existing inquiries based on actual last message'
  task backfill_inquiry_last_message: :environment do
    puts 'Starting backfill of last_message_by for existing inquiries...'

    updated_count = 0
    Inquiry.find_each do |inquiry|
      last_message = inquiry.inquiry_messages.order(created_at: :desc).first

      if last_message
        # 最後のメッセージの送信者に基づいて last_message_by を設定
        new_value = last_message.user.admin? ? :admin : :user
        old_value = inquiry.last_message_by

        if old_value == new_value.to_s
          puts "- Inquiry ##{inquiry.id}: already correct (#{old_value})"
        else
          inquiry.update_column(:last_message_by, new_value == :admin ? 1 : 0)
          puts "✓ Inquiry ##{inquiry.id}: #{old_value} → #{new_value}"
          updated_count += 1
        end
      else
        puts "⚠ Inquiry ##{inquiry.id}: no messages found, skipping"
      end
    end

    puts "\nBackfill complete!"
    puts "Updated #{updated_count} inquiries"

    # キャッシュをクリア
    puts "\nClearing notification caches..."
    User.find_each do |user|
      Rails.cache.delete("unread_inquiry_count_user_#{user.id}")
    end
    puts '✓ Caches cleared'
  end
end
