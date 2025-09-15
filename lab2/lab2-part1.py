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

# --- Global variables ---
current_user = None
encryption_key = None


# --- User management functions ---

def get_salt():
    """Generates a new salt."""
    return os.urandom(SALT_SIZE)


def hash_password(password, salt):
    """Hashes a password using a salt."""
    pwd_hash = pbkdf2_hmac('sha256', password.encode('utf-8'), salt, KEY_ITERATIONS)
    return pwd_hash


def load_users():
    """Loads user data from a file."""
    if not os.path.exists(USER_DATA_FILE):
        return {}
    with open(USER_DATA_FILE, 'r') as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            return {}


def save_users(users):
    """Saves user data to a file."""
    with open(USER_DATA_FILE, 'w') as f:
        json.dump(users, f, indent=4)


def register_user():
    """Registers a new user."""
    username = input("Enter username: ")
    users = load_users()
    if username in users:
        print("User with this name already exists.")
        return

    password = getpass("Enter password: ")
    salt = get_salt()
    hashed_password = hash_password(password, salt)

    users[username] = {
        'salt': salt.hex(),
        'password_hash': hashed_password.hex()
    }
    save_users(users)
    print(f"User {username} has been successfully registered.")


def login_user():
    """Logs in a user."""
    global current_user, encryption_key
    username = input("Enter username: ")
    users = load_users()
    if username not in users:
        print("Invalid username or password.")
        return

    password = getpass("Enter password: ")
    user_data = users[username]
    salt = bytes.fromhex(user_data['salt'])
    password_hash = bytes.fromhex(user_data['password_hash'])

    if hash_password(password, salt) == password_hash:
        current_user = username
        # Generate an encryption key based on the user's password
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,  # Use the same salt to derive the key
            iterations=KEY_ITERATIONS,
            backend=default_backend()
        )
        encryption_key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
        print(f"Welcome, {username}!")
    else:
        print("Invalid username or password.")


def logout_user():
    """Logs out the current user."""
    global current_user, encryption_key
    current_user = None
    encryption_key = None
    print("You have been logged out.")


# --- Data management functions ---

def load_data(file_path):
    """Loads data from a JSON file."""
    if not os.path.exists(file_path):
        return {}
    with open(file_path, 'r') as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            return {}


def save_data(data, file_path):
    """Saves data to a JSON file."""
    with open(file_path, 'w') as f:
        json.dump(data, f, indent=4)


def load_confidential_data():
    """Loads and decrypts confidential data."""
    if not os.path.exists(CONFIDENTIAL_DATA_FILE):
        return {}
    with open(CONFIDENTIAL_DATA_FILE, 'rb') as f:
        encrypted_data = f.read()

    if not encrypted_data:
        return {}

    fernet = Fernet(encryption_key)
    try:
        decrypted_data = fernet.decrypt(encrypted_data)
        return json.loads(decrypted_data.decode('utf-8'))
    except Exception as e:
        print(f"Error decrypting data: {e}")
        return {}


def save_confidential_data(data):
    """Encrypts and saves confidential data."""
    fernet = Fernet(encryption_key)
    encrypted_data = fernet.encrypt(json.dumps(data).encode('utf-8'))
    with open(CONFIDENTIAL_DATA_FILE, 'wb') as f:
        f.write(encrypted_data)


def manage_data(is_confidential):
    """Manages data (confidential or non-confidential)."""
    if is_confidential:
        if not current_user:
            print("Access denied. Please log in.")
            return
        load_func = load_confidential_data
        save_func = save_confidential_data
        data_type = "confidential"
    else:
        load_func = lambda: load_data(NON_CONFIDENTIAL_DATA_FILE)
        save_func = lambda data: save_data(data, NON_CONFIDENTIAL_DATA_FILE)
        data_type = "non-confidential"

    data = load_func()

    while True:
        print(f"\n--- Manage {data_type} data ---")
        print("1. View all data")
        print("2. Add data")
        print("3. Edit data")
        print("4. Delete data")
        print("5. Return to main menu")

        choice = input("Select an option: ")

        if choice == '1':
            print(json.dumps(data, indent=4))
        elif choice == '2':
            key = input("Enter key: ")
            value = input("Enter value: ")
            data[key] = value
            save_func(data)
            print("Data added.")
        elif choice == '3':
            key = input("Enter key to edit: ")
            if key in data:
                new_value = input("Enter new value: ")
                data[key] = new_value
                save_func(data)
                print("Data updated.")
            else:
                print("Key not found.")
        elif choice == '4':
            key = input("Enter key to delete: ")
            if key in data:
                del data[key]
                save_func(data)
                print("Data deleted.")
            else:
                print("Key not found.")
        elif choice == '5':
            break
        else:
            print("Invalid choice.")


# --- Main menu ---

def menu():
    """The main menu of the application."""
    while True:
        print("\n--- Main Menu ---")
        if current_user:
            print(f"Current user: {current_user}")
        else:
            print("You are not logged in.")

        print("1. Register")
        print("2. Login")
        print("3. Logout")
        print("4. Manage confidential data")
        print("5. Manage non-confidential data")
        print("6. Exit")

        choice = input("Select an option: ")

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
            manage_data(is_confidential=True)
        elif choice == '5':
            manage_data(is_confidential=False)
        elif choice == '6':
            break
        else:
            print("Invalid choice. Please try again.")


if __name__ == "__main__":
    menu()