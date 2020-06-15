#Takes in the book file and converts it to a string
function bookToString(file_path)
    stringBook = open(file_path) do file
        read(file, String)
    end
    return stringBook
end

#Returns total words in the book
function totalWords(book)
    totalWords = length(split(book))
    return totalWords
end

#Returns total characters in the book
function totalChars(book)
    processedBook = replace(book, r"""[!?.;,-_():"' ]""" => "")
    finalIndex = lastindex(processedBook)
    return finalIndex
end

#Returns average word length of words in the book
function avgWordLength(totalChars, totalWords)
    return totalChars / totalWords
end

#Returns the number of sentence ending puncuation marks in the book
function sentenceEnders(book)
    enders = count(c -> c == '.', book)
    enders += count(c -> c == '!', book)
    enders += count(c -> c == '?', book)
    return enders
end

#Returns the average sentence length by dividing total words by number of
#sentence ending punctuation marks
function avgSentenceLength(totalWords, enders)
    return totalWords / enders
end

#Converts text of book to lowercase, removes punctuation, and creates a dictionary
#to associate each word with frequency of its occurrence
function createDictionary(book)
    lowercaseBook = lowercase(book)
    noPuncBook = replace(lowercaseBook, r"""[!?.;,-_():"']""" => "")
    bookArray = split(noPuncBook)
    bookDictionary = Dict()
    for i in bookArray
        if(haskey(bookDictionary, i))
            bookDictionary[i] += 1
        else
            bookDictionary[i] = 1
        end
    end
    return bookDictionary
end

#Creates an array of tuples sorted by frequency of word occurence in dictionary;
#first index is the key (word), second index is the value (frequency)
function createFreqArray(bookDict)
    frequencyArray = sort(collect(bookDict), by = tuple -> last(tuple))
    return frequencyArray
end

#Returns number of unique words in the book
function uWords(freqArray)
    return length(freqArray)
end

#Returns a measure of how likely a text is to use unusual language,
#based on the variation of the words in the text itself
function vocabVariation(freqArray)
    uniqWords = length(freqArray)
    medianWords = uniqWords / 2
    currentIndex = 1
    wordCounter = 0
    while (wordCounter <= medianWords)
        wordCounter += (freqArray[currentIndex][2])
        currentIndex += 1
    end
    #Calculation is based on where the median falls - earlier means less
    #variation of vocabulary in the text
    vocabularyVariation = currentIndex / uniqWords
    return vocabularyVariation
end

#Calculates composite language complexity score by multiplying together
#average word length, average sentence length, and variation in vocabulary
function langCompositeScore(wLength, sLength, vVariation)
    return wLength * sLength * vVariation
end

#Tests using Pride and Prejudice
pripred = bookToString("C:\\Users\\wolfe\\Documents\\GitHub\\csci_6221\\testdoc.txt")
ppWords = totalWords(pripred)
ppChars = totalChars(pripred)
ppWordLength = avgWordLength(ppChars, ppWords)
ppEnders = sentenceEnders(pripred)
ppSentenceLength = avgSentenceLength(ppWords, ppEnders)
ppDictionary = createDictionary(pripred)
ppArray = createFreqArray(ppDictionary)
ppUniqWords = uWords(ppArray)
ppVocab = vocabVariation(ppArray)
ppScore = langCompositeScore(ppWordLength, ppSentenceLength, ppVocab)

print("\nPride and Prejudice\nTotal Words: $ppWords\nUnique Words: $ppUniqWords
Total Characters: $ppChars\nAverage Word Length: $ppWordLength
Average Sentence Length: $ppSentenceLength\nVocabulary Variation: $ppVocab
Composite Literary Score: $ppScore")
