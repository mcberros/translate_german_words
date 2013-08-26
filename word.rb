class Word
  
  TYPE = {noun: 'NOUN', 
          verb: 'VERB',
          adverb: 'ADV',
          adjective: 'ADJ',
          conjuntion: 'CONJ',
          preposition: 'PREP',
          other: 'OTHER'}

  attr_accessor :wordNotSimplified, :wordSimplified, :url, :sentences, :translation, :type
  
  def initialize()
    @translation = []
  end
end
