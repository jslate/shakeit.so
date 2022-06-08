# frozen_string_literal: true

require 'dotenv/load'
require 'active_support/all'
require 'net/http'
require 'json'
require 'sinatra'
require 'sinatra/json'
require 'pry'
require 'sequel'
require 'haml'
require 'rqrcode'
require './google_client'
require './spotify_client'
require './note'

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
require './models/party'
require './models/response'
require './models/song_grid'
require './models/song_grid_response'

class ShakeItSo < Sinatra::Base
  def format_time(milliseconds)
    total_seconds = milliseconds / 1000
    minutes = total_seconds / 60
    seconds = total_seconds % 60
    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end

  def notes
    client = GoogleClient.new('A1', 'C100')
    client.data['values']&.map { |values| Note.new(values) }&.select do |note|
      note.enabled? && note.show_for_song?(@now_playing)
    end
  end

  def format_data
    return unless @now_playing.present?

    {
      title: ellipsify(@now_playing.title, 40), artist: ellipsify(@now_playing.artist, 40),
      duration: @now_playing.duration, progress: @now_playing.progress,
      image: @now_playing.image, time_remaining: format_time(@now_playing.time_remaining),
      progress_percentage: @now_playing.progress_percentage,
      notes: notes&.map(&:text)
    }
  end

  def ellipsify(string, length)
    if string.length <= length
      string
    else
      "#{string.slice(0, length)}…"
    end
  end

  def fake_data
    {
      title: 'Twice As Hard',
      artist: 'The Black Crowes',
      time_remaining: '-3:54',
      progress_percentage: '6',
      image: '/images/twice-as-hard.jpg',
      notes: ["Keep on rockin'!"]
    }
  end

  def load_data
    @now_playing = SpotifyClient.new.now_playing
  end

  enable :sessions

  before do
    expires 600, :public, :must_revalidate
  end

  get '/' do
    haml :index
  end

  get '/hhgh' do
    haml :index
  end

  get '/about' do
    haml :about
  end

  get '/player' do
    haml :player
  end

  get '/international' do
    haml :international
  end

  get '/hhgh_videos' do
    haml :hhgh_videos
  end

  get '/playlists' do
    load_data
    data = @now_playing.nil? ? fake_data : format_data

    ids = SpotifyClient.new.latest_playlist_ids

    haml :playlists, locals: data.merge(ids: ids)
  end

  get '/np' do
    load_data
    json(format_data)
  end

  get '/qr' do
    # qr_code = RQRCode::QRCode.new('https://8175-174-83-26-31.ngrok.io/now_playing_grid')
    qr_code = RQRCode::QRCode.new(env['REQUEST_URI'].sub(/\w*$/, 'now_playing_grid'))
    haml :now_playing_qr_code, locals: { qr_code: qr_code }
  end

  get '/now_playing_grid' do
    load_data
    song_grid = SongGrid.first(song_uri: @now_playing.uri)
    haml :now_playing_grid, locals: {
      song_grid: song_grid,
      song: @now_playing,
      song_grid_responses: SongGridResponse.where(song_grid_id: song_grid.id),
      submitted: session["#{@now_playing.uri}_submitted"] || params[:submitted]
    }
  end

  post '/now_playing_grid/:song_uri' do
    song_grid = SongGrid.first(song_uri: params[:song_uri])
    SongGridResponse.create(
      song_grid_id: song_grid.id,
      x_axis: (params[:x_pos].to_f * 100).to_i,
      y_axis: (params[:y_pos].to_f * 100).to_i,
      song_uri: params[:song_uri]
    )
    session["#{params[:song_uri]}_submitted"] = true
    redirect '/now_playing_grid'
  end

  get '/party/:id' do
    party = Party.first(id: params[:id])
    responses = Response.where(party_id: party.id, show_response: true, reviewed: true).reverse_order(:created_at).all
    haml :party, locals: { party: party, responses: responses, thank_you: params[:thank_you].present? },
                 escape_html: true
  end

  post '/party/:id' do
    Response.create(
      party_id: params[:id],
      name: params[:name],
      email: params[:email],
      email_opt_in_this_event: params[:email_opt_in_this_event],
      email_opt_in: params[:email_opt_in],
      show_response: params[:show_response],
      note: params[:note],
      created_at: Time.now,
      updated_at: Time.now
    )
    redirect "/party/#{params[:id]}?thank_you=true"
  end

  get '/party_review/:id' do
    cache_control :no_cache
    logged_in = session[:logged_in]
    party = Party.first(id: params[:id])
    responses = Response.where(party_id: party.id).reverse_order(:reviewed, :created_at).all
    haml :party_review, locals: { logged_in: logged_in, party: party, responses: responses }, escape_html: true
  end

  post '/party_review/:id' do
    session[:logged_in] = true if params[:password] == ENV['REVIEW_PASSWORD']
    redirect "/party_review/#{params[:id]}"
  end

  post '/party_review/:response_id/:action' do
    redirect "/party_review/#{params[:id]}" unless session[:logged_in]
    response = Response.first(id: params[:response_id])

    case params[:action]
    when 'approve' then response.update(reviewed: true)
    when 'destroy' then response.destroy
    end

    redirect "/party_review/#{response.party_id}"
  end

  post '/logout' do
    session[:logged_in] = nil
    redirect '/'
  end

  get '/robin' do
    <<-HTML
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>body { font-size: 1.5em; }</style>
      <p>Here ya go:<p>
      <a style="word-break: break-all;" href="https://us06web.zoom.us/j/96598219853?pwd=eVo3MDRDdElvVFZCN2dSSkl0ZXE3QT09">
        https://us06web.zoom.us/j/96598219853?pwd=eVo3MDRDdElvVFZCN2dSSkl0ZXE3QT09
      </a>

      <p>Passcode: dw/j-4fun</p>
      <p>Meeting ID: 965 9821 9853</p>
    HTML
  end

  get '/mzanga' do
    <<-HTML
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>body { font-size: 1.5em; }</style>
      <p>Here ya go, mzanga!<p>
      <a style="word-break: break-all;" href="https://us06web.zoom.us/j/96598219853?pwd=eVo3MDRDdElvVFZCN2dSSkl0ZXE3QT09">
        https://us06web.zoom.us/j/96598219853?pwd=eVo3MDRDdElvVFZCN2dSSkl0ZXE3QT09
      </a>

      <p>Passcode: dw/j-4fun<br/>
      Meeting ID: 965 9821 9853</p>

      <p>Good for all regular morning dance parties, just not a few special events (like w/ Mphepo Chimtali)</p>
    HTML
  end
end
