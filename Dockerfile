# Stage 1: Build snix from source
FROM debian:bookworm AS snix-builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libfuse3-dev \
    pkg-config \
    build-essential \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Install rustup and Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone and build snix
WORKDIR /build
RUN git clone https://git.snix.dev/snix/snix.git && \
    cd snix/snix && \
    SNIX_BUILD_SANDBOX_SHELL=/bin/sh cargo build --features snix-store/xp-composition-cli --release

# Stage 2: Runtime image
FROM debian:bookworm-slim

# Install runtime dependencies including tini
RUN apt-get update && apt-get install -y \
    fuse3 \
    ca-certificates \
    procps \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Copy snix binary from builder
COPY --from=snix-builder /build/snix/snix/target/release/snix /usr/local/bin/snix
COPY --from=snix-builder /build/snix/snix/target/release/snix-store /usr/local/bin/snix-store

# Create necessary directories
RUN mkdir -p /var/lib/snix-castore/blobs \
    /var/lib/snix-store \
    /nix/store

# Copy snix configuration and entrypoint
COPY store-config.toml /etc/snix/store-config.toml
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["/bin/sh"]
