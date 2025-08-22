#!/bin/bash
set -euo pipefail

# ============================================================================
# Enhanced Docker Container Startup Script
# Features:
# - Comprehensive system diagnostics
# - Environment validation
# - Interactive startup (if terminal detected)
# - Better error handling
# - Enhanced logging
# - Resource monitoring
# ============================================================================

# Constants
readonly SCRIPT_VERSION="2.1.0"
readonly LOG_FILE="/var/log/container-startup.log"
readonly MAX_LOG_SIZE=$((10 * 1024 * 1024)) # 10MB
readonly MIN_DISK_SPACE=$((5 * 1024 * 1024)) # 5GB in KB
readonly MIN_MEMORY=$((512 * 1024)) # 512MB in KB

# Colors for output
declare -A COLORS=(
  ["RESET"]='\033[0m' ["BOLD"]='\033[1m' ["DIM"]='\033[2m'
  ["RED"]='\033[0;31m' ["GREEN"]='\033[0;32m' ["YELLOW"]='\033[1;33m'
  ["BLUE"]='\033[0;34m' ["MAGENTA"]='\033[0;35m' ["CYAN"]='\033[0;36m'
  ["WHITE"]='\033[1;37m' ["GRAY"]='\033[0;90m'
  ["BG_RED"]='\033[41m' ["BG_GREEN"]='\033[42m' ["BG_YELLOW"]='\033[43m'
)

# Global variables
declare -A SYSTEM_INFO JAVA_INFO NETWORK_INFO CONTAINER_INFO
declare -a STARTUP_WARNINGS STARTUP_ERRORS
declare STARTUP_COMMAND=""
declare IS_TTY=false
declare VERBOSE_MODE=false

# ============================================================================
# Core Functions
# ============================================================================

# Initialize logging system
setup_logging() {
  local log_dir=$(dirname "$LOG_FILE")

  # Create log directory if it doesn't exist
  if [[ ! -d "$log_dir" ]]; then
    mkdir -p "$log_dir" || {
      echo -e "${COLORS[RED]}? Failed to create log directory: $log_dir${COLORS[RESET]}" >&2
      return 1
    }
  fi

  # Rotate log if it's too large
  if [[ -f "$LOG_FILE" && $(stat -c%s "$LOG_FILE") -gt $MAX_LOG_SIZE ]]; then
    mv "$LOG_FILE" "${LOG_FILE}.old" || {
      echo -e "${COLORS[YELLOW]}? Could not rotate log file${COLORS[RESET]}" >&2
    }
  fi

  # Write header to new log
  {
    echo "============================================================="
    echo " Container Startup Log - $(date)"
    echo " Script Version: $SCRIPT_VERSION"
    echo "============================================================="
  } > "$LOG_FILE"
}

# Check if we're running in a terminal
check_tty() {
  if [[ -t 1 ]]; then
    IS_TTY=true
    # Enable more verbose output when running interactively
    VERBOSE_MODE=true
  fi
}

# Enhanced spinner with status tracking
spinner() {
  local pid=\$1
  local message="\$2"
  local delay=0.1
  local spin_str='??????????'

  # Don't show spinner if not in TTY or verbose mode
  if [[ "$IS_TTY" != true || "$VERBOSE_MODE" != true ]]; then
    echo -n "[$message] "
    wait "$pid" >/dev/null 2>&1
    return $?
  fi

  # Display spinning animation while process runs
  while kill -0 "$pid" 2>/dev/null; do
    local temp=${spin_str#?}
    printf " [%c] %s" "$spin_str" "$message"
    spin_str=$temp${spin_str%"$temp"}
    sleep "$delay"
    printf "\r"
  done

  # Get exit status of the process
  wait "$pid"
  local status=$?

  # Clear the spinner line
  printf "\r"

  if [[ $status -eq 0 ]]; then
    echo -e "${COLORS[GREEN]}?${COLORS[RESET]} [$message] - Completed successfully"
  else
    echo -e "${COLORS[RED]}?${COLORS[RESET]} [$message] - Failed with exit code $status"
  fi

  return $status
}

# Progress bar function
progress_bar() {
  local progress=\$1
  local width=${2:-40}
  local filled=$((progress * width / 100))
  local empty=$((width - filled))

  # Don't show progress bar if not in TTY
  if [[ "$IS_TTY" != true ]]; then
    echo -n "[${progress}%] "
    return
  fi

  printf "["
  printf "%${filled}s" | tr ' ' '-'
  printf "%${empty}s" | tr ' ' '-'
  printf "] %d%%" "$progress"
}

# Log messages with timestamps and colors
log_message() {
  local level=\$1
  local message=\$2
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local color="${COLORS[$level]}"
  local log_entry="[$timestamp] [$level] $message"

  # Print to console with color if TTY
  if [[ "$IS_TTY" == true ]]; then
    echo -e "${color}${log_entry}${COLORS[RESET]}"
  else
    echo -e "$log_entry"
  fi

  # Always write to log file without colors
  echo -e "[$timestamp] [$level] ${message//${COLORS[@]}/}" >> "$LOG_FILE"
}

# ============================================================================
# System Information Gathering
# ============================================================================

get_system_info() {
  # Memory information
  SYSTEM_INFO[mem_total]=$(awk '/MemTotal:/ {print int(\$2/1024)}' /proc/meminfo 2>/dev/null || echo 0)
  SYSTEM_INFO[mem_avail]=$(awk '/MemAvailable:/ {print int(\$2/1024)}' /proc/meminfo 2>/dev/null || echo 0)
  SYSTEM_INFO[mem_used]$((SYSTEM_INFO[mem_total] - SYSTEM_INFO[mem_avail]))
  SYSTEM_INFO[mem_pct]$((SYSTEM_INFO[mem_used] * 100 / SYSTEM_INFO[mem_total]))

  # CPU information
  SYSTEM_INFO[cpu_cores]=$(nproc 2>/dev/null || echo 0)
  SYSTEM_INFO[cpu_model]=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | xargs || echo "Unknown")
  SYSTEM_INFO[load_avg]=$(uptime 2>/dev/null | awk -F'load average:' '{print \$2}' | cut -d',' -f1 | xargs || echo 0)

  # Disk information
  SYSTEM_INFO[disk_total]=$(df -k / 2>/dev/null | awk 'NR==2 {print \$2}' || echo 0)
  SYSTEM_INFO[disk_used]=$(df -k / 2>/dev/null | awk 'NR==2 {print \$3}' || echo 0)
  SYSTEM_INFO[disk_avail]=$(df -k / 2>/dev/null | awk 'NR==2 {print \$4}' || echo 0)
  SYSTEM_INFO[disk_pct]=$(df / 2>/dev/null | awk 'NR==2 {print substr(\$5,1,length(\$5)-1)}' || echo 0)

  # System uptime
  SYSTEM_INFO[uptime]=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")

  # Kernel version
  SYSTEM_INFO[kernel]=$(uname -r 2>/dev/null || echo "Unknown")
}

get_java_info() {
  if command -v java >/dev/null 2>&1; then
    JAVA_INFO[version]=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 || echo "Unknown")
    JAVA_INFO[vendor]=$(java -version 2>&1 | grep -iE "openjdk|oracle|azul" | head -n1 || echo "Unknown")
    JAVA_INFO[home]=$(dirname $(dirname $(readlink -f $(which java) 2>/dev/null)) 2>/dev/null || echo "Unknown")

    # Check Java version compatibility
    if [[ "${JAVA_INFO[version]}" =~ ^1\.[6-8]\. ]]; then
      STARTUP_WARNINGS+=("Java version ${JAVA_INFO[version]} is outdated and may have security vulnerabilities")
    fi
  else
    JAVA_INFO[version]="Not installed"
    JAVA_INFO[vendor]="N/A"
    JAVA_INFO[home]="N/A"
    STARTUP_ERRORS+=("Java is not installed but may be required by your application")
  fi
}

get_network_info() {
  NETWORK_INFO[hostname]=$(hostname 2>/dev/null || echo "Unknown")
  NETWORK_INFO[internal_ip]=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "Unknown")

  # Try to get external IP if possible (might not work in all container environments)
  NETWORK_INFO[external_ip]=$(curl -s --max-time 2 ifconfig.me 2>/dev/null || echo "Unknown")

  # Get all network interfaces
  local ifaces=$(ip -o link show 2>/dev/null | awk -F': ' '{print \$2}')
  local iface_info=""
  for iface in $ifaces; do
    local ip=$(ip -o addr show dev "$iface" 2>/dev/null | awk '{print \$4}' | cut -d'/' -f1)
    if [[ -n "$ip" && "$ip" != "127.0.0.1" ]]; then
      iface_info+=" $iface($ip)"
    fi
  done
  NETWORK_INFO[interfaces]=${iface_info:-None}
}

get_container_info() {
  # Check if we're in a container
  if [[ -f /.dockerenv || -f /.dockerinit ]]; then
    CONTAINER_INFO[type]="Docker"
    CONTAINER_INFO[id]=$(cat /proc/self/cgroup 2>/dev/null | grep -oP 'docker-.{12}' | head -n1 || echo "Unknown")
  elif [[ -f /run/.containerenv ]]; then
    CONTAINER_INFO[type]="Podman"
    CONTAINER_INFO[id]=$(hostname 2>/dev/null || echo "Unknown")
  else
    CONTAINER_INFO[type]="None"
    CONTAINER_INFO[id]="N/A"
  fi

  CONTAINER_INFO[name]=$(hostname 2>/dev/null || echo "Unknown")
}

# ============================================================================
# Validation Functions
# ============================================================================

validate_system() {
  local errors=0
  local warnings=0

  # Check critical directories
  for dir in /home/container /tmp /var/log; do
    if [[ ! -d "$dir" ]]; then
      STARTUP_ERRORS+=("Missing critical directory: $dir")
      ((errors++))
    fi
  done

  # Check disk space
  if [[ ${SYSTEM_INFO[disk_pct]} -gt 95 ]]; then
    STARTUP_ERRORS+=("Critical disk space usage: ${SYSTEM_INFO[disk_pct]}% used")
    ((errors++))
  elif [[ ${SYSTEM_INFO[disk_pct]} -gt 90 ]]; then
    STARTUP_WARNINGS+=("High disk space usage: ${SYSTEM_INFO[disk_pct]}% used")
    ((warnings++))
  fi

  # Check available disk space in KB
  if [[ ${SYSTEM_INFO[disk_avail]} -lt $MIN_DISK_SPACE ]]; then
    local required=$((MIN_DISK_SPACE / 1024 / 1024))
    local available=$((SYSTEM_INFO[disk_avail] / 1024 / 1024))
    STARTUP_ERRORS+=("Insufficient disk space: ${available}GB available, ${required}GB required")
    ((errors++))
  fi

  # Check memory
  if [[ ${SYSTEM_INFO[mem_pct]} -gt 95 ]]; then
    STARTUP_ERRORS+=("Critical memory usage: ${SYSTEM_INFO[mem_pct]}% used (${SYSTEM_INFO[mem_used]}MB/${SYSTEM_INFO[mem_total]}MB)")
    ((errors++))
  elif [[ ${SYSTEM_INFO[mem_pct]} -gt 90 ]]; then
    STARTUP_WARNINGS+=("High memory usage: ${SYSTEM_INFO[mem_pct]}% used (${SYSTEM_INFO[mem_used]}MB/${SYSTEM_INFO[mem_total]}MB)")
    ((warnings++))
  fi

  # Check minimum memory requirement
  if [[ ${SYSTEM_INFO[mem_total]} -lt $MIN_MEMORY ]]; then
    local required=$((MIN_MEMORY / 1024))
    STARTUP_ERRORS+=("Insufficient total memory: ${SYSTEM_INFO[mem_total]}MB available, ${required}MB recommended")
    ((errors++))
  fi

  # Check CPU load
  local load_threshold=$((SYSTEM_INFO[cpu_cores] * 2))
  local current_load=$(echo "${SYSTEM_INFO[load_avg]}" | cut -d'.' -f1)

  if [[ $current_load -gt $load_threshold ]]; then
    STARTUP_WARNINGS+=("High system load: ${SYSTEM_INFO[load_avg]} (threshold: $load_threshold)")
    ((warnings++))
  fi

  return $((errors > 0 ? 1 : 0))
}

validate_environment() {
  # Check for required environment variables
  local required_vars=("JAVA_HOME" "PATH" "HOME")
  local missing_vars=()

  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      missing_vars+=("$var")
    fi
  done

  if [[ ${#missing_vars[@]} -gt 0 ]]; then
    STARTUP_WARNINGS+=("Missing environment variables: ${missing_vars[*]}")
  fi

  # Check if we have a startup command
  if [[ -z "${STARTUP:-}" ]]; then
    STARTUP_ERRORS+=("No STARTUP command defined")
    return 1
  fi

  return 0
}

# ============================================================================
# Display Functions
# ============================================================================

display_header() {
  local width=60
  local header="Docker Container Management System v$SCRIPT_VERSION"
  local padding=$(((width - ${#header}) / 2))

  if [[ "$IS_TTY" == true ]]; then
    echo -e "${COLORS[BLUE]}-$(printf '¦%.0s' $(seq 1 $width))¬${COLORS[RESET]}"
    printf "${COLORS[BLUE]}-${COLORS[RESET]}%${padding}s${COLORS[CYAN]}%s${COLORS[RESET]}%${padding}s${COLORS[BLUE]}-${COLORS[RESET]}\n" "" "$header" ""
    echo -e "${COLORS[BLUE]}+$(printf '¦%.0s' $(seq 1 $width))+${COLORS[RESET]}"
    printf "${COLORS[BLUE]}-${COLORS[RESET]} ${COLORS[YELLOW]}ID:${COLORS[RESET]} %-15s ${COLORS[YELLOW]}Type:${COLORS[RESET]} %-10s ${COLORS[YELLOW]}Uptime:${COLORS[RESET]} %-15s ${COLORS[BLUE]}-${COLORS[RESET]}\n" \
      "${CONTAINER_INFO[id]:0:15}" \
      "${CONTAINER_INFO[type]:0:10}" \
      "${SYSTEM_INFO[uptime]:0:15}"
    echo -e "${COLORS[BLUE]}L$(printf '¦%.0s' $(seq 1 $width))-${COLORS[RESET]}"
  else
    echo "============================================================="
    echo " $header"
    echo " ID: ${CONTAINER_INFO[id]} | Type: ${CONTAINER_INFO[type]} | Uptime: ${SYSTEM_INFO[uptime]}"
    echo "============================================================="
  fi
}

display_system_info() {
  echo -e "\n${COLORS[CYAN]}System Information${COLORS[RESET]}"

  if [[ "$IS_TTY" == true ]]; then
    echo -e "  ${COLORS[GREEN]}Memory:${COLORS[RESET]}   ${SYSTEM_INFO[mem_used]}MB/${SYSTEM_INFO[mem_total]}MB (${SYSTEM_INFO[mem_pct]}%) $(progress_bar ${SYSTEM_INFO[mem_pct]})"
    echo -e "  ${COLORS[GREEN]}CPU:${COLORS[RESET]}      ${SYSTEM_INFO[cpu_cores]} cores | Load: ${SYSTEM_INFO[load_avg]}"
    echo -e "  ${COLORS[GREEN]}Disk:${COLORS[RESET]}     ${SYSTEM_INFO[disk_used]}KB/${SYSTEM_INFO[disk_total]}KB (${SYSTEM_INFO[disk_pct]}%) $(progress_bar ${SYSTEM_INFO[disk_pct]})"
    echo -e "  ${COLORS[GREEN]}Kernel:${COLORS[RESET]}   ${SYSTEM_INFO[kernel]}"
  else
    echo "  Memory: ${SYSTEM_INFO[mem_used]}MB/${SYSTEM_INFO[mem_total]}MB (${SYSTEM_INFO[mem_pct]}%)"
    echo "  CPU: ${SYSTEM_INFO[cpu_cores]} cores | Load: ${SYSTEM_INFO[load_avg]}"
    echo "  Disk: ${SYSTEM_INFO[disk_used]}KB/${SYSTEM_INFO[disk_total]}KB (${SYSTEM_INFO[disk_pct]}%)"
    echo "  Kernel: ${SYSTEM_INFO[kernel]}"
  fi
}

display_java_info() {
  echo -e "\n${COLORS[CYAN]}Java Runtime${COLORS[RESET]}"
  echo -e "  ${COLORS[GREEN]}Version:${COLORS[RESET]}  ${JAVA_INFO[version]}"
  echo -e "  ${COLORS[GREEN]}Vendor:${COLORS[RESET]}   ${JAVA_INFO[vendor]}"
  echo -e "  ${COLORS[GREEN]}Home:${COLORS[RESET]}    ${JAVA_INFO[home]}"
}

display_network_info() {
  echo -e "\n${COLORS[CYAN]}Network Information${COLORS[RESET]}"
  echo -e "  ${COLORS[GREEN]}Hostname:${COLORS[RESET]}   ${NETWORK_INFO[hostname]}"
  echo -e "  ${COLORS[GREEN]}Internal IP:${COLORS[RESET]} ${NETWORK_INFO[internal_ip]}"
  echo -e "  ${COLORS[GREEN]}External IP:${COLORS[RESET]} ${NETWORK_INFO[external_ip]}"
  echo -e "  ${COLORS[GREEN]}Interfaces:${COLORS[RESET]}  ${NETWORK_INFO[interfaces]}"
}

display_health_status() {
  local total_issues=$(( ${#STARTUP_ERRORS[@]} + ${#STARTUP_WARNINGS[@]} ))
  local health_score=100

  # Calculate health score (errors weight more than warnings)
  for error in "${STARTUP_ERRORS[@]}"; do
    health_score=$((health_score - 15))
  done

  for warning in "${STARTUP_WARNINGS[@]}"; do
    health_score=$((health_score - 5))
  done

  [[ $health_score -lt 0 ]] && health_score=0

  echo -e "\n${COLORS[YELLOW]}Health Check Status${COLORS[RESET]}"

  if [[ $total_issues -eq 0 ]]; then
    echo -e "  ${COLORS[GREEN]}? All systems operational${COLORS[RESET]}"
  else
    echo -e "  ${COLORS[RED]}? Issues detected: ${#STARTUP_ERRORS[@]} errors, ${#STARTUP_WARNINGS[@]} warnings${COLORS[RESET]}"

    # Display errors
    if [[ ${#STARTUP_ERRORS[@]} -gt 0 ]]; then
      echo -e "\n${COLORS[RED]}Errors:${COLORS[RESET]}"
      for error in "${STARTUP_ERRORS[@]}"; do
        echo -e "  - $error"
      done
    fi

    # Display warnings
    if [[ ${#STARTUP_WARNINGS[@]} -gt 0 ]]; then
      echo -e "\n${COLORS[YELLOW]}Warnings:${COLORS[RESET]}"
      for warning in "${STARTUP_WARNINGS[@]}"; do
        echo -e "  - $warning"
      done
    fi
  fi

  echo -e "\n  System Health: $(progress_bar $health_score)"

  if [[ "$IS_TTY" == true ]]; then
    if [[ $health_score -ge 80 ]]; then
      echo -e "  Status:       ${COLORS[BG_GREEN]}${COLORS[WHITE]} HEALTHY ${COLORS[RESET]}"
    elif [[ $health_score -ge 50 ]]; then
      echo -e "  Status:       ${COLORS[BG_YELLOW]}${COLORS[WHITE]} DEGRADED ${COLORS[RESET]}"
    else
      echo -e "  Status:       ${COLORS[BG_RED]}${COLORS[WHITE]} CRITICAL ${COLORS[RESET]}"
    fi
  else
    echo "  Status:       $health_score/100"
  fi
}

display_startup_info() {
  echo -e "\n${COLORS[MAGENTA]}Startup Configuration${COLORS[RESET]}"

  # Process startup command (handle template variables if present)
  STARTUP_COMMAND=$(echo -e "${STARTUP:-}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

  echo -e "  ${COLORS[GREEN]}Command:${COLORS[RESET]}   ${COLORS[CYAN]}${STARTUP_COMMAND}${COLORS[RESET]}"
  echo -e "  ${COLORS[GREEN]}Work Dir:${COLORS[RESET]}  ${COLORS[CYAN]}$(pwd)${COLORS[RESET]}"

  local user_name=$(whoami 2>/dev/null || echo "user-$(id -u)")
  echo -e "  ${COLORS[GREEN]}User:${COLORS[RESET]}     ${COLORS[CYAN]}${user_name} (UID: $(id -u))${COLORS[RESET]}"

  echo -e "\n${COLORS[GRAY]}Key Environment Variables:${COLORS[RESET]}"
  env | grep -E "^(JAVA|PATH|HOME|USER|STARTUP)" | head -10 | while read -r line; do
    echo "  $line"
  done
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  # Initial setup
  setup_logging
  check_tty

  log_message "INFO" "Starting container initialization (v$SCRIPT_VERSION)"

  # Gather system information
  log_message "INFO" "Collecting system information..."
  get_system_info &
  local sys_pid=$!
  spinner $sys_pid "Gathering system information"

  get_java_info &
  local java_pid=$!
  spinner $java_pid "Checking Java runtime"

  get_network_info &
  local net_pid=$!
  spinner $net_pid "Collecting network information"

  get_container_info &
  local cont_pid=$!
  spinner $cont_pid "Detecting container environment"

  # Validate environment
  log_message "INFO" "Validating system environment..."
  if ! validate_environment; then
    log_message "ERROR" "Environment validation failed"
  fi

  if ! validate_system; then
    log_message "ERROR" "System validation failed"
  fi

  # Display startup information
  if [[ "$VERBOSE_MODE" == true ]]; then
    clear
    display_header
    display_system_info
    display_java_info
    display_network_info
    display_health_status
    display_startup_info
  else
    log_message "INFO" "Container ID: ${CONTAINER_INFO[id]}"
    log_message "INFO" "Internal IP: ${NETWORK_INFO[internal_ip]}"
    log_message "INFO" "Memory: ${SYSTEM_INFO[mem_used]}MB/${SYSTEM_INFO[mem_total]}MB"
    log_message "INFO" "Disk: ${SYSTEM_INFO[disk_pct]}% used"
    log_message "INFO" "Java: ${JAVA_INFO[version]} (${JAVA_INFO[vendor]})"
  fi

  # Check if we should proceed with startup
  if [[ ${#STARTUP_ERRORS[@]} -gt 0 ]]; then
    log_message "ERROR" "Critical errors detected during startup validation"

    if [[ "$IS_TTY" == true ]]; then
      echo -e "\n${COLORS[RED]}Critical errors detected. Startup aborted.${COLORS[RESET]}"
      echo -e "Check ${COLORS[CYAN]}$LOG_FILE${COLORS[RESET]} for details.\n"
    fi

    exit 1
  fi

  # Log all collected information
  {
    echo -e "\n=== System Information ==="
    for key in "${!SYSTEM_INFO[@]}"; do
      echo "  $key: ${SYSTEM_INFO[$key]}"
    done

    echo -e "\n=== Java Information ==="
    for key in "${!JAVA_INFO[@]}"; do
      echo "  $key: ${JAVA_INFO[$key]}"
    done

    echo -e "\n=== Network Information ==="
    for key in "${!NETWORK_INFO[@]}"; do
      echo "  $key: ${NETWORK_INFO[$key]}"
    done

    echo -e "\n=== Container Information ==="
    for key in "${!CONTAINER_INFO[@]}"; do
      echo "  $key: ${CONTAINER_INFO[$key]}"
    done

    echo -e "\n=== Startup Configuration ==="
    echo "  Command: $STARTUP_COMMAND"
    echo "  Working Directory: $(pwd)"
    echo "  User: $(whoami) (UID: $(id -u))"

    echo -e "\n=== Environment Variables ==="
    env | grep -E "^(JAVA|PATH|HOME|USER|STARTUP)" | head -20

    echo -e "\n=== Health Status ==="
    if [[ ${#STARTUP_ERRORS[@]} -gt 0 ]]; then
      echo "  Errors:"
      for error in "${STARTUP_ERRORS[@]}"; do
        echo "    - $error"
      done
    fi

    if [[ ${#STARTUP_WARNINGS[@]} -gt 0 ]]; then
      echo "  Warnings:"
      for warning in "${STARTUP_WARNINGS[@]}"; do
        echo "    - $warning"
      done
    fi
  } >> "$LOG_FILE"

  # Start the application
  log_message "INFO" "Launching application server..."
  log_message "INFO" "Startup command: $STARTUP_COMMAND"

  if [[ "$IS_TTY" == true ]]; then
    echo -e "\n${COLORS[GREEN]}===== LAUNCHING APPLICATION =====${COLORS[RESET]}"
    echo -e "${COLORS[GRAY]}Command: ${COLORS[CYAN]}${STARTUP_COMMAND}${COLORS[RESET]}\n"
  else
    log_message "INFO" "Executing startup command..."
  fi

  # Execute the startup command
  if [[ -n "$STARTUP_COMMAND" ]]; then
    # Run in current shell to preserve environment and handle signals properly
    exec $STARTUP_COMMAND
  else
    log_message "ERROR" "No startup command specified"
    echo -e "${COLORS[RED]}? No startup command specified${COLORS[RESET]}" >&2
    exit 1
  fi
}

# Execute main function
main "$@"