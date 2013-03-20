require 'watir-webdriver'

Selenium::WebDriver::Firefox::Binary.path='/Applications/Herramientas/Firefox.app/Contents/MacOS/firefox'
begin
  browser = Watir::Browser.new
  words = ['ab', 'abbiegen']
  wordToUrl=Hash[words.map { |word| [word, "http://en.pons.eu/dict/search/results/?q=#{word}&l=dees&in=&lf=de"]}]
  wordTranslation={}
  wordToUrl.each do |word, url|
    wordTranslation[word]=[]
    browser.goto url
    browser.trs(:class => 'kne').each do |tr|
      maybeAHeadword=tr.td(:class => 'source').strong(:class => 'headword')
      if maybeAHeadword.exists? and maybeAHeadword.text == word
        maybeATarget = tr.td(:class => 'target')
        wordTranslation[word]=wordTranslation[word].push(maybeATarget.text) if maybeATarget.exists? and not wordTranslation[word].include?(maybeATarget.text) and not maybeATarget.text.include?('LatAm')
      end
    end
    puts "#{word} #{wordTranslation[word]}"
  end
ensure
  browser.close
end

