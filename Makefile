README.md: README.Rmd
	@R --slave -e "rmarkdown::render('$<')"
	@rm README.html