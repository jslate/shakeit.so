# frozen_string_literal: true

require 'dotenv/load'
require 'json'
require 'net/http'
require './spotify_client'
require 'pry'

name = ARGV[0]
client = SpotifyClient.new
playlists = client.latest_playlists(limit: 100)

items = []

playlists.each do |pl|
  playlist = client.playlist(pl.href)
  items += playlist.tracks.items.select { |i| %w[2019 2020 2021].include?(i.track.album.release_date.split('-').first) }
end

items.map! do |item|
  {
    name: item.track.name,
    year: item.track.album.release_date,
    artists: item.track.artists.map(&:name).join('; '),
    popularity: item.track.popularity,
    uri: item.track.uri
  }
end

puts items.map { |d| d[:uri] }.join(',')
