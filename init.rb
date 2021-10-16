# frozen_string_literal: true

require 'dotenv/load'
require 'active_support/all'
require 'net/http'
require 'json'
require 'sinatra'
require 'sinatra/json'
require 'pry'
require 'sequel'
require 'haml'
require './google_client'
require './spotify_client'
require './note'

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
require './models/party'
require './models/response'
require './models/song_grid'
