class AddSalesforceTypeToSections < ActiveRecord::Migration[6.0]
  def change
    add_column :sections, :salesforce_type, :string
  end
end
