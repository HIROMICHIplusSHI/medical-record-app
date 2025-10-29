class AddIndexToInvitationCodesCreatedAt < ActiveRecord::Migration[7.2]
  def change
    add_index :invitation_codes, :created_at
  end
end
