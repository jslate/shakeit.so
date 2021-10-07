require "sequel"

DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
unless DB.tables.include?(:responses)
  puts "create response table"
  DB.create_table :responses do
    primary_key :id
    column :name, String
    column :note, String
    column :created_at, DateTime
    column :party_id, Integer
  end
end

class Response < Sequel::Model(:responses)
end
