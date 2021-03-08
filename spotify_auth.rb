get "/refresh_token" do
  refresh_spotify_access_token
end

get "/spot_auth" do
  base = "https://accounts.spotify.com/authorize"
  request_params = {
    client_id: "be9bf6d4e3ab47b89f62ec63da06d3af",
    response_type: "code",
    redirect_uri: "http://localhost:4567/spot_auth_callback",
    scope: "user-read-currently-playing user-read-playback-position",
  }
  url = "#{base}?#{request_params.map { |key, value| [key,value].join('=') }.join('&') }"
  redirect url
end

get '/spot_auth_callback' do
  code = params['code']
  uri = URI("https://accounts.spotify.com/api/token")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Post.new(uri.request_uri)
  request.set_form_data({
    grant_type: "authorization_code",
    code: code,
    redirect_uri: "http://localhost:4567/spot_auth_callback",
    client_id: ENV["SPOTIFY_CLIENT_ID"],
    client_secret: ENV["SPOTIFY_CLIENT_SECRET"],
  })

  response = http.request(request)
  response.body.to_json
end
