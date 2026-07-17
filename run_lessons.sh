#!/bin/bash

# 1. Determine comparison target (origin/main for GitHub CI, main for local)
TARGET_BRANCH="origin/main"
if ! git rev-parse --verify origin/main >/dev/null 2>&1; then
  TARGET_BRANCH="main"
fi

# 2. Get a list of changed files compared to the target branch
CHANGED_FILES=$(git diff --name-only "$TARGET_BRANCH"...HEAD)

# 3. Array to collect the specific spec files we want to run
SPECS_TO_RUN=()

for FILE in $CHANGED_FILES; do
  # If the changed file is an implementation file (e.g., exercises/exercise1.rb)
  if [[ "$FILE" =~ /(exercises|)\/?(.+)\.rb$ ]]; then
    # Extract directory path and file name base
    DIR_PATH=$(dirname "$FILE")
    BASE_NAME=$(basename "$FILE" .rb)
    
    # Climb up to find the lesson root if inside an 'exercises' folder
    LESSON_DIR="${DIR_PATH%/exercises}"
    SPEC_FILE="${LESSON_DIR}/spec/${BASE_NAME}_spec.rb"
    
    if [ -f "$SPEC_FILE" ]; then
      SPECS_TO_RUN+=("$SPEC_FILE")
    fi
    
  # If the changed file is already a spec file (e.g., spec/exercise1_spec.rb)
  elif [[ "$FILE" =~ spec/.+_spec\.rb$ ]]; then
    SPECS_TO_RUN+=("$FILE")
  fi
done

# 4. Remove duplicate entries from our list
UNIQUE_SPECS=$(echo "${SPECS_TO_RUN[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

# 5. Run RSpec on the files, or skip if no relevant files changed
if [ -n "$UNIQUE_SPECS" ]; then
  echo "🎯 Running targeted tests for: $UNIQUE_SPECS"
  bundle exec rspec $UNIQUE_SPECS
else
  echo "✅ No exercise or spec changes detected. Skipping tests."
fi
