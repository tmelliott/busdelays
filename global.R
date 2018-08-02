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
               factor(levels = dows))


delayplot <- function(...) {
    ggplot(smry.overall, aes(date)) +
        geom_line(aes(y = percent_ontime * 100)) +
        geom_line(aes(y = percent_early * 100)) +
        geom_line(aes(y = percent_late * 100))

}