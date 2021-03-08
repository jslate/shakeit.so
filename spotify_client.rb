class SpotifyClient
  JSON_PATH = "./tmp/spotify_token.json".freeze
  TOKEN_FORM_DATA = {
    grant_type: "refresh_token".freeze,
    refresh_token: ENV["SPOTIFY_REFRESH_TOKEN"].freeze,
    client_id: ENV["SPOTIFY_CLIENT_ID"].freeze,
    client_secret: ENV["SPOTIFY_CLIENT_SECRET"].freeze,
  }.freeze
  ACCESS_TOKEN_TOKEN = URI("https://accounts.spotify.com/api/token").freeze
  CURRENTLY_PLAYING_TOKEN = URI("https://api.spotify.com/v1/me/player/currently-playing").freeze

  def now_playing
    request = Net::HTTP::Get.new(CURRENTLY_PLAYING_TOKEN)
    request["Accept"] = "application/json"
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{access_token}"
    response = Net::HTTP.start(
      CURRENTLY_PLAYING_TOKEN.hostname,
      CURRENTLY_PLAYING_TOKEN.port,
      use_ssl: true) { |http| http.request(request) }
    response.body && JSON.parse(response.body, object_class: OpenStruct)
  end

  private

  def access_token
    access_token_from_file || access_token_from_spotify
  end

  def access_token_from_file
    return unless File.exists?(JSON_PATH)

    data = JSON.parse(File.read(JSON_PATH))
    data["access_token"] if Time.now.to_i < data["expiration"].to_i
  end

  def access_token_from_spotify
    http = Net::HTTP.new(ACCESS_TOKEN_TOKEN.host, ACCESS_TOKEN_TOKEN.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(ACCESS_TOKEN_TOKEN.request_uri)
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
