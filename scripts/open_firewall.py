import ctypes
import sys
import subprocess
import os

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if is_admin():
    print("Running as admin. Adding firewall rule...")
    cmd = 'netsh advfirewall firewall add rule name="Allow Krishi Vikas Port 8000" dir=in action=allow protocol=TCP localport=8000'
    subprocess.call(cmd, shell=True)
    with open("firewall_status.txt", "w") as f:
        f.write("Port 8000 opened successfully!")
else:
    print("Not admin. Requesting elevation...")
    script = os.path.abspath(__file__)
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, script, None, 1)
