#!/bin/sh
set -o allexport
export DOCKER_IMAGE_CBIOPORTAL=cbioportal/cbioportal:6.0.17
export FRONTEND_SRC=~/Desktop/cbioportal-frontend
set +o allexport

TEST_REPO_URL="https://github.com/cBioPortal/cbioportal-test.git"

# Create a temp dir and clone test repo
ROOT_DIR=$(pwd)
TEMP_DIR=$(mktemp -d)
git clone "$TEST_REPO_URL" "$TEMP_DIR/cbioportal-test" || exit 1
cd "$TEMP_DIR/cbioportal-test"

# Start backend
./scripts/docker-compose.sh --portal_type='web-and-data' --docker_args='-d'

# Wait for backend at localhost:8080
./utils/check-connection.sh --url=localhost:8080

# Import studies into backend
echo "lgg_ucsf_2014" > studies.txt
cat studies.txt
./scripts/import-data.sh --study_list=studies.txt

# Build frontend
printf "\nStarting frontend ...\n\n"
cd "$FRONTEND_SRC" || exit 1
export BRANCH_ENV=master
rm -rf node_modules
yarn install --frozen-lockfile
yarn run buildDLL:dev
yarn run buildModules
yarn start

# Wait for frontend at localhost:3000
printf "\nVerifying frontend connection ...\n\n"
cd "$TEMP_DIR/cbioportal-test" || exit 1
./utils/check-connection.sh --url=localhost:3000

# Cleanup
cd "$ROOT_DIR" || exit 1
rm -rf "$TEMP_DIR"