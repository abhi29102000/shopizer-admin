#!/bin/bash
set -e

log() { echo "[$(date '+%H:%M:%S')] $1"; }

log "Loading nvm..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

log "Switching to Node 12.22.7..."
nvm use 12.22.7 || (log "Node 12.22.7 not found, installing..." && nvm install 12.22.7 && nvm use 12.22.7)
log "Using Node $(node --version)"

NODE12="$NVM_DIR/versions/node/v12.22.7/bin/node"
NG12="$NVM_DIR/versions/node/v12.22.7/bin/ng"

if [ ! -f "$NG12" ]; then
  log "Angular CLI not found, installing @angular/cli@11..."
  npm install -g @angular/cli@11
  log "Angular CLI installed."
else
  log "Angular CLI already installed."
fi

if [ ! -d "node_modules" ]; then
  log "Installing dependencies..."
  npm install --legacy-peer-deps
  log "Pinning incompatible packages (@types/jquery, @types/minimatch, angular-file)..."
  npm install @types/jquery@3.5.14 @types/minimatch@3.0.5 angular-file@3.1.2 --legacy-peer-deps
  log "Dependencies installed."
else
  log "node_modules already exists, skipping install."
fi

log "Starting dev server at http://localhost:4200 ..."
"$NODE12" "$NG12" serve --open
