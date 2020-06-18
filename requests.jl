using Pkg
Pkg.add("PyCall")

using PyCall
re = pyimport("requests")

Pkg.add("Gumbo")

Pkg.add("Cascadia")

Pkg.add("HTTP")

using Gumbo
using Cascadia
using HTTP

url = HTTP.get("https://www.goodreads.com/list/show/1.Best_Books_Ever")
body = parsehtml(String(url.body))

book_title = String[]
book_author = String[]
book_rating = String[]
# book_voters = String[] - not working

title = eachmatch(Selector(".bookTitle"),body.root)
author = eachmatch(Selector(".authorName"),body.root)
rating = eachmatch(Selector(".minirating"),body.root)
# voters = eachmatch(Selector(".greyText"),body.root) - not working

for i in title
    name = nodeText(eachmatch(Selector(".bookTitle"), i)[1])
    push!(book_title, name)
end

for i in author
    name1 = nodeText(eachmatch(Selector(".authorName"), i)[1])
    push!(book_author, name1)
end

for i in rating
    rating1 = nodeText(eachmatch(Selector(".minirating"), i)[1])
    push!(book_rating, rating1)
end

# for i in voters
#    votes = nodeText(eachmatch(Selector(".greyText"), i)[1])
#    push!(book_voters, votes)
# end - not working

[book_title book_author]
