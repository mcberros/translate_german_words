# encoding: UTF-8
require_relative 'word'

class ReadWordsFromFileAndSearch 

  WORD_LATIN_AMERICA = 'LatAm'
  WRITE_ACCESS_FILE_MODE = 'wb'

  attr_accessor :words_from_csv_file, :browser,
                :dictionary_hostname
                :path_csv_file_words_input

  def initialize(params)
    Selenium::WebDriver::Firefox::Binary.path = params[:selenium_webdriver_path]
    @browser = Watir::Browser.new params[:browser]
    
    @path_csv_file_words_input = "#{ params[:path_csv_file] }" +
                                 "#{ params[:file_name] }"
    @words_from_csv_file = []
    @dictionary_hostname = params[:dictionary_hostname]
  end

  def read_and_search
    read_words_from_file
    search_all_words
  end

  def read_words_from_file
    CSV.foreach(@path_csv_file_words_input, { skip_blanks: true }) do |row_csv_source|
      add_word_in_list(row_csv_source)
    end
  end

  def add_word_in_list(row_csv_source)
    word_to_search = transform_line_file_into_word(row_csv_source)
    return if word_to_search.nil?
    @words_from_csv_file.push(word_to_search)
  end

  def transform_line_file_into_word(row_csv)
    return unless valid_line_file?(row_csv)
    create_word(row_csv)
  end

  def valid_line_file?(row_csv)
    !row_csv.first.nil? &&
    !row_csv.at(1).nil? &&
    row_csv.first.split(',').length >= 1
  end

  def create_word(row_csv) # HACK
    word = Word.new(@browser)
    word.word_not_simplified = row_csv.first
    word.sentences = row_csv.at(1)
    array_word_not_simplified = row_csv.first.split(',')
    word.word_simplified = array_word_not_simplified.first.strip

    if is_word_a_noun_or_a_verb?(array_word_not_simplified)
      if is_word_a_noun?(word)
        word.word_simplified = array_word_not_simplified.first.split.at(1).strip
        word.type = Word::TYPE.fetch(:noun)
      elsif is_word_a_reflexive_verb?(word)
        word.word_simplified = word.word_simplified.sub(' sich$', '')
        word.type = Word::TYPE.fetch(:verb)
      else # HACK
        # Verb without sich. Example: "abbiegen, biegt ab, bog ab, ist abgebogen"
        word.type = Word::TYPE.fetch(:verb)
      end
    elsif is_word_not_a_noun_or_not_a_verb?(array_word_not_simplified)
      word.type = Word::TYPE.fetch(:other)
    end

    word.url = "#{@dictionary_hostname}?q=#{word.word_simplified}&l=dees&in=&lf=de"
    word
  end

  def is_word_not_a_noun_or_not_a_verb?(array_word_not_simplified)
    array_word_not_simplified.size == 1
  end

  def is_word_a_noun_or_a_verb?(array_word_not_simplified)
    array_word_not_simplified.length > 1
  end

  def is_word_a_noun?(word)
    word.word_simplified.match('^(der|die|das) ')
  end

  def is_word_a_reflexive_verb?(word)
    word.word_simplified.match(' sich$')
  end

  def search_all_words
    @words_from_csv_source.each do |word|
      word.search_word_in_dictionary
      puts "#{ word.to_s }"
    end
  end

end
