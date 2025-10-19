class AddItemContentToConsentItemResponses < ActiveRecord::Migration[7.2]
  def change
    add_column :consent_item_responses, :item_content, :text
  end
end
