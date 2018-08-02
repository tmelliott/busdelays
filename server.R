function(input, output) {
    output$mainplot <- renderPlot({
        delayplot(input$stop.n, input$dow)
    })
}
