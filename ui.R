fluidPage(
    sidebarLayout(
        sidebarPanel(
            h1("Auckland Bus Delays"),
            hr(),
            sliderInput("stop.n", "Stop Number: 0 = all, -1 = show separately", 0, min = -1, max = 50, step = 1),
            sliderInput("dow", "Day of the Week: 0 = all, -1 = show separately", 0, min = -1, max = 7, step = 1)
        ),
        mainPanel(
            plotOutput("mainplot")#, width = 800, height = 400)
        )
    )
)