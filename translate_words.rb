# encoding: UTF-8

require_relative 'load_config'
require_relative 'write_words_in_file'
require_relative 'read_words_from_file'
require_relative 'search_words_in_dictionary'

begin
  config_reader = LoadConfig.new
  config_reader.read_config
  app_config = config_reader.app_config

  words_reader = ReadWordsFromFile.new(app_config[:input][:read_file])
  words_reader.read_from_file
  words = words_reader.words_from_csv_file

  words_searcher = SearchWordsInDictionary.new(app_config[:input][:search_in_dictionary])
  words_searcher.translate_all_words(words)

  writer_words = WriteWordsInFile.new(words, app_config[:output])

  writer_words.save_all_words_in_different_files
  writer_words.save_all_words_in_one_file

end
