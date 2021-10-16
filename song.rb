# frozen_string_literal: true

class Song
  attr_reader :title, :artist, :duration, :progress, :image, :uri

  def initialize(title:, artist:, duration:, progress:, image:, uri:)
    @title = title
    @artist = artist
    @duration = duration
    @progress = progress
    @image = image
    @uri = uri
  end

  def time_remaining
    @duration - @progress
  end

  def progress_percentage
    (@progress / @duration.to_f * 100).floor
  end
end
