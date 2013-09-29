translate_german_words
======================

App that translate a list of german words into spanish.

1. We have a list of german words in an input csv file.


Example:
ab,1. Die Fahrt kostet ab Hamburg 200 Euro. 2. Ab nächster Woche bleibt unser Geschäft samstags geschlossen. 3. Mein Bruder besucht uns ab und zu.
"abbiegen, biegt ab, bog ab, ist abgebogen",An der nächsten Kreuzung müssen Sie links abbiegen.
der Alkohol,"1. Du musst die Wunde mit Alkohol reinigen. 2. Nein, danke! Ich trinke keinen Alkohol."
"amüsieren sich, amüsiert sich, amüsierte sich, hat sich amüsiert",Bei dem Fest haben wir uns sehr gut amüsiert.

We have different cases:
- Noun: 
  Article, name, plural, example sentences
- Verb
  Verb, example sentences
- Other words (adjectives, prepositions, adverbs, conjuntions)
  Word, example sentences

To search the word:
- From verb, select only the first word
- From noun, select only the noun without the artikel.

2. We will read the input file, and for each file, we will create a word with the attributes:
  - word_not_simplified: Word from the input file
  - word_simplified: Only the significant word
  - url: URL of the dictionary associated to this word
    Word: ab
    http://en.pons.eu/dict/search/results/?q=ab&l=dees&in=&lf=de
  - sentences: example sentences from the input file
  - type: Noun, Verb,...

3. We will access using Watir, the url associated to each word.
  - To install Watir:
    gem install watir-webdriver
    gem install headless

    - From the http response we obtain a list of data of a table:
      Word: ab

      <td class="source">
        <strong class="headword">ab</strong>
      </td>    
      <td class="target">
        <a href="/spanish-german/desde">desde</a>
      </td>

      <td class="source">
        <strong class="headword">ab</strong>
      </td>
          
      <td class="target">
        <a href="/spanish-german/desde">desde</a>
      </td>

      <td class="source">
        <strong class="headword">ab</strong>
      </td>
          
      <td class="target">
        a partir de
      </td>

    When
      in first td 
      class="source" and 
      class="headword" and 
      the word in German is the one that we search 
    and
      in second td
      class="target"
    then
      obtain the word in Spanish

    and we will assign the translation attribute of the word

4. For each word we will write a line in the csv file with four columns:
1. Original word from the input csv file.
2. Translation in spanish
3. Word type: Noun, Verb, Other
4. Examples sentences for this word
The fields will be separated with ';'.

Example:
ab;desde,a partir de,de... en adelante;OTHER;1. Die Fahrt kostet ab Hamburg 200 Euro. 2. Ab nächster Woche bleibt unser Geschäft samstags geschlossen. 3. Mein Bruder besucht uns ab und zu.



