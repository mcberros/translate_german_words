# encoding: UTF-8

require_relative 'load_config'
require_relative 'write_words_in_file'
require_relative 'read_words_from_file_and_search'

begin
  config_reader = LoadConfig.new
  config_reader.read_config
  app_config = config_reader.app_config
  
  words_reader = ReadWordsFromFileAndSearch.new(app_config[:input])
  words_reader.read_and_search
  words = words_reader.words_from_csv_file

  # Para cada palabra vamos a grabar un csv con tres columnas:
  #   1. Palabra original del csv, es decir, no simplificada.
  #   2. Traducción de la palabra simplificada al español.
  #   3. Tipo de palabra.
  #   4. Frases de ejemplo.
  #   Los tres campos están separados por ';'.

  writer_words = WriteWordsInFile.new(words, app_config[:output])

  writer_words.save_all_words_in_different_files
  writer_words.save_all_words_in_one_file

end
