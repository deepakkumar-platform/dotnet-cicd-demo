#!/usr/bin/env bash
# Linux stand-in for the real deploy-windows.ps1 (IIS):
#   stop app -> back up live folder -> copy new files (keep existing appsettings) -> start app
set -euo pipefail

: "${ARTIFACT_DIR:?}" "${DEPLOY_PATH:?}" "${BACKUP_ROOT:?}" "${ENTRY_DLL:?}" "${PORT:?}" "${RUN_NUMBER:?}"
DEPLOY_PATH="${DEPLOY_PATH/#\~/$HOME}"
BACKUP_ROOT="${BACKUP_ROOT/#\~/$HOME}"
PID_FILE="$DEPLOY_PATH/app.pid"

DOTNET="${DOTNET_ROOT:-$HOME/.dotnet}/dotnet"
[ -x "$DOTNET" ] || DOTNET="$(command -v dotnet)"

# 1. Stop the running app (like stopping the IIS app pool)
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Stopping running app (pid $(cat "$PID_FILE"))"
  kill "$(cat "$PID_FILE")"
  for _ in $(seq 1 20); do kill -0 "$(cat "$PID_FILE")" 2>/dev/null || break; sleep 0.5; done
fi

# 2. Back up the live folder
if [ -d "$DEPLOY_PATH" ] && [ -n "$(ls -A "$DEPLOY_PATH")" ]; then
  mkdir -p "$BACKUP_ROOT"
  cp -a "$DEPLOY_PATH" "$BACKUP_ROOT/run-$RUN_NUMBER"
  echo "Backup: $BACKUP_ROOT/run-$RUN_NUMBER"
fi

# 3. Copy new files; appsettings*.json already on the server are not overwritten
mkdir -p "$DEPLOY_PATH"
find "$ARTIFACT_DIR" -maxdepth 1 -mindepth 1 ! -name 'appsettings*.json' -exec cp -a {} "$DEPLOY_PATH"/ \;
for cfg in "$ARTIFACT_DIR"/appsettings*.json; do
  [ -e "$cfg" ] || continue
  if [ -e "$DEPLOY_PATH/$(basename "$cfg")" ]; then
    echo "Keeping existing $(basename "$cfg")"
  else
    cp "$cfg" "$DEPLOY_PATH"/
  fi
done

# 4. Start the app. Clearing RUNNER_TRACKING_ID stops the runner from killing it when the job ends.
cd "$DEPLOY_PATH"
RUNNER_TRACKING_ID="" setsid nohup "$DOTNET" "$ENTRY_DLL" --urls "http://localhost:$PORT" > app.log 2>&1 < /dev/null &
echo $! > "$PID_FILE"
echo "Started $ENTRY_DLL on port $PORT (pid $(cat "$PID_FILE"))"
