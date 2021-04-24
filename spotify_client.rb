require "./song"

class SpotifyClient
  JSON_PATH = "./tmp/spotify_token.json".freeze
  TOKEN_FORM_DATA = {
    grant_type: "refresh_token".freeze,
    refresh_token: ENV["SPOTIFY_REFRESH_TOKEN"].freeze,
    client_id: ENV["SPOTIFY_CLIENT_ID"].freeze,
    client_secret: ENV["SPOTIFY_CLIENT_SECRET"].freeze,
  }.freeze
  ACCESS_TOKEN_URI = URI("https://accounts.spotify.com/api/token").freeze
  CURRENTLY_PLAYING_URI = URI("https://api.spotify.com/v1/me/player/currently-playing").freeze
  USER_PLAYLISTS_URI = URI("https://api.spotify.com/v1/users/jslate73/playlists").freeze

  def now_playing
    request = Net::HTTP::Get.new(CURRENTLY_PLAYING_URI)
    request["Accept"] = "application/json"
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{access_token}"
    response = Net::HTTP.start(
      CURRENTLY_PLAYING_URI.hostname,
      CURRENTLY_PLAYING_URI.port,
      use_ssl: true) { |http| http.request(request) }

    return if response.body.nil?

    song_data = JSON.parse(response.body, object_class: OpenStruct)
    Song.new(
      title: song_data.item.name,
      artist: song_data.item.artists.map(&:name).join(", "),
      duration: song_data.item.duration_ms.to_i,
      progress: song_data.progress_ms.to_i,
      image: song_data.item.album.images[1].url,
    )
  end

  def latest_playlists
    playlists.items.find { |playlist| playlist.name.match?(/D\d+\b/) }.first(5)
  end

  private

  def playlist(url)
    request = Net::HTTP::Get.new(url)
    request["Accept"] = "application/json"
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{access_token}"
    response = Net::HTTP.start(
      CURRENTLY_PLAYING_URI.hostname,
      CURRENTLY_PLAYING_URI.port,
      use_ssl: true) { |http| http.request(request) }

    response.body && JSON.parse(response.body, object_class: OpenStruct)
  end

  def playlists
    request = Net::HTTP::Get.new(USER_PLAYLISTS_URI)
    request["Accept"] = "application/json"
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{access_token}"
    response = Net::HTTP.start(
      CURRENTLY_PLAYING_URI.hostname,
      CURRENTLY_PLAYING_URI.port,
      use_ssl: true) { |http| http.request(request) }
    response.body && JSON.parse(response.body, object_class: OpenStruct)
  end

  def access_token
    access_token_from_file || access_token_from_spotify
  end

  def access_token_from_file
    return unless File.exists?(JSON_PATH)

    data = JSON.parse(File.read(JSON_PATH))
    data["access_token"] if Time.now.to_i < data["expiration"].to_i
  end

  def access_token_from_spotify
    http = Net::HTTP.new(ACCESS_TOKEN_URI.host, ACCESS_TOKEN_URI.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(ACCESS_TOKEN_URI.request_uri)
    request.set_form_data(TOKEN_FORM_DATA)
    response = http.request(request)
    parsed_response = JSON.parse(response.body)
    token = parsed_response["access_token"]
    save_token(token, parsed_response["expires_in"].to_i)
    token
  end

  def save_token(token, expires_in)
    File.write(JSON_PATH, {
      access_token: token,
      expiration: Time.now.to_i + expires_in
    }.to_json)
  end
end
