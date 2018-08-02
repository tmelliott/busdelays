library(RSQLite)
library(tidyverse)
library(dbplyr)
library(lubridate)

load('data/summary.rda')
dows <- c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
          "Saturday", "Sunday")
smry.overall <- do.call(
    bind_rows,
    lapply(names(daysmry$overall),
           function(x)
               daysmry$overall[[x]] %>%
               add_column(date = ymd(x), .before = 1))) %>%
    mutate(dow = date %>% format("%A") %>%
               factor(levels = dows)) %>%
    gather("ontime", "percent", percent_ontime, percent_early, percent_late) %>%
    mutate(n = round(n * percent),
           week.n = date %>% format("%Y-%V"),
           ontime = factor(ontime, levels = c('percent_ontime', 'percent_late', 'percent_early')))

smry.stop <- do.call(
    bind_rows,
    lapply(names(daysmry$stop),
           function(x)
               daysmry$stop[[x]] %>%
               add_column(date = ymd(x), .before = 1))) %>%
    mutate(dow = date %>% format("%A") %>%
               factor(levels = dows)) %>% 
    group_by(stop_sequence) %>%
    do((.) %>% gather("ontime", "percent", percent_ontime, percent_early, percent_late)) %>%
    ungroup() %>%
    mutate(n = round(n * percent),
           week.n = date %>% format("%Y-%V"),
           ontime = factor(ontime, levels = c('percent_ontime', 'percent_late', 'percent_early')))

delayplot <- function(stop.n = 0, dayofweek = 0, peak = FALSE) {
    if (stop.n == 0)
        d <- smry.overall
    else if (stop.n > 0)
        d <- smry.stop %>% filter(stop_sequence == stop.n)
    else 
        d <- smry.stop

    if (dayofweek > 0) 
        d <- d %>% filter(dow == dows[dayofweek])

    p <- ggplot(d, aes(date, percent * 100, colour = ontime)) + ylim(0, 100)

    if (stop.n == -1 && dayofweek == -1) {
        p <- p + facet_grid(ontime ~ dow) + geom_path(aes(x = stop_sequence, group = week.n))
    } else if (stop.n == -1) {
        p <- p + facet_grid(ontime ~ .) + geom_path(aes(x = stop_sequence, group = week.n))
    } else if (dayofweek == -1) {
        p <- p + facet_grid(ontime ~ .) + geom_path(aes(x = dow, group = week.n))
    } else {
         p <- p + geom_path()
    }
    p + scale_color_brewer(palette = "Set2")
}