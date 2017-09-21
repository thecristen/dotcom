FROM elixir:1.5

WORKDIR /root

# Configure Git to use HTTPS in order to avoid issues with the internal MBTA network
RUN git config --global url.https://github.com/.insteadOf git://github.com/

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Install node/npm
# Instructions from https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g brunch

# Install Sass
RUN apt-get install -y rubygems ruby2.1-dev && \
    gem install sass

# Install and configure AWS CLI
RUN apt-get install -y python-pip libpython-dev && \
    pip install awscli && \
    mkdir ~/.aws && \
    echo "[default]" >> ~/.aws/credentials && \
    echo aws_access_key_id=$AWS_ACCESS_KEY_ID >> ~/.aws/credentials && \
    echo aws_secret_access_key=$AWS_SECRET_ACCESS_KEY >> ~/.aws/credentials && \
    echo "[default]" >> ~/.aws/config && \
    echo region=us-east-1 >> ~/.aws/config && \
    echo output=json >> ~/.aws/config

# Clean up
RUN apt-get clean

ENV MIX_ENV=prod

ADD . .

WORKDIR /root/apps/site
RUN mix do deps.get, deps.compile && \
    npm install --only=production --no-optional && \
    brunch build --production && \
    mix do compile, phoenix.digest, release --verbosity=verbose --no-confirm-missing

RUN aws s3 sync priv/static/css s3://mbta-dotcom/css --size-only && \
    aws s3 sync priv/static/js s3://mbta-dotcom/js --size-only
