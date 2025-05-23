#!/bin/bash

# Check and install necessary system dependencies
echo "Checking system dependencies (systemctl, nano, inotify-tools, libssl-dev, libxml2-dev, acl, libsodium23)..."
apt-get update && apt-get install -y --no-install-recommends \
    systemctl \
    nano \
    inotify-tools \
    libssl-dev \
    libxml2-dev \
    acl \
    libsodium23 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the cache directory to a valid location
echo "Setting R_USER_CACHE_DIR to /tmp/R_cache"
export R_USER_CACHE_DIR=/tmp/R_cache
mkdir -p $R_USER_CACHE_DIR
chown shiny:shiny $R_USER_CACHE_DIR
chmod 770 $R_USER_CACHE_DIR

# Set Sass cache directory for bslib::bs_theme()
echo "Setting Sass cache directory for bslib::bs_theme()..."
R -e "options(sass.cache = '/tmp/R_cache')"

# Shiny app source directory inside the container
APP_SRC="/srv/shiny-server/UI"

echo "Starting Shiny App Deployment Process..."

# Step 1: Copy app files if necessary (if using a mounted volume, this may not be needed)
if [ ! -d "$APP_SRC" ]; then
  echo "Error: Shiny app source directory '$APP_SRC' does not exist."
  exit 1
fi

# Step 2: Install required R libraries only if they are not already installed
R_LIBS=("shiny" "shinydashboard" "shinyWidgets" "shinyjs" "shinyBS" "shinyalert" "dplyr" "plyr" "DT" "ggplot2" "plotly" "scales" "pastecs" "car" "ggfortify" "arrow" "psych" "sqldf" "lubridate" "kableExtra" "gridExtra" "reshape2" "fastDummies" "DataExplorer" "tidyverse" "colorspace" "here" "rjson" "purrr" "RSQLite" "sodium" "DBI" "slickR")

echo "Checking CRAN R libraries..."
for lib in "${R_LIBS[@]}"; do
    if R -e "if (!require('$lib')) { quit(status = 1) }" > /dev/null 2>&1; then
        echo "$lib is already installed."
    else
        echo "$lib is not installed. Installing..."
        R -e "install.packages('$lib', dependencies = TRUE, repos = 'https://cran.r-project.org/')"
    fi
done

# Ensure remotes package is installed
if ! R -e "require('remotes')" > /dev/null 2>&1; then
    echo "remotes package is missing. Installing..."
    R -e "install.packages('remotes')"
fi

# Define GitHub repositories for additional packages
GITHUB_PACKAGES=("rstudio/gridlayout" "tidyverse/ggplot2" "thomasp85/patchwork")

echo "Checking GitHub R packages..."
for repo in "${GITHUB_PACKAGES[@]}"; do
    package_name=$(basename "$repo")
    if R -e "if (!require('$package_name')) { quit(status = 1) }" > /dev/null 2>&1; then
        echo "$package_name is already installed."
    else
        echo "$package_name is not installed. Installing from GitHub..."
        R -e "remotes::install_github('$repo')"
    fi
done

if [ $? -eq 0 ]; then
  echo "All R libraries installed successfully."
else
  echo "Error: Failed to install R libraries."
  exit 1
fi

# Step 3: Restart Shiny Server to reflect changes
echo "Restarting Shiny Server..."
systemctl restart shiny-server

# Step 4: Set ACL for both root and shiny users to ensure proper access to app files
echo "Setting ACLs for Shiny app files..."
setfacl -R -m u:shiny:rwx /srv/shiny-server/UI
setfacl -R -m u:root:rwx /srv/shiny-server/UI
setfacl -R -d -m u:shiny:rwx /srv/shiny-server/UI
setfacl -R -d -m u:root:rwx /srv/shiny-server/UI

# Step 5: Create a file monitoring script to watch for changes in the UI folder
echo "Creating file monitoring script..."
cat << 'EOF' > /srv/shiny-server/monitor_shiny_app.sh
#!/bin/bash

APP_DIR="/srv/shiny-server/UI"
LOG_FILE="/srv/shiny-server/shiny_app_monitor.log"

echo "Monitoring Shiny app directory for changes..." >> $LOG_FILE

inotifywait -m -r -e modify,create,delete $APP_DIR |
while read path action file; do
    echo "$(date) - Change detected: $action $file" >> $LOG_FILE
    echo "$(date) - Restarting Shiny app..." >> $LOG_FILE
    systemctl restart shiny-server
    echo "$(date) - Shiny app restarted." >> $LOG_FILE
done
EOF

chmod +x /srv/shiny-server/monitor_shiny_app.sh
chmod +x /srv/shiny-server/start_shiny_app.sh
chmod +x /srv/shiny-server/init.deploy.sh
chmod +x /srv/shiny-server/install_shiny_packages.sh

# Step 6: Optionally, you can add the monitoring script to systemd to run on startup
#echo "Creating systemd service for Shiny app monitoring..."
#cat << 'EOF' > /etc/systemd/system/shiny-app-monitor.service
#[Unit]
#Description=Shiny App Directory Monitor

#[Service]
#ExecStart=/srv/shiny-server/monitor_shiny_app.sh
#Restart=always

#[Install]
#WantedBy=multi-user.target
#EOF

#systemctl daemon-reload
#systemctl enable shiny-app-monitor.service
#systemctl start shiny-app-monitor.service

# Step 7: Set file ownership and permissions
echo "Setting ownership and permissions..."
chown shiny:shiny /srv/shiny-server/settings.rds
chown shiny:shiny /srv/shiny-server/saved_setting/settings.rds
chown shiny:shiny /srv/shiny-server/saved_setting/source_settings.rds
chown -R shiny:shiny /srv/shiny-server/fetched_data
#chown shiny:shiny /srv/shiny-server/HEAT
#chown shiny:shiny /srv/shiny-server/HEAT-Plus

chmod 644 /srv/shiny-server/settings.rds
chmod 644 /srv/shiny-server/saved_setting/settings.rds
chmod 644 /srv/shiny-server/saved_setting/source_settings.rds
#chmod 755 /srv/shiny-server/HEAT
#chmod 755 /srv/shiny-server/HEAT-Plus

chmod +x /srv/shiny-server/monitor_shiny_app.sh
chmod +x /srv/shiny-server/start_shiny_app.sh
chmod +x /srv/shiny-server/init.deploy.sh
chmod +x /srv/shiny-server/install_shiny_packages.sh

sudo chmod -R 755 /srv/shiny-server/UI
sudo chown -R shiny:shiny /srv/shiny-server/UI


# Step 8: Final confirmation
if [ $? -eq 0 ]; then
  echo "Shiny Server restarted successfully. Monitoring script deployed and service started. Deployment complete!"
else
  echo "Error: Failed to restart Shiny Server or deploy monitoring service."
  exit 1
fi
