#!/system/bin/sh
# post-fs-data.sh: Monitor active app and check for new files only if specific apps are active

# Check if /data/adb/ksu/modules.img exists
if [ -f "/data/adb/ksu/modules.img" ]; then
  # If it exists, use this path
  MODULE_IMG_PATH="/data/adb/ksu/modules.img"
else
  # If not, use the fallback path
  MODULE_IMG_PATH="/data/adb/apd/modules.img"
fi

MODULES_DIR="/data/adb/modules"
MODULES_UPDATE_DIR="/data/adb/modules_update"
EXTRA_SPACE=$((1 * 1024 * 1024))  # 1 GB in KB

# List of app package names to check for
ACTIVE_APPS=("me.weishu.kernelsu" "com.rifsxd.ksunext" "me.bmax.apatch" "me.garfieldhan.apatch.next" "com.dergoogler.mmrl")

# Function to calculate the actual sparse size of the module directory
get_sparse_size() {
  du -s $MODULES_DIR | awk '{print $1}'  # Return size in KB
}

# Function to resize the modules.img file to the actual size + 1GB
resize_modules_img() {
  ACTUAL_SIZE=$(get_sparse_size)
  # Add extra space (1GB) to the actual size
  NEW_SIZE=$((ACTUAL_SIZE + EXTRA_SPACE))
  
  # Print the new size for debugging
  echo "Resizing modules.img to $NEW_SIZE KB (Actual + 1GB)"
  
  # Resize the sparse file (resize2fs requires the new size to be in the correct format)
  resize2fs $MODULE_IMG_PATH $NEW_SIZE
}

# Function to check if there are new files in the modules_update directory
check_for_new_files() {
  if [ "$(ls -A $MODULES_UPDATE_DIR)" ]; then
    # Files are present in the directory, so resize the modules.img
    echo "New files found in $MODULES_UPDATE_DIR, resizing modules.img..."
    resize_modules_img
  else
    echo "No new files found in $MODULES_UPDATE_DIR."
  fi
}

# Function to check the current active app
is_app_active() {
  CURRENT_APP=$(dumpsys activity | grep "mResumedActivity" | awk -F ' ' '{print $2}' | cut -d '/' -f 1)
  
  # Check if the current app matches any of the specified app package names
  for app in "${ACTIVE_APPS[@]}"; do
    if [[ "$CURRENT_APP" == "$app" ]]; then
      return 0  # App is active
    fi
  done

  return 1  # No specified app is active
}

# Infinite loop to monitor the active app and check for new files
while true; do
  # Check if one of the specified apps is active
  if is_app_active; then
    # If the app is active, run check_for_new_files
    check_for_new_files
  else
    echo "No specified app is active. Skipping check."
  fi

  # Sleep for 30 seconds before checking again
  sleep 30
done

