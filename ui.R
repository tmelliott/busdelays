fluidPage(
    sidebarLayout(
        sidebarPanel(
            h1("Auckland Bus Delays"),
            hr()
            # textOutput("connected")
        ),
        mainPanel(
            plotOutput("mainplot")#, width = 800, height = 400)
        )
    )
)