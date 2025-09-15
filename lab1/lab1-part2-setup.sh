#!/usr/bin/env bash

#!/usr/bin/env bash

DB_NAME="lab_db"
TABLE_NAME="secrets"

ADMIN_PASSWORD="admin"
USER_PASSWORD="user"
GUEST_PASSWORD="guest"

sudo -u postgres psql -c "CREATE ROLE db_admin WITH LOGIN PASSWORD '$ADMIN_PASSWORD' SUPERUSER;"
sudo -u postgres psql -c "CREATE ROLE db_user WITH LOGIN PASSWORD '$USER_PASSWORD';"
sudo -u postgres psql -c "CREATE ROLE db_guest WITH LOGIN PASSWORD '$GUEST_PASSWORD';"

sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -d $DB_NAME -c "CREATE TABLE $TABLE_NAME (id SERIAL PRIMARY KEY, secret_info TEXT NOT NULL);"

sudo -u postgres psql -d $DB_NAME -c "GRANT ALL PRIVILEGES ON TABLE $TABLE_NAME TO db_admin;"
sudo -u postgres psql -d $DB_NAME -c "GRANT SELECT, INSERT, UPDATE ON TABLE $TABLE_NAME TO db_user;"
sudo -u postgres psql -d $DB_NAME -c "GRANT USAGE ON SEQUENCE ${TABLE_NAME}_id_seq TO db_user;"
sudo -u postgres psql -d $DB_NAME -c "GRANT SELECT ON TABLE $TABLE_NAME TO db_guest;"

sudo -u postgres psql -d $DB_NAME -c "INSERT INTO $TABLE_NAME (secret_info) VALUES ('Wi-Fi password: 12345678');"