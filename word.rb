# encoding: UTF-8
require 'watir-webdriver'

class Word

  TYPE = { noun: 'NOUN',
           verb: 'VERB',
           adverb: 'ADV',
           adjective: 'ADJ',
           conjuntion: 'CONJ',
           preposition: 'PREP',
           other: 'OTHER' }

  attr_accessor :word_not_simplified,
                :word_simplified,
                :url, :sentences, :translation, :type

  def initialize
    @translation = []
  end

  def decide_type
    if a_noun_or_a_verb?
      treat_noun_or_verb
    elsif not_a_noun_or_not_a_verb?
      other_word
    end
  end

  def treat_noun_or_verb
    if noun?
      treat_noun
    elsif reflexiv_verb?
      treat_reflexiv_verb
    elsif !reflexiv_verb?
      treat_not_reflexiv_verb
    end
  end

  def noun?
    @word_simplified.match('^(der|die|das) ')
  end

  def treat_noun
    @word_simplified = to_a.first.split.at(1).strip
    @type = Word::TYPE.fetch(:noun)
  end

  def reflexiv_verb?
    @word_simplified.match(' sich$')
  end

  def treat_reflexiv_verb
    @word_simplified = @word_simplified.sub(' sich$', '')
    @type = Word::TYPE.fetch(:verb)
  end

  def treat_not_reflexiv_verb
    @type = Word::TYPE.fetch(:verb)
  end

  def other_word
    @type = Word::TYPE.fetch(:other)
  end

  def not_a_noun_or_not_a_verb?
    to_a.size == 1
  end

  def a_noun_or_a_verb?
    to_a.size > 1
  end

  def to_a
    @word_not_simplified.split(',')
  end

  def simplify
    @word_simplified = to_a.first.strip
  end

  def build_url(dictionary_hostname)
    @url = "#{ dictionary_hostname }?q=#{ @word_simplified }&l=dees&in=&lf=de"
  end

  def to_s
    "#{ @word_simplified }"
  end

end
