#!/bin/bash
source /etc/environment

# Script: create-healthcheck-workload-mysql.sh
# Purpose: Create HR schema with duplicate names, bloat, and unused indexes for MySQL health check testing
# Version: 1.0 - Uses MySQL environment variables

# Function to display usage information
usage() {
  echo "Usage: $0 [--duration <MINUTES>] [--database <DB_NAME>] [--help]"
  echo
  echo "This script uses MySQL environment variables from ~/.bashrc:"
  echo "  MYSQL_HOST      - Database host"
  echo "  MYSQL_PORT      - Database port (default: 3306)"
  echo "  MYSQL_USER      - Database user"
  echo "  MYSQL_PASSWORD  - Database password"
  echo "  MYSQL_DATABASE  - Default database (can be overridden with --database)"
  echo
  echo "Options:"
  echo "  --duration <MINUTES>   Duration for workload in minutes (default: 1440)"
  echo "  --database <DB_NAME>   Override database name (default: uses MYSQL_DATABASE)"
  echo "  --help                 Display this help message"
  echo
  echo "Example:"
  echo "  $0 --duration 10 --database hr_messy"
  echo "  $0  # Uses all environment variables with defaults"
  exit 1
}

# Default values for benchmark run
DURATION=1440
DB_NAME=${MYSQL_DATABASE:-"hr_messy"}

# Parse input flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --duration)
      DURATION=$2
      shift 2
      ;;
    --database)
      DB_NAME=$2
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Check if required environment variables are set
if [ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
  echo "Error: Required MySQL environment variables are not set"
  echo "Please ensure the following are set in ~/.bashrc:"
  echo "  export MYSQL_HOST=your-db-host"
  echo "  export MYSQL_USER=your-db-user"
  echo "  export MYSQL_PASSWORD=your-db-password"
  echo "  export MYSQL_DATABASE=your-default-db (optional)"
  echo "  export MYSQL_PORT=3306 (optional, defaults to 3306)"
  echo ""
  echo "Then run: source ~/.bashrc"
  exit 1
fi

# Set defaults for optional environment variables
MYSQL_PORT=${MYSQL_PORT:-3306}

# Convert duration to seconds for workload
DURATION_SECONDS=$((DURATION * 60))

# Build MySQL connection string
MYSQL_CMD="mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD"

echo "========================================"
echo "Creating HR schema with duplicate names and bloat"
echo "========================================"
echo "Host: $MYSQL_HOST"
echo "Port: $MYSQL_PORT"
echo "User: $MYSQL_USER"
echo "Database: $DB_NAME"
echo "Duration: $DURATION minutes"
echo ""

# Test connection first
echo "Testing database connection..."
$MYSQL_CMD -e "SELECT 1" 2>/dev/null
if [ $? -ne 0 ]; then
  echo "Error: Unable to connect to database. Please check your environment variables:"
  echo "  MYSQL_HOST=$MYSQL_HOST"
  echo "  MYSQL_PORT=$MYSQL_PORT"
  echo "  MYSQL_USER=$MYSQL_USER"
  echo "  MYSQL_PASSWORD=[hidden]"
  exit 1
fi

# Create MySQL workload script
echo "Creating workload script..."
cat << 'WORKLOAD_SCRIPT_EOF' > /tmp/hr_workload_$$.sql
-- MySQL workload script with variable placeholders
-- Variables will be substituted by shell script

-- Update operations that don't change first_name
START TRANSACTION;
UPDATE employees SET salary = salary + @salary_increase WHERE emp_id = @emp_id;
COMMIT;

START TRANSACTION;
UPDATE employees SET department_id = @dept_id WHERE emp_id = @emp_id;
COMMIT;

START TRANSACTION;
UPDATE employees SET last_name = CONCAT(last_name, '_u') WHERE emp_id = @emp_id AND LENGTH(last_name) < 45;
COMMIT;

-- Insert duplicate rows (maintains the pattern)
START TRANSACTION;
INSERT INTO employees (first_name, last_name, email, department_id, salary)
SELECT first_name, CONCAT('dup_', last_name), CONCAT('dup_', email), department_id, @new_salary
FROM employees
WHERE emp_id = @emp_id;
COMMIT;

-- Delete some duplicate entries to create more bloat
START TRANSACTION;
DELETE FROM employees 
WHERE emp_id IN (
    SELECT emp_id 
    FROM (
        SELECT emp_id 
        FROM employees 
        WHERE last_name LIKE 'dup_%' 
        LIMIT 10
    ) AS subquery
);
COMMIT;

-- Use indexes in select queries (except unused ones)
-- SELECT COUNT(*) FROM employees WHERE department_id = @dept_id;
SELECT COUNT(*) FROM employee_projects WHERE emp_id = @emp_id;

-- Email lookups that will be slow without index 
SELECT emp_id, first_name, last_name, email FROM employees WHERE email = CONCAT('user', @emp_id, '@company.com');
SELECT COUNT(*) FROM employees WHERE email = CONCAT('user', @emp_id, '@company.com');

WORKLOAD_SCRIPT_EOF

# Function to execute workload with random values
execute_workload() {
  local emp_id=$((RANDOM % 3000000 + 1))
  local salary_increase=$((RANDOM % 4900 + 100))
  local new_salary=$((RANDOM % 120000 + 30000))
  local dept_id=$((RANDOM % 100 + 1))
  
  $MYSQL_CMD $DB_NAME << EOF
SET @emp_id = $emp_id;
SET @salary_increase = $salary_increase;
SET @new_salary = $new_salary;
SET @dept_id = $dept_id;
$(cat /tmp/hr_workload_$$.sql)
EOF
}

# Run workload to create more bloat
echo "Running workload for $DURATION minutes to create additional bloat..."
echo "This will run continuously with 2 concurrent connections..."

# Calculate iterations per second (rough estimate: 1 iteration per second per connection)
ITERATIONS_PER_SECOND=2
TOTAL_ITERATIONS=$((DURATION_SECONDS * ITERATIONS_PER_SECOND))
START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION_SECONDS))
ITERATION=0

# Run workload in background processes
(
  while [ $(date +%s) -lt $END_TIME ]; do
    execute_workload > /dev/null 2>&1
    ITERATION=$((ITERATION + 1))
    if [ $((ITERATION % 100)) -eq 0 ]; then
      echo "Progress: $ITERATION iterations completed..." >&2
    fi
  done
) &
PID1=$!

(
  while [ $(date +%s) -lt $END_TIME ]; do
    execute_workload > /dev/null 2>&1
    ITERATION=$((ITERATION + 1))
    if [ $((ITERATION % 100)) -eq 0 ]; then
      echo "Progress: $ITERATION iterations completed..." >&2
    fi
  done
) &
PID2=$!

# Wait for both background processes to complete
wait $PID1 $PID2 2>/dev/null

echo "Workload execution completed."

# Note: MySQL doesn't have autovacuum like PostgreSQL
# MySQL uses different maintenance mechanisms (OPTIMIZE TABLE, etc.)
echo "Note: MySQL uses different maintenance mechanisms than PostgreSQL."
echo "Consider running OPTIMIZE TABLE if needed for maintenance."

# Clean up
rm -f /tmp/hr_workload_$$.sql

echo ""
echo "To run the health check (if MySQL healthcheck script exists):"
echo "bash /workshop/src/mysql-healthcheck.sh --database $DB_NAME --top-tables --duplicate-indexes --unused-indexes --bloat-analysis"
echo ""
echo ""
echo "========================================"
echo "Benchmark completed!"
echo "========================================"

