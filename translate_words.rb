require 'watir-webdriver'
require 'csv'
require_relative 'word'

Selenium::WebDriver::Firefox::Binary.path ='/Applications/Firefox.app/Contents/MacOS/firefox'
WORD_LATIN_AMERICA = 'LatAm'
WRITE_ACCESS_FILE_MODE = 'wb'

def readWordsFromFile(pathCSV_Source)
  wordsFromCSV_Source = []
  CSV.foreach(pathCSV_Source, {skip_blanks: true}) do |rowCSV_Source|
    addWordInList(wordsFromCSV_Source, rowCSV_Source)
  end
  wordsFromCSV_Source
end

def addWordInList(wordsFromCSV_Source, rowCSV_Source)
  wordToSearch = transformLineFileIntoWord(rowCSV_Source)
  wordsFromCSV_Source.push(wordToSearch) if not wordToSearch.nil?
end

def transformLineFileIntoWord(rowCSV)
  if validLineFile?(rowCSV)
    createWord(rowCSV)
  end
end

def validLineFile?(rowCSV) 
  not rowCSV[0].nil? and not rowCSV[1].nil? and rowCSV[0].split(',').length >= 1
end

def createWord(rowCSV)
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

def saveWordsInFile(allWords, splitPerType = true, typeWord = 'all', fileParams = {pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv'})
  if not allWords.empty?
    if typeWord == 'all'
      saveAllWords(allWords, splitPerType, fileParams)
    elsif Word::TYPE.has_value?(typeWord)
      saveWordsPerTypeInFile(allWords, typeWord, fileParams)
    end
  end
end

def saveAllWords(allWords, splitPerType = true, fileParams = {pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv'})
  if not allWords.empty?
    if splitPerType
      Word::TYPE.each_value { |typeWord| saveWordsPerTypeInFile(allWords, typeWord) }
    else
      puts "caso splitPerType false"
      writeWords(allWords, fileParams)
    end
  end
end

def saveWordsPerTypeInFile(allWords, typeWord, fileParams = {pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv'})
  if not allWords.empty?
    selectedWords = allWords.select { |word| word.type == typeWord}
    writeWords(selectedWords, typeWord, fileParams) if not selectedWords.empty?
  end
end

def writeWords(words, typeWord = 'all', fileParams = {pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv'}) 
  resultFileName = obtainResultFileName(words, typeWord, fileParams)
  puts "#{resultFileName}"
  writeWordsInFile(words, resultFileName)
end

def obtainResultFileName(words, typeWord = 'all', fileParams = {pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv'})
  firstWord = words[0]
  "#{fileParams[:pathCSVTranslation]}#{fileParams[:fileNameTranslation]}_#{firstWord.wordSimplified}_#{typeWord}#{fileParams[:sufixFile]}"
end

def writeWordsInFile(words, resultFileName)
  CSV.open(resultFileName, WRITE_ACCESS_FILE_MODE, {col_sep:  ';'}) do |csvFile|
    words.each do |word|
      csvFile << prepCSVRow(word)
    end
  end
end

def prepCSVRow(word)
  [word.wordNotSimplified, word.translation.join(','), word.type, word.sentences]
end

def searchAllWords(wordsFromCSV_Source, browser)
  wordsFromCSV_Source.each do |word|
  word.searchWordInDictionary(browser)
  puts "#{word.wordSimplified}"
  end
end

begin
  browser = Watir::Browser.new :firefox
  # Path where is the file with the list of words.
  pathCSV_Source = '/Users/mcberros/workspace/translate_german_words/GermanWords.csv'
    
  wordsFromCSV_Source = readWordsFromFile(pathCSV_Source)
  searchAllWords(wordsFromCSV_Source, browser)

ensure
  browser.close

  # Para cada palabra vamos a grabar un csv con tres columnas:
  # 1. Palabra original del csv, es decir, no simplificada
  # 2. Traducción de la palabra simplificada al español
  # 3. Tipo de palabra
  # 4. Frases de ejemplo
  # Los tres campos están separados por ;

  #Creamos un fichero por cada tipo
  saveWordsInFile(wordsFromCSV_Source, splitPerType = true) if not wordsFromCSV_Source.nil?

  #Creamos un unico fichero con todas las palabras
  #saveWordsInFile(wordsFromCSV_Source, splitPerType = false)
   
end
