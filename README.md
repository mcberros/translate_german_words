translate_german_words
======================

App that translate a list of german words into spanish.

1. We have a list of german words
ab
abbiegen, biegt ab, bog ab, ist abgebogen
die Abbildung, -en
...

Problem:
- From verb, select only the first word
- From noun, select only the noun without the artikel.

2. We can construct a list of URLs:
http://en.pons.eu/dict/search/results/?q=ab&l=dees&in=&lf=de
http://en.pons.eu/dict/search/results/?q=abbiegen&l=dees&in=&lf=de
http://en.pons.eu/dict/search/results/?q=Abbildung&l=dees&in=&lf=de

3. From the http response we obtain a list of data of a table:
ab:

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

Problem:
- When
  in first td
  class="source" and class="headword" and the word in German is the one that we search 
  and
  in second td
  class="target"
  then
  obtain the word in Spanish

Solution: We use Watir
- Install: gem install watir-webdriver

4. The result has to be:
ab; de, a partir de



