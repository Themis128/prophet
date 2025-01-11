#!/bin/bash

# Script to debug and address CI workflow failures in Docker Compose, Python, and R

echo "Starting CI debug script..."

# Step 1: Debug Docker Compose Services
echo "Step 1: Debugging Docker Compose Services..."
docker-compose down  # Stop any running services
docker-compose up --build -d  # Build and start services in detached mode

# Check the status of running containers
echo "Checking Docker Compose services..."
docker-compose ps

# Show logs for each service
for service in $(docker-compose ps --services); do
  echo "Logs for service: $service"
  docker logs $service || echo "Error fetching logs for $service"
done

# Step 2: Test Python Environment
echo "Step 2: Testing Python environment..."
if command -v python3 &>/dev/null; then
  echo "Python version:"
  python3 --version

  echo "Checking installed Python packages..."
  pip freeze

  echo "Running Python tests..."
  pytest || echo "Python tests failed. Check the logs above."
else
  echo "Python is not installed or not accessible."
fi

# Step 3: Test R Environment
echo "Step 3: Testing R environment..."
if command -v R &>/dev/null; then
  echo "R version:"
  R --version

  echo "Installing required R packages..."
  R -e "install.packages(c('devtools', 'Rcpp', 'ggplot2', 'dplyr'), repos = 'https://cloud.r-project.org')"

  echo "Running R CMD check..."
  R CMD check . || echo "R CMD check failed. Check the logs above."
else
  echo "R is not installed or not accessible."
fi

# Step 4: Cleanup Docker Resources
echo "Step 4: Cleaning up Docker resources..."
docker-compose down --volumes  # Stop services and remove volumes
docker system prune -f  # Clean up unused Docker resources

# Step 5: Re-run GitHub Actions Locally (Optional, requires act CLI)
if command -v act &>/dev/null; then
  echo "Running GitHub Actions workflows locally using act..."
  act || echo "act command failed. Check your local environment and workflows."
else
  echo "act CLI not installed. Skipping local GitHub Actions workflow testing."
fi

echo "CI debug script completed."
