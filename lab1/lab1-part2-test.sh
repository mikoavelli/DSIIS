#!/usr/bin/env bash

# This should be executed one by one by hand

PGPASSWORD='guest' psql -h localhost -U db_guest -d lab_db -c "SELECT * FROM secrets;"  # SUCCESS
PGPASSWORD='guest' psql -h localhost -U db_guest -d lab_db -c "INSERT INTO secrets (secret_info) VALUES ('new_data_guest');"  # ERROR

PGPASSWORD='user' psql -h localhost -U db_user -d lab_db -c "SELECT * FROM secrets;"  # SUCCESS
PGPASSWORD='user' psql -h localhost -U db_user -d lab_db -c "INSERT INTO secrets (secret_info) VALUES ('new_data_user');"  # SUCCESS
PGPASSWORD='user' psql -h localhost -U db_user -d lab_db -c "DROP TABLE secrets;"  # ERROR

PGPASSWORD='admin' psql -h localhost -U db_admin -d lab_db -c "SELECT * FROM secrets;" # SUCCESS
PGPASSWORD='admin' psql -h localhost -U db_admin -d lab_db -c "INSERT INTO secrets (secret_info) VALUES ('new_data_admin');"  # SUCCESS
PGPASSWORD='admin' psql -h localhost -U db_admin -d lab_db -c "DROP TABLE secrets;"  # SUCCESS