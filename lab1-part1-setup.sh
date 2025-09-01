#!/usr/bin/env bash

PZS="/home/admin/pzs"
PZS11="/home/admin/pzs/pzs11"
PZS12="/home/admin/pzs/pzs12"
PZS13="/home/admin/pzs/pzs13"
PZS14="/home/admin/pzs/pzs14"
PZS15="/home/admin/pzs/pzs15"

# step1 - create groups
sudo groupadd group_iit1
sudo groupadd group_iit2

# step2 - create group_iit1 users
sudo useradd -m -g group_iit1 iit11
sudo useradd -m -g group_iit1 iit12

# step3 - create group_iit2 users
sudo useradd -m -g group_iit2 iit21
sudo useradd -m -g group_iit2 iit22

# step4 - add iit21 to sudo group
sudo usermod -aG wheel iit21

# step5 - create user iit3
sudo useradd -m iit3

# step5.1 - set passwords for all users
sudo chpasswd -c SHA512 < ~/pass.txt

# step6 - create directories
mkdir -p "$PZS"/pzs1{1,2,3,4,5}

# step7-11 - set permissions
sudo chown iit11:group_iit1 "$PZS11"
sudo chmod 700 "$PZS11"

sudo chown admin:group_iit1 "$PZS12"
sudo chmod 070 "$PZS12"

sudo chown admin:admin "$PZS13"
sudo chmod 007 "$PZS13"

sudo chmod 777 "$PZS14"

sudo chown root:root "$PZS15"
sudo chmod 700 "$PZS15"

echo "Create files by user iit11"

# step12-13 - create files and set permissions
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
sudo setfacl -m g:group_iit1:r   "$PZS12"/file25

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


sudo find "$PZS" -type f -iname "file?5" -print0 | while IFS= read -r -d $'\0' file; do 
cat <<EOF | sudo tee "$file" > /dev/null
#!/usr/bin/env bash

read -p "Enter testVariable: " testVariable
echo "Your testVariable: $testVariable"
EOF
done

sudo find "$PZS" -type f ! -iname "file?5" -print0 | while IFS= read -r -d $'\0' file; do 
echo 'echo "Hello world"' | sudo tee "$file" > /dev/null
done

# step14 - ...

echo "Change user to admin"
su - admin
