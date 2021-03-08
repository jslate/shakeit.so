require 'uri'
require 'net/http'
require 'json'

class GoogleClient
  API_KEY = ENV["GOOGLE_API_KEY"].freeze
  GOOGLE_SHEETS_HOST = URI("https://sheets.googleapis.com").freeze
  SHEET_ID = "1FDQWEK7ZRYt4egJVKE8CHZKnopi8S6UCCbzxbf9OciQ".freeze

  def initialize(range_start, range_end)
    @range_start = range_start
    @range_end = range_end
  end

  def notes
    request = Net::HTTP::Get.new(
      "#{GOOGLE_SHEETS_HOST.request_uri}/v4/spreadsheets/#{SHEET_ID}/values/#{range}?key=#{API_KEY}"
    )
    response = Net::HTTP.start(
      GOOGLE_SHEETS_HOST.hostname,
      GOOGLE_SHEETS_HOST.port,
      use_ssl: true) { |http| http.request(request) }
    response.body && JSON.parse(response.body)
  end

  private

  def range
    "#{@range_start}:#{@range_end}"
  end
end
