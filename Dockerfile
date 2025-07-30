# to run this locally, you have to give it some args:
#
# docker build .

FROM ruby:3.4.4-bullseye

# Allow apt to work with https-based sources
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends

RUN apt-get install -yqq --no-install-recommends \
  apt-transport-https \
  apt-utils \
  curl \
  iputils-ping \
  net-tools \
  python-dev \
  software-properties-common \
  unzip \
  vim \
  wget \
  zip

ARG AWSCLI_ARCH

# Install aws-cli for cloud watch
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Postgres packages

# Create the file repository configuration:
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key:
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
# Update the package lists:
RUN apt-get update

# Install the latest version of PostgreSQL.
# If you want a specific version, use 'postgresql-12' or similar instead of 'postgresql':
RUN apt-get -y install \
   postgresql-16

COPY Gemfile Gemfile.lock ./

# Don't install development or test dependencies
RUN bundle config set without "development test"
RUN bundle install --jobs=3 --retry=3

# Create a non-root user to run the app and own app-specific files
RUN groupadd app
RUN useradd -rm -d /home/app -s /bin/bash -g app -G sudo -u 1001 app

# Switch to this user
USER app

# We'll install the app in this directory
WORKDIR /home/app

# Finally, copy over the code
# This is where the .dockerignore file comes into play
# Note that we have to use `--chown` here
COPY --chown=app . ./
