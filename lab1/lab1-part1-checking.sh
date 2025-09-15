#!/usr/bin/env bash

BASE_DIR="/home/admin/pzs"

USERS_TO_CHECK=(iit11 iit12 iit21 iit22 iit3 root)

FILES_TO_CHECK=(
  "$BASE_DIR"/pzs11/file1{1,2,3,4,5}
  "$BASE_DIR"/pzs12/file2{1,2,3,4,5}
  "$BASE_DIR"/pzs13/file3{1,2,3,4,5}
  "$BASE_DIR"/pzs14/file4{1,2,3,4,5}
  "$BASE_DIR"/pzs15/file5{1,2,3,4,5}
)

can_run() {
  local user=$1
  shift
  local cmd=$@

  sudo -u "$user" bash -c "$cmd" &>/dev/null

  if [ $? -eq 0 ]; then
    echo -e "\e[32mSUCCESS\e[0m"
  else
    echo -e "\e[31mFAIL\e[0m"
  fi
}

check_permissions() {
  for user in "${USERS_TO_CHECK[@]}"; do
    for file in "${FILES_TO_CHECK[@]}"; do
      local short_file_path=${file#"$BASE_DIR/"}

      local can_read=$(can_run "$user" "cat '$file'")
      local can_write=$(can_run "$user" "echo 'echo "User $user can write"' >> '$file'")
      local can_execute=$(can_run "$user" "bash '$file' <<< '$user'")

      printf "%-10s | %-30s | %-10s | %-10s | %-10s\n" "$user" "$short_file_path" "$can_read" "$can_write" "$can_execute"
    done
    echo "----------------------------------------------------------------------------------"
  done
}

check_process_stop() {
  pass
}

check_read_write_delete() {
  printf "%-10s | %-15s | %-10s | %-10s | %-10s\n" "USER" "DIR" "READ" "WRITE" "DELETE"
  echo "---------------------------------------------------------------------"

  for user in "${USERS_TO_CHECK[@]}"; do
    for folder in "${FOLDERS_TO_CHECK[@]}"; do
      local short_folder_path=${folder#"$BASE_DIR/"}
      local test_file_path="$folder/testfile_by_$user"

      local can_read=$(can_run "$user" "ls -lA '$folder'")
      local can_create=$(can_run "$user" "touch '$test_file_path'")
      local can_delete="-"
      if [[ "$can_create" == *"SUCCESS"* ]]; then
        can_delete=$(can_run "$user" "rm '$test_file_path'")
      else
        can_delete=$(can_run "$user" "rm -f '$test_file_path'")
      fi

      printf "%-10s | %-15s | %-10s | %-10s | %-10s\n" "$user" "$short_folder_path" "$can_read" "$can_create" "$can_delete"
    done
    echo "---------------------------------------------------------------------"
  done
}