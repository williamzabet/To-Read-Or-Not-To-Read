totallines = open("C:/Users/wolfe/AppData/Local/JuliaPro-1.0.5-2/docs/testdoc.txt") do f
    linecounter = 0
    for ln in eachline(f)
        linecounter += 1
    end
    (linecounter)
end

book = open("C:/Users/wolfe/AppData/Local/JuliaPro-1.0.5-2/docs/testdoc.txt") do file
    read(file, String)
end

new_arr = split(book)
words = length(new_arr)
print("There are $words words in the book")

function getChars(_arr)
    totalchars = 0
    for i in _arr
        totalchars += (length(i))
    end
    return totalchars
end
chars = getChars(new_arr)
print("There are $chars characters in the book")

wordLength = chars / words
print("The average word length is $wordLength characters")

function getPunc(_arr)
    totalPunc = 0
    for i in _arr
        if(occursin(".", i))
            totalPunc += 1
        end
        if(occursin("!", i))
            totalPunc += 1
        end
        if(occursin("?", i))
            totalPunc += 1
        end
    end
    return totalPunc
end
numPunc = getPunc(new_arr)
print("The number of punctuation marks in the book is $numPunc")

sentenceLength = words / numPunc
print("The average sentence length is $sentenceLength words")

function killPunc(_arr)
    for i in _arr
        replace(i, "." => "")
        replace(i, "," => "")
        replace(i, "!" => "")
        replace(i, "?" => "")
    end
    return _arr
end

killedArr = killPunc(new_arr)

function createDictionary(_arr)
    dict = Dict()
    for i in _arr
        if(haskey(dict, i))
            dict[i] += 1
        else
            dict[i] = 1
        end
    end
    return dict
end

bookDict = createDictionary(killedArr)
print(bookDict["Bingley"])
#print(sizeof(bookDict))
#dictionarySize = length.(collect(keys(bookDict)))
#print(" $dictionarySize")
bookArray = sort(collect(bookDict), by = tuple -> last(tuple), rev=true)
uniqueWords = length(bookArray)
print(" $uniqueWords")
