require 'dotenv/load'
require "json"
require "net/http"
require 'uri'
require "./spotify_client"

puts JSON.pretty_generate(SpotifyClient.new.playlists)
