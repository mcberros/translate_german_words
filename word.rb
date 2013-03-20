class Word
  attr_accessor :wordNotSimplified, :wordSimplified, :url, :sentences, :translation
  def initialize()
    @translation = []
  end
end