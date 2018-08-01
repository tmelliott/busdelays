library(RSQLite)
library(dbplyr)

db <- "data/history.db"
if (!file.exists(db))
    stop("Please unzip the database first")

## connection function
connect <- function() dbConnect(SQLite(), db)

function(input, output) {
    con <- connect()
    connected <- ifelse(dbIsValid(con), "connected", "couldn't connect")
    output$connected <- renderText(sprintf("Database %s", connected))
    dbDisconnect(con)
}
