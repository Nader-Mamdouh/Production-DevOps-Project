# Use a slim Python base image
FROM python:3.11-slim
# Set working directory
WORKDIR /app
# Create a non-root user
RUN useradd -m appuser
# Copy dependency file first (for caching)
COPY requirements.txt .
# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt
# Copy the application code
COPY . .
# Change ownership to the non-root user
RUN chown -R appuser /app
# Switch to non-root user
USER appuser
# Expose port 8080 for Flask
EXPOSE 8080
# Run the app
CMD ["flask", "run", "--host=0.0.0.0", "--port=8080"]