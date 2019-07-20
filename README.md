## Language detection

In full depth, it's a very complex problem, which may require even semantical considerations, as there are words that
are valid in several languages (like 'bad' and 'rot' are valid both in English and in German).

On the other hand, if we accept less than perfect results, than surprisingly primitive approaches may achieve
surprisingly low error rates.

One such simpler approach is when we treat the text only as a sequence of letters (don't care about their meanings),
and examine their statistical behaviour.


## Markov chains

The Portuguese language has a consonant (ɲ) whose transcription is 'nh', and it appears quite frequently in the
everyday words as well. This two-letter combination does appear in other languages as well ('Lionheart', 'eisenhaltig'),
but by far not as frequently.

So, if you see a text that contains a lot of 'nh' digrams (i.e. significantly more than the average), then you may
suspect that it's in Portuguese.

Similarly, the 'sch' trigram occurs quite frequently in German, and while it does occur in other languages
(eg. 'school'), a lot of 'sch'-s suggests a higher probability of the text being German.

If we try to formalise these observations, we get the following model:

* The text is nothing but a sequence of characters (not entirely true, but will do for a first approach)
* We examine this sequence of characters as sequence of N-grams that consist of:
    * N-1 leading characters (prefix)
    * followed by the final character (suffix)
* These N-grams are independent of each other (also not true, but will do for now)
* The probabilities of N-grams is an attribute of the languages

For example, if we parse the word "today", we'll find the following N-grams:

* 2-grams: "t-o", "o-d", "d-a", "a-y"
* 3-grams: "to-d", "od-a", "da-y"
* 4-grams: "tod-a", "oda-y"
* 5-grams: "toda-y"

If we analyse a large enough text corpus in some language, and count the occurences of the N-grams we find,
and then use these counts (that belong that given corpus) to estimate the probabilities of the N-grams (which
belongs to the language itself), then later we can use these to

** calculate the possibility of that some given N-gram-sequence belongs to some given language ** .

When we are concerned only about the occurences of N-grams, we implicitely state that the occurence of each letter
depends **only** on the preceding N-1 characters, and this is exactly the definition of
[Markov chains](https://en.wikipedia.org/wiki/Markov_chain): "... a sequence of possible events in which the probability
of each event depends only on the state attained in the previous event."

Analysing the various Markovian properties of languages (eg. their communicating classes) can help in answering some
interesting linguistic questions like identifying loanwords (and their suspected origins), or quantising the
relationships between languages, but these are far beyond the scope of this little experiment :).


## Collecting 2-grams

The English alphabet contains 26 letters, and that means 26^2 = 676 2-grams, or 26^3 = 17576 3-grams, etc. It quickly
grows to impractical amounts of combinations, so we'll have to draw the line somewhere.

Fortunately, for our humble goal of guessing the language, even 2-grams are fine, so we won't need too complex code,
nor huge amounts of data.

The code `mkstat.pl` is quite self-explanatory:
* it reads a text corpus line by line
* splits lines to characters
* zaps non-alphabetic ones with spaces
* collects the 2-grams: counts them individually and in total
* and finally it dumps the estimated relative probabilities as a perl hash definition


## The Bayes theorem

Now that we have the N-gram statistics, how exactly could we use them?

As we are processing our input letter by letter, and thus N-gram by N-gram, we want to answer the following question:

The probability of the language being some L is `p(L)` at this point, **given that** we found that
N-gram `X`, **what is the probability** of the language being L?

It's a nice case of [conditional probability](https://en.wikipedia.org/wiki/Conditional_probability).


Our problem with this is that we have one kind of probability, but we need a different one.

Let the event `X` mean that we found this given N-gram and the event `L` is that the text is in language L.

What we have: the relative probabilities of N-grams in each language, that is,
"*Assuming that the language is L, what's the probability of finding the N-gram X?*", or otherwise: `P(X | L)`.

What we need: the relative probabilities of languages among the occurences of N-grams, that is,
"*Assuming that we found the N-gram X, what's the probability of the language being L?*", or otherwise: `P(L | X)`.


And here comes the Bayes theorem into the picture.


We can express the probability of `L and X` in two ways:

1. `P(L & X) = P(X | L) * P(L)`

    The probability of the language being L and finding the N-gram X is the probability of the language being L,
    multiplied by the relative probability of the N-gram X in the language L.

2. `P(L & X) = P(L | X) * P(X)`

    The probability of the language being L and finding the N-gram X is the probability of finding X,
    multiplied by the relative probability of language L among the occurences of X.

As both sides are equal to the same thing, they are equal to each other: `P(L | X) * P(X) = P(X | L) * P(L)`, from
which we can express that `P(L | X)` we need:

`P(L | X) = P(L) * P(X | L) / P(X)`


## Applying it to our problem

This formula means that if we know
* the probability of the text being L prior to encountering X (that is `P(L)`)
* the probability of encountering X in language L (that is `P(X | L)`)
* and the total probability of X (that is `P(X)`), see below.

then we can calculate the probability of the language being L **after** encountering X (that is `P(L | X)`).


As there are a finite number of (supported) languages, the event 'X' is nothing but the union of 'X and L1' and
'X and L2', ... 'X and Ln', and because the languages are disjunct, these events will be disjunct as well, so
we may simply add their probabilities:

`P(X) = P(X & L1) + P(X & L2) + ... + P(X & Ln)`

and because `P(X & Li) = P(X | Li) * P(Li)`, now we have everything we need:

`P(X) = P(X | L1)*P(L1) + P(X | L2)*P(L2) + ... + P(X | Ln)*P(Ln)`


So, our algorithm will look like:
* we maintain a list for the probabilities of the languages, as they change throughout the process
* these probabilities start from 1/N (though if we had some pre-information, it could be represented here)
* for each encountered N-gram:
    * for each language we calculate that `P(X | Li) * P(Li)`
    * we calculate `P(X)` as the sum of them
    * for each language we calculate the updated probability as `P(L | X) = (P(X | L) * P(L)) / P(X)`


As of the implementation, the frame is similar as for collecting the N-grams, only the `process_ngram()`
sub is different: it implements the algorithm above.

Though the probabilities are updated on each N-gram, to keep the output clean, we display them only at the end.

(Setting the `$DEBUG` variable to non-zero changes this, and displays the in-progress results as well.)


## Conclusion

Simple as it is, even such a small, almost trivial algorithm produces a surprisingly good recognition performance.

Maybe it could be improved somewhat by working with 3-grams, but as the result will never be perfect, I think that the
increase of memory usage isn't worth the effort.

Another option would be to add dictionaries with some most frequent N words of each language (as a few 1000 words
usually covers >80% of the actual texts), but then for agglutinative languages it would require stemming
(removing of pre- and suffixes and declinations), which by itself is a more complex task.

