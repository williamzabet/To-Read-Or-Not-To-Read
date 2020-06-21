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

book_data = String[]
book_title = String[]
push!(book_title, "Title")
book_author = String[]
push!(book_author, "Author")
book_avg_rating = String[]
push!(book_avg_rating, "Average Ratings")
book_total_rating = String[]
push!(book_total_rating, "Total Ratings")

# edit final number for # of pages 
for i = 1:5
    b = string(i)
    html = "https://www.goodreads.com/list/show/1.Best_Books_Ever?page="*b
    url = HTTP.get(html)
    body = parsehtml(String(url.body))
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
        if (!occursin("(", name1))
            push!(book_author, name1)
        end
    end
    for i in rating
        rating1 = nodeText(eachmatch(Selector(".minirating"), i)[1])
        rating2 = split(rating1, " — ")
        push!(book_avg_rating, rating2[1])
        push!(book_total_rating, rating2[2])
    end
end
# for i in voters
#    votes = nodeText(eachmatch(Selector(".greyText"), i)[1])
#    push!(book_voters, votes)
# end - not working

book_data = [book_title book_author book_avg_rating book_total_rating]

using DelimitedFiles
writedlm("Titles.csv",  book_title, ',')
writedlm("Authors.csv",  book_author, ',')
writedlm("Ratings.csv",  book_rating, ',')
writedlm("Data.csv",  book_data, ',')
