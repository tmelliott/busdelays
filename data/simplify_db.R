library(tidyverse)
library(RSQLite)
library(dbplyr)

db <- "history.db"
con <- dbConnect(SQLite(), db)

# ## Step 1: delete every row that isn't a departure delay
# r <- dbSendQuery(con, "DELETE FROM trip_updates WHERE departure_delay IS NULL")
# dbClearResult(r)
# dbGetQuery(con, "SELECT count(*) FROM trip_updates")

# ## Step 2: create index on timestamp, departure_delay columns
# dbClearResult(dbSendQuery(con, "CREATE INDEX Idx1 ON trip_updates(timestamp)"))
# dbClearResult(dbSendQuery(con, "CREATE INDEX Idx2 ON trip_updates(departure_delay)"))
# dbClearResult(dbSendQuery(con, "CREATE INDEX Idx3 ON trip_updates(stop_sequence)"))

## Step 3: delete singleton observations and trips that are clearly in the wrong place

dbGetQuery(con, "SELECT count(*) FROM trip_updates WHERE departure_delay < -3600 OR departure_delay > 2*3600")
dbGetQuery(con, "SELECT count(*) FROM trip_updates WHERE departure_delay < -18000 OR departure_delay > 18000")

date <- "2018-02-01"
tstart <- as.integer(as.POSIXct(date, origin = "1970-01-01"))
tend <- tstart + 86400L

q <- dbSendQuery(con, "SELECT vehicle_id, trip_id, timestamp, stop_sequence, departure_delay FROM trip_updates WHERE timestamp >= ? AND timestamp < ?")
dbBind(q, list(tstart, tend))
r <- dbFetch(q)
dbClearResult(q)

d <- tbl(con, "trip_updates") %>%
    select(vehicle_id, trip_id, timestamp, stop_sequence, departure_delay) %>%
    filter(timestamp >= tstart & timestamp < tend)

ggplot(d, aes(timestamp, departure_delay/60/60)) + geom_point() +
    geom_point(data = d %>% filter(stop_sequence > 1), colour = 'orangered') +
    geom_hline(aes(yintercept = -1), color = 'blue') +
    geom_hline(aes(yintercept = 2), color = 'blue')


## March
library(lubridate)
month <- ymd_hms("2017-10-01 00:00:00", tz = "Pacific/Auckland")
tstart <- as.integer(as.POSIXct(month))
tend <- as.integer(as.POSIXct(month + months(1)))
d <- tbl(con, "trip_updates") %>%
    filter(timestamp >= tstart & timestamp < tend & stop_sequence == 1) %>%
    mutate(date = strftime('%Y-%m-%d', datetime(timestamp, 'unixepoch', 'localtime')),
           time = strftime('%H:%M:%S', datetime(timestamp, 'unixepoch', 'localtime')))

ggplot(d, aes(timestamp, departure_delay/60/60)) + geom_point() + facet_wrap(~date, scales="free_x")

dd <- d %>% group_by(date) %>%
    summarize(ontime = sum(departure_delay >= -60 & departure_delay <= 300, na.rm = TRUE),
              early = sum(departure_delay < -60, na.rm = TRUE),
              early2 = sum(departure_delay < -60 & departure_delay > -1800, na.rm = TRUE),
              late = sum(departure_delay > 300, na.rm = TRUE),
              late2 = sum(departure_delay > 300 & departure_delay < 3600, na.rm = TRUE),
              n = n()) %>%
    collect() %>%
    mutate(invalid = n - ontime - early2 - late2, nvalid = n - invalid)

dd2 <- dd %>% 
    mutate(p_ontime = ontime / n, p_ontime2 = ontime / nvalid,
           p_early = early / n, p_early2 = early2 / nvalid,
           p_late = late / n, p_late2 = late2 / nvalid) %>%
    gather(key = "ontime", value = "percent", p_ontime, p_ontime2, p_early, p_early2, p_late, p_late2)

ggplot(dd2, aes(as.Date(date), percent, group = ontime, color = ontime)) + 
    geom_path() + scale_y_continuous(breaks = 0:5*0.2, limits = 0:1)


