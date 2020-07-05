import Pkg
Pkg.add("PyCall")
Pkg.add("Plots")
ENV["PYTHON"] = "C:\\Users\\wolfe\\AppData\\Local\\Programs\\Python\\Python37\\python.exe"
Pkg.build("PyCall")
import PyCall
using PyCall
using Plots

gr()
Plots.GRBackend()

projectDir = (Base.source_path(), @__DIR__)
scrapeFile = "\\GoodReads_Scraping.jl"
imFile = string(projectDir[2], scrapeFile)
include(imFile)

function getLibPath()
    base = (Base.source_path(), @__DIR__)
    lib = "\\Ulibrary\\"
    libPath = string(base[2], lib)
    return libPath
end

libPath = getLibPath()

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

rlwISBNS = ["9780977716173", "9781521128220", "0486282112", "1640320342", "9780553213119", "9781605975962",
"0486284735", "9780895772770", "9780141439600", "9781494405496", "1558611584"]

function visualize(libName)
    xValues = []
    yValues = []

    for i in libName.bookList
        push!(xValues, i.overlap)
        push!(yValues, i.languageComplexity)
    end

    t = plot(xValues, yValues, seriestype = :scatter, markersize = 4, c = :orange,
    title = "RLW Library", legend = nothing)
    xlabel!("D2V Overlap Score")
    ylabel!("Language Complexity Score")
    for i = 1:length(libName.bookList)
        annotate!(xValues[i], (yValues[i] + 0.035), Plots.text(libName.bookList[i].title, 6, :blue, :center))
    end
    display(t)
end

#Test Code
rlw = bookLibrary("RLW", libPath, rlwISBNS)

visualize(rlw)
