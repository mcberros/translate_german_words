# encoding: UTF-8
require 'csv'
require_relative 'word'

class ReadWordsFromFileAndSearch

  WORD_LATIN_AMERICA = 'LatAm'

  attr_reader :words_from_csv_file

  def initialize(params)
    @path_csv_file_words_input = "#{ params[:path_csv_file] }" +
                                 "#{ params[:file_name] }"
    @words_from_csv_file = []
    @dictionary_hostname = params[:dictionary_hostname]
    Selenium::WebDriver::Firefox::Binary.path = params [:selenium_webdriver_path]
    @name_browser = params [:browser]
  end

  def read_and_search
    read_words_from_file
    search_all_words
  end

  private

  def read_words_from_file
    CSV.foreach(@path_csv_file_words_input, { skip_blanks: true }) do |row_csv_source|
      @row_csv_source = row_csv_source
      add_word_in_list
    end
  end

  def add_word_in_list
    word_to_search = transform_line_file_into_word
    return if word_to_search.nil?
    @words_from_csv_file.push(word_to_search)
  end

  def transform_line_file_into_word
    return unless valid_line_file?
    create_word_from_file
  end

  def valid_line_file?
    !@row_csv_source.first.nil? &&
    !@row_csv_source.at(1).nil? &&
    @row_csv_source.first.split(',').length >= 1
  end

  def create_word_from_file
    @word = Word.new
    decompose_row_cvs
    @word.simplify
    @word.decide_type
    @word.build_url(@dictionary_hostname)
    @word
  end

  def decompose_row_cvs
    @word.word_not_simplified = @row_csv_source.first
    @word.sentences = @row_csv_source.at(1)
  end

  def search_all_words
    return if @words_from_csv_file.nil?
    @words_from_csv_file.each do |w|
      search_word_in_dictionary(w)
    end
  end

  def search_word_in_dictionary(w)
    @browser = Watir::Browser.new @name_browser
    @browser.goto w.url
    explore_page_for_word(w)
  ensure
    @browser.close
  end

  def explore_page_for_word(w)
    translation_table = @browser.trs(class: 'kne')
    obtain_translation_list_for_word(translation_table, w)
    explore_type_of_word(w)
  end

  def obtain_translation_list_for_word(translation_table, w)
    translation_table.each do |table_row|
      explore_table_row_for_translation(table_row, w)
    end
  end

  def explore_type_of_word(w)
    return unless change_word_type?(w)
    w.type = @browser.h2.element(tag_name: 'acronym').text
  end

  def change_word_type?(w)
    @browser.h2s.size == 1 &&
    w.type == Word::TYPE[:other] &&
    Word::TYPE.value?(@browser.h2.element(tag_name: 'acronym').text)
  end

  def explore_table_row_for_translation(table_row, w)
    maybe_a_headword = table_row.td(class: 'source').strong(class: 'headword')
    return unless maybe_a_target?(maybe_a_headword, w)
    maybe_a_target = table_row.td(class: 'target')
    push_new_translation_for_word(maybe_a_target, w)
  end

  def maybe_a_target?(maybe_a_headword, w)
    maybe_a_headword.exists? &&
    maybe_a_headword.text.strip == w.word_simplified
  end

  def push_new_translation_for_word(maybe_a_target, w)
    return unless is_a_translation?(maybe_a_target, w)
    w.translation = w.translation.push(maybe_a_target.text)
  end

  def is_a_translation?(maybe_a_target, w)
    maybe_a_target.exists? &&
    !w.translation.include?(maybe_a_target.text) &&
    !maybe_a_target.text.include?(WORD_LATIN_AMERICA)
  end

end
