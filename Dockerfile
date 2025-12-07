# Stage 1: download zserve binary
FROM alpine:3.20 AS downloader

# Install curl for fetching the binary
RUN apk add --no-cache curl

# Download your zserve binary from GitHub releases
# (replace with your actual repo and tag URL)
# Example:
# https://github.com/<username>/<repo>/releases/download/v1.0.0/zserve-linux-amd64
# Version and release info
ARG ZSERVE_VERSION=1.0.4
ARG ZSERVE_URL=https://github.com/krishnadubagunta/zserve/releases/download/v${ZSERVE_VERSION}/zserve-x86_64-linux-gnu-${ZSERVE_VERSION}.tar.gz

# Download and extract
RUN mkdir -p /tmp/zserve
RUN curl -L ${ZSERVE_URL} -o /tmp/zserve.tar.gz
RUN tar -xzf /tmp/zserve.tar.gz -C /tmp/zserve
RUN ls /tmp/zserve
RUN chmod +x /tmp/zserve/zserve

# Stage 2: minimal runtime container
FROM alpine:3.20

# Copy only the binary, no build tools
COPY --from=downloader /tmp/zserve/zserve /usr/local/bin/zserve

# Create a non-root user
RUN adduser -D appuser
USER appuser

# Create working directory for docs
WORKDIR /app

COPY ./zig-out/docs ./docs

# Expose your service port (if zserve serves e.g. port 8080)
EXPOSE 8080

# Run the server
ENTRYPOINT ["zserve"]
CMD ["-f", "./docs", "-h", "0.0.0.0", "-p", "8080"]
