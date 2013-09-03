class Word
  
  TYPE = {noun: 'NOUN', 
          verb: 'VERB',
          adverb: 'ADV',
          adjective: 'ADJ',
          conjuntion: 'CONJ',
          preposition: 'PREP',
          other: 'OTHER'}

  attr_accessor :wordNotSimplified, :wordSimplified, :url, :sentences, :translation, :type
  
  def initialize()
    @translation = []
  end

  def searchWordInDictionary(browser)
    browser.goto @url
    explorePageForWord(browser)
  end

  def explorePageForWord(browser)
    translationTable = browser.trs(class: 'kne')
    obtainTranslationListForWord(translationTable)
    exploreTypeOfWord(browser)
  end
  
  def obtainTranslationListForWord(translationTable)
    translationTable.each do |tableRow|
      exploreTableRowForTranslation(tableRow)
    end
  end

  def exploreTypeOfWord(browser)
    if changeWordType?(browser)
      @type = browser.h2.element(tag_name: 'acronym').text
    end
  end
  
  def changeWordType?(browser)
    browser.h2s.length == 1 and @type == Word::TYPE[:other] and Word::TYPE.has_value?(browser.h2.element(tag_name: 'acronym').text)
  end

  def exploreTableRowForTranslation(tableRow)
    maybeAHeadword = tableRow.td(class: 'source').strong(class: 'headword')
    if maybeATarget?(maybeAHeadword)
      maybeATarget = tableRow.td(class: 'target')
      pushNewTranslationForWord(maybeATarget)
    end
  end

  def maybeATarget?(maybeAHeadword)
    maybeAHeadword.exists? and maybeAHeadword.text.strip == @wordSimplified
  end

  def pushNewTranslationForWord(maybeATarget)
    if isATranslation?(maybeATarget)
      @translation = @translation.push(maybeATarget.text)
    end
  end

  def isATranslation?(maybeATarget)
    maybeATarget.exists? and not @translation.include?(maybeATarget.text) and not maybeATarget.text.include?(WORD_LATIN_AMERICA)
  end
end
