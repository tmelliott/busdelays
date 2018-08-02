function(input, output) {
    output$mainplot <- renderPlot({
        delayplot()
    })
}
