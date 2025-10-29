class AddInvitationCodeToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :invitation_code, null: true, foreign_key: true, index: true
  end
end
