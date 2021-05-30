require 'dotenv/load'
require "json"
require "net/http"
require "./spotify_client"

client = SpotifyClient.new
playlist = client.playlist(client.latest_playlists(limit: 1).first.href)

data = playlist.tracks.items.map do |item|
  { name: item.track.name, year: item.track.album.release_date }
end

puts data.map { |d| d[:name]}
puts data.map { |d| d[:year].split("-").first }
