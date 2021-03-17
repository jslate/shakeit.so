require 'dotenv/load'
require "net/http"
require "json"
require "sinatra"
require "sinatra/json"
require "pry"
require "haml"
require "./google_client"
require "./spotify_client"

def format_time(milliseconds)
  total_seconds = milliseconds / 1000
  minutes = total_seconds / 60
  seconds = total_seconds % 60
  "#{minutes}:#{seconds.to_s.rjust(2, "0")}"
end

def notes
  client = GoogleClient.new("A1", "C100")
  selected_rows = client.notes["values"].select do |row|
    row[0] && row[1] == "TRUE" && (!row[2] || @now_playing.item.name.downcase.include?(row[2]&.downcase))
  end

  selected_rows.empty? ? [""] : selected_rows.map(&:first).map(&:to_s)
end

def format_data
  if !@now_playing.nil?
    {
      song: @now_playing.item.name,
      artist: @now_playing.item.artists.map(&:name).join(", "),
      time_remaining: "-#{format_time(@now_playing.item.duration_ms.to_i - @now_playing.progress_ms.to_i)}",
      duration: @now_playing.item.duration_ms.to_i,
      progress: @now_playing.progress_ms.to_i,
      progress_width: "#{(@now_playing.progress_ms.to_f/@now_playing.item.duration_ms.to_f*100).floor}%",
      image: @now_playing.item.album.images[1].url,
      notes: notes,
    }
  end
end

def fake_data
  {
    song: "Twice As Hard",
    artist: "The Black Crowes",
    time_remaining: "-3:54",
    progress_width: "6%",
    image: "/images/twice-as-hard.jpg",
    notes: ["Keep on rockin'!"],
  }
end

def load_data
  @now_playing = SpotifyClient.new.now_playing
end

get '/' do
  load_data
  data = @now_playing.nil? ? fake_data : format_data

  haml :index, locals: data
end

get '/about' do
  haml :about
end

get '/playlists' do
  haml :playlists
end

get "/np" do
  load_data
  json(format_data)
end
