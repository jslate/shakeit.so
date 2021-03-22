class Song
  attr_reader  :title, :artist, :duration, :progress, :image
  def initialize(title:,artist:,duration:,progress:,image:)
    @title = title
    @artist = artist
    @duration = duration
    @progress = progress
    @image = image
  end

  def time_remaining
    @duration - @progress
  end

  def progress_percentage
    (@progress / @duration.to_f * 100).floor
  end
end
