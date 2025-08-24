#!/bin/bash
set -euo pipefail

readonly SCRIPT_VERSION="2.2.0"
readonly LOG_FILE="/var/log/container-startup.log"
readonly MAX_LOG_SIZE=$((10 * 1024 * 1024)) # 10MB
readonly MIN_DISK_SPACE=$((5 * 1024 * 1024)) # 5GB in KB
readonly MIN_MEMORY=$((512 * 1024)) # 512MB in KB

declare -A COLORS=(
  ["RESET"]='\033[0m' ["BOLD"]='\033[1m' ["DIM"]='\033[2m'
  ["RED"]='\033[0;31m' ["GREEN"]='\033[0;32m' ["YELLOW"]='\033[1;33m'
  ["BLUE"]='\033[0;34m' ["MAGENTA"]='\033[0;35m' ["CYAN"]='\033[0;36m'
  ["WHITE"]='\033[1;37m' ["GRAY"]='\033[0;90m'
  ["BG_RED"]='\033[41m' ["BG_GREEN"]='\033[42m' ["BG_YELLOW"]='\033[43m'
)

declare -A SYSTEM_INFO JAVA_INFO NETWORK_INFO CONTAINER_INFO
declare -a STARTUP_WARNINGS=() STARTUP_ERRORS=()
declare STARTUP_COMMAND=""
declare IS_TTY=false
declare VERBOSE_MODE=false

# Optimalizované logování s buffer
LOG_BUFFER=""
log_to_buffer() {
  LOG_BUFFER+="\$1\n"
}

flush_log_buffer() {
  if [[ -n "$LOG_BUFFER" ]]; then
    echo -e "$LOG_BUFFER" >> "$LOG_FILE"
    LOG_BUFFER=""
  fi
}

setup_logging() {
  local log_dir=$(dirname "$LOG_FILE")

  # Vytvoř log adresář pokud neexistuje
  [[ ! -d "$log_dir" ]] && mkdir -p "$log_dir" 2>/dev/null

  # Rotace logu optimalizovaná
  if [[ -f "$LOG_FILE" ]]; then
    local log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    [[ $log_size -gt $MAX_LOG_SIZE ]] && mv "$LOG_FILE" "${LOG_FILE}.old" 2>/dev/null
  fi

  # Batch write úvodní informace
  {
    echo "============================================================="
    echo " Container Startup Log - $(date)"
    echo " Script Version: $SCRIPT_VERSION"
    echo "============================================================="
  } > "$LOG_FILE"
}

check_tty() {
  [[ -t 1 ]] && { IS_TTY=true; VERBOSE_MODE=true; }
}

# Optimalizovaný spinner s lepší podporou TTY
spinner() {
  local pid=\$1
  local message="\$2"
  local delay=0.1
  local spin_chars='|/-\'

  if [[ "$IS_TTY" != true || "$VERBOSE_MODE" != true ]]; then
    echo -n "[$message] "
    wait "$pid" 2>/dev/null
    return $?
  fi

  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r [%c] %s" "${spin_chars:$((i%4)):1}" "$message"
    ((i++))
    sleep "$delay"
  done

  wait "$pid"
  local status=$?
  printf "\r"

  if [[ $status -eq 0 ]]; then
    echo -e "${COLORS[GREEN]}✓${COLORS[RESET]} [$message] - Completed successfully"
  else
    echo -e "${COLORS[RED]}✗${COLORS[RESET]} [$message] - Failed with exit code $status"
  fi

  return $status
}

# Optimalizovaný progress bar
progress_bar() {
  local progress=\$1
  local width=${2:-40}
  
  [[ "$IS_TTY" != true ]] && { echo -n "[${progress}%] "; return; }

  local filled=$((progress * width / 100))
  local empty=$((width - filled))

  printf "["
  [[ $filled -gt 0 ]] && printf "%${filled}s" | tr ' ' '█'
  [[ $empty -gt 0 ]] && printf "%${empty}s" | tr ' ' '░'
  printf "] %d%%" "$progress"
}

log_message() {
  local level=\$1
  local message=\$2
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local color="${COLORS[$level]:-}"
  local log_entry="[$timestamp] [$level] $message"

  if [[ "$IS_TTY" == true ]]; then
    echo -e "${color}${log_entry}${COLORS[RESET]}"
  else
    echo "$log_entry"
  fi

  log_to_buffer "[$timestamp] [$level] ${message}"
}

# Optimalizované získávání systémových informací s méně subprocess voláními
get_system_info() {
  # Memory info v jednom průchodu
  local mem_info
  mem_info=$(awk '/^MemTotal:|^MemAvailable:/ {print \$2}' /proc/meminfo 2>/dev/null)
  if [[ -n "$mem_info" ]]; then
    local mem_values=($mem_info)
    SYSTEM_INFO[mem_total]=$((${mem_values[0]:-0}/1024))
    SYSTEM_INFO[mem_avail]=$((${mem_values[1]:-0}/1024))
    SYSTEM_INFO[mem_used]=$((SYSTEM_INFO[mem_total] - SYSTEM_INFO[mem_avail]))
    SYSTEM_INFO[mem_pct]=$(( SYSTEM_INFO[mem_total] > 0 ? SYSTEM_INFO[mem_used] * 100 / SYSTEM_INFO[mem_total] : 0 ))
  fi

  # CPU info
  SYSTEM_INFO[cpu_cores]=$(nproc 2>/dev/null || echo 1)
  SYSTEM_INFO[cpu_model]=$(awk -F': ' '/^model name/ {print \$2; exit}' /proc/cpuinfo 2>/dev/null || echo "Unknown")
  SYSTEM_INFO[load_avg]=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null || echo "0")

  # Disk info v jednom volání
  local disk_info
  disk_info=$(df -k / 2>/dev/null | awk 'NR==2 {print \$2, \$3, \$4, \$5}')
  if [[ -n "$disk_info" ]]; then
    local disk_values=($disk_info)
    SYSTEM_INFO[disk_total]=${disk_values[0]:-0}
    SYSTEM_INFO[disk_used]=${disk_values[1]:-0}
    SYSTEM_INFO[disk_avail]=${disk_values[2]:-0}
    SYSTEM_INFO[disk_pct]=${disk_values[3]%?}
  fi

  # Ostatní info
  SYSTEM_INFO[uptime]=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")
  SYSTEM_INFO[kernel]=$(uname -r 2>/dev/null || echo "Unknown")
}

# Optimalizované Java info s cache
get_java_info() {
  local java_cmd
  java_cmd=$(command -v java 2>/dev/null)
  
  if [[ -n "$java_cmd" ]]; then
    local java_version_output
    java_version_output=$(java -version 2>&1 | head -n3)
    
    JAVA_INFO[version]=$(echo "$java_version_output" | head -n1 | grep -o '"[^"]*"' | tr -d '"' || echo "Unknown")
    JAVA_INFO[vendor]=$(echo "$java_version_output" | grep -iE "openjdk|oracle|azul|amazon" | head -n1 || echo "Unknown")
    JAVA_INFO[home]=$(dirname $(dirname $(readlink -f "$java_cmd" 2>/dev/null)) 2>/dev/null || echo "Unknown")

    # Check for outdated versions
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

# Optimalizované network info
get_network_info() {
  NETWORK_INFO[hostname]=$(hostname 2>/dev/null || echo "Unknown")
  
  # Internal IP optimalizovaně
  NETWORK_INFO[internal_ip]=$(ip route get 1.1.1.1 2>/dev/null | awk '{print \$7; exit}' || echo "Unknown")

  # External IP s timeoutem
  NETWORK_INFO[external_ip]=$(timeout 3 curl -s --max-time 2 ifconfig.me 2>/dev/null || echo "Unknown")

  # Network interfaces v jednom průchodu
  local interfaces
  interfaces=$(ip -br addr show 2>/dev/null | awk '$2=="UP" && \$3!~/^127/ {printf "%s(%s) ", \$1, \$3}' || echo "None")
  NETWORK_INFO[interfaces]=${interfaces% }
}

get_container_info() {
  if [[ -f /.dockerenv || -f /.dockerinit ]]; then
    CONTAINER_INFO[type]="Docker"
    CONTAINER_INFO[id]=$(awk -F'/' '/docker/ {print substr($NF,1,12); exit}' /proc/self/cgroup 2>/dev/null || echo "Unknown")
  elif [[ -f /run/.containerenv ]]; then
    CONTAINER_INFO[type]="Podman"
    CONTAINER_INFO[id]=$(hostname 2>/dev/null || echo "Unknown")
  else
    CONTAINER_INFO[type]="None"
    CONTAINER_INFO[id]="N/A"
  fi

  CONTAINER_INFO[name]=$(hostname 2>/dev/null || echo "Unknown")
}

# Optimalizované validace s batch processingem
validate_system() {
  local errors=0 warnings=0

  # Batch check directories
  for dir in /home/container /tmp /var/log; do
    [[ ! -d "$dir" ]] && STARTUP_ERRORS+=("Missing critical directory: $dir") && ((errors++))
  done

  # Disk validation
  local disk_pct=${SYSTEM_INFO[disk_pct]:-0}
  if [[ $disk_pct -gt 95 ]]; then
    STARTUP_ERRORS+=("Critical disk space usage: ${disk_pct}% used")
    ((errors++))
  elif [[ $disk_pct -gt 90 ]]; then
    STARTUP_WARNINGS+=("High disk space usage: ${disk_pct}% used")
    ((warnings++))
  fi

  # Memory validation
  local mem_pct=${SYSTEM_INFO[mem_pct]:-0}
  if [[ $mem_pct -gt 95 ]]; then
    STARTUP_ERRORS+=("Critical memory usage: ${mem_pct}% used")
    ((errors++))
  elif [[ $mem_pct -gt 90 ]]; then
    STARTUP_WARNINGS+=("High memory usage: ${mem_pct}% used")
    ((warnings++))
  fi

  # Load validation
  local load_avg=${SYSTEM_INFO[load_avg]:-0}
  local load_threshold=$((${SYSTEM_INFO[cpu_cores]:-1} * 2))
  if (( $(echo "$load_avg > $load_threshold" | bc -l 2>/dev/null || echo "0") )); then
    STARTUP_WARNINGS+=("High system load: $load_avg (threshold: $load_threshold)")
    ((warnings++))
  fi

  return $((errors > 0 ? 1 : 0))
}

validate_environment() {
  local required_vars=("PATH" "HOME")
  local missing_vars=()

  for var in "${required_vars[@]}"; do
    [[ -z "${!var:-}" ]] && missing_vars+=("$var")
  done

  [[ ${#missing_vars[@]} -gt 0 ]] && STARTUP_WARNINGS+=("Missing environment variables: ${missing_vars[*]}")
  [[ -z "${STARTUP:-}" ]] && STARTUP_ERRORS+=("No STARTUP command defined") && return 1

  return 0
}

# Optimalizované display funkce
display_header() {
  local width=60
  local header="Container Management System v$SCRIPT_VERSION"
  local padding=$(((width - ${#header}) / 2))

  if [[ "$IS_TTY" == true ]]; then
    printf "${COLORS[BLUE]}┌%${width}s┐${COLORS[RESET]}\n" | tr ' ' '─'
    printf "${COLORS[BLUE]}│${COLORS[RESET]}%${padding}s${COLORS[CYAN]}%s${COLORS[RESET]}%${padding}s${COLORS[BLUE]}│${COLORS[RESET]}\n" "" "$header" ""
    printf "${COLORS[BLUE]}├%${width}s┤${COLORS[RESET]}\n" | tr ' ' '─'
    printf "${COLORS[BLUE]}│${COLORS[RESET]} ${COLORS[YELLOW]}ID:${COLORS[RESET]} %-15s ${COLORS[YELLOW]}Type:${COLORS[RESET]} %-10s ${COLORS[YELLOW]}Uptime:${COLORS[RESET]} %-15s ${COLORS[BLUE]}│${COLORS[RESET]}\n" \
      "${CONTAINER_INFO[id]:0:15}" \
      "${CONTAINER_INFO[type]:0:10}" \
      "${SYSTEM_INFO[uptime]:0:15}"
    printf "${COLORS[BLUE]}└%${width}s┘${COLORS[RESET]}\n" | tr ' ' '─'
  else
    echo "============================================================="
    echo " $header"
    echo " ID: ${CONTAINER_INFO[id]} | Type: ${CONTAINER_INFO[type]} | Uptime: ${SYSTEM_INFO[uptime]}"
    echo "============================================================="
  fi
}

display_system_info() {
  echo -e "\n${COLORS[CYAN]}📊 System Information${COLORS[RESET]}"

  if [[ "$IS_TTY" == true ]]; then
    printf "  ${COLORS[GREEN]}Memory:${COLORS[RESET]}   %sMB/%sMB (%s%%) %s\n" \
      "${SYSTEM_INFO[mem_used]}" "${SYSTEM_INFO[mem_total]}" "${SYSTEM_INFO[mem_pct]}" "$(progress_bar ${SYSTEM_INFO[mem_pct]})"
    printf "  ${COLORS[GREEN]}CPU:${COLORS[RESET]}      %s cores | Load: %s\n" \
      "${SYSTEM_INFO[cpu_cores]}" "${SYSTEM_INFO[load_avg]}"
    printf "  ${COLORS[GREEN]}Disk:${COLORS[RESET]}     %sKB/%sKB (%s%%) %s\n" \
      "${SYSTEM_INFO[disk_used]}" "${SYSTEM_INFO[disk_total]}" "${SYSTEM_INFO[disk_pct]}" "$(progress_bar ${SYSTEM_INFO[disk_pct]})"
    printf "  ${COLORS[GREEN]}Kernel:${COLORS[RESET]}   %s\n" "${SYSTEM_INFO[kernel]}"
  else
    printf "  Memory: %sMB/%sMB (%s%%)\n" "${SYSTEM_INFO[mem_used]}" "${SYSTEM_INFO[mem_total]}" "${SYSTEM_INFO[mem_pct]}"
    printf "  CPU: %s cores | Load: %s\n" "${SYSTEM_INFO[cpu_cores]}" "${SYSTEM_INFO[load_avg]}"
    printf "  Disk: %sKB/%sKB (%s%%)\n" "${SYSTEM_INFO[disk_used]}" "${SYSTEM_INFO[disk_total]}" "${SYSTEM_INFO[disk_pct]}"
    printf "  Kernel: %s\n" "${SYSTEM_INFO[kernel]}"
  fi
}

display_java_info() {
  echo -e "\n${COLORS[CYAN]}☕ Java Runtime${COLORS[RESET]}"
  printf "  ${COLORS[GREEN]}Version:${COLORS[RESET]}  %s\n" "${JAVA_INFO[version]}"
  printf "  ${COLORS[GREEN]}Vendor:${COLORS[RESET]}   %s\n" "${JAVA_INFO[vendor]}"
  printf "  ${COLORS[GREEN]}Home:${COLORS[RESET]}     %s\n" "${JAVA_INFO[home]}"
}

display_network_info() {
  echo -e "\n${COLORS[CYAN]}🌐 Network Information${COLORS[RESET]}"
  printf "  ${COLORS[GREEN]}Hostname:${COLORS[RESET]}   %s\n" "${NETWORK_INFO[hostname]}"
  printf "  ${COLORS[GREEN]}Internal IP:${COLORS[RESET]} %s\n" "${NETWORK_INFO[internal_ip]}"
  printf "  ${COLORS[GREEN]}External IP:${COLORS[RESET]} %s\n" "${NETWORK_INFO[external_ip]}"
  printf "  ${COLORS[GREEN]}Interfaces:${COLORS[RESET]}  %s\n" "${NETWORK_INFO[interfaces]}"
}

display_health_status() {
  local total_issues=$(( ${#STARTUP_ERRORS[@]} + ${#STARTUP_WARNINGS[@]} ))
  local health_score=$((100 - ${#STARTUP_ERRORS[@]} * 15 - ${#STARTUP_WARNINGS[@]} * 5))
  [[ $health_score -lt 0 ]] && health_score=0

  echo -e "\n${COLORS[YELLOW]}🏥 Health Check Status${COLORS[RESET]}"

  if [[ $total_issues -eq 0 ]]; then
    echo -e "  ${COLORS[GREEN]}✓ All systems operational${COLORS[RESET]}"
  else
    echo -e "  ${COLORS[RED]}⚠ Issues detected: ${#STARTUP_ERRORS[@]} errors, ${#STARTUP_WARNINGS[@]} warnings${COLORS[RESET]}"

    [[ ${#STARTUP_ERRORS[@]} -gt 0 ]] && {
      echo -e "\n${COLORS[RED]}Errors:${COLORS[RESET]}"
      printf '  - %s\n' "${STARTUP_ERRORS[@]}"
    }

    [[ ${#STARTUP_WARNINGS[@]} -gt 0 ]] && {
      echo -e "\n${COLORS[YELLOW]}Warnings:${COLORS[RESET]}"
      printf '  - %s\n' "${STARTUP_WARNINGS[@]}"
    }
  fi

  printf "\n  System Health: %s\n" "$(progress_bar $health_score)"

  if [[ "$IS_TTY" == true ]]; then
    local status_color status_text
    if [[ $health_score -ge 80 ]]; then
      status_color="${COLORS[BG_GREEN]}" status_text="HEALTHY"
    elif [[ $health_score -ge 50 ]]; then
      status_color="${COLORS[BG_YELLOW]}" status_text="DEGRADED"
    else
      status_color="${COLORS[BG_RED]}" status_text="CRITICAL"
    fi
    printf "  Status:       %s${COLORS[WHITE]} %s ${COLORS[RESET]}\n" "$status_color" "$status_text"
  else
    printf "  Status:       %s/100\n" "$health_score"
  fi
}

display_startup_info() {
  echo -e "\n${COLORS[MAGENTA]}🚀 Startup Configuration${COLORS[RESET]}"

  STARTUP_COMMAND="${STARTUP:-}"
  printf "  ${COLORS[GREEN]}Command:${COLORS[RESET]}   ${COLORS[CYAN]}%s${COLORS[RESET]}\n" "$STARTUP_COMMAND"
  printf "  ${COLORS[GREEN]}Work Dir:${COLORS[RESET]}  ${COLORS[CYAN]}%s${COLORS[RESET]}\n" "$(pwd)"
  printf "  ${COLORS[GREEN]}User:${COLORS[RESET]}      ${COLORS[CYAN]}%s (UID: %s)${COLORS[RESET]}\n" "$(whoami 2>/dev/null || echo "unknown")" "$(id -u)"

  echo -e "\n${COLORS[GRAY]}Key Environment Variables:${COLORS[RESET]}"
  env | grep -E "^(JAVA|PATH|HOME|USER|STARTUP)" | head -10 | sed 's/^/  /'
}

# Batch collection s paralelizací
collect_all_info() {
  get_system_info &
  local sys_pid=$!
  
  get_java_info &
  local java_pid=$!
  
  get_network_info &
  local net_pid=$!
  
  get_container_info &
  local cont_pid=$!

  # Wait s progress
  spinner $sys_pid "Gathering system information"
  spinner $java_pid "Checking Java runtime"
  spinner $net_pid "Collecting network information"
  spinner $cont_pid "Detecting container environment"
}

main() {
  setup_logging
  check_tty

  log_message "INFO" "Starting container initialization (v$SCRIPT_VERSION)"

  # Batch informace s paralelizací
  collect_all_info

  log_message "INFO" "Validating system environment..."
  validate_environment || log_message "ERROR" "Environment validation failed"
  validate_system || log_message "ERROR" "System validation failed"

  # Display podle módu
  if [[ "$VERBOSE_MODE" == true ]]; then
    clear 2>/dev/null || true
    display_header
    display_system_info
    display_java_info
    display_network_info
    display_health_status
    display_startup_info
  else
    log_message "INFO" "Container ID: ${CONTAINER_INFO[id]}"
    log_message "INFO" "Memory: ${SYSTEM_INFO[mem_used]}MB/${SYSTEM_INFO[mem_total]}MB"
    log_message "INFO" "Java: ${JAVA_INFO[version]}"
  fi

  # Critical error check
  if [[ ${#STARTUP_ERRORS[@]} -gt 0 ]]; then
    log_message "ERROR" "Critical errors detected during startup validation"
    [[ "$IS_TTY" == true ]] && echo -e "\n${COLORS[RED]}❌ Critical errors detected. Startup aborted.${COLORS[RESET]}"
    flush_log_buffer
    exit 1
  fi

  # Batch log všech informací
  {
    printf "\n=== System Information ===\n"
    for key in "${!SYSTEM_INFO[@]}"; do
      printf "  %s: %s\n" "$key" "${SYSTEM_INFO[$key]}"
    done
    
    printf "\n=== Container Information ===\n"
    for key in "${!CONTAINER_INFO[@]}"; do
      printf "  %s: %s\n" "$key" "${CONTAINER_INFO[$key]}"
    done
  } >> "$LOG_FILE"

  flush_log_buffer

  log_message "INFO" "Launching application: $STARTUP_COMMAND"

  if [[ "$IS_TTY" == true ]]; then
    echo -e "\n${COLORS[GREEN]}🚀 LAUNCHING APPLICATION${COLORS[RESET]}"
    echo -e "${COLORS[GRAY]}Command: ${COLORS[CYAN]}${STARTUP_COMMAND}${COLORS[RESET]}\n"
  fi

  [[ -n "$STARTUP_COMMAND" ]] && exec $STARTUP_COMMAND || {
    log_message "ERROR" "No startup command specified"
    exit 1
  }
}

# Signal handling pro clean shutdown
trap 'echo -e "\n${COLORS[YELLOW]}Received signal, shutting down...${COLORS[RESET]}"; flush_log_buffer; exit 130' INT TERM

main "$@"