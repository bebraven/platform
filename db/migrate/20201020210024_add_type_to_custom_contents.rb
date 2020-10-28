class AddTypeToCustomContents < ActiveRecord::Migration[6.0]
  def change
    add_column :custom_contents, :type, :string
  end
end
