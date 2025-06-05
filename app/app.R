#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
# 
# Copyright © 2025, Umeå Plant Science Center, Swedish University Of Agricultural Sciences, Umeå, Sweden
# All rights reserved.
# 
# Developers: Adrien Heymans
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted under the GNU General Public License v3 and provided that the following conditions are met:
#   
#   1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
# 
# Disclaimer
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# You should have received the GNU GENERAL PUBLIC LICENSE v3 with this file in license.txt but can also be found at http://www.gnu.org/licenses/gpl-3.0.en.html
# 
# NOTE: The GPL.v3 license requires that all derivative work is distributed under the same license. That means that if you use this source code in any other program, you can only distribute that program with the full source code included and licensed under a GPL license.


library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(svglite)

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .app-header {
        background-color: #f5f5f5;
        padding: 20px 20px 10px 20px;
        margin-bottom: 20px;
        border-bottom: 1px solid #ddd;
      }
      .header-title {
        font-size: 28px;
        font-weight: bold;
        margin-bottom: 10px;
      }
      .header-text {
        font-size: 14px;
        color: #555;
      }
    "))
  ),
  
  # Header section
  fluidRow(
    column(12, class = "app-header",
           div("Apical Hook Kinetics Analyzer", class = "header-title"),
           div(class = "header-text",
               tags$p("One critical early-stage process in plant development, known as the apical hook, protects the shoot meristem as dicot seedlings emerge from the soil. It unfolds in three distinct phases: formation, maintenance, and opening."),
               tags$p("This Shiny app allows users to analyze the kinematics of apical hook angles from ", a("DLhook",href = "https://github.com/SRobertGroup/DLhook/", target = "_blank")," CSV files, a high-throughput apical hook phenotyping software of dark-grown Arabidopsis thaliana seedlings."
               )
           )
    )
  ),
  
  sidebarLayout(
    sidebarPanel(
      
      
      fileInput("files", "Upload CSV files", multiple = TRUE, accept = ".csv"),
      checkboxInput("shared_time", "All CSVs share the same time points", value = TRUE),
      checkboxInput("time_in_name", "Extract time from image file names", value = FALSE),
      textInput("time_input", "Time points (comma-separated)", placeholder = "e.g. 0, 10, 20, 30, 40"),
      actionButton("plot_btn", "Generate Plot"),
      hr(),
      downloadButton("download_png", "Download PNG"),
      downloadButton("download_svg", "Download SVG"),
      hr(),
      hr(),
      # Logo
      img(src = "logos.png", class = "logo-img",width = "100%"),
      div("This app was developed by Adrien Heymans from ", a("Stéphanie Robert Group", href = "https://srobertgroup.com/", target = "_blank")," using the R Shiny framework.")
    ),
    
    mainPanel(
      plotOutput("anglePlot"),
      verbatimTextOutput("msg")
    )
    
    
  )
)


server <- function(input, output) {
  
  plot_data <- reactiveVal(NULL)
  
  observeEvent(input$plot_btn, {
    req(input$files)
    
    file_list <- input$files
    data_list <- list()
    
    if (!input$time_in_name) {
      time_series_text <- input$time_input
      if (time_series_text == "") {
        output$msg <- renderText("Please enter time points before plotting.")
        return()
      }
      
      time_vector <- as.numeric(strsplit(time_series_text, ",")[[1]])
      if (any(is.na(time_vector))) {
        output$msg <- renderText("Time points must be numeric and comma-separated.")
        return()
      }
    }
    
    for (i in seq_len(nrow(file_list))) {
      file_path <- file_list$datapath[i]
      file_label <- file_list$name[i]
      
      df <- read_csv(file_path, show_col_types = FALSE)
      
      if (!"img_name" %in% names(df)) {
        output$msg <- renderText(paste("Missing 'img_name' column in file:", file_label))
        return()
      }
      
      long_df <- df |>
        pivot_longer(-img_name, names_to = "sample_id", values_to = "angle") |>
        mutate(sample_id = as.character(sample_id),
               file = file_label)
      
      if (input$time_in_name) {
        long_df$time <- as.numeric(str_extract(long_df$img_name, "\\d+"))
        if (any(is.na(long_df$time))) {
          output$msg <- renderText(
            paste("Could not extract numeric time from some 'img_name' entries in:", file_label)
          )
          return()
        }
      } else {
        n_img <- length(unique(long_df$img_name))
        if (!input$shared_time && length(time_vector) != n_img) {
          output$msg <- renderText(
            paste("Time points must match number of images in file:", file_label)
          )
          return()
        }
        long_df$time <- rep(time_vector, each = length(unique(long_df$sample_id)))
      }
      
      data_list[[file_label]] <- long_df
    }
    
    full_data <- bind_rows(data_list)
    
    summary_data <- full_data |>
      group_by(file, time) |>
      summarise(
        mean_angle = mean(angle, na.rm = TRUE),
        sd_angle = sd(angle, na.rm = TRUE),
        .groups = "drop"
      )
    
    plot_data(summary_data)
  
    
    output$anglePlot <- renderPlot({
      ggplot(summary_data, aes(x = time, y = 180-mean_angle, color = file)) +
        geom_line() +
        geom_point() +
        geom_hline(yintercept = 180, linetype = 2)+
        geom_errorbar(aes(ymin = 180-mean_angle - sd_angle, ymax = 180-mean_angle + sd_angle), width = 0.2) +
        labs(
          title = "Apical Hook Angle Kinetics",
          x = "Time",
          y = "Angle (degrees)",
          color = "Dataset (CSV file)"
        ) +
        theme_classic()
    })
    
    output$msg <- renderText("")
  })
  
  # Download handlers
  output$download_png <- downloadHandler(
    filename = function() "hook_kinetics_plot.png",
    content = function(file) {
      req(plot_data())
      pl = ggplot(plot_data(), aes(x = time, y = 180-mean_angle, color = file)) +
        geom_line() +
        geom_point() +
        geom_hline(yintercept = 180, linetype = 2)+
        geom_errorbar(aes(ymin = 180-mean_angle - sd_angle, ymax = 180-mean_angle + sd_angle), width = 0.2) +
        labs(
          title = "Apical Hook Angle Kinetics",
          x = "Time [hour]",
          y = "Angle (degrees)",
          color = "Dataset (CSV file)"
        ) +
        theme_classic()
      
      ggsave(file, plot = pl, width = 8, height = 8, dpi = 100)
    }
  )
  
  output$download_svg <- downloadHandler(
    filename = function() "hook_kinetics_plot.svg",
    content = function(file) {
      req(plot_data())
      pl = ggplot(plot_data(), aes(x = time, y = 180-mean_angle, color = file)) +
        geom_line() +
        geom_point() +
        geom_hline(yintercept = 180, linetype = 2)+
        geom_errorbar(aes(ymin = 180-mean_angle - sd_angle, ymax = 180-mean_angle + sd_angle), width = 0.2) +
        labs(
          title = "Apical Hook Angle Kinetics",
          x = "Time",
          y = "Angle (degrees)",
          color = "Dataset (CSV file)"
        ) +
        theme_classic()
      
      ggsave(file, plot = pl, width = 8, height = 8, dpi = 100)
    }
  )
}

shinyApp(ui, server)
