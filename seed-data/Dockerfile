FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends apache2-utils curl && \
    rm -rf /var/lib/apt/lists/*

# Copy scripts
COPY make-data.py generate-votes.sh ./

# Make script executable
RUN chmod +x generate-votes.sh

# Run the script (remove EXPOSE and USER if causing issues)
CMD ["./generate-votes.sh"]