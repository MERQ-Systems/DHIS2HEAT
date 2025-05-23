library(shiny)
library(shinydashboard) # for Dashboard
library(shinyWidgets) # for radio button widgets
library(shinydashboardPlus)
library(shinyjs) # to perform common useful JavaScript operations in Shiny apps
library(shinyBS) # for bsTooltip function
library(shinyalert) # for alert message very nice format
library(plyr) # empty() function is from this package
library(dplyr) # select functions are covered in the require
library(DT) # for using %>% which works as a pipe in R code
library(ggplot2)
library(plotly)
library(scales) ## used to format date like only month or month and year
library(colorspace) # to generate Rainbow coloring function
library(pastecs) # for descriptive statistics
library(shinycssloaders)
library(gridlayout)
library(bslib)
library(colourpicker)
library(httr)
library(openxlsx)
library(tidyr)
library(arrow) # Add arrow library for Parquet support
library(rjson)
library(jsonlite)
library(slickR)

# Source the UI and server components of data exploration and cleaning
# source("exclean.R")
# source("clean.R", local = TRUE)$value
source("exclean.R", local = TRUE)$value
source("ethgeo.R", local = TRUE)$value
source("dba.R", local = TRUE)$value
# source("geoheatmap.R", local = TRUE)$value

# Custom CSS for hiding the sidebar and settings
css <- "

"

# Define specific organisation units (regions)
specific_org_units <- c(
  "yY9BLUUegel", "UFtGyqJMEZh", "yb9NKGA8uqt", "Fccw8uMlJHN",
  "tDoLtk2ylu4", "G9hDiPNoB7d", "moBiwh9h5Ce", "b9nYedsL8te",
  "XU2wpLlX4Vk", "xNUoZIrGKxQ", "PCKGSJoNHXi", "a2QIIR2UXcd",
  "HIlnt7Qj8do", "Gmw0DJLXGtx"
)

# Define UI
ui <- tagList(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  div(
    id = "preloader",
    tags$a(
      img(src = "moh_logo_blue.svg", height = "100px"),
      href = "#",
      # style = "color: #007BDDFF; font-weight: bold; font-size: 16px; padding: 15px;",
      # " Ministry of Health - ETHIOPIA"
    ),
    hr(),
    div(
      class = "progress-container",
      div(id = "progress-bar", class = "progress-bar"),
      div(id = "progress-percent", class = "progress-percent", "0%") # Add this line
    ),
    div(
      class = "loader-text loading-pulse",
      # p("Loading Health Equity Assessment Dashboard..."),
      HTML("<span>Loading </span><span style='color: #007dc9; font-weight: bold;'>Health Equity Assessment </span><span>Dashboard...</span>"),
      hr(),
      tags$img(src = "dhis2-icon.svg", height = "50px"),
      HTML("<span style='color: #009BDDFF; font-weight: bold;'>DHIS2 </span><span>Data Fetcher for </span><span style='color: #007dc9; font-weight: bold;'>HEAT </span><span style='color: #b5e71c; font-weight: bold;'>Plus(+)</span>"),
    ),
    tags$script(HTML("
    // Simulate progress
    let progress = 0;
    const progressBar = document.getElementById('progress-bar');
    const progressPercent = document.getElementById('progress-percent'); // Add this line
    const startTime = Date.now();
    const minDuration = 27000; // Minimum duration in milliseconds (45 seconds)
    const progressInterval = setInterval(() => {
      const elapsedTime = Date.now() - startTime;
      progress += Math.random() * 7; // Adjust the increment to control the speed
      progress = Math.min(progress, 100);
      progressBar.style.width = progress + '%';
      progressPercent.textContent = Math.floor(progress) + '%'; // Add this line

      if (progress >= 100 && elapsedTime >= minDuration) {
        clearInterval(progressInterval);
      }
    }, 200);

    // Hide preloader when Shiny is ready
    $(document).on('shiny:connected', function(event) {
      const elapsedTime = Date.now() - startTime;
      const remainingTime = Math.max(0, minDuration - elapsedTime);
      setTimeout(() => {
        clearInterval(progressInterval);
        progressBar.style.width = '100%';
        progressPercent.textContent = '100%'; // Add this line
        setTimeout(() => {
          $('#preloader').fadeOut(500, function() {
            $(this).remove();
          });
        }, 300);
      }, remainingTime);
    });
  "))
  ),
  shinyjs::useShinyjs(),
  navbarPage(
    # title = div(img(src = "dhis2-icon.svg", height = "30px"),
    #            "DHIS2 Data Fetcher"),
    title = tags$div(
      tags$img(src = "dhis2-icon.svg", height = "50px"),
      HTML("<span style='color: #d7d7d7;'>DHIS2 Data Fetcher for </span><span style='color: #007dc9; font-weight: bold;'>HEAT </span><span style='color: #b5e71c; font-weight: bold;'>Plus(+)</span>")
    ),
    id = "main_nav",
    windowTitle = "DHIS2 Data Fecher & Visualizations for HEAT+",
    # theme = shinytheme("flatly"),

    # Conditionally display "Home" tab for non-logged-in users
    conditionalPanel(
      condition = "output.logged_in == false",
      tabPanel("Home",
        value = "home",
        fluidPage(
          class = "start-page",
          tags$a(
            img(src = "moh_logo_blue.svg", height = "100px"),
            href = "#",
            # style = "color: #007BDDFF; font-weight: bold; font-size: 16px; padding: 15px;",
            # " Ministry of Health - ETHIOPIA"
          ),
          hr(),
          hr(),
          h1("Welcome To"),
          tags$img(src = "dhis2-icon.svg", height = "50px"),
          HTML("<span style='color: #009BDDFF; font-weight: bold;'>DHIS2 </span><span>Data Fetcher for </span><span style='color: #007dc9; font-weight: bold;'>HEAT </span><span style='color: #b5e71c; font-weight: bold;'>Plus(+)</span>"),
          hr(),
          p("Comprehensive data management and Health Equity Assessment and Analysis platform"),
          p("Use demo/demo for username and password to login and test the system"),
          p("You can also register and create your account to test the system"),
          hr(),
          hr(),
          actionButton("login_btn", "Login", class = "btn-primary"),
          actionButton("register_btn", "Register", class = "btn-success"),
          hr(),
          hr(),
          # Content Slider
          div(
            class = "section animated fadeIn",
            hr(),
            hr(),
            # h2("Features"),
            # slickROutput("content_slider", width = "100%")
            slickROutput("content_slider", width = "500px")
            # slickROutput("content_slider", width = "100%")
          ),

          # Release Notes
          div(
            class = "release-notes animated fadeIn",
            h2("Major Release Notes"),
            p("Version 1.0.0 - Initial release with core features."),
            p("Version 1.1.0 - Added data visualization and export options."),
            p("Version 1.1.1 - Added Reactive components and Dynamic Updates."),
            p("Version 1.2.0 - Improved user interface and performance.")
          ),

          # Additional Sections
          div(
            class = "section animated fadeIn",
            hr(),
            h2("More Information"),
            p("For more information, visit our website or contact support."),
            hr(),
            HTML("Version-1.2 | &copy; 2025 Designed & Developed by: <a href='https://merqconsultancy.org'><b>MERQ Consultancy</b>.</a>")
          )
        )
      )
    ),

    # Main Application (conditional display)
    conditionalPanel(
      condition = "output.logged_in",
      dashboardPage(
        dashboardHeader(
          title = tags$div(
            tags$img(src = "dhis2-icon.svg", height = "50px"),
            HTML("<span style='color: #d7d7d7;'>DHIS2 Data Fetcher for </span><span style='color: #007dc9; font-weight: bold;'>HEAT </span><span style='color: #b5e71c; font-weight: bold;'>Plus(+)</span>")
          ),
          tags$li(
            class = "dropdown",
            tags$a(
              img(src = "moh_logo_white.png", height = "18px"),
              href = "#",
              style = "color: white; font-weight: bold; font-size: 16px; padding: 15px;",
              " Ministry of Health - ETHIOPIA"
            )
          )
        ),
        dashboardSidebar(
          width = 350,
          tags$li(
            class = "dropdown user-menu",
            uiOutput("user_profile")
          ),
          hr(),
          sidebarMenu(
            menuItem("Data Preview", tabName = "data_preview", icon = icon("eye")),
            menuItem("Settings",
              tabName = "settings", icon = icon("cogs"),
              menuSubItem("Source Setting", tabName = "source_setting", icon = icon("sliders-h")),
              menuSubItem("Fetcher Setting", tabName = "fetcher_setting", icon = icon("download"))
            ),
            menuItem("Data Management",
              icon = icon("database"),
              menuSubItem("Data Cleaner", tabName = "dash_explore_clean", icon = icon("broom")) # ,
              # menuSubItem("Explore & Clean", tabName = "explore_clean", icon = icon("broom"))
            ),
            hr(),
            menuItem("Admin Panel",
              tabName = "admin_panel", icon = icon("users"),
              conditionalPanel(
                condition = "output.is_admin",
                menuSubItem("User Management", tabName = "user_management"),
                menuSubItem("Role Management", tabName = "role_management"),
                menuSubItem("Database Management", tabName = "db_management"),
              )
            )
          )
        ),
        dashboardBody(
          useShinyjs(),
          tags$head(tags$style(HTML(css))),
          tabItems(


            # user admin panel tabs
            # user admin panel tabs
            tabItem(
              tabName = "user_management",
              fluidRow(
                box(
                  title = "User Management",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  actionButton("add_user", "Add User", class = "btn-success"),
                  DTOutput("user_table"),
                  actionButton("edit_user", "Edit User", class = "btn-primary"),
                  actionButton("delete_user", "Delete User", class = "btn-danger")
                )
              )
            ),
            tabItem(
              tabName = "role_management",
              fluidRow(
                box(
                  title = "Role Management",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  fluidRow(
                    column(
                      4,
                      h4("Add New Permission"),
                      textInput("new_permission", "New Permission Name"),
                      actionButton("add_permission", "Add Permission", class = "btn-success")
                    ),
                    column(
                      4,
                      h4("Create New Role"),
                      textInput("new_role_name", "Role Name"),
                      actionButton("add_role", "Create Role", class = "btn-primary")
                    ),
                    column(
                      4,
                      h4("Manage Existing Roles"),
                      selectInput("role_select", "Select Role", choices = NULL),
                      uiOutput("permissions_ui"),
                      actionButton("save_permissions", "Save Permissions", class = "btn-warning"),
                      actionButton("delete_role", "Delete Role", class = "btn-danger")
                    )
                  )
                )
              )
            ),


            # Database Management tab

            tabItem(
              tabName = "db_management",
              hr(),
              dba_module_ui("dba_module"),
              hr(),
              fluidRow(
                box(
                  title = "Database Administration and Management",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  p("CAUTION: Please becareful when updating and editing the database. You need Higher Level Credentials to Edit Update, Delete and Take a Backup or Restore the database. Please contact your super admin for credentials"),
                )
              )
            ),

            # other tab items


            tabItem(
              tabName = "source_setting",
              fluidRow(
                box(
                  title = "Source Setting",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  textInput("setting", "Setting", value = "Ethiopia"),
                  textInput("source", "Source", value = "DHIS_2"),
                  textInput("iso3", "ISO3", value = "ETH"),
                  conditionalPanel(
                    # condition = "output.role == 'mikeintosh'",
                    condition = "output.is_admin",
                    actionButton("save_source_settings", "Save Source Settings", class = "btn-primary")
                  ),
                  actionButton("load_source_settings", "Load Source Settings", class = "btn-info")
                )
              )
            ),
            tabItem(
              tabName = "fetcher_setting",
              fluidRow(
                box(
                  title = "Fetcher Setting",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  conditionalPanel(
                    # condition = "output.role == 'mikeintosh'",
                    condition = "output.is_admin",
                    actionButton("save_settings", "Save Settings", class = "btn-primary"),
                    textInput("base_url", "DHIS2 Base URL", value = Sys.getenv("DHIS2_BASE_URL")),
                    textInput("username", "Username", value = Sys.getenv("DHIS2_USERNAME")),
                    passwordInput("password", "Password", value = Sys.getenv("DHIS2_PASSWORD"))
                  ),
                  actionButton("load_settings", "Load Settings", class = "btn-info"),
                  actionButton("fetch_data", "Fetch Data", class = "btn-success"),
                  downloadButton("export_data", "Export to Excel", class = "btn-warning"),
                  downloadButton("export_parquet", "Export to Parquet", class = "btn-danger"),
                  actionButton("help", "Help", class = "btn-info"),
                  hr(),
                  checkboxInput("select_all_indicators", "Select All Indicators", value = FALSE),
                  selectizeInput("indicators", "Select Indicators", choices = NULL, multiple = TRUE, options = list(maxOptions = 1000)),
                  textInput("indicator_abbr", "Indicator Abbreviations (comma-separated)", value = ""),
                  selectizeInput("favorable_indicators", "Favorable Indicators", choices = NULL, multiple = TRUE, options = list(maxOptions = 1000)),
                  hr(),
                  checkboxInput("custom_indicator_scales", "Set Custom Indicator Scales", value = TRUE),
                  conditionalPanel(
                    condition = "input.custom_indicator_scales == true",
                    selectizeInput("custom_indicators", "Select Indicators for Custom Scales", choices = NULL, multiple = TRUE, options = list(maxOptions = 1000)),
                    uiOutput("custom_scales_ui")
                  ),
                  hr(),
                  checkboxInput("select_all_org_units", "Select All Organisation Units", value = FALSE),
                  selectizeInput("org_units", "Select Organisation Units", choices = NULL, multiple = TRUE, options = list(maxOptions = 1000)),
                  hr(),
                  checkboxInput("select_all_zones", "Select All Zones", value = FALSE),
                  selectizeInput("zones", "Select Zones", choices = NULL, multiple = TRUE, options = list(maxOptions = 1000)),
                  hr(),
                  checkboxInput("select_all_woredas", "Select All Woredas", value = FALSE),
                  selectizeInput("woredas", "Select Woredas", choices = NULL, multiple = TRUE, options = list(maxOptions = 1000)),
                  hr(),
                  # In the fetcher_setting tab box, after Woredas section
                  hr(),
                  checkboxInput("select_all_facilities", "Select All Facility Types", value = FALSE),
                  selectizeInput("facility_types", "Select Facility Types",
                    choices = list(
                      "Clinics" = "kwcNbI9fPdB",
                      "Health Centers" = "j8SCxUTyzfm",
                      "Health Post" = "FW4oru60vgc",
                      "Hospitals" = "nVEDFMfnStv"
                    ),
                    multiple = TRUE,
                    options = list(maxOptions = 1000)
                  ),
                  hr(),
                  checkboxInput("select_all_settlements", "Select All Settlement Types", value = FALSE),
                  selectizeInput("settlement_types", "Select Settlement Types",
                    choices = list(
                      "Urban Settlement" = "nKT0uoFbxdf",
                      "Pastoral Settlement" = "ZktuKijP5jN",
                      "Agrarian Settlement" = "V9sleOboZJ1"
                    ),
                    multiple = TRUE,
                    options = list(maxOptions = 1000)
                  ),
                  hr(),
                  textInput("periods", "Periods (comma-separated)", value = ""),
                  hr(),
                  hr()
                )
              )
            ),
            tabItem(
              tabName = "data_preview",
              fluidRow(
                actionButton("load_settings", "Load Settings", class = "btn-info"),
                actionButton("fetch_data", "Fetch Data", class = "btn-success"),
                downloadButton("export_data", "Export to Excel", class = "btn-warning"),
                downloadButton("export_parquet", "Export to Parquet", class = "btn-danger"),
                actionButton("help", "Help", class = "btn-info"),
                hr(),
                box(
                  title = tagList(
                    "Filters",
                    p("To get started, select indicators and dimensions, then apply filters",
                      style = "font-size: 14px; color: #b7b7b7;"
                    )
                  ),
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  fluidRow(
                    column(3, selectizeInput("filter_indicators", "Indicators", choices = NULL, multiple = TRUE, options = list(maxOptions = 1000))),
                    column(3, selectizeInput("filter_dimensions", "Dimensions", choices = NULL, multiple = TRUE, options = list(maxOptions = 1000))),
                    column(3, selectizeInput("filter_subgroups", "Subgroups", choices = NULL, multiple = TRUE, options = list(maxOptions = 1000))),
                    column(3, selectizeInput("filter_dates", "Dates", choices = NULL, multiple = TRUE, options = list(maxOptions = 1000))),
                    column(12, actionButton("apply_filters", "Apply Filters", class = "btn-primary", style = "float: right;"))
                  )
                ),
                column(
                  width = 6,
                  box(
                    title = "Histogram Plot",
                    status = "primary",
                    solidHeader = TRUE,
                    width = 12,
                    plotlyOutput("distPlot", width = "100%", height = "380px")
                  ),
                  box(
                    title = "Geo Heatmap",
                    status = "primary",
                    solidHeader = TRUE,
                    width = 12,
                    height = 600,
                    ethgeoUI("ethgeo_module"), # Embed the ethgeo module inside the box
                    hr()
                  )
                ),
                column(
                  width = 6,
                  box(
                    title = "Dynamic Plot Settings",
                    status = "primary",
                    solidHeader = TRUE,
                    width = 12,
                    fluidRow(
                      column(4, colourInput("plot_color", "Marker Color", value = "#75FF09")),
                      column(4, numericInput("marker_size", "Marker Size", value = 3, min = 1, max = 10)),
                      column(4, conditionalPanel(
                        condition = "input.chart_type == 'Scatter'",
                        selectInput("plot_mode", "Plot Mode",
                          choices = c(
                            "Markers" = "markers",
                            "Lines+Markers" = "lines+markers",
                            "Lines" = "lines"
                          )
                        ),
                        colourInput("line_color", "Line Color", value = "#075E57")
                      ))
                    )
                  ),
                  box(
                    title = "Dynamic Plot & Visualizations",
                    status = "primary",
                    solidHeader = TRUE,
                    width = 12,
                    selectInput("view_by", "Dynamic Plot:", choices = c("Subgroup", "Dimension", "Date")),
                    # selectInput("view_by", "Dynamic Plot:", choices = c("Subgroup", "Dimension")),
                    selectInput("chart_type", "Chart Type:",
                      # choices = c("Scatter", "Bar", "Geo Heatmap", "Pie", "Heatmap"), selected = "Scatter"),
                      # choices = c("Scatter", "Bar"), selected = "Scatter"),
                      choices = c("Scatter", "Bar", "Geo Heatmap", "Heatmap", "Pie"), selected = "Scatter"
                    ),
                    uiOutput("dynamicPlotUI"), # Dynamic UI for plots
                    plotlyOutput("dynamicPlotOutput", width = "100%", height = "100%")
                  )
                ),

                # Move Data Preview to the bottom with full width
                box(
                  title = "Data Preview",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12, # Full width
                  withSpinner(DTOutput("data_preview"))
                )
              )
            ),
            tabItem(
              tabName = "dash_explore_clean",
              fluidPage(
                tags$head(
                  tags$link(rel = "stylesheet", type = "text/css", href = "styles.css") # Link to external CSS
                ),
                titlePanel(div(class = "title-panel", "Data Cleaning Dashboard")),
                fluidRow(
                  column(
                    width = 12,
                    div(
                      class = "horizontal-sidebar",
                      selectInput("na_action", "Handle Missing Values:",
                        choices = c("None", "Remove Rows", "Replace with Mean", "Replace with Median", "Replace with Mode")
                      ),
                      actionButton("apply_na", "Apply", class = "btn"),
                      checkboxInput("remove_dupes", "Remove Duplicates", FALSE),
                      actionButton("apply_dupes", "Apply", class = "btn"),
                      uiOutput("col_select"),
                      selectInput("convert_type", "Convert Data Type:",
                        choices = c("None", "Numeric", "Character", "Factor", "Date")
                      ),
                      actionButton("apply_convert", "Apply", class = "btn"),
                      uiOutput("rename_ui"), # Dynamically generated rename UI
                      actionButton("apply_rename", "Apply Rename", class = "btn"),
                      numericInput("zscore_threshold", "Z-score Outlier Threshold", value = 3, min = 1, max = 10, step = 0.1),
                      actionButton("detect_outliers", "Detect Outliers", class = "outbtn"),
                      actionButton("save_clean", "Save Cleaned Data", class = "savebtn"),
                      downloadButton("download_clean", "Download Cleaned Data", class = "downbtn")
                    )
                  )
                ),
                fluidRow(
                  column(
                    width = 12,
                    tabsetPanel(
                      tabPanel("Data Preview", DTOutput("clean_table")),
                      tabPanel("Outlier Detection", DTOutput("outliers"))
                    )
                  )
                )
              )
            ),
            tabItem(
              tabName = "explore_clean",
              # h2("Data Management"),
              hr(),
              uiOutput("exclean_ui"),
              hr(),
              fluidRow(
                # uiOutput("exclean_ui"),
                box(
                  title = "Data Management",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  p("Data Cleansing or Data Wrangling is an important early step in the data analytics process."),
                  # Dynamically render the exclean UI here
                  # uiOutput("exclean_ui")
                  # uiOutput("mDataExplorationUI")
                )
              )
            )
          ),
          hr(),
          hr(),
          div(
            class = "footer",
            HTML("&copy; 2025 Designed & Developed by: <a href='https://merqconsultancy.org'><b>MERQ Consultancy</b>.</a>")
          )
        ),
        tags$head(
          tags$title("DHIS2 Data Fetcher for HEAT Plus(+) - Dashboard")
        )
      )
    )
  )
)



# Run the application
# shinyApp(ui = ui, server = server)
# shinyApp(ui = ui, server = server)
