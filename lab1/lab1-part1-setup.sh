#!/usr/bin/env bash

PZS="$HOME"/pzs
PZS11="$PZS"/pzs11
PZS12="$PZS"/pzs12
PZS13="$PZS"/pzs13
PZS14="$PZS"/pzs14
PZS15="$PZS"/pzs15

FILE_WITH_VARIABLE_CONTENT="
#!/usr/bin/env bash

read -p 'Enter testVariable: ' testVariable
echo 'Your testVariable: ' \$testVariable
"

FILE_WITH_HELLO_CONTENT="
#!/usr/bin/env bash

echo 'Hello world!'
"

create_groups_and_users() {
  echo "--> Creating groups and users"

  sudo groupadd group_iit1
  sudo groupadd group_iit2

  sudo useradd -m -g group_iit1 iit11
  sudo useradd -m -g group_iit1 iit12
  sudo useradd -m -g group_iit2 iit21
  sudo useradd -m -g group_iit2 iit22
  sudo useradd -m iit3

  sudo usermod -aG wheel iit21

  sudo chpasswd -c SHA512 < "$HOME"/pass.txt
}

create_dirs_and_set_permissions() {
  echo "--> Creating directories and set permissions"

  mkdir -p "$PZS"/pzs1{1,2,3,4,5}
  
  sudo chown iit11:group_iit1 "$PZS11"
  sudo chmod 700 "$PZS11"
  sudo chown "$USER":group_iit1 "$PZS12"
  sudo chmod 070 "$PZS12"
  sudo chown "$USER":"$USER" "$PZS13"
  sudo chmod 007 "$PZS13"
  sudo chmod 777 "$PZS14"
  sudo chown root:root "$PZS15"
  sudo chmod 700 "$PZS15"
}

create_files_and_set_permissions() {
  echo "--> Creating files and set permissions"
  
  sudo -u iit11 touch "$PZS11"/file1{1,2,3,4,5}
  sudo chmod 400 "$PZS11"/file11
  sudo chmod 600 "$PZS11"/file12
  sudo chmod 200 "$PZS11"/file13
  sudo chmod 700 "$PZS11"/file14
  sudo chmod 100 "$PZS11"/file15

  sudo -u iit11 touch "$PZS12"/file2{1,2,3,4,5}
  sudo chmod 000 "$PZS12"/file2{1,2,3,4,5}
  sudo setfacl -m g:group_iit1:r   "$PZS12"/file21
  sudo setfacl -m g:group_iit1:rw  "$PZS12"/file22
  sudo setfacl -m g:group_iit1:w   "$PZS12"/file23
  sudo setfacl -m g:group_iit1:rwx "$PZS12"/file24
  sudo setfacl -m g:group_iit1:x   "$PZS12"/file25

  sudo -u iit11 touch "$PZS13"/file3{1,2,3,4,5}
  sudo chmod 004 "$PZS13"/file31
  sudo chmod 006 "$PZS13"/file32
  sudo chmod 002 "$PZS13"/file33
  sudo chmod 007 "$PZS13"/file34
  sudo chmod 001 "$PZS13"/file35

  sudo -u iit11 touch "$PZS14"/file4{1,2,3,4,5}
  sudo chmod 444 "$PZS14"/file41
  sudo chmod 666 "$PZS14"/file42
  sudo chmod 222 "$PZS14"/file43
  sudo chmod 777 "$PZS14"/file44
  sudo chmod 111 "$PZS14"/file45

  sudo touch "$PZS15"/file5{1,2,3,4,5}
  sudo chmod 400 "$PZS15"/file51
  sudo chmod 600 "$PZS15"/file52
  sudo chmod 200 "$PZS15"/file53
  sudo chmod 700 "$PZS15"/file54
  sudo chmod 100 "$PZS15"/file55
}

fill_files() {
  sudo find "$PZS" -type f -iname "file?5" -print0 | while IFS= read -r -d $'\0' file; do
    echo "$FILE_WITH_VARIABLE_CONTENT" | sudo tee "$file" > /dev/null
  done

  sudo find "$PZS" -type f ! -iname "file?5" -print0 | while IFS= read -r -d $'\0' file; do
    echo "$FILE_WITH_HELLO_CONTENT" | sudo tee "$file" > /dev/null
  done
}

cleanup() {
  sudo rm -rf "$PZS"

  sudo userdel -r iit11
  sudo userdel -r iit12
  sudo userdel -r iit21
  sudo userdel -r iit22
  sudo userdel -r iit3

  sudo groupdel group_iit1
  sudo groupdel group_iit2
}

create_groups_and_users
create_dirs_and_set_permissions
create_files_and_set_permissions
fill_files

source lab1-part1-checking.sh
check_permissions
check_process_stop
check_read_write_delete

cleanup
