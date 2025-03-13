# Build stage
FROM hexpm/elixir:1.17.2-erlang-25.3.2.9-debian-bullseye-20240130 as builder

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

# Copy config files
COPY config config

# Compile and build release
COPY lib lib
RUN mix compile
RUN mix release

# Start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM debian:bullseye-slim

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR "/app"
RUN chown nobody /app

# Set runner ENV
ENV MIX_ENV=prod

# Copy the release from the builder stage
COPY --from=builder /app/_build/prod/rel/workspace ./

USER nobody

# The entrypoint script will be injected by the parent container
ENTRYPOINT ["bin/workspace"]
CMD ["start"] 