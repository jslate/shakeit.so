# frozen_string_literal: true

require 'yaml'
require './song'

class SpotifyClient
  JSON_PATH = './tmp/spotify_token.json'
  TOKEN_FORM_DATA = {
    grant_type: 'refresh_token',
    refresh_token: ENV['SPOTIFY_REFRESH_TOKEN'],
    client_id: ENV['SPOTIFY_CLIENT_ID'],
    client_secret: ENV['SPOTIFY_CLIENT_SECRET']
  }.freeze
  ACCESS_TOKEN_URI = URI('https://accounts.spotify.com/api/token').freeze
  CURRENTLY_PLAYING_URI = URI('https://api.spotify.com/v1/me/player/currently-playing').freeze
  USER_PLAYLISTS_URI = URI('https://api.spotify.com/v1/users/jslate73/playlists').freeze

  def now_playing
    request = Net::HTTP::Get.new(CURRENTLY_PLAYING_URI)
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{access_token}"
    response = Net::HTTP.start(
      CURRENTLY_PLAYING_URI.hostname,
      CURRENTLY_PLAYING_URI.port,
      use_ssl: true
    ) { |http| http.request(request) }

    return if response.body.nil?

    song_hash = JSON.parse(response.body)
    song_data = {
      title: song_hash['item']['name'],
      artist: song_hash['item']['artists']&.map { |a| a['name'] }.join(', '),
      duration: song_hash['item']['duration_ms'].to_i,
      progress: song_hash['progress_ms'].to_i,
      image: song_hash['item']['album']['images'].first&.fetch('url', nil),
      uri: song_hash['item']['uri'],
    }

    local_song_data = YAML.load(File.read('./local_song_data.yml'))[song_data[:uri]] || {}

    Song.new(song_data.merge(local_song_data))
  end

  def latest_playlist_ids
    latest_playlists(limit: 10).map(&:id)
  end

  def latest_playlists(limit: 10)
    matches = playlists.items.select do |playlist|
      playlist.name.match?(/D\d+\b/) || playlist.name.match?(/WDP\d+\b/)
    end
    matches.first(limit)
  end

  def playlist(url)
    request = Net::HTTP::Get.new(url)
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{access_token}"
    response = Net::HTTP.start(
      CURRENTLY_PLAYING_URI.hostname,
      CURRENTLY_PLAYING_URI.port,
      use_ssl: true
    ) { |http| http.request(request) }

    response.body && JSON.parse(response.body, object_class: OpenStruct)
  end

  private

  def playlists
    request = Net::HTTP::Get.new(USER_PLAYLISTS_URI)
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{access_token}"
    response = Net::HTTP.start(
      CURRENTLY_PLAYING_URI.hostname,
      CURRENTLY_PLAYING_URI.port,
      use_ssl: true
    ) { |http| http.request(request) }
    response.body && JSON.parse(response.body, object_class: OpenStruct)
  end

  def access_token
    access_token_from_file || access_token_from_spotify
  end

  def access_token_from_file
    return unless File.exist?(JSON_PATH)

    data = JSON.parse(File.read(JSON_PATH))
    data['access_token'] if Time.now.to_i < data['expiration'].to_i
  end

  def access_token_from_spotify
    http = Net::HTTP.new(ACCESS_TOKEN_URI.host, ACCESS_TOKEN_URI.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(ACCESS_TOKEN_URI.request_uri)
    request.set_form_data(TOKEN_FORM_DATA)
    response = http.request(request)
    parsed_response = JSON.parse(response.body)
    token = parsed_response['access_token']
    save_token(token, parsed_response['expires_in'].to_i)
    token
  end

  def save_token(token, expires_in)
    File.write(JSON_PATH, {
      access_token: token,
      expiration: Time.now.to_i + expires_in
    }.to_json)
  end
end
