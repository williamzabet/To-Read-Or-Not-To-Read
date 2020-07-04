using Pkg
Pkg.add("PyCall")

Pkg.add("Gumbo")

Pkg.add("Cascadia")

Pkg.add("HTTP")

Pkg.add("DataFrames")

Pkg.add("Dates")

using Gumbo
using Cascadia
using HTTP
using DataFrames
using Dates

#Function that takes a string array of a person's 10 favorite books (IBSN# for each book) and returns a df of 9 values
function book_stats(book_list)

    #empty array to take the url for each book on Goodreads.com
    review_url = String[]
    #function that takes the IBSN and adds it to the default Goodreads/search url, returns the url for each book
    for ibsn in book_list
        a = "https://www.goodreads.com/search?utf8=%E2%9C%93&q="
        review = a*ibsn
        push!(review_url, review)
    end

    #empty arrays for 9 values being scraped
    book_title = String[]
    book_author = String[]
    book_published = []
    book_rating = String[]
    book_raters = String[]
    book_reviews = String[]
    book_pages = String[]
    book_awards = []
    book_genres = []

    #loops through each url and scrapes the page based on the criteria
    for i in review_url
        #get request for each page
        url = HTTP.get(i)
        #parses the html body of each page
        body = parsehtml(String(url.body))

        #Title of each book was found at id = bookTitle
        title = eachmatch(Selector("#bookTitle"),body.root)
        title1 = nodeText(eachmatch(Selector("#bookTitle"), body.root)[1])
        #replace the whitespaces & line breaks to soley get the title
        title2 = replace(title1, "\n" => "")
        title3 = replace(title2, "      " => "")
        push!(book_title, title3)

        #author of each book was found at class = authorName
        author = eachmatch(Selector(".authorName"),body.root)
        author1 = nodeText(eachmatch(Selector(".authorName"), body.root)[1])
        push!(book_author, author1)

        #dates published were found at the 2nd id=row within the class = .uitext darkGreyText
        book_published0 = []
        published = eachmatch(Selector(".uitext.darkGreyText"), body.root)
        for i in published
            dates = String[]
            published1 = nodeText(eachmatch(Selector(".row"), i)[2])
            #regex to match 4 digits within the text to get the year
            rx = r"\d\d\d\d"
            published2 = eachmatch(rx, published1)
            published3 = collect(published2)
            for i in published3
                push!(dates, i.match)
            end
            #some books had multiple publish dates so the oldest year was taken
            dates = minimum(dates)
            push!(book_published0, dates)
        end
        for i in book_published0
            converter = DateFormat("y")
            #i = Date(i, converter) returns the dates in a YYYY-MM-YY format but exact dates aren't available
            push!(book_published, i)
        end

        #rating for each book was found at <span itemprop=ratingValue></span>
        rating = eachmatch(Selector("span[itemprop*=ratingValue]"),body.root)
        rating1 = nodeText(eachmatch(Selector("span[itemprop*=ratingValue]"), body.root)[1])
        rating2 = replace(rating1, "\n" => "")
        rating3 = replace(rating2, "  " => "")
        push!(book_rating, rating3)

        #num of raters was found within  <a><href = other_reviews></a> on the first row
        raters = eachmatch(Selector("a[href*=other_reviews]"),body.root)
        raters1 = nodeText(eachmatch(Selector("a[href*=other_reviews]"), body.root)[1])
        raters2 = replace(raters1, "\n" => "")
        raters3 = replace(raters2, "  " => "")
        raters4 = replace(raters3, "ratings" => "")
        raters5 = replace(raters4, "," => "")
        push!(book_raters, raters5)

        #num of reviews was found within  <a><href = other_reviews></a> on the second row
        reviews = eachmatch(Selector("a[href*=other_reviews]"),body.root)
        reviews1 = nodeText(eachmatch(Selector("a[href*=other_reviews]"), body.root)[2])
        reviews2 = replace(reviews1, "\n" => "")
        reviews3 = replace(reviews2, "    " => "")
        reviews4 = replace(reviews3, "reviews" => "")
        reviews5 = replace(reviews4, "," => "")
        push!(book_reviews, reviews5)


        details = eachmatch(Selector(".infoBoxRowTitle"), body.root)
        awards = String[]
        for i in details
            details1 = nodeText(eachmatch(Selector(".infoBoxRowTitle"), i)[1])
            push!(awards, details1)
        end
        awards0 = String[]
        if in("Literary Awards", awards)
            awards1 = eachmatch(Selector(".award"), body.root)
            for i in awards1
                awards2 = nodeText(eachmatch(Selector(".award"), i)[1])
                push!(awards0, awards2)
            end
        end

        n = 0
        for i in awards0
            n += 1
        end
        push!(book_awards, n)

        pages = nodeText(eachmatch(Selector("span[itemprop*=numberOfPages]"), body.root)[1])
        pages1 = replace(pages, " pages" => "")
        push!(book_pages, pages1)
    end

    for i in review_url
        url = HTTP.get(i)
        body = parsehtml(String(url.body))

        genre1 = eachmatch(Selector(".actionLinkLite.bookPageGenreLink"), body.root)
        genre0 = String[]
        for g in genre1
            genre2 = nodeText(eachmatch(Selector(".actionLinkLite.bookPageGenreLink"), g)[1])
            if occursin("users", genre2) == false
                push!(genre0, genre2)
            end
            genre0 = unique(genre0)
        end
        push!(book_genres, genre0)
    end

    book_rating = parse.(Float64, book_rating)
    book_raters = parse.(Int, book_raters)
    book_reviews = parse.(Int, book_reviews)

    df = DataFrame(Title=book_title, Author=book_author, Date_Published = book_published, Rating=book_rating, Num_of_Raters=book_raters,
        Num_of_Reviews=book_reviews, Num_of_Pages = book_pages, Literary_Awards = book_awards, Genres=book_genres)

    display(df)

    scrapedDataArr = [book_title, book_author, book_published, book_rating, book_raters, book_reviews, book_pages,
    book_awards, book_genres]

    return scrapedDataArr

end

williams_list = ["9780060935467", "0316769177", "9780439554930", "9780743273565", "0439023483", "0618260307",
"0553588486", "9780345342966", "0393341763", "0062315005"]

#book_stats(williams_list)
