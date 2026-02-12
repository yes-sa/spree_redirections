# frozen_string_literal: true

class AddIndexesForRedirection < ActiveRecord::Migration[7.2]
  def change
    add_index :redirections, :old_url
    add_index :redirections, :store_url
    add_index :redirections, :deleted_at
    add_index :redirections, :created_at
    add_index :redirections, :new_url
    add_index :redirections, :deleted_by
    add_index :redirections, :created_by
    add_index :redirections, %i[store_url old_url], unique: true, where: 'deleted_at IS NULL'
  end
end
