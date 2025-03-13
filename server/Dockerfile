# Build stage
FROM hexpm/elixir:1.17.2-erlang-25.3.2.9-debian-bullseye-20240130 as builder

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Build assets
COPY assets assets
RUN mix assets.deploy

# Copy config files
COPY config config

# Compile and build release
COPY lib lib
COPY priv priv
RUN mix compile
RUN mix release

# Start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM debian:bullseye-slim

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# Set runner ENV
ENV MIX_ENV=prod
ENV PHX_SERVER=true

# Copy the release from the builder stage
COPY --from=builder /app/_build/prod/rel/server ./

# Copy entry point script
COPY rel/overlays/bin/server.sh ./bin/
RUN chmod +x ./bin/server.sh

USER nobody

# Set the entry point
ENTRYPOINT ["bin/server.sh"]
CMD [] 