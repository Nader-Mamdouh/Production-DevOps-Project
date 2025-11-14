#!/bin/bash

echo "Waiting for vote service to be ready..."

# Wait for vote service
max_attempts=30
for ((attempt=1; attempt<=max_attempts; attempt++)); do
    if curl -s http://vote:8080/ > /dev/null; then
        echo "Vote service is ready!"
        break
    else
        echo "Attempt $attempt/$max_attempts: Vote service not ready..."
        sleep 2
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        echo "ERROR: Vote service never became ready!"
        exit 1
    fi
done

echo "Generating vote data files..."
python3 make-data.py

echo "Sending 2000 votes for option A..."
ab -n 2000 -c 50 -p posta -T "application/x-www-form-urlencoded" http://vote:8080/

echo "Sending 1000 votes for option B..."
ab -n 1000 -c 50 -p postb -T "application/x-www-form-urlencoded" http://vote:8080/

echo "Seed data completed! 3000 votes sent."