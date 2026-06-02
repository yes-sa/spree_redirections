# frozen_string_literal: true

class AddProductIdToRedirection < ActiveRecord::Migration[7.2]
  def change
    add_column :redirections, :spree_product_id, :string, default: '', null: false
    add_column :redirections, :redirection_type, :string, default: ''
    add_index :redirections, :spree_product_id
    add_index :redirections, :redirection_type
  end
end
