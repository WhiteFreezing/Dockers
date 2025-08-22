#!/bin/bash
# entrypoint.sh

# Print a message to confirm container started
echo "Container started!"

# If you need to run a server, you can replace this line
# For example, start a Java application or Pterodactyl command
# exec java -jar /home/container/server.jar "$@"

# Keep the container running (optional, for testing)
exec "$@"
