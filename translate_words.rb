require 'watir-webdriver'
require 'csv'
require_relative 'word'

Selenium::WebDriver::Firefox::Binary.path = '/Applications/Firefox.app/Contents/MacOS/firefox'
WORD_LATIN_AMERICA = 'LatAm'
WRITE_ACCESS_FILE_MODE = 'wb'

def read_words_from_file(pathCSV_Source)
  wordsFromCSV_Source = []

  CSV.foreach(pathCSV_Source, { skip_blanks: true }) do |rowCSV_Source|
    add_word_in_list(wordsFromCSV_Source, rowCSV_Source)
  end

  wordsFromCSV_Source
end

def add_word_in_list(wordsFromCSV_Source, rowCSV_Source)
  wordToSearch = transform_line_file_into_word(rowCSV_Source)
  wordsFromCSV_Source.push(wordToSearch) if !wordToSearch.nil?
end

def transform_Line_File_Into_Word(rowCSV)
  if valid_line_file?(rowCSV)
    create_word(rowCSV)
  end
end

def valid_line_file?(rowCSV) 
  !rowCSV[0].nil? && !rowCSV[1].nil? && rowCSV[0].split(',').length >= 1
end

def create_word(rowCSV)
  word = Word.new
  word.wordNotSimplified = rowCSV[0]
  word.sentences = rowCSV[1]
  arrayWordNotSimplified = rowCSV[0].split(',')
  word.wordSimplified = arrayWordNotSimplified[0].strip
  if arrayWordNotSimplified.length > 1
    if word.wordSimplified.match('^(der|die|das) ')
      # Case: Noun. Example: "das Abonnement, -s"
      word.wordSimplified = arrayWordNotSimplified[0].split[1].strip
      word.type = Word::TYPE[:noun]
    elsif word.wordSimplified.match(' sich$')
      # Verb with sich. Example: Example: "amüsieren sich, amüsiert sich, amüsierte sich, hat sich amüsiert"
      word.wordSimplified = word.wordSimplified.sub(' sich$','')
      word.type = Word::TYPE[:verb]
    else  
      # Verb without sich. Example: "abbiegen, biegt ab, bog ab, ist abgebogen"
      word.type = Word::TYPE[:verb]
    end
  elsif arrayWordNotSimplified.length == 1
    # Other word different from noun or verb: ab
    word.type = Word::TYPE[:other]
  end
  word.url = "http://en.pons.eu/dict/search/results/?q=#{word.wordSimplified}&l=dees&in=&lf=de"
  word
end

def save_words_in_file(allWords, 
                       splitPerType = true, 
                       typeWord = 'all', 
                       fileParams = { pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv' })
  if !allWords.empty?
    if typeWord == 'all'
      save_all_words(allWords, splitPerType, fileParams)
    elsif Word::TYPE.has_value?(typeWord)
      save_words_per_type_in_file(allWords, typeWord, fileParams)
    end
  end
end

def save_all_words(allWords, 
                   splitPerType = true, 
                   fileParams = { pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv' })
  if !allWords.empty?
    if splitPerType
      Word::TYPE.each_value { |typeWord| save_words_per_type_in_file(allWords, typeWord) }
    else
      puts "caso splitPerType false"
      write_words(allWords, fileParams)
    end
  end
end

def save_words_per_type_in_file(allWords, 
                                typeWord, 
                                fileParams = { pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv' })
  if !allWords.empty?
    selectedWords = allWords.select { |word| word.type == typeWord }
    write_words(selectedWords, typeWord, fileParams) if !selectedWords.empty?
  end
end

def write_words(words, 
                typeWord = 'all', 
                fileParams = { pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv' }) 
  resultFileName = obtain_result_file_name(words, typeWord, fileParams)
  puts "#{resultFileName}"
  write_words_in_file(words, resultFileName)
end

def obtain_result_file_name(words, 
                            typeWord = 'all', 
                            fileParams = { pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv' })
  firstWord = words[0]
  "#{fileParams[:pathCSVTranslation]}#{fileParams[:fileNameTranslation]}_#{firstWord.wordSimplified}_#{typeWord}#{fileParams[:sufixFile]}"
end

def write_words_in_file(words, resultFileName)
  CSV.open(resultFileName, WRITE_ACCESS_FILE_MODE, { col_sep:  ';' }) do |csvFile|
    words.each do |word|
      csvFile << prepare_CSV_row(word)
    end
  end
end

def prepare_CSV_row(word)
  [word.wordNotSimplified, word.translation.join(','), word.type, word.sentences]
end

def search_all_words(wordsFromCSV_Source, browser)
  wordsFromCSV_Source.each do |word|
    word.search_word_in_dictionary(browser)
    puts "#{word.wordSimplified}"
  end
end

begin
  browser = Watir::Browser.new :firefox
  # Path where is the file with the list of words.
  pathCSV_Source = '/Users/mcberros/workspace/translate_german_words/GermanWords.csv'
    
  wordsFromCSV_Source = read_words_from_file(pathCSV_Source)
  search_all_words(wordsFromCSV_Source, browser)

ensure
  browser.close

  # Para cada palabra vamos a grabar un csv con tres columnas:
  # 1. Palabra original del csv, es decir, no simplificada
  # 2. Traducción de la palabra simplificada al español
  # 3. Tipo de palabra
  # 4. Frases de ejemplo
  # Los tres campos están separados por ;

  #Creamos un fichero por cada tipo
  save_words_in_file(wordsFromCSV_Source, splitPerType = true) if !wordsFromCSV_Source.nil?

  #Creamos un unico fichero con todas las palabras
  #saveWordsInFile(wordsFromCSV_Source, splitPerType = false)
   
end
