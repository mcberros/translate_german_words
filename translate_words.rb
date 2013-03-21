require 'watir-webdriver'
require 'csv'
require_relative 'word'

Selenium::WebDriver::Firefox::Binary.path='/Applications/Herramientas/Firefox.app/Contents/MacOS/firefox'

def saveWordsFile (pathCSVTranslation='/Users/mcberros/ruby/translate_german_words/',
                  fileNameTranslation='GermanWordsTranslation',
                  sufixFile='.csv', words)
  if not words.empty?
    firstTerm=words[0]
    nameFile=pathCSVTranslation+fileNameTranslation+'_'+firstTerm.wordSimplified+sufixFile
    CSV.open(nameFile, "wb", {:col_sep => ";"}) do |csv|
      words.each do |term|
        csv << [term.wordNotSimplified, term.translation.join(','), term.sentences]
      end
    end
  end 
end

begin
  
  browser = Watir::Browser.new :firefox
  # Path where is the file with the list of words.
  pathCSVWord='/Users/mcberros/ruby/translate_german_words/GermanWords_from_liegen.csv'
  #pathCSVTranslation='/Users/mcberros/ruby/translate_german_words/'
  #fileNameTranslation='GermanWordsTranslation_test'
  #sufixFile='.csv'
  words=[]
  
  # We obtain from csv file the information, that we will search in 
  # the dictionary
  CSV.foreach(pathCSVWord,{:skip_blanks => true}) do |row|

    if not row[0].nil? and not row[1].nil?
      arrayFirstColumn = row[0].split(',')
      if arrayFirstColumn.length >= 1
        term=Word.new()
        term.wordNotSimplified=row[0]
        term.sentences=row[1]
        # Case:
        # Verb without sich. Example: "abbiegen, biegt ab, bog ab, ist abgebogen"
        # Other word different from noun or verb: ab
        word=arrayFirstColumn[0].strip

        # Case: Noun. Example: "das Abonnement, -s"
        word=arrayFirstColumn[0].split[1].strip if word.match('^(der|die|das) ')
        
        
        # Verb with sich. Example: Example: "amüsieren sich, amüsiert sich, amüsierte sich, hat sich amüsiert"
        word=word.sub(' sich$','') if word.match(' sich$')
        
      end
      #wordsToSimple[row[0]]=word
      term.wordSimplified=word
      #wordToUrl[word]="http://en.pons.eu/dict/search/results/?q=#{word}&l=dees&in=&lf=de"
      term.url="http://en.pons.eu/dict/search/results/?q=#{word}&l=dees&in=&lf=de"
    end
    words.push(term) if not term.nil?
  end
  
  # Para cada palabra simplificada buscamos en el diccionario
  words.each do |term|
    browser.goto term.url
    browser.trs(:class => 'kne').each do |tr|
      maybeAHeadword=tr.td(:class => 'source').strong(:class => 'headword')
      if maybeAHeadword.exists? and maybeAHeadword.text.strip == term.wordSimplified
        maybeATarget = tr.td(:class => 'target')
        term.translation=term.translation.push(maybeATarget.text) if maybeATarget.exists? and not term.translation.include?(maybeATarget.text) and not maybeATarget.text.include?('LatAm')
      end
    end
    puts "#{term.wordSimplified}"
  end
 
ensure
  browser.close

  # Para cada palabra vamos a grabar un csv con tres columnas:
  # 1. Palabra original del csv, es decir, no simplificada
  # 2. Traducción de la palabra simplificada al español
  # 3. Frases de ejemplo
  # Los tres campos están separados por ;
  saveWordsFile(words)
end




