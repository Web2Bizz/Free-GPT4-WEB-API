# Nginx Dockerfile for FreeGPT4 API with Load Balancing

FROM nginx:alpine

# Install required packages
RUN apk add --no-cache \
    curl

# Create necessary directories
RUN mkdir -p /var/log/nginx

# Create nginx config directory
RUN mkdir -p /etc/nginx/conf.d


# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:15432/health || exit 1

# Expose ports
EXPOSE 15432

# Use default nginx entrypoint
CMD ["nginx", "-g", "daemon off;"]
