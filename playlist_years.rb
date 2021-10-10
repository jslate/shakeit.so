# frozen_string_literal: true

require 'dotenv/load'
require 'json'
require 'net/http'
require './spotify_client'
require 'pry'

name = ARGV[0]
client = SpotifyClient.new
playlists = client.latest_playlists(limit: 10)

href = if name.nil?
         playlists.first.href
       else
         playlists.find { |playlist| playlist.name.downcase.include?(name.downcase) }.href
       end

playlist = client.playlist(href)

data = playlist.tracks.items.map do |item|
  {
    name: item.track.name,
    year: item.track.album.release_date,
    artists: item.track.artists.map(&:name).join('; '),
    popularity: item.track.popularity
  }
end

puts data.map { |d| d[:name] }
puts data.map { |d| d[:year].split('-').first }
puts data.map { |d| "How popular? (1-100); #{d[:popularity]}" }

data.each_with_index do |d, i|
  puts "#{i + 1}. #{d[:name]} - #{d[:artists]}\n"
end
