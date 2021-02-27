require 'dotenv/load'
require "net/http"
require "json"
require "sinatra"
require "sinatra/json"
require "pry"
require "haml"
# require "./read_spreadsheet"

def now_playing
  uri = URI("https://api.spotify.com/v1/me/player/currently-playing")
  request = Net::HTTP::Get.new(uri)
  request["Accept"] = "application/json"
  request["Content-Type"] = "application/json"
  request["Authorization"] = "Bearer #{ENV['SPOTIFY_TOKEN']}"
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
    notes: ["Nice moves!", "Looking good"] # SpreadsheetReader.new.get_notes,
  }
end

def load_data
  @now_playing = now_playing
end

get "/" do
  haml :home
end

get "/spot_auth" do
  base = "https://accounts.spotify.com/authorize"
  request_params = {
    client_id: "be9bf6d4e3ab47b89f62ec63da06d3af",
    response_type: "code",
    redirect_uri: "https://shakeit-so-8a5sw.ondigitalocean.app/spot_auth_callback",
    scope: "user-read-currently-playing user-read-playback-position",
  }
  url = "#{base}?#{request_params.map { |key, value| [key,value].join('=') }.join('&') }"
  redirect url
end

get '/spot_auth_callback' do
  code = params['code']
  uri = URI("https://accounts.spotify.com/api/token")

  request = Net::HTTP::Post.new(uri.request_uri)
  request.set_form_data({
    grant_type: "authorization_code",
    code: code,
    redirect_uri: "https://shakeit-so-8a5sw.ondigitalocean.app/spot_auth_callback",
    client_id: ENV["SPOTIFY_CLIENT_ID"],
    client_secret: ENV["SPOTIFY_CLIENT_SECRET"],
  })

  response = http.request(request)
  response.to_json

  # request = Net::HTTP::Post.new(uri)
  # request["Accept"] = "application/json"
  # request["Content-Type"] = "application/json"
  # request["Authorization"] = "Bearer #{ENV['SPOTIFY_TOKEN']}"
  # response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
end

get '/player' do
  load_data
  haml :index, locals: data
end

get "/np" do
  load_data
  json(data)
end
