# Change to match your CPU core count
workers 1

# Min and Max threads per worker
threads 1, 6

# Set up socket location
bind "unix:///var/run/puma.sock"

# Logging
stdout_redirect "/var/log/puma.stdout.log", "/var/log/puma.stderr.log", true

daemonize

# Set master PID and state locations
pidfile "/var/run/puma.pid"
state_path "/var/run/puma.state"

