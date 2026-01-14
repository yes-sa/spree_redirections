# frozen_string_literal: true

class CreateRedirection < ActiveRecord::Migration[7.2]
  def change
    create_table :redirections do |t|
      t.string :store_id, null: false
      t.string :old_url, null: false
      t.string :new_url, null: false
      t.string :http_status, null: false
      t.boolean :external_redirection
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
