#!/usr/bin/env io

// bIog
// A simple blog compiler in Io

/*
	Source directory structure:
	
	- description.txt
		* file containing info about the blog. values are set on the Description object 
		for use during interpolation format is:
		blogName: A Blog
		description: A blog about blogs
		baseURL: http://blog.example.com
		
	- articles/
		* article files in markdown format, first lines contain info about 
		the article, e.g. title and date. files should be named with the 
		"slug", which is used for the urls
		e.g.  
		title: New Blog
		date: 2011/05/27 15:30
		description:  
		
		followed my markdown formatted content of post
		
	- pages/
		* static pages in markdown format. filenames are used to determine URLs
		e.g. about.txt will generate "build/about/index.html"
	
	- templates/
		- layout.html
			* the main template file used for all pages. available to interpolate 
			is a Page object (page) content is inserted by using #{page content}
			
		- feed.xml
			* template for the atom feed
			
		- pages/
			- index.html
				* template for the content of the index page. available to interpolate 
				is a list of recent article objects. 
				
			- article.html
				* template for single article contents. will be inserted into the 
				layout template. available to interpolate is an Article object
				
			- archives.html
				* template for an archive page. available is a list of all 
				articles, sorted by date
				
	- static/
		* static content like css that will be copied into the build directory at build time
	
	Interpolation:
	
	Basic fields are inserted with io interpolation syntax e.g #{page title} for 
	the page title in the layout template. Dates can be formated in various 
	ways: #{article date asString("%c") produces "Fri May 27 02:18:34 2011"
	or #{article date asString("%B %d %Y")} produces "May 27 2011"
	
	For lists of items, they can be iterated over like:
	<!-- loop articles !-->
		<li><a href="#{entry url}">#{entry title}<span class="date">#{entry date asString("%c")}</span></a></li>
	<!-- endloop articles !-->
	
	where "entry" represents the current item
	
	Use:
	
	to build a blog:
	bIog /my/blog/source
	or run bIog within the source dir
	
	after running, files are output to the build/ directory in the source dir, ready to be uploaded
*/


// =============================================================
// extensions to base objects

Directory copyToPath := method(targetPath,
	if (list(".", "..") contains(targetPath lastPathComponent), return)
	Directory with(targetPath) createIfAbsent
	self items foreach(i, i copyToPath(targetPath cloneAppendPath(i name)))
)

Directory empty := method(
	if (exists,
		files foreach(remove)
		directories foreach(d, if (list(".", "..") contains(d name) not, d empty; d remove))
	)
	self
)

Sequence htmlEscape := method(
	self clone replaceMap(Map with("<", "&lt;", ">", "&gt;", "&", "&amp;"))
)

// ============================================================


if (System args size == 1) then(
	// no arguments argument, assume we are in the source dir
	sourceDir := Directory currentWorkingDirectory
) elseif (System args size == 2) then(
	// single arg, assumme it is source path
	sourceDir := System args last
	if (sourceDir == "--help",
		"Usage: bIog /path/to/source" println
		System exit
	)
) 

// use the source dir name as the blog name, unless a different one is provided in the description file
Description := Object clone
Description blogName := sourceDir fileName

// read the description file
descriptionFile := File with(sourceDir cloneAppendPath("description.txt")) 
if (descriptionFile exists,
	rawDescription := descriptionFile contents
	rawDescription split("\n") foreach(line,
		key := line beforeSeq(":")
		Description setSlot(key, line afterSeq(":") lstrip)
	)
)


// ============================================================


Page := Object clone do(
	// slots available on page object when interpolating:
	title := nil // Page Title
	url := nil // the url
	contents := nil //content to be inserted into page"
	body := nil //Entire Page Contents that is written to file
	description := nil // description for meta tag
	
	localPath := nil
	template := File with(sourceDir cloneAppendPath("templates/layout.html")) contents
	
	with := method(source,
		new := self clone
		new url := source url
		new title := source title
		new localPath := source localPath
		new contents := source contents
		new description := source description
		new
	)
	
	build := method(
		page := self
		body := template interpolate
		
		file := File with(localPath) remove open
		file write(body)
		file close
	)
)


Article := Object clone do(
	// slots available from article
	title := nil // Article title
	body := nil // article body
	summary := nil // summary of article (first paragraph usually)
	date := nil // articel creation date
	slug := nil // the-slug
	url := nil // article url e.g. /11/5/3/some-article
	description := nil // description for meta tag
		
	localPath := "temp path to markup processed file"
	template := File with(sourceDir cloneAppendPath("templates/pages/article.html")) contents
	
	with := method(theTitle, theBody, theSummary, theDate, theSlug, theDescription,
		new := self clone
		new title := theTitle
		new body := theBody
		new summary := theSummary
		new date := theDate
		new slug := theSlug
		new description := theDescription
		new
	)
	
	build := method(
		self url := date year asString appendPathSeq(date month asString) appendPathSeq(date day asString) appendPathSeq(slug)
		lp := sourceDir cloneAppendPath("build") cloneAppendPath(url)
		Directory with(lp) createIfAbsent
		self localPath := lp cloneAppendPath("index.html")
		
		article := self
		self contents := template interpolate
		self
	)
)


Index := Object clone do(
	url := "/"
	localPath := sourceDir cloneAppendPath("build/index.html")
	title := nil
	template := File with(sourceDir cloneAppendPath("templates/pages/index.html")) contents
	description := Description ?description
	
	buildWithArticles := method(articles,
		loopTemp := template betweenSeq("<!-- loop articles !-->", "<!-- endloop articles !-->")
		self contents := Sequence clone
		contents appendSeq(template beforeSeq("<!-- loop articles !-->") interpolate)
		articles foreach(entry, contents appendSeq(loopTemp interpolate))
		contents appendSeq(template afterSeq("<!-- endloop articles !-->") interpolate)
		self
	)
)


Archive := Index clone do(
	url := "/archive"
	title := Description blogName .. " Archive"
	template := File with(sourceDir cloneAppendPath("templates/pages/archive.html")) contents
	description := Description blogName .. " archive"
	
	withArticles := method(articles, url,
		new := self clone
		new localPath := sourceDir cloneAppendPath("build/") cloneAppendPath(url) cloneAppendPath("index.html")
		Directory with(sourceDir cloneAppendPath("build/") cloneAppendPath(url)) createIfAbsent 
		new url := url
		new articles := articles
		new
	)
	
	build := method(
		buildWithArticles(articles)
	)
)

Feed := Object clone do(
	url := "feed.xml"
	title := nil
	template := File with(sourceDir cloneAppendPath("templates/feed.xml")) contents
	description := nil
	localPath := sourceDir cloneAppendPath("build/") cloneAppendPath("feed.xml")
	
	build := method(articles,
		loopTemp := template betweenSeq("<!-- loop articles !-->", "<!-- endloop articles !-->")
		buf := Sequence clone
		articles foreach(entry, buf appendSeq(loopTemp interpolate))
		self contents := (template beforeSeq("<!-- loop articles !-->") interpolate) .. buf .. (template afterSeq("<!-- endloop articles !-->") interpolate)
		
		file := File with(localPath) remove open
		file write(contents)
		file close
	)
)

StaticPage := Article clone do(
	build := method(
		self url := slug 
		lp := sourceDir cloneAppendPath("build") cloneAppendPath(url)
		Directory with(lp) createIfAbsent
		self localPath := lp cloneAppendPath("index.html")
		self contents := body
		self
	)
)

convertMarkdownFile := method(f, type, collect,
	slug := f baseName
	con := f contents
	infoMap := Map clone
	infolines := con beforeSeq("\n\n") split("\n")
	infolines foreach(l,
		key := l beforeSeq(":")
		infoMap atPut(key, l afterSeq(":") lstrip)
	)
	
	date := if (infoMap at("date"), 
		Date clone fromString(infoMap at("date"), "%Y/%m/%d %H:%m"),
		Date clone now
	)
	con = con afterSeq("\n\n")
	
	tempMDPath := sourceDir cloneAppendPath("working") cloneAppendPath(slug .. ".markdown")
	tempPath := sourceDir cloneAppendPath("working") cloneAppendPath(slug)
	
	File with(tempMDPath) remove open write(con) close
	Markdown parse(tempMDPath, tempPath)
	body := File with(tempPath) contents
	summary := body split("\n") first
	collect append(type with(infoMap at("title"), body, summary, date, slug, infoMap at("description")))
)


// ========================================================================

// create working dirs
Directory with(sourceDir cloneAppendPath("working")) createIfAbsent files foreach(remove)
Directory with(sourceDir cloneAppendPath("build")) createIfAbsent empty

"Finding articles..." println

// get the articles
articles := list clone
articleDir := Directory with(sourceDir cloneAppendPath("articles"))
articleDir files foreach(f, convertMarkdownFile(f, Article, articles))

"Generating pages for #{articles size asString} articles..." interpolate println

articles foreach(build)
articles sortInPlaceBy(block(a, b, (a date) > (b date)))

// generate full article pages 
articles foreach(article, Page with(article) build)

// find and build any static pages
pages := list clone
pagesDir := Directory with(sourceDir cloneAppendPath("pages"))
pagesDir files foreach(f, convertMarkdownFile(f, StaticPage, pages))
pages foreach(p, Page with(p build) build)

"Generating archive pages..." println

// makes the master archive
masterArchive := Archive withArticles(articles, "archive") build
Page with(masterArchive) build

// generate yearly and monthly archive pages
years := articles map(date year) unique
years foreach(y,
	yarticles := articles select(date year == y)
	ar := Archive withArticles(yarticles, (y asString .. "/")) build
	Page with(ar) build
	
	months := yarticles map(date month) unique
	months foreach(m,
		marticles := articles select(date month == m)
		ar := Archive withArticles(marticles, y asString cloneAppendPath(m asString .. "/")) build
		Page with(ar) build
	)
)

"Generating index and feed pages..." println

// create the index page. show the first 4 entries
Index buildWithArticles(articles slice(0, 4))
Page with(Index) build

// create the atom feed. use the newest 10 articles
Feed build(articles slice(0, 10))

// copy any static files
staticDir := Directory with(sourceDir cloneAppendPath("static"))
if (staticDir exists,
	buildPath := sourceDir cloneAppendPath("build")
	staticDir items foreach(i, i copyToPath(buildPath cloneAppendPath(i name)))
)

// cleanup
workingDir := Directory with(sourceDir cloneAppendPath("working")) 
workingDir files foreach(remove)
workingDir remove

"Blog update complete." println
