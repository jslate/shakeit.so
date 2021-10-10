# frozen_string_literal: true

require 'sequel'

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
unless DB.tables.include?(:parties)
  puts 'create party table'
  DB.create_table :parties do
    primary_key :id
    column :name, String
  end
end

class Party < Sequel::Model(:parties)
end
