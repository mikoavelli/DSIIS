import json
import os
from hashlib import pbkdf2_hmac
from getpass import getpass
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.backends import default_backend
import base64

# --- Constants ---
USER_DATA_FILE = 'users.json'
CONFIDENTIAL_DATA_FILE = 'confidential_data.enc'
NON_CONFIDENTIAL_DATA_FILE = 'non_confidential_data.json'
SALT_SIZE = 16
KEY_ITERATIONS = 100000

# --- Global Variables ---
current_user = None
encryption_key = None
# Dictionaries to store data in RAM
confidential_data_in_memory = {}
non_confidential_data_in_memory = {}


# --- User Management Functions ---
def get_salt():
    return os.urandom(SALT_SIZE)


def hash_password(password, salt):
    pwd_hash = pbkdf2_hmac('sha256', password.encode('utf-8'), salt, KEY_ITERATIONS)
    return pwd_hash


def load_users():
    if not os.path.exists(USER_DATA_FILE):
        return {}
    with open(USER_DATA_FILE, 'r') as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            return {}


def save_users(users):
    with open(USER_DATA_FILE, 'w') as f:
        json.dump(users, f, indent=4)


def register_user():
    username = input("Enter username: ")
    users = load_users()
    if username in users:
        print("A user with this name already exists.")
        return
    password = getpass("Enter password: ")
    salt = get_salt()
    hashed_password = hash_password(password, salt)
    users[username] = {
        'salt': salt.hex(),
        'password_hash': hashed_password.hex()
    }
    save_users(users)
    print(f"User {username} successfully registered.")


def login_user():
    global current_user, encryption_key
    username = input("Enter username: ")
    users = load_users()
    if username not in users:
        print("Incorrect username or password.")
        return
    password = getpass("Enter password: ")
    user_data = users[username]
    salt = bytes.fromhex(user_data['salt'])
    password_hash = bytes.fromhex(user_data['password_hash'])
    if hash_password(password, salt) == password_hash:
        current_user = username
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=KEY_ITERATIONS,
            backend=default_backend()
        )
        encryption_key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
        print(f"Welcome, {username}!")
        # Load data into memory on login
        load_all_data_to_memory()
    else:
        print("Incorrect username or password.")


def logout_user():
    global current_user, encryption_key, confidential_data_in_memory, non_confidential_data_in_memory
    # Save data before logging out
    save_all_data_from_memory()
    current_user = None
    encryption_key = None
    # Clear data from memory
    confidential_data_in_memory = {}
    non_confidential_data_in_memory = {}
    print("You have logged out. Data in memory has been cleared.")


# --- New functions for managing data in memory and on disk ---

def load_all_data_to_memory():
    """Loads all data from disk into RAM."""
    global confidential_data_in_memory, non_confidential_data_in_memory
    # Loading non-confidential data
    if os.path.exists(NON_CONFIDENTIAL_DATA_FILE):
        with open(NON_CONFIDENTIAL_DATA_FILE, 'r') as f:
            try:
                non_confidential_data_in_memory = json.load(f)
            except json.JSONDecodeError:
                non_confidential_data_in_memory = {}

    # Loading and decrypting confidential data
    if current_user and os.path.exists(CONFIDENTIAL_DATA_FILE):
        with open(CONFIDENTIAL_DATA_FILE, 'rb') as f:
            encrypted_data = f.read()
        if encrypted_data:
            try:
                fernet = Fernet(encryption_key)
                decrypted_data = fernet.decrypt(encrypted_data)
                confidential_data_in_memory = json.loads(decrypted_data.decode('utf-8'))
            except Exception as e:
                print(f"Error decrypting confidential data: {e}")
                confidential_data_in_memory = {}
    print("Data loaded from disk into RAM.")


def save_all_data_from_memory():
    """Saves all data from RAM to disk."""
    # Saving non-confidential data
    with open(NON_CONFIDENTIAL_DATA_FILE, 'w') as f:
        json.dump(non_confidential_data_in_memory, f, indent=4)

    # Encrypting and saving confidential data
    if current_user:
        fernet = Fernet(encryption_key)
        encrypted_data = fernet.encrypt(json.dumps(confidential_data_in_memory).encode('utf-8'))
        with open(CONFIDENTIAL_DATA_FILE, 'wb') as f:
            f.write(encrypted_data)
    print("Data from RAM has been saved to disk.")


# --- Function for managing data in memory ---

def manage_data_in_memory(is_confidential):
    """Manages data that is currently in RAM."""
    if is_confidential:
        if not current_user:
            print("Access denied. Please log in.")
            return
        data_store = confidential_data_in_memory
        data_type = "confidential"
    else:
        data_store = non_confidential_data_in_memory
        data_type = "non-confidential"

    while True:
        print(f"\n--- Manage {data_type} data in MEMORY ---")
        print("1. View all data")
        print("2. Add data")
        print("3. Edit data")
        print("4. Delete data")
        print("5. Return to main menu")

        choice = input("Select an action: ")

        if choice == '1':
            print(json.dumps(data_store, indent=4, ensure_ascii=False))
        elif choice == '2':
            key = input("Enter key: ")
            value = input("Enter value: ")
            data_store[key] = value
            print("Data added to memory.")
            input("!!! THIS IS A BREAKPOINT FOR CREATING A MEMORY DUMP (after ADDING). Press Enter to continue...")
        elif choice == '3':
            key = input("Enter key to edit: ")
            if key in data_store:
                new_value = input("Enter new value: ")
                data_store[key] = new_value
                print("Data updated in memory.")
                input(
                    "!!! THIS IS A BREAKPOINT FOR CREATING A MEMORY DUMP (after UPDATING). Press Enter to continue...")
            else:
                print("Key not found.")
        elif choice == '4':
            key = input("Enter key to delete: ")
            if key in data_store:
                del data_store[key]
                print("Data deleted from memory.")
                input(
                    "!!! THIS IS A BREAKPOINT FOR CREATING A MEMORY DUMP (after DELETING). Press Enter to continue...")
            else:
                print("Key not found.")
        elif choice == '5':
            break
        else:
            print("Invalid choice.")


# --- Main Menu ---

def menu():
    print(f"Application started with PID: {os.getpid()}")
    while True:
        print("\n--- Main Menu ---")
        if current_user:
            print(f"Current user: {current_user}")
        else:
            print("You are not logged in.")

        print("1. Register")
        print("2. Login")
        print("3. Logout (with data save)")
        print("4. Manage confidential data in memory")
        print("5. Manage non-confidential data in memory")
        print("6. Save all data from memory to disk")
        print("7. Load all data from disk to memory")
        print("8. Exit")

        choice = input("Select an action: ")

        if choice == '1':
            register_user()
        elif choice == '2':
            if not current_user:
                login_user()
            else:
                print("You are already logged in.")
        elif choice == '3':
            if current_user:
                logout_user()
            else:
                print("You are not logged in.")
        elif choice == '4':
            manage_data_in_memory(is_confidential=True)
        elif choice == '5':
            manage_data_in_memory(is_confidential=False)
        elif choice == '6':
            save_all_data_from_memory()
        elif choice == '7':
            load_all_data_to_memory()
        elif choice == '8':
            if current_user:
                save_all_data_from_memory()
            break
        else:
            print("Invalid choice. Please try again.")


if __name__ == "__main__":
    menu()