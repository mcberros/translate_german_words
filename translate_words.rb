require 'watir-webdriver'
require 'csv'
require_relative 'word'

Selenium::WebDriver::Firefox::Binary.path ='/Applications/Firefox.app/Contents/MacOS/firefox'
WORD_LATIN_AMERICA = 'LatAm'
WRITE_ACCESS_FILE_MODE = 'wb'

def transformLineFileIntoWord(rowCSV)
  wordNotSimplified = rowCSV[0] if not rowCSV[0].nil?
  wordExamples = rowCSV[1] if not rowCSV[1].nil?

  if wordNotSimplified and wordExamples
    arrayWordNotSimplified = wordNotSimplified.split(',')

    if arrayWordNotSimplified.length >= 1
      word = Word.new
      word.wordNotSimplified = wordNotSimplified
      word.sentences = wordExamples
      cleanWord = arrayWordNotSimplified[0].strip
      
      if arrayWordNotSimplified.length > 1
        if cleanWord.match('^(der|die|das) ')
          # Case: Noun. Example: "das Abonnement, -s"
          cleanWord = arrayWordNotSimplified[0].split[1].strip
          word.type = Word::TYPE[:noun]
        elsif cleanWord.match(' sich$')
          # Verb with sich. Example: Example: "amüsieren sich, amüsiert sich, amüsierte sich, hat sich amüsiert"
          cleanWord = cleanWord.sub(' sich$','')
          word.type = Word::TYPE[:verb]
        else  
          # Verb without sich. Example: "abbiegen, biegt ab, bog ab, ist abgebogen"
          word.type = Word::TYPE[:verb]
        end
      elsif arrayWordNotSimplified.length == 1
        # Other word different from noun or verb: ab
        word.type = Word::TYPE[:other]
      end
    end

    word.wordSimplified = cleanWord 
    word.url = "http://en.pons.eu/dict/search/results/?q=#{cleanWord}&l=dees&in=&lf=de"
  end

  word 
end

def searchWordInDictionary(word, browser)
  browser.goto word.url
  browser.trs(class: 'kne').each do |tablerow|
    maybeAHeadword = tablerow.td(class: 'source').strong(class: 'headword')
    if maybeAHeadword.exists? and maybeAHeadword.text.strip == word.wordSimplified
      maybeATarget = tablerow.td(class: 'target')
      word.translation = word.translation.push(maybeATarget.text) if maybeATarget.exists? and not word.translation.include?(maybeATarget.text) and not maybeATarget.text.include?(WORD_LATIN_AMERICA)
    end
  end
  word.type = browser.h2.element(tag_name: 'acronym').text if browser.h2s.length == 1 and word.type == Word::TYPE[:other] and Word::TYPE.has_value?(browser.h2.element(tag_name: 'acronym').text) 
end

def prepCSVRow(word)
  [word.wordNotSimplified, word.translation.join(','), word.type, word.sentences]
end

def obtainResultFileName(firstWord, typeWord = 'all', fileParams = {pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv'})
  fileName = "#{fileParams[:pathCSVTranslation]}#{fileParams[:fileNameTranslation]}_#{firstWord.wordSimplified}_#{typeWord}#{fileParams[:sufixFile]}"
end

def saveWordsInFile(allWords, splitPerType = true, typeWord = 'all', fileParams = {})
  if not allWords.empty?
    if typeWord == 'all'
      if splitPerType
        Word::TYPE.each_value { |typeWord| saveWordsPerTypeInFile(allWords, typeWord) }
      else
        writeWords(allWords)
      end
    elsif Word::TYPE.has_value?(typeWord)
      saveWordsPerTypeInFile(allWords, typeWord)
    end
  end
end

def saveWordsPerTypeInFile(allWords, typeWord)
  if not allWords.empty?
    selectedWords = allWords.select { |word| word.type == typeWord}
    writeWords(selectedWords, typeWord) if not selectedWords.empty?
  end
end

def writeWords(words, typeWord='all', fileParams = {})
    firstWord = words[0]
    resultFileName = obtainResultFileName(firstWord, typeWord)
    CSV.open(resultFileName, WRITE_ACCESS_FILE_MODE, {col_sep:  ';'}) do |csvFile|
      words.each do |word|
        csvFile << prepCSVRow(word)  
      end
    end
end

begin
  browser = Watir::Browser.new :firefox
  # Path where is the file with the list of words.
  pathCSV_Source = '/Users/mcberros/workspace/translate_german_words/GermanWords.csv'
  wordsFromCSV_Source = []
  
  # We obtain from csv file the information, that we will use to search in 
  # the dictionary
  CSV.foreach(pathCSV_Source, {skip_blanks: true}) do |rowCSV_Source|
    wordToSearch = transformLineFileIntoWord(rowCSV_Source)
    wordsFromCSV_Source.push(wordToSearch) if not wordToSearch.nil?
  end
  
  # Para cada palabra simplificada buscamos en el diccionario
  wordsFromCSV_Source.each do |word|
    searchWordInDictionary(word, browser)
    puts "#{word.wordSimplified}"
  end

ensure
  browser.close

  # Para cada palabra vamos a grabar un csv con tres columnas:
  # 1. Palabra original del csv, es decir, no simplificada
  # 2. Traducción de la palabra simplificada al español
  # 3. Tipo de palabra
  # 4. Frases de ejemplo
  # Los tres campos están separados por ;

  #Creamos un fichero por cada tipo
  saveWordsInFile(wordsFromCSV_Source, splitPerType = true)

  #Creamos un unico fichero con todas las palabras
  saveWordsInFile(wordsFromCSV_Source, splitPerType = false)
   
end
