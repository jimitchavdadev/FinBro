#!/bin/bash

# Define the base URL and test data
BASE_URL="http://localhost:3000/api"
PHONE_NUMBER="1234567890"  # Updated phone number
PASSWORD="somepass"        # Updated password

# Define an expense to be added
AMOUNT="50.00"
CATEGORY="Groceries"
NOTES="Weekly grocery run"
DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Step 1: Login and get the JWT token
echo "➡️ Step 1: Logging in to get JWT token..."
LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:3000/api/auth" \
-H "Content-Type: application/json" \
-d '{
  "phoneNumber": "1234567890",
  "password": "somepass"
}')

# The rest of the script remains the same.

# Extract the token using `jq` or a simple string manipulation
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "❌ Login failed. Check credentials and server status."
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo "✅ Login successful. Token obtained."
echo "Token: $TOKEN"

# Step 2: Add a new expense using the JWT token
echo "
➡️ Step 2: Adding a new expense..."
ADD_EXPENSE_RESPONSE=$(curl -s -X POST "$BASE_URL/expenses" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
  "amount": "'"$AMOUNT"'",
  "date": "'"$DATE"'",
  "category": "'"$CATEGORY"'",
  "notes": "'"$NOTES"'"
}')

echo "Response from add expense endpoint:"
echo "$ADD_EXPENSE_RESPONSE"

if [ $(echo "$ADD_EXPENSE_RESPONSE" | jq -r '.id' 2>/dev/null) == "null" ]; then
    echo "❌ Failed to add expense. Check server logs."
else
    echo "✅ Expense added successfully."
fi

# Step 3: Fetch the history for all expenses
echo "
➡️ Step 3: Fetching all expense history..."
HISTORY_RESPONSE_ALL=$(curl -s -X GET "$BASE_URL/history" \
-H "Authorization: Bearer $TOKEN")

echo "Response from history endpoint (All categories):"
echo "$HISTORY_RESPONSE_ALL"

if [ -z "$(echo "$HISTORY_RESPONSE_ALL" | jq '.[]' 2>/dev/null)" ]; then
    echo "❌ No history found or an error occurred."
else
    echo "✅ History retrieved successfully."
fi


# Step 4: Fetch the history for a specific category
echo "
➡️ Step 4: Fetching history for a specific category ($CATEGORY)..."
HISTORY_RESPONSE_FILTERED=$(curl -s -X GET "$BASE_URL/history?category=$CATEGORY" \
-H "Authorization: Bearer $TOKEN")

echo "Response from history endpoint (Filtered by category):"
echo "$HISTORY_RESPONSE_FILTERED"

if [ -z "$(echo "$HISTORY_RESPONSE_FILTERED" | jq '.[]' 2>/dev/null)" ]; then
    echo "❌ No filtered history found or an error occurred."
else
    echo "✅ Filtered history retrieved successfully."
fi

echo "
Script execution finished."