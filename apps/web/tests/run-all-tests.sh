#!/bin/bash
set -e

echo "Running Database Ecosystem Verification Tests..."
echo "================================================="

for file in tests/test-*.mjs; do
  echo "Running $file..."
  node "$file"
  echo "-------------------------------------------------"
done

echo "✅ All backend verification tests executed."
