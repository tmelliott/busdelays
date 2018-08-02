library(tidyverse)
library(dbplyr)

db <- "history.db"
con <- RSQLite::dbConnect(RSQLite::SQLite(), db)

## Step 1: delete every row that isn't a departure delay
r <- RSQLite::dbSendQuery(con, "DELETE FROM trip_updates WHERE departure_delay IS NULL")
RSQLite::dbClearResult(r)
RSQLite::dbGetQuery(con, "SELECT count(*) FROM trip_updates")

## Step 2: create index on timestamp, departure_delay columns
RSQLite::dbClearResult(RSQLite::dbSendQuery(con, "CREATE INDEX Idx1 ON trip_updates(timestamp)"))
RSQLite::dbClearResult(RSQLite::dbSendQuery(con, "CREATE INDEX Idx12 ON trip_updates(departure_delay)"))

## Step 3: delete singleton observations and trips that are clearly in the wrong place

RSQLite::dbGetQuery(con, "SELECT count(*) FROM trip_updates WHERE departure_delay < -3600 OR departure_delay > 2*3600")
RSQLite::dbGetQuery(con, "SELECT count(*) FROM trip_updates WHERE departure_delay < -18000 OR departure_delay > 18000")

date <- "2018-02-01"
tstart <- as.integer(as.POSIXct(date, origin = "1970-01-01"))
tend <- tstart + 86400L

q <- RSQLite::dbSendQuery(con, "SELECT vehicle_id, trip_id, timestamp, stop_sequence, departure_delay FROM trip_updates WHERE timestamp >= ? AND timestamp < ?")
RSQLite::dbBind(q, list(tstart, tend))
r <- RSQLite::dbFetch(q)
RSQLite::dbClearResult(q)

d <- tbl(con, "trip_updates") %>%
    select(vehicle_id, trip_id, timestamp, stop_sequence, departure_delay) %>%
    filter(timestamp >= tstart & timestamp < tend)

ggplot(d, aes(timestamp, departure_delay/60/60)) + geom_point() +
    geom_point(data = d %>% filter(stop_sequence > 1), colour = 'orangered') +
    geom_hline(aes(yintercept = -1), color = 'blue') +
    geom_hline(aes(yintercept = 2), color = 'blue')

