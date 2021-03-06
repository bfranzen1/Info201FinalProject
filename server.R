library(httr)
library(jsonlite)
library(ggplot2)
source('searchGame.R')
source("gameComparison.R")
source('top.R')
server <- function(input, output) {
  #checks if search button is clicked
  #does nothing if not, otherwise
  #gets list of games based on text in search
  data <- reactive({
    if(input$search==0) {
      return(NULL)
    } else {
      isolate({
        gameList <- games(input$game)
        names <- nameList(gameList)
      }) 
    }
  })
  #gets game data from game that was
  #selected from drop down
  game <- reactive({
       names <- data()
       choice <- input$choices
       id <- names[choice][[1]]
       return(gameData(id))
    })
  
  #displays drop down of games based on search text
  output$choice <- renderUI({
    names <- data()
    selectInput("choices", "Choices", colnames(names))
  })
  
  #outputs UI page containing information about game
  #selected form drop down 
  output$page <- renderUI({
    gameInfo <- game()
    if(!is.null(gameInfo$summary)) {
      if (!is.null(gameInfo$total_rating)) {
        gameInfo$total_rating <- paste0(round(as.numeric(gameInfo$total_rating)), "%") 
      }
      if (!is.null(gameInfo$release_dates)) {
        gameInfo$release_dates[[1]][[5]][[1]] <- paste0("Release Date: ", gameInfo$release_dates[[1]][[5]][[1]])  
      }
      if (!is.null(gameInfo$total_rating_count)) {
        gameInfo$total_rating_count <- paste0("based on ", gameInfo$total_rating_count, " reviews")
      }
      if (!is.null(gameInfo$platforms)) {
        gameInfo$platforms <- idToName(gameInfo$platforms[[1]], "platforms/")
      }
      if (!is.null(gameInfo$themes)) {
        gameInfo$themes <- idToName(gameInfo$themes[[1]], "themes/")
      }
      gameInfo$screenshots[[1]][[1]][[1]] <- gsub("t_thumb", "t_screenshot_big", gameInfo$screenshots[[1]][[1]][[1]])
      withTags({
        div(
          h1(gameInfo$name),
          h3(paste(gameInfo$total_rating, gameInfo$total_rating_count)),
          h4(gameInfo$release_dates[[1]][[5]][[1]]),
          h5(gameInfo$platforms),
          h5(gameInfo$themes),
          img(src=gameInfo$screenshots[[1]][[1]][[1]]),
          p(gameInfo$summary),
          p(gameInfo$storyline),
          a(href=gameInfo$url, "More Information here!")
        )
      })
    } else {
      print("No Information to Display")
    }
  })
  
  #compares current game from drop down against
  #radio button selected (developers, genres, themes, year, platform, franchise)
  output$comparisons <- renderPlot({
    gameInfo <- game()
    
    #plot for company/developer
    if(!is.null(gameInfo$developers) & input$compareField == "Developer") {
      plotData("developers", gameInfo$developers[[1]][1], gameInfo, input$compareField, "companies/")
    }
    
    #plot for genres
    else if(!is.null(gameInfo$genres) & input$compareField == "Genre") {
      plotData("genres", gameInfo$genres[[1]][1], gameInfo, input$compareField, "genres/")
    }
    
    #plot for theme
    else if(!is.null(gameInfo$themes) & input$compareField == "Theme") {
      plotData("themes", gameInfo$themes[[1]][1], gameInfo, input$compareField, "themes/")
    }
    
    else if(input$compareField == "Year") {
      yearData <- compareField("release_dates.y", gameInfo$release_dates[[1]][[6]][[1]],5)
      ggplot(yearData) + geom_bar(aes(x=name, y=total_rating), stat="identity", fill="gray8") + 
        geom_bar(data=gameInfo, aes(x=name, y=total_rating), stat="identity", fill="red4") + 
        coord_flip() + theme(legend.position="none") + ggtitle(paste0("Comparison with the top five games from ", gameInfo$release_dates[[1]][[6]][[1]])) +
        ylab("Rating(%)") + xlab("Name of Game")
    }
    
    else if(input$compareField == "Platform") {
      platformData <- compareField("release_dates.platform", gameInfo$platforms[[1]][2],5)
      platformName <- idToName(gameInfo$platforms[[1]][1], "platforms/")
      ggplot(platformData) + geom_bar(aes(x=name, y=total_rating), stat="identity", fill="gray8") + 
        geom_bar(data=gameInfo, aes(x=name, y=total_rating), stat="identity", fill="red4") + 
        coord_flip() + theme(legend.position="none") + ggtitle(paste0("Comparison with the top five games made on ", platformName)) +
        ylab("Rating(%)") + xlab("Name of Game")
    }
    
    else if(!is.null(gameInfo$franchise) & input$compareField == "Franchise") {
      plotData("franchises", gameInfo$franchise, gameInfo, input$compareField, "franchises/")
    }
    else{
      print("")
    }
  })
  
  #function that renders choices for chosen categories 
  output$categoryChoices <- renderUI({
    catData <- categoryData()
    cat <- filter(catData, name == input$categoryField)
    selectInput("categories", "Category", getCategoryIds(cat$value)$name)
  })
  
  #renders plot of top five games from selected category
  output$categoryPlot <- renderPlotly({
    catData <- categoryData()
    cat <- filter(catData, name == input$categoryField)
    catIds <- getCategoryIds(cat$value)
    catId <- filter(catIds, name == input$categories)
    if(input$categoryField == "Genre") {
      plotDataTop("genres", catId$id, cat$name, "genres/", input$yearSlider, input$countSlider)
    } else if (input$categoryField == "Company") {
      plotDataTop("developers", catId$id, cat$name, "companies/", input$yearSlider, input$countSlider)
    } else if (input$categoryField == "Game Engine") {
      plotDataTop("game_engines", catId$id, cat$name, "game_engines/", input$yearSlider, input$countSlider)
    } else if (input$categoryField == "Platform") {
      plotDataTop("release_dates.platform", catId$id, cat$name, "platforms/", input$yearSlider, input$countSlider)
    } else if (input$categoryField == "Theme") {
      plotDataTop("themes", catId$id, cat$name, "themes/", input$yearSlider, input$countSlider)
    }
  })
}