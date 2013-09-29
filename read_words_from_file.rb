# encoding: UTF-8
require 'csv'
require_relative 'word'

class ReadWordsFromFile

  attr_reader :words_from_csv_file

  def initialize(params)
    @path_csv_file_words_input = "#{ params[:path_csv_file] }" +
                                 "#{ params[:file_name] }"
    @words_from_csv_file = []
    @dictionary_hostname = params[:dictionary_hostname]
  end

  def read_from_file
    CSV.foreach(@path_csv_file_words_input, { skip_blanks: true }) do |row_csv_source|
      @row_csv_source = row_csv_source
      add_word_in_list
    end
  end

  private

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

end
