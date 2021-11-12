# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:parties) do
      primary_key :id
      String :name, null: false
      DateTime :created_at
      DateTime :updated_at
    end

    create_table(:responses) do
      primary_key :id
      foreign_key :party_id, :parties
      String :name
      String :note
      String :email
      TrueClass :email_opt_in
      TrueClass :email_opt_in_this_event
      DateTime :created_at
      DateTime :updated_at
    end
  end

  down do
    drop_table :responses
    drop_table :parties
  end
end
