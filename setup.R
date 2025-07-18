# Install R packages (run once)
install.packages(c("shiny", "reticulate", "shinyjs"))

# Load reticulate package
library(reticulate)

# Create Python virtual environment and install Python packages (run once)
virtualenv_create("blinkenv")
virtualenv_install("blinkenv", packages = c("opencv-python", "mediapipe", "numpy"))
