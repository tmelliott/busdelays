
library(tidyverse)
library(dbplyr)
library(RSQLite)
library(lubridate)

con <- dbConnect(SQLite(), "history.db")

delays <- tbl(con, 'trip_updates') %>%
    mutate(date = strftime('%Y-%m-%d', datetime(timestamp, 'unixepoch', 'localtime')),
           time = strftime('%H:%M:%S', datetime(timestamp, 'unixepoch', 'localtime')))

daysmry <- list(overall = list(),
                peak = list(),
                stop = list(),
                peak.stop = list())

DATES <- seq(as.Date("2017-04-01"), as.Date("2018-04-01") - 1, by = 1) %>% as.character

TSTART <- Sys.time()
cat(" * Processing ")
for (DATE in DATES) {
    cat("\r * Processing", DATE)
    pt <- as.POSIXct(paste(DATE, c("6:00:00", "9:30:00", "14:30:00", "19:00:00"))) %>%
        as.numeric
    
    d <- delays %>%
        filter(!is.na(departure_delay) & date == DATE &
               departure_delay > -60*60) %>%
        mutate(delay = departure_delay,
               ontime = case_when(departure_delay < -60*60 | departure_delay > 60*60 ~ 'invalid',
                                  departure_delay < -60 ~ 'early',
                                  departure_delay > 300 ~ 'late',
                                  TRUE ~ 'ontime'),
               peak = case_when(between(timestamp, !!pt[1], !!pt[2]) ~ 'morning peak',
                                between(timestamp, !!pt[2], !!pt[3]) ~ 'off-peak',
                                between(timestamp, !!pt[3], !!pt[4]) ~ 'evening peak',
                                TRUE ~ ''))
    
    ## overall delay
    pct.overall <- d %>% group_by(ontime) %>% summarize(n = n())

    # summarize(percent_early = mean(ontime == 'early', na.rm = TRUE),
    #                                percent_ontime = mean(ontime == 'ontime', na.rm = TRUE),
    #                                percent_late = mean(ontime == 'late', na.rm = TRUE),
    #                                n = n())
    
    ## delay by peak
    pct.peak <- d %>% group_by(peak, ontime) %>% summarize(n = n())
        # summarize(percent_early = mean(ontime == 'early', na.rm = TRUE),
        #           percent_ontime = mean(ontime == 'ontime', na.rm = TRUE),
        #           percent_late = mean(ontime == 'late', na.rm = TRUE),
        #           n = n())
    
    ## delay by stop number
    pct.stop <- d %>% group_by(stop_sequence, ontime) %>% summarize(n = n())
        # summarize(percent_early = mean(ontime == 'early', na.rm = TRUE),
        #           percent_ontime = mean(ontime == 'ontime', na.rm = TRUE),
        #           percent_late = mean(ontime == 'late', na.rm = TRUE),
        #           n = n())

    ## delay by peak * stop number
    pct.peak.stop <- d %>% group_by(peak, stop_sequence, ontime) %>% summarize(n = n())
        # summarize(percent_early = mean(ontime == 'early', na.rm = TRUE),
        #           percent_ontime = mean(ontime == 'ontime', na.rm = TRUE),
        #           percent_late = mean(ontime == 'late', na.rm = TRUE),
        #           n = n())

    ## retrieve values from the database
    daysmry$overall[[DATE]] <- pct.overall %>% collect
    daysmry$peak[[DATE]] <- pct.peak %>% collect
    daysmry$stop[[DATE]] <- pct.stop %>% collect
    daysmry$peak.stop[[DATE]] <- pct.peak.stop %>% collect

    save(daysmry, file = "summary.rda.partial")
    file.rename("summary.rda.partial", "summary.rda")
}

TEND <- Sys.time()
TDIFF <- as.numeric(TEND - TSTART)
diffstring <- try({
    gsub(".+~|)", "", as.character(dseconds(TDIFF)))
}, silent = TRUE)
if (inherits(diffstring, "try-error")) 
    diffstring <- paste(TDIFF, "seconds")

cat(sep = "", "\r * Processing complete (", diffstring, ")\n")
