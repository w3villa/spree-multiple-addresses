class ToAddParentIdToOrder < ActiveRecord::Migration
  def change
  	add_column :spree_orders, :parent_id, :integer
  	add_column :spree_orders, :recipient_name, :string
  end
end
