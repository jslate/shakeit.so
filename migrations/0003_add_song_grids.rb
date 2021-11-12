# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:song_grids) do
      primary_key :id
      String :x_axis_label, null: false
      String :y_axis_label, null: false
      String :song_uri, null: false
    end

    create_table(:song_grid_responses) do
      primary_key :id
      foreign_key :song_grid_id, :song_grids
      Integer :x_axis, null: false
      Integer :y_axis, null: false
      String :song_uri, null: false
    end
  end

  down do
    drop_table :song_grid_responses
    drop_table :song_grids
  end
end
