# Use Haskell base image
FROM haskell:9.6

# Install C++ build dependencies
RUN apt-get update && apt-get install -y \
    g++ \
    make \
    flex \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Build Haskell Server
# We run cabal update to get latest package lists
RUN cd server && cabal update && cabal build

# Build C++ Client
RUN cd chat-client && make

# Make the run script executable
RUN chmod +x run_all.sh

# The client needs a TUI, so we'll need to run with -it
CMD ["./run_all.sh"]
