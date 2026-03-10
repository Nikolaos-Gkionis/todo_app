# frozen_string_literal: true

class AddPolarFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :polar_customer_id, :string
    add_column :users, :polar_product_id, :string
    add_column :users, :polar_order_id, :string
    add_index :users, :polar_customer_id
    add_index :users, :polar_order_id
  end
end
