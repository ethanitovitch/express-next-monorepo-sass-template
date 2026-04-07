#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ]; then
  read -p "Enter your app name (camelCase, e.g. myApp): " APP_NAME
else
  APP_NAME=$1
fi

if [ -z "$APP_NAME" ]; then
  echo -e "${RED}App name is required${NC}"
  exit 1
fi

DB_NAME=$(echo "$APP_NAME" | sed 's/\([A-Z]\)/_\1/g' | tr '[:upper:]' '[:lower:]')_db

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Setting up ${GREEN}$APP_NAME${NC}"
echo -e "${BLUE}  Database:  ${GREEN}$DB_NAME${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# --- Copy .env files ---
echo -e "${YELLOW}[1/4] Copying .env files...${NC}"

cp "$SCRIPT_DIR/backend/.env.example" "$SCRIPT_DIR/backend/.env"
cp "$SCRIPT_DIR/frontend/.env.example" "$SCRIPT_DIR/frontend/.env"
cp "$SCRIPT_DIR/shared/db/.env.example" "$SCRIPT_DIR/shared/db/.env"

echo -e "${GREEN}  ✓ backend/.env${NC}"
echo -e "${GREEN}  ✓ frontend/.env${NC}"
echo -e "${GREEN}  ✓ shared/db/.env${NC}"

# --- Update database name ---
echo -e "${YELLOW}[2/4] Updating database name to ${DB_NAME}...${NC}"

sed -i '' "s/dev_db/${DB_NAME}/g" "$SCRIPT_DIR/backend/.env"
sed -i '' "s/dev_db/${DB_NAME}/g" "$SCRIPT_DIR/shared/db/.env"
sed -i '' "s/dev_db/${DB_NAME}/g" "$SCRIPT_DIR/docker-compose.yml"

echo -e "${GREEN}  ✓ backend/.env${NC}"
echo -e "${GREEN}  ✓ shared/db/.env${NC}"
echo -e "${GREEN}  ✓ docker-compose.yml${NC}"

# --- Update package.json name ---
echo -e "${YELLOW}[3/4] Updating package name...${NC}"

sed -i '' "s/\"name\": \"express-next-monorepo-template\"/\"name\": \"${APP_NAME}\"/g" "$SCRIPT_DIR/package.json"

echo -e "${GREEN}  ✓ package.json → ${APP_NAME}${NC}"

# --- Install dependencies ---
echo -e "${YELLOW}[4/4] Installing dependencies...${NC}"

cd "$SCRIPT_DIR"
pnpm install

echo -e "${GREEN}  ✓ Dependencies installed${NC}"
echo ""

# --- Open terminals ---
echo -e "${BLUE}Opening terminals...${NC}"

osascript <<EOF
tell application "Terminal"
  activate

  -- Tab 1: Docker
  do script "cd '$SCRIPT_DIR' && echo '🐳 Starting Docker services...' && docker compose up"

  -- Tab 2: Migrations (waits for postgres)
  do script "cd '$SCRIPT_DIR/shared/db' && echo '⏳ Waiting for PostgreSQL...' && while ! docker inspect --format='{{.State.Health.Status}}' dev-postgres 2>/dev/null | grep -q healthy; do sleep 2; done && echo '✅ PostgreSQL ready — running migrations...' && pnpm db:migrate"

  -- Tab 3: Backend
  do script "cd '$SCRIPT_DIR/backend' && echo '⏳ Waiting for Docker services...' && sleep 20 && echo '🚀 Starting backend...' && pnpm dev"

  -- Tab 4: Frontend
  do script "cd '$SCRIPT_DIR/frontend' && echo '🖥️  Starting frontend...' && pnpm dev"
end tell
EOF

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  $APP_NAME is starting up!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Frontend:  ${BLUE}http://localhost:3000${NC}"
echo -e "  Backend:   ${BLUE}http://localhost:8000${NC}"
echo -e "  MailHog:   ${BLUE}http://localhost:8025${NC}"
echo -e "  GlitchTip: ${BLUE}http://localhost:8100${NC}"
echo ""
