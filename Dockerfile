# Use Python 3.7 with Debian Bookworm base image
FROM python:3.7-bookworm

# Update and install essential system dependencies
RUN apt-get update && apt-get -y install --no-install-recommends \
    libc-dev \
    build-essential \
    zlib1g-dev \
    curl \
    gnupg2 \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    software-properties-common \
    dirmngr \
    pkgconf \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libgit2-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install R from Bookworm repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base=4.2.2.20221110-2 \
    r-base-dev=4.2.2.20221110-2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Ruby using RVM (Ruby Version Manager)
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
    curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c "rvm install 3.2.0" && \
    /bin/bash -l -c "rvm use 3.2.0 --default"

# Ensure Ruby and Bundler are installed
ENV PATH="/usr/local/rvm/rubies/ruby-3.2.0/bin:${PATH}"
RUN gem install bundler jekyll

# Upgrade pip
RUN pip install --upgrade pip

# Install Python dependencies from requirements.txt
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy project files to the container
COPY . .

# Install R packages and Prophet
WORKDIR /R
RUN R -e "install.packages(c('devtools', 'Rcpp', 'ggplot2', 'dplyr'), repos = 'https://cloud.r-project.org')" && \
    R -e "if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools')" && \
    R -e "devtools::install('.')"

# Install Ruby dependencies for the docs directory
WORKDIR /docs
RUN bundle install

# Set the working directory to the python directory for package installation
WORKDIR /python
RUN python -m pip install -e ".[dev, parallel]"

# Set the working directory to the root
WORKDIR /

# Copy and set up the local start-notebook.sh script
COPY start-notebook.sh /usr/local/bin/start-notebook.sh
RUN chmod +x /usr/local/bin/start-notebook.sh

# Expose ports for JupyterLab and Jekyll
EXPOSE 8888 4000
