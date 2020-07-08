import Pkg
Pkg.add("PyCall")
Pkg.add("Plots")

#CHANGE LOCATION OF PYTHON EXECUTABLE FOR YOUR LOCAL MACHINE
ENV["PYTHON"] = "/Library/Frameworks/Python.framework/Versions/3.8/bin/python3"
#ENV["PYTHON"] = "C:\\Users\\wolfe\\AppData\\Local\\Programs\\Python\\Python37\\python.exe"

Pkg.build("PyCall")
import PyCall
using PyCall
using Plots

gr()
Plots.GRBackend()

projectDir = (Base.source_path(), @__DIR__)
# scrapeFile = "\\GoodReads_Scraping.jl"  # FOR WINDOWS
scrapeFile = "/GoodReads_Scraping.jl" # FOR MACS
imFile = string(projectDir[2], scrapeFile)
include(imFile)


base = (Base.source_path(), @__DIR__)
lib = "/Ulibrary/"  # FOR MACS
# lib = "\\Ulibrary\\"  # FOR WINDOWS
libPath = string(base[2], lib)

py"""
import numpy as numpy
import os as os
import gensim as gensim
import smart_open as smart_open
import io as io
import re as re

from gensim.test.utils import datapath
from gensim import utils as utils
from scipy import spatial
from os import listdir
from os.path import isfile, join

libLink = $libPath

user_corpus = []
d2v_vecs = []
overlap = []
most_similar = []

user_library = [join(libLink, file) for file in os.listdir(libLink) if os.path.isfile(join(libLink, file))]
# print('\n\nUSER LIBRARY: %s\n\n\n' % user_library)

def d2v():
    master_string = ""

    for book in user_library:
        with smart_open.open(book, encoding="iso-8859-1") as x:
            user_corpus.append(
                gensim.models.doc2vec.TaggedDocument(
                    gensim.utils.simple_preprocess(
                        x.read()), ['{}'.format(book)]
                )
            )
        with io.open(book, 'r', encoding="utf-8") as y:
            master_string += y.read()

    master_list = gensim.utils.simple_preprocess(master_string)

    lib_model = gensim.models.Doc2Vec(min_count = 1, epochs = 10)
    lib_model.build_vocab(user_corpus)

    for i in range(len(user_corpus)):
        d2v_vecs.append(lib_model.infer_vector(user_corpus[i].words))

    for i in range(len(d2v_vecs)):
        overlap.append(spatial.distance.cosine(d2v_vecs[i], lib_model.infer_vector(master_list)))

    for i in range(len(user_corpus)):
        most_similar.append(lib_model.docvecs.most_similar(i))

def returnIndex(filePath):
    for i in range(len(user_library)):
        if (filePath == user_library[i]):
            return i

def returnVector(i):
    return d2v_vecs[i]

def returnOverlap(i):
    return overlap[i]

def returnSimilar(i):
    return most_similar[i]

d2v()

"""

mutable struct bookLibrary
    name
    dirPath
    bookFiles
    bookList
    isbnList

    #=
    masterDictionary::Dict
    meanTotalWords::Int
    meanTotalChars::Int
    meanWordLength::Float32
    meanSentenceEnders::Int
    meanSentenceLength::Float32
    meanUniqueWords::Int
    meanVocabVariation::Float32
    meanLanguageComplexity::Float32
    meanUnsharedUnique::Int
    meanUnsharedTotal::Int
    meanOverlap::Float32
    =#
    function bookLibrary(name, dirPath, isbnList)
        fileNames = readdir(dirPath)
        structList = []
        scrapedData = book_stats(isbnList)
        for i in fileNames
            push!(structList, book(i, dirPath, scrapedData))
        end
        new(name, dirPath, fileNames, structList, isbnList)
    end
end

struct book
    fileName
    filePath
    totalWords
    totalChars
    wordLength
    sentenceEnders
    sentenceLength
    bookDictionary
    wordFrequency
    uniqueWords
    vocabVariation
    languageComplexity
    overlap
    d2vVector
    mostSimilarBooks
    title
    author
    publishDate
    rating
    numRaters
    numReviews
    numPages
    awards
    genres

    function book(fileName, filePath, scrapedData)
        bookString = bookToString(string(filePath, fileName))
        tWords = totalWords(bookString)
        tChars = totalChars(bookString)
        wLength = avgWordLength(tWords, tChars)
        sEnders = sentenceEnders(bookString)
        sLength = avgSentenceLength(tWords, sEnders)
        bDict = createDictionary(bookString)
        fArray = createFreqArray(bDict)
        uW = uWords(fArray)
        vV = vocabVariation(fArray)
        lCS = langCompositeScore(wLength, sLength, vV)
        ind = py"returnIndex"(string(filePath, fileName))
        langOverlap = py"returnOverlap"(ind)
        vect = py"returnVector"(ind)
        similarBooks = py"returnSimilar"(ind)
        julInd = ind + 1
        bTitle = getindex(getindex(scrapedData, 1), julInd)
        bAuthor = getindex(getindex(scrapedData, 2), julInd)
        bPubDate = getindex(getindex(scrapedData, 3), julInd)
        bRating = getindex(getindex(scrapedData, 4), julInd)
        bRaters = getindex(getindex(scrapedData, 5), julInd)
        bRevs = getindex(getindex(scrapedData, 6), julInd)
        bPages = getindex(getindex(scrapedData, 7), julInd)
        bAwards = getindex(getindex(scrapedData, 8), julInd)
        bGenres = getindex(getindex(scrapedData, 9), julInd)

        new(fileName, filePath, tWords, tChars, wLength, sEnders, sLength, bDict, fArray, uW, vV, lCS,
        langOverlap, vect, similarBooks, bTitle, bAuthor, bPubDate, bRating, bRaters, bRevs, bPages, bAwards,
        bGenres)
    end
end

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

rlwISBNS = ["9780977716173", "9781521128220", "0486282112", "0451532252", "9780553213119", "9781605975962",
"0486284735", "9780895772770", "9780141439600", "9781494405496", "1558611584"]

function visualize(libName, choice1 = "overlap", choice2="languageComplexity")
    xValues = []
    yValues = []
    xSum = 0
    ySum = 0

    if (choice1 == "overlap")
        for i in libName.bookList
            push!(xValues, i.overlap)
            xSum += i.overlap
        end
    elseif (choice1 == "languageComplexity")
        for i in libName.bookList
            push!(xValues, i.languageComplexity)
            xSum += i.languageComplexity
        end
    elseif (choice1 == "totalWords")
        for i in libName.bookList
            push!(xValues, i.totalWords)
            xSum += i.totalWords
        end
    elseif (choice1 == "totalChars")
        for i in libName.bookList
            push!(xValues, i.totalChars)
            xSum += i.totalChars
        end
    elseif (choice1 == "wordLength")
        for i in libName.bookList
            push!(xValues, i.wordLength)
            xSum += i.wordLength
        end
    elseif (choice1 == "sentenceEnders")
        for i in libName.bookList
            push!(xValues, i.sentenceEnders)
            xSum += i.sentenceEnders
        end
    elseif (choice1 == "sentenceLength")
        for i in libName.bookList
            push!(xValues, i.sentenceLength)
            xSum += i.sentenceLength
        end
    elseif (choice1 == "wordFrequency")
        for i in libName.bookList
            push!(xValues, i.wordFrequency)
            xSum += i.wordFrequency
        end
    elseif (choice1 == "uniqueWords")
        for i in libName.bookList
            push!(xValues, i.uniqueWords)
            xSum += i.uniqueWords
        end
    elseif (choice1 == "vocabVariation")
        for i in libName.bookList
            push!(xValues, i.vocabVariation)
            xSum += i.vocabVariation
        end
    elseif (choice1 == "d2vVector")
        for i in libName.bookList
            push!(xValues, i.d2vVector)
            xSum += i.d2vVector
        end
    elseif (choice1 == "publishDate")
        for i in libName.bookList
            push!(xValues, i.publishDate)
            xSum += i.publishDate
        end
    elseif (choice1 == "rating")
        for i in libName.bookList
            push!(xValues, i.rating)
            xSum += i.rating
        end
    elseif (choice1 == "numRaters")
        for i in libName.bookList
            push!(xValues, i.numRaters)
            xSum += i.numRaters
        end
    elseif (choice1 == "numReviews")
        for i in libName.bookList
            push!(xValues, i.numReviews)
            xSum += i.numReviews
        end
    elseif (choice1 == "numPages")
        for i in libName.bookList
            push!(xValues, i.numPages)
            xSum += i.numPages
        end
    elseif (choice1 == "awards")
        for i in libName.bookList
            push!(xValues, i.awards)
            xSum += i.awards
        end
    else
        for i in libName.bookList
            push!(xValues, i.overlap)
            xSum += i.overlap
        choice1 = "D2V Overlap Score"
        end
    end


    if (choice2 == "overlap")
        for i in libName.bookList
            push!(yValues, i.overlap)
            ySum += i.overlap
        end
    elseif (choice2 == "languageComplexity")
        for i in libName.bookList
            push!(yValues, i.languageComplexity)
            ySum += i.languageComplexity
        end
    elseif (choice2 == "totalWords")
        for i in libName.bookList
            push!(yValues, i.totalWords)
            ySum += i.totalWords
        end
    elseif (choice2 == "totalChars")
        for i in libName.bookList
            push!(yValues, i.totalChars)
            ySum += i.totalChars
        end
    elseif (choice2 == "wordLength")
        for i in libName.bookList
            push!(yValues, i.wordLength)
            ySum += i.wordLength
        end
    elseif (choice2 == "sentenceEnders")
        for i in libName.bookList
            push!(yValues, i.sentenceEnders)
            ySum += i.sentenceEnders
        end
    elseif (choice2 == "sentenceLength")
        for i in libName.bookList
            push!(yValues, i.sentenceLength)
            ySum += i.sentenceLength
        end
    elseif (choice2 == "wordFrequency")
        for i in libName.bookList
            push!(yValues, i.wordFrequency)
            ySum += i.wordFrequency
        end
    elseif (choice2 == "uniqueWords")
        for i in libName.bookList
            push!(yValues, i.uniqueWords)
            ySum += i.uniqueWords
        end
    elseif (choice2 == "vocabVariation")
        for i in libName.bookList
            push!(yValues, i.vocabVariation)
            ySum += i.vocabVariation
        end
    elseif (choice2 == "d2vVector")
        for i in libName.bookList
            push!(yValues, i.d2vVector)
            ySum += i.d2vVector
        end
    elseif (choice2 == "publishDate")
        for i in libName.bookList
            push!(yValues, i.publishDate)
            ySum += i.publishDate
        end
    elseif (choice2 == "rating")
        for i in libName.bookList
            push!(yValues, i.rating)
            ySum += i.rating
        end
    elseif (choice2 == "numRaters")
        for i in libName.bookList
            push!(yValues, i.numRaters)
            ySum += i.numRaters
        end
    elseif (choice2 == "numReviews")
        for i in libName.bookList
            push!(yValues, i.numReviews)
            ySum += i.numReviews
        end
    elseif (choice2 == "numPages")
        for i in libName.bookList
            push!(yValues, i.numPages)
            ySum += i.numPages
        end
    elseif (choice2 == "awards")
        for i in libName.bookList
            push!(yValues, i.awards)
            ySum += i.awards
        end
    else
        for i in libName.bookList
            push!(yValues, i.languageComplexity)
            ySum += i.languageComplexity
        end
        choice2 = "Language Complexity Score"
    end


    xMean = xSum / length(libName.bookList)
    yMean = ySum / length(libName.bookList)

    push!(xValues, xMean)
    push!(yValues, yMean)

    t = Plots.plot(xValues, yValues, seriestype = :scatter, markersize = 4, c = :orange,
    title = "RLW Library", legend = nothing)
    labelx = string("Choice 1: ",choice1)
    labely = string("Choice 2: ",choice2)
    xlabel!(labelx)
    ylabel!(labely)
    for i = 1:(length(xValues) - 1)
        annotate!(xValues[i], (yValues[i] + 0.035), Plots.text(libName.bookList[i].title, 6, :blue, :center))
    end
    annotate!(xValues[length(xValues)], (yValues[length(yValues)] + 0.035), Plots.text("Mean User Taste", 6, :red, :center))

    display(t)
end

#Test Code
rlw = bookLibrary("RLW", libPath, rlwISBNS)



while(true)
    print("\nChoices are:
    totalWords
    totalChars
    sentenceEnders
    sentenceLength
    wordFrequency
    uniqueWords
    vocabVariation
    languageComplexity
    overlap
    d2vVector
    publishDate
    rating
    numRaters
    numReviews
    numPages
    awards
    \nType in full variable name as is for choices.\nType \'quit\' to exit for either choice.\nDefault x is overlap, default y is languageComplexity")

    choice1 = input("\nChoice 1 (x-axis): ")
    choice2 = input("\nChoice 2 (y-axis): ")

    if (choice1 == "quit") || (choice2 == "quit")
        break
    end

    visualize(rlw, choice1, choice2)
end
print("\nGOODBYE")
