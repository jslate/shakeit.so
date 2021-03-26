require "active_support/all"

class Note
  attr_reader :text, :enabled

  def initialize(row)
    @text, enabled_str, @song_matcher = row
    @enabled = text.present? && enabled_str.upcase == "TRUE"
  end

  def show_for_song?(song)
    @song_matcher.blank? || song.title.downcase.include?(@song_matcher.downcase)
  end

  def enabled?
    enabled
  end
end
