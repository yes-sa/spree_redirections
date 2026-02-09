# frozen_string_literal: true

class AddColumnsToRedirections < ActiveRecord::Migration[7.2]
  def change
    add_column :redirections, :deleted_by, :string, default: 'Unknown'
    add_column :redirections, :created_by, :string, default: 'Unknown'
  end
end
