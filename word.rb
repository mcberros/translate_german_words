# encoding: UTF-8
require 'watir-webdriver'

class Word

  WORD_LATIN_AMERICA = 'LatAm'

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

  def initialize(selenium_webdriver_path, browser)
    @translation = []
    @selenium_webdriver_path = selenium_webdriver_path
    @name_browser = browser
  end

  def search_word_in_dictionary
    Selenium::WebDriver::Firefox::Binary.path = @selenium_webdriver_path
    @browser = Watir::Browser.new @name_browser
    @browser.goto @url
    explore_page_for_word
  ensure
    @browser.close
  end

  def decide_type
    if not_a_noun_or_not_a_verb?
      if noun?
        @word_simplified = to_a.first.split.at(1).strip
        @type = Word::TYPE.fetch(:noun)
      elsif reflexive_verb?
        @word_simplified = @word_simplified.sub(' sich$', '')
        @type = Word::TYPE.fetch(:verb)
      else # HACK
        # Verb without sich. Example: "abbiegen, biegt ab, bog ab, ist abgebogen"
        @type = Word::TYPE.fetch(:verb)
      end
    elsif a_noun_or_a_verb?
      @type = Word::TYPE.fetch(:other)
    end
  end

  def noun?
    @word_simplified.match('^(der|die|das) ')
  end

  def reflexive_verb?
    @word_simplified.match(' sich$')
  end

  def not_a_noun_or_not_a_verb?
    array_word_not_simplified = to_a
    array_word_not_simplified.size == 1
  end

  def a_noun_or_a_verb?
    array_word_not_simplified = to_a
    array_word_not_simplified.length > 1
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

  private

  def explore_page_for_word
    translation_table = @browser.trs(class: 'kne')
    obtain_translation_list_for_word(translation_table)
    explore_type_of_word
  end

  def obtain_translation_list_for_word(translation_table)
    translation_table.each do |table_row|
      explore_table_row_for_translation(table_row)
    end
  end

  def explore_type_of_word
    return unless change_word_type?
    @type = @browser.h2.element(tag_name: 'acronym').text
  end

  def change_word_type?
    @browser.h2s.size == 1 &&
    @type == Word::TYPE[:other] &&
    Word::TYPE.value?(@browser.h2.element(tag_name: 'acronym').text)
  end

  def explore_table_row_for_translation(table_row)
    maybe_a_headword = table_row.td(class: 'source').strong(class: 'headword')
    return unless maybe_a_target?(maybe_a_headword)
    maybe_a_target = table_row.td(class: 'target')
    push_new_translation_for_word(maybe_a_target)
  end

  def maybe_a_target?(maybe_a_headword)
    maybe_a_headword.exists? &&
    maybe_a_headword.text.strip == @word_simplified
  end

  def push_new_translation_for_word(maybe_a_target)
    return unless is_a_translation?(maybe_a_target)
    @translation = @translation.push(maybe_a_target.text)
  end

  def is_a_translation?(maybe_a_target)
    maybe_a_target.exists? &&
    !@translation.include?(maybe_a_target.text) &&
    !maybe_a_target.text.include?(WORD_LATIN_AMERICA)
  end

end
