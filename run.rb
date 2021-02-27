require "net/http"
require "json"
require "sinatra"
require "sinatra/json"
require "pry"
require "haml"
require "./read_spreadsheet"

def now_playing
  uri = URI("https://api.spotify.com/v1/me/player/currently-playing")
  request = Net::HTTP::Get.new(uri)
  request["Accept"] = "application/json"
  request["Content-Type"] = "application/json"
  request["Authorization"] = "Bearer #{File.read("./token").chomp}"
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
  JSON.parse(response.body, object_class: OpenStruct)
end

def format_time(milliseconds)
  total_seconds = milliseconds / 1000
  minutes = total_seconds / 60
  seconds = total_seconds % 60
  "#{minutes}:#{seconds.to_s.rjust(2, "0")}"
end

def data
  {
    song: @now_playing.item.name,
    artist: @now_playing.item.artists.map(&:name).join(", "),
    time_remaining: "-#{format_time(@now_playing.item.duration_ms.to_i - @now_playing.progress_ms.to_i)}",
    progress_width: "#{(@now_playing.progress_ms.to_f/@now_playing.item.duration_ms.to_f*100).floor}%",
    image: @now_playing.item.album.images[1].url,
    notes: SpreadsheetReader.new.get_notes,
  }
end

def load_data
  @now_playing = now_playing
end

get "/" do
  haml :home
end

get '/player' do
  load_data
  haml :index, locals: data
end

get "/np" do
  load_data
  json(data)
end
