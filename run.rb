require 'dotenv/load'
require "active_support/all"
require "net/http"
require "json"
require "sinatra"
require "sinatra/json"
require "pry"
require "haml"
require "./google_client"
require "./spotify_client"
require "./note"

def format_time(milliseconds)
  total_seconds = milliseconds / 1000
  minutes = total_seconds / 60
  seconds = total_seconds % 60
  "#{minutes}:#{seconds.to_s.rjust(2, "0")}"
end

def notes
  client = GoogleClient.new("A1", "C100")
  client.data["values"].map { |values| Note.new(values) }.select do |note|
    note.enabled? && note.show_for_song?(@now_playing)
  end
end

def format_data
  if @now_playing.present?
    {
      title: @now_playing.title,
      artist: @now_playing.artist,
      duration: @now_playing.duration,
      progress: @now_playing.progress,
      image: @now_playing.image,
      time_remaining: format_time(@now_playing.time_remaining),
      progress_percentage: @now_playing.progress_percentage,
      notes: notes.map(&:text),
    }
  end
end

def fake_data
  {
    title: "Twice As Hard",
    artist: "The Black Crowes",
    time_remaining: "-3:54",
    progress_percentage: "6",
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

get '/international' do
  haml :international
end

get '/playlists' do
  haml :playlists
end

get "/np" do
  load_data
  json(format_data)
end
