# Dockerfile for integration testing container metrics
# This container runs integration tests inside Docker to verify cgroup detection

FROM ruby:3.4-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  libyaml-dev \
  && rm -rf /var/lib/apt/lists/*

# Configure git to trust mounted volumes
RUN git config --global --add safe.directory /app

WORKDIR /app

# Copy gemspec and Gemfile for dependency installation
COPY karafka-web.gemspec Gemfile Gemfile.lock ./
COPY lib/karafka/web/version.rb ./lib/karafka/web/

# Install Ruby dependencies
# Remove diffend plugin line to avoid configuration validation issues in Docker
RUN bundle config set without 'development tools benchmarks docs' && \
    bundle install --jobs 4 --retry 3

# Copy the rest of the application
COPY . .
