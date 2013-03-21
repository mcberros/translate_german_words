require 'watir-webdriver'
require 'csv'
require_relative 'word'

Selenium::WebDriver::Firefox::Binary.path='/Applications/Herramientas/Firefox.app/Contents/MacOS/firefox'

def fillTerm( rowCSV )
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

def searchWord( term, browser )
  browser.goto term.url
  browser.trs(:class => 'kne').each do |tr|
    maybeAHeadword=tr.td(:class => 'source').strong(:class => 'headword')
    if maybeAHeadword.exists? and maybeAHeadword.text.strip == term.wordSimplified
      maybeATarget = tr.td(:class => 'target')
      term.translation=term.translation.push(maybeATarget.text) if maybeATarget.exists? and not term.translation.include?(maybeATarget.text) and not maybeATarget.text.include?('LatAm')
    end
  end
  term.type = browser.h2.acronym.text if browser.h2s.length == 1 and term.type == Word::TYPE[:other] and Word::TYPE.has_value?(browser.h2.acronym.text) 
end

def saveWords ( words,
                division=false,
                typeTerm='',
                fileParams={
                  :pathCSVTranslation => '/Users/mcberros/ruby/translate_german_words/third_version/',
                  :fileNameTranslation => 'GermanWordsTranslation_test',
                  :sufixFile => '.csv'})
  
  if division
    #Obtener un fichero para cada tipo
    Word::TYPE.each_value { |type| saveWordsbyType(words, type)}
  else
    if typeTerm.empty?
      # obtener un fichero con todas las palabras
      saveAllWords(words)
    else
      # obtener el fichero de un solo un tipo
      saveWordsbyType(words, typeTerm)
    end
  end
end

def prepCSVRow( term )
  return [term.wordNotSimplified, term.translation.join(','), term.type, term.sentences]
end

def saveAllWords( words,
                  fileParams={
                    :pathCSVTranslation => '/Users/mcberros/ruby/translate_german_words/third_version/',
                    :fileNameTranslation => 'GermanWordsTranslation_test',
                    :sufixFile => '.csv'})
  if not words.empty?
    firstTerm=words[0]
    nameFile="#{fileParams[:pathCSVTranslation]}#{fileParams[:fileNameTranslation]}_#{firstTerm.wordSimplified}_all#{fileParams[:sufixFile]}"
    CSV.open(nameFile, "wb", {:col_sep => ";"}) do |csv|
      words.each do |term|
        csv << prepCSVRow(term)  
      end
    end
  end
end

=begin
  words: Array de palabras sin filtrar
  typeTerm: Debe haber un tipo obligatoriamente
  fileParams={
    :pathCSVTranslation
    :fileNameTranslation
    :sufixFile
=end
def saveWordsbyType( words,
                     typeTerm,
                     fileParams={
                      :pathCSVTranslation => '/Users/mcberros/ruby/translate_german_words/third_version/',
                      :fileNameTranslation => 'GermanWordsTranslation_test',
                      :sufixFile => '.csv'})
  
  if Word::TYPE.has_value?(typeTerm) and not words.empty?
    wordsFiltered=words.select { |word| word.type == typeTerm}
    if not wordsFiltered.empty?
      nameFile="#{fileParams[:pathCSVTranslation]}#{fileParams[:fileNameTranslation]}_#{wordsFiltered[0].wordSimplified}_#{typeTerm}#{fileParams[:sufixFile]}"
      CSV.open(nameFile, "wb", {:col_sep => ";"}) do |csv|
        wordsFiltered.each do |term|
          csv << prepCSVRow(term)
        end
      end
    end
  end
end

begin
  browser = Watir::Browser.new :firefox
  # Path where is the file with the list of words.
  pathCSVWord='/Users/mcberros/ruby/translate_german_words/third_version/GermanWords_test.csv'
  words=[]
  
  # We obtain from csv file the information, that we will use to search in 
  # the dictionary
  CSV.foreach(pathCSVWord,{:skip_blanks => true}) do |row|
    term=fillTerm(row)
    words.push(term) if not term.nil?
  end
  
  # Para cada palabra simplificada buscamos en el diccionario
  words.each do |term|
    searchWord(term, browser)
    puts "#{term.wordSimplified}"
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
  saveWords(words,true)

  #Creamos un unico fichero con todas las palabras
  saveWords(words,false)
   
end




