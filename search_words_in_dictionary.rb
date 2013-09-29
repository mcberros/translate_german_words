# encoding: UTF-8
require_relative 'word'

class SearchWordsInDictionary

  WORD_LATIN_AMERICA = 'LatAm'

  def initialize(params)
    @dictionary_hostname = params[:dictionary_hostname]
    Selenium::WebDriver::Firefox::Binary.path = params [:selenium_webdriver_path]
    @name_browser = params [:browser]
  end

  def translate_all_words(words)
    return if words.nil?
    words.each do |word|
      @word = word
      search_word_in_dictionary
    end
  end

  private

  def search_word_in_dictionary
    @browser = Watir::Browser.new @name_browser
    @browser.goto @word.url
    explore_page_for_word
  ensure
    @browser.close
  end

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
    @word.type = @browser.h2.element(tag_name: 'acronym').text
  end

  def change_word_type?
    @browser.h2s.size == 1 &&
    @word.type == Word::TYPE[:other] &&
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
    maybe_a_headword.text.strip == @word.word_simplified
  end

  def push_new_translation_for_word(maybe_a_target)
    return unless is_a_translation?(maybe_a_target)
    @word.translation = @word.translation.push(maybe_a_target.text)
  end

  def is_a_translation?(maybe_a_target)
    maybe_a_target.exists? &&
    !@word.translation.include?(maybe_a_target.text) &&
    !maybe_a_target.text.include?(WORD_LATIN_AMERICA)
  end

end
