require 'watir-webdriver'
require 'csv'
require_relative 'word'

Selenium::WebDriver::Firefox::Binary.path='/Applications/Firefox.app/Contents/MacOS/firefox'

def obtainWordToSearch(rowCSV)
  if not rowCSV[0].nil? and not rowCSV[1].nil?
    arrayFirstColumn = rowCSV[0].split(',')
    if arrayFirstColumn.length >= 1
      term=Word.new()
      term.wordNotSimplified=rowCSV[0]
      term.sentences=rowCSV[1]
      # Case:
      word=arrayFirstColumn[0].strip
      
      if arrayFirstColumn.length > 1
        # Verb without sich. Example: "abbiegen, biegt ab, bog ab, ist abgebogen"
        term.type=Word::TYPE[:verb]
      elsif arrayFirstColumn.length == 1
        # Other word different from noun or verb: ab
        term.type=Word::TYPE[:other]
      end

      # Case: Noun. Example: "das Abonnement, -s"
      if word.match('^(der|die|das) ')
        word=arrayFirstColumn[0].split[1].strip
        term.type=Word::TYPE[:noun]
      end
      
      # Verb with sich. Example: Example: "amüsieren sich, amüsiert sich, amüsierte sich, hat sich amüsiert"
      if word.match(' sich$')
        word=word.sub(' sich$','')
        term.type=Word::TYPE[:verb]
      end 
    end
    term.wordSimplified=word
    term.url="http://en.pons.eu/dict/search/results/?q=#{word}&l=dees&in=&lf=de"
  end
  return term
end

def searchWordInDictionary(word, browser)
  browser.goto word.url
  browser.trs(class: 'kne').each do |tablerow|
    maybeAHeadword = tablerow.td(class: 'source').strong(class: 'headword')
    if maybeAHeadword.exists? and maybeAHeadword.text.strip == word.wordSimplified
      maybeATarget = tablerow.td(class: 'target')
      word.translation = word.translation.push(maybeATarget.text) if maybeATarget.exists? and not word.translation.include?(maybeATarget.text) and not maybeATarget.text.include?('LatAm')
    end
  end
  word.type = browser.h2.element(tag_name: 'acronym').text if browser.h2s.length == 1 and word.type == Word::TYPE[:other] and Word::TYPE.has_value?(browser.h2.element(tag_name: 'acronym').text) 
end

def prepCSVRow( term )
  return [term.wordNotSimplified, term.translation.join(','), term.type, term.sentences]
end

def obtainResultFileName(firstTerm, typeWord = 'all', fileParams = {pathCSVTranslation: '/Users/mcberros/workspace/translate_german_words/', fileNameTranslation: 'GermanWordsTranslation', sufixFile: '.csv'})
  fileName = "#{fileParams[:pathCSVTranslation]}#{fileParams[:fileNameTranslation]}_#{firstWord.wordSimplified}_#{typeWord}#{fileParams[:sufixFile]}"
end

def saveWordsInFile(allWords, splitPerType = true, typeWord = 'all', fileParams = {})
  if not allWords.empty?
    if Word::TYPE.has_value?(typeWord)
      selectedWords = allWords.select { |word| word.type == typeWord}
      writeWords(selectedWords, typeWord)
    else if typeWord == 'all'
      if splitPerType

      ###########Mal
        Word::TYPE.each_value { |type| saveWordsInFile(allWords, typeWord = type)}
      else
        selectedWords = allWords
        writeWords(selectedWords)
      end
    end
  end
end

def writeWords(words, typeWord='all', fileParams = {})
  firstWord = words[0]
  resultFileName = obtainResultFileName(firstWord, typeWord)
  CSV.open(nameFile, "wb", {:col_sep => ";"}) do |csv|
    words.each do |term|
      csv << prepCSVRow(term)  
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
    wordToSearch = obtainWordToSearch(rowCSV_Source)
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
  saveWordsInFile(wordsFromCSV_Source, splitPerType: true)

  #Creamos un unico fichero con todas las palabras
  saveWordsInFile(wordsFromCSV_Source, splitPerType: false)
   
end




