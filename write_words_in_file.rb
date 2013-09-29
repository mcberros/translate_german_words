# encoding: UTF-8
require 'csv'

class WriteWordsInFile

  WRITE_ACCESS_FILE_MODE = 'wb'

  def initialize(words, file_output)
    @words = words
    @file_output = file_output
  end

  def save_all_words_in_one_file
    return if @words.empty?
    result_file_name = obtain_result_file_name

    write_words_in_file(result_file_name)
  end

  def save_all_words_in_different_files
    return if @words.empty?
    Word::TYPE.each_value do |type_word|
      save_words_of_a_type_in_file(type_word)
    end
  end

  private

  def save_words_of_a_type_in_file(type_word)

    return if @words.empty?

    selected_words = select_words_of_a_type(type_word)
    return if selected_words.empty?

    result_file_name = obtain_result_file_name(selected_words, type_word)

    write_words_in_file(result_file_name, selected_words)
  end

  def select_words_of_a_type(type_word)
    selected_words = @words.select do |word|
      word.type == type_word
    end
  end

  def obtain_result_file_name(words = @words,
                              type_word = 'all')
    return if words.empty?
    first_word = words.first.word_simplified
    "#{ @file_output[:path_csv_file] }#{ @file_output[:file_name] }_" +
    "#{ first_word }_#{ type_word }_words#{ @file_output[:sufix_file] }"
  end

  def prepare_csv_row(word)
    [word.word_not_simplified,
     word.translation.join(','),
     word.type, word.sentences]
  end

  def write_words_in_file(result_file_name, words = @words)
    CSV.open(result_file_name, WRITE_ACCESS_FILE_MODE, { col_sep: ';' }) do |csv_file|
      words.each { |word| csv_file << prepare_csv_row(word) }
    end
  end
end
