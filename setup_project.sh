#!/bin/bash

#  Getting a project name 
read -p "Enter project name suffix: " INPUT

if [[ -z "$INPUT" ]]; then
  echo "Error: Project name cannot be empty."
  exit 1
fi

PROJECT_DIR="attendance_tracker_${INPUT}"

# ── Trap: runs on Ctrl+C ───────
cleanup() {
  echo ""
  echo "Interrupt detected! Cleaning up..."
  if [[ -d "$PROJECT_DIR" ]]; then
    tar -czf "${PROJECT_DIR}_archive.tar.gz" "$PROJECT_DIR"
    echo "Archive created: ${PROJECT_DIR}_archive.tar.gz"
    rm -rf "$PROJECT_DIR"
    echo "Incomplete directory removed."
  fi
  exit 1
}

trap cleanup SIGINT

# ── Create directories ───────────────────────────────────────
echo "Creating project: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR/Helpers" "$PROJECT_DIR/reports"

if [[ $? -ne 0 ]]; then
  echo "Error: Could not create directories. Check permissions."
  exit 1
fi

echo "Directories created."

# ── Write project files (exact content, unmodified) ──────────
cat > "$PROJECT_DIR/Helpers/config.json" << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

cat > "$PROJECT_DIR/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

cat > "$PROJECT_DIR/reports/reports.log" << 'EOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

cat > "$PROJECT_DIR/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    
    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            
            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100
            
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

echo "Files written."

# Updating thresholds with sed 
read -p "Update attendance thresholds? (yes/no): " UPDATE

if [[ "$UPDATE" == "yes" ]]; then
  read -p "  New Warning threshold % (default 75): " WARN_VAL
  read -p "  New Failure threshold % (default 50): " FAIL_VAL

  if ! [[ "$WARN_VAL" =~ ^[0-9]+$ ]] || ! [[ "$FAIL_VAL" =~ ^[0-9]+$ ]]; then
    echo "Invalid input. Must be whole numbers. Keeping defaults."
  elif [[ "$FAIL_VAL" -ge "$WARN_VAL" ]]; then
    echo "Failure must be less than Warning. Keeping defaults."
  else
    sed -i "s/\"warning\": [0-9][0-9]*/\"warning\": $WARN_VAL/" "$PROJECT_DIR/Helpers/config.json"
    sed -i "s/\"failure\": [0-9][0-9]*/\"failure\": $FAIL_VAL/" "$PROJECT_DIR/Helpers/config.json"
    echo "Thresholds updated: Warning=${WARN_VAL}%, Failure=${FAIL_VAL}%"
  fi
fi

# Health check 
echo ""
echo "--- Health Check ---"

if python3 --version > /dev/null 2>&1; then
  echo "[OK]   python3 found: $(python3 --version)"
else
  echo "[WARN] python3 not found. App will not run."
fi

echo "Checking files..."
ALL_OK=true
for FILE in "$PROJECT_DIR/attendance_checker.py" \
            "$PROJECT_DIR/Helpers/config.json" \
            "$PROJECT_DIR/Helpers/assets.csv" \
            "$PROJECT_DIR/reports/reports.log"; do
  if [[ -f "$FILE" ]]; then
    echo "  [FOUND]   $FILE"
  else
    echo "  [MISSING] $FILE"
    ALL_OK=false
  fi
done

if $ALL_OK; then
  echo ""
  echo "Setup complete: $PROJECT_DIR"
  echo "Run with: cd $PROJECT_DIR && python3 attendance_checker.py"
else
  echo "Setup finished with missing files."
fi
