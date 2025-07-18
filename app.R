library(shiny)
library(shinyjs)
library(qdapDictionaries)

setwd("F:/blink-keyboard")

groups <- list(
  "A B C D E",
  "F G H I J",
  "K L M N O",
  "P Q R S T",
  "U V W X Y",
  "Z SPACE BACK"
)

ui <- fluidPage(
  useShinyjs(),
  titlePanel("Blink Keyboard - Blink Detection"),
  sidebarLayout(
    sidebarPanel(
      actionButton("start_blink", "Start Blink Detection"),
      br(), br(),
      verbatimTextOutput("blink_status"),
      h4("Current Group:"),
      uiOutput("group_ui"),
      h4("Letters:"),
      uiOutput("letters_ui"),
      uiOutput("confirm_ui")
    ),
    mainPanel(
      h3("Typed Text:"),
      verbatimTextOutput("typed_text"),
      h4("Suggestions:"),
      uiOutput("suggestions_ui")
    )
  )
)

server <- function(input, output, session) {
  state <- reactiveValues(
    mode = "select_group",
    group_idx = 1,
    letter_idx = 1,
    selected_letter = NULL,
    typed_word = ""
  )
  
  observeEvent(input$start_blink, {
    writeLines("0", "blink_flag.txt")
    system('cmd /c "cd /d F:/blink-keyboard && python blink_detector.py"', wait = FALSE)
    showNotification("Blink detection started.", type = "message")
  })
  
  observe({
    invalidateLater(300, session)
    if (file.exists("blink_flag.txt")) {
      val <- readLines("blink_flag.txt", warn = FALSE)
      if (length(val) > 0 && val != "0") {
        blinks <- as.numeric(val)
        if (!is.na(blinks)) {
          if (blinks >= 2) {
            blink_action("select")
          } else if (blinks == 1) {
            blink_action("next")
          }
        }
        writeLines("0", "blink_flag.txt")  # Reset
      }
    }
  })
  
  blink_action <- function(action) {
    cat("Blink Action:", action, " | Mode:", state$mode, "\n")  # Debug
    
    if (state$mode == "select_group") {
      if (action == "next") {
        state$group_idx <- (state$group_idx %% length(groups)) + 1
        state$letter_idx <- 1
      } else if (action == "select") {
        state$mode <- "select_letter"
      }
      
    } else if (state$mode == "select_letter") {
      letters <- unlist(strsplit(groups[[state$group_idx]], " "))
      if (action == "next") {
        state$letter_idx <- (state$letter_idx %% length(letters)) + 1
      } else if (action == "select") {
        state$selected_letter <- letters[state$letter_idx]
        state$mode <- "confirm_letter"
      }
      
    } else if (state$mode == "confirm_letter") {
      if (action == "select") {
        letter <- state$selected_letter
        if (!is.null(letter)) {
          if (letter == "SPACE") {
            state$typed_word <- paste0(state$typed_word, " ")
          } else if (letter == "BACK") {
            if (nchar(state$typed_word) > 0) {
              state$typed_word <- substr(state$typed_word, 1, nchar(state$typed_word) - 1)
            }
          } else {
            state$typed_word <- paste0(state$typed_word, letter)
          }
        }
        # Reset
        state$mode <- "select_group"
        state$group_idx <- 1
        state$letter_idx <- 1
        state$selected_letter <- NULL
      } else if (action == "next") {
        state$mode <- "select_letter"
        state$selected_letter <- NULL
      }
    }
  }
  
  output$blink_status <- renderText({
    paste0("Mode: ", state$mode, 
           if (!is.null(state$selected_letter)) paste0(" | Selected: ", state$selected_letter) else "")
  })
  
  output$group_ui <- renderUI({
    HTML(paste0("<b>", groups[[state$group_idx]], "</b>"))
  })
  
  output$letters_ui <- renderUI({
    if (state$mode %in% c("select_letter", "confirm_letter")) {
      letters <- unlist(strsplit(groups[[state$group_idx]], " "))
      letters_html <- sapply(seq_along(letters), function(i) {
        if (state$mode == "select_letter" && i == state$letter_idx) {
          paste0("<b><u>", letters[i], "</u></b>")
        } else if (state$mode == "confirm_letter" && state$selected_letter == letters[i]) {
          paste0("<span style='color:green'><b>", letters[i], "</b></span>")
        } else {
          letters[i]
        }
      })
      HTML(paste(letters_html, collapse = " "))
    } else {
      ""
    }
  })
  
  output$confirm_ui <- renderUI({
    if (state$mode == "confirm_letter") {
      HTML("<i>Double blink = Confirm | Single blink = Cancel</i>")
    } else {
      ""
    }
  })
  
  output$typed_text <- renderText({
    state$typed_word
  })
  
  output$suggestions_ui <- renderUI({
    word <- tolower(state$typed_word)
    if (nchar(word) > 0) {
      matches <- GradyAugmented[startsWith(tolower(GradyAugmented), word)]
      if (length(matches) > 0) {
        HTML(paste(matches[1:min(5, length(matches))], collapse = ", "))
      } else {
        "No suggestions"
      }
    } else {
      ""
    }
  })
}

shinyApp(ui, server)
