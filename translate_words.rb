# encoding: UTF-8

require 'watir-webdriver'
require 'csv'
require_relative 'word'

Selenium::WebDriver::Firefox::Binary.path = '/Applications/Firefox.app/Contents/MacOS/firefox'
WORD_LATIN_AMERICA = 'LatAm'
WRITE_ACCESS_FILE_MODE = 'wb'

def read_words_from_file(path_csv_source)
  words_from_csv_source = []

  CSV.foreach(path_csv_source, { skip_blanks: true }) do |row_csv_source|
    add_word_in_list(words_from_csv_source, row_csv_source)
  end

  words_from_csv_source
end

def add_word_in_list(words_from_csv_source, row_csv_source)
  word_to_search = transform_line_file_into_word(row_csv_source)
  return if word_to_search.nil?
  words_from_csv_source.push(word_to_search)
end

def transform_line_file_into_word(row_csv)
  return unless valid_line_file?(row_csv)
  create_word(row_csv)
end

def valid_line_file?(row_csv)
  !row_csv.first.nil? && !row_csv.at(1).nil? && row_csv.first.split(',').length >= 1
end

def create_word(row_csv) # HACK
  word = Word.new
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

  word.url = "http://en.pons.eu/dict/search/results/?q=#{word.word_simplified}&l=dees&in=&lf=de"
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

def save_words_in_file(all_words,
                       split_per_type = true,
                       type_word = 'all',
                       file_params = { path_csv_translation: '/Users/mcberros/workspace/translate_german_words/', file_name_translation: 'GermanWordsTranslation', sufix_file: '.csv' })
  return if all_words.empty?
  if type_word == 'all'
    save_all_words(all_words, split_per_type, file_params)
  elsif Word::TYPE.value?(type_word)
    save_words_per_type_in_file(all_words, type_word, file_params)
  end
end

def save_all_words(all_words,
                   split_per_type = true,
                   file_params = { path_csv_translation: '/Users/mcberros/workspace/translate_german_words/', file_name_translation: 'GermanWordsTranslation', sufix_file: '.csv' })
  return if all_words.empty?
  if split_per_type
    Word::TYPE.each_value do |type_word|
      save_words_per_type_in_file(all_words, type_word)
    end
  else
    write_words(all_words, file_params)
  end
end

def save_words_per_type_in_file(all_words,
                                type_word,
                                file_params = { path_csv_translation: '/Users/mcberros/workspace/translate_german_words/', file_name_translation: 'GermanWordsTranslation', sufix_file: '.csv' })
  return if all_words.empty?
  selected_words = all_words.select { |word| word.type == type_word }
  return if selected_words.empty?
  write_words(selected_words, type_word, file_params)
end

def write_words(words,
                type_word = 'all',
                file_params = { path_csv_translation: '/Users/mcberros/workspace/translate_german_words/', file_name_translation: 'GermanWordsTranslation', sufix_file: '.csv' })
  result_file_name = obtain_result_file_name(words, type_word, file_params)
  write_words_in_file(words, result_file_name)
end

def obtain_result_file_name(words,
                            type_word = 'all',
                            file_params = { path_csv_translation: '/Users/mcberros/workspace/translate_german_words/', file_name_translation: 'GermanWordsTranslation', sufix_file: '.csv' })
  "#{ file_params[:path_csv_translation] }#{ file_params[:file_name_translation] }_#{ words.first.word_simplified }_#{ type_word }#{ file_params[:sufix_file] }"
end

def write_words_in_file(words, result_file_name)
  CSV.open(result_file_name, WRITE_ACCESS_FILE_MODE, { col_sep: ';' }) do |csv_file|
    words.each { |word| csv_file << prepare_csv_row(word) }
  end
  # CSV.close # Review
end

def prepare_csv_row(word)
  [word.word_not_simplified, word.translation.join(','), word.type, word.sentences]
end

def search_all_words(words_from_csv_source, browser)
  words_from_csv_source.each do |word|
    word.search_word_in_dictionary(browser)
    puts "#{ word.to_s }"
  end
end

begin
  browser = Watir::Browser.new :firefox
  path_csv_file_words_input = '/Users/mcberros/workspace/translate_german_words/GermanWords.csv'

  words_from_csv_source = read_words_from_file(path_csv_file_words_input)
  search_all_words(words_from_csv_source, browser)

ensure
  browser.close

  # Para cada palabra vamos a grabar un csv con tres columnas:
  #   1. Palabra original del csv, es decir, no simplificada.
  #   2. Traducción de la palabra simplificada al español.
  #   3. Tipo de palabra.
  #   4. Frases de ejemplo.
  #   Los tres campos están separados por ';'.

  # Creamos un fichero por cada tipo.
  # HACK
  save_words_in_file(words_from_csv_source, split_per_type = true) unless words_from_csv_source.nil?

  # Creamos un unico fichero con todas las palabras.
  # HACK
  # saveWordsInFile(wordsFromCSV_Source, split_per_type = false)
   
end
