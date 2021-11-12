# frozen_string_literal: true

Sequel.migration do
  up do
    add_column :responses, :show_response, TrueClass
    add_column :responses, :reviewed, TrueClass
  end

  down do
    drop_column :responses, :show_response
    drop_column :responses, :reviewed
  end
end
