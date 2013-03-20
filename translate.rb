require 'watir-webdriver'
require 'csv'

Selenium::WebDriver::Firefox::Binary.path='/Applications/Herramientas/Firefox.app/Contents/MacOS/firefox'

begin
  
  browser = Watir::Browser.new :firefox
  # Path where is the file with the list of words.
  pathCSVWord='/Users/mcberros/Documents/estudio/aleman/GermanWords.csv'
  pathCSVTranslation='/Users/mcberros/Documents/estudio/aleman/GermanWordsTranslation.csv'
  # From CSV. Key: word NOT simplified, value:Sentences
  wordsToExample={}

  # Key: word NOT Simplified from CSV
  # Value: Simplified word, that we will use to search in the dictionary
  wordsToSimple={}

  # Key:Simplified word, Value: URL where we can find the translation
  wordToUrl={}

  # Key:Simplified word, Value: Translation obtained from the site
  wordTranslation={}

  # We obtain from csv file the information, that we will search in 
  # the dictionary
  CSV.foreach(pathCSVWord,{:skip_blanks => true}) do |row|

    if not row[0].nil? and not row[1].nil?

      wordsToExample[row[0]]=row[1]

      arrayFirstColumn = row[0].split(',')
      if arrayFirstColumn.length >= 1 
        # Case:
        # Verb without sich. Example: "abbiegen, biegt ab, bog ab, ist abgebogen"
        # Other word different from noun or verb: ab
        word=arrayFirstColumn[0].strip

        # Case: Noun. Example: "das Abonnement, -s"
        word=arrayFirstColumn[0].split[1].strip if word.match('^(der|die|das) ')
        
        # Verb with sich. Example: Example: "amüsieren sich, amüsiert sich, amüsierte sich, hat sich amüsiert"
        word=word.sub(' sich$','') if word.match(' sich$')
        
      end

      wordsToSimple[row[0]]=word
      wordToUrl[word]="http://en.pons.eu/dict/search/results/?q=#{word}&l=dees&in=&lf=de"
    
    end

  end

  # Para cada palabra simplificada buscamos en el diccionario
  wordToUrl.each do |word, url|
    wordTranslation[word]=[]
    browser.goto url
    browser.trs(:class => 'kne').each do |tr|
      maybeAHeadword=tr.td(:class => 'source').strong(:class => 'headword')
      if maybeAHeadword.exists? and maybeAHeadword.text.strip == word
        maybeATarget = tr.td(:class => 'target')
        wordTranslation[word]=wordTranslation[word].push(maybeATarget.text) if maybeATarget.exists? and not wordTranslation[word].include?(maybeATarget.text) and not maybeATarget.text.include?('LatAm')
      end
    end
    puts "#{word} #{wordTranslation[word]}"
  end

  # Para cada palabra vamos a grabar un csv con tres columnas:
  # 1. Palabra original del csv, es decir, no simplificada
  # 2. Traducción de la palabra simplificada al español
  # 3. Frases de ejemplo

  CSV.open(pathCSVTranslation, "wb", {:col_sep => ";"}) do |csv|
    wordsToExample.each do |word_not_simplified, sentences|
      simplified_word=wordsToSimple[word_not_simplified]
      translated_word=wordTranslation[simplified_word]
      puts "#{word_not_simplified} #{translated_word.join(',')} #{sentences}"
      csv << [word_not_simplified, translated_word.join(','), sentences]
    end
  end 

ensure
  browser.close
end


