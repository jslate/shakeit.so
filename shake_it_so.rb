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
require './google_client'
require './spotify_client'
require './note'

DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
require './models/party'
require './models/response'

class ShakeItSo < Sinatra::Base
  def format_time(milliseconds)
    total_seconds = milliseconds / 1000
    minutes = total_seconds / 60
    seconds = total_seconds % 60
    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end

  def notes
    client = GoogleClient.new('A1', 'C100')
    client.data['values'].map { |values| Note.new(values) }.select do |note|
      note.enabled? && note.show_for_song?(@now_playing)
    end
  end

  def format_data
    return unless @now_playing.present?

    {
      title: @now_playing.title, artist: @now_playing.artist,
      duration: @now_playing.duration, progress: @now_playing.progress,
      image: @now_playing.image, time_remaining: format_time(@now_playing.time_remaining),
      progress_percentage: @now_playing.progress_percentage,
      notes: notes.map(&:text)
    }
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

  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', '@toadly!']
  end

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
    protected!
    party = Party.first(id: params[:id])
    responses = Response.where(party_id: party.id).reverse_order(:reviewed, :created_at).all
    haml :party_review, locals: { party: party, responses: responses }, escape_html: true
  end

  post '/party_review/:response_id/:action' do
    protected!
    response = Response.first(id: params[:response_id])

    case params[:action]
    when 'approve' then response.update(reviewed: true)
    when 'destroy' then response.destroy
    end

    redirect "/party_review/#{response.party_id}"
  end
end
