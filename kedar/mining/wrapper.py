import sys
import time
import signal
import atexit
from subprocess import Popen, run
from datetime import datetime

open_process = None

miner_path = sys.argv[1]
nvidia_smi_path = sys.argv[2]
pool_url = sys.argv[3]

def on_exit():
  global open_process
  print("Shutting down", flush=True)
  if open_process is not None:
    print("Stopping mining process", flush=True)
    if open_process.poll() is None:
      open_process.terminate()
    run([nvidia_smi_path, "-i", "0", "-pl", "215"])
    open_process = None
  sys.exit(0)

atexit.register(on_exit)
signal.signal(signal.SIGTERM, lambda a, b: sys.exit(0))
signal.signal(signal.SIGINT, lambda a, b: sys.exit(0))

while True:
  cur_time = datetime.now()
  print(f"Current time is {cur_time}", flush=True)
  should_run = not (cur_time.hour >= 17 and cur_time.hour <= 20)
  if open_process == None and should_run:
    print("Starting mining process", flush=True)
    run([miner_path, "--list-devices"])
    run([nvidia_smi_path, "-i", "0", "-pl", "125"])
    open_process = Popen([miner_path, "--report-hashrate", "--cuda", "--pool", pool_url])
  elif open_process != None and not should_run:
    print("Stopping mining process", flush=True)
    open_process.terminate()
    run([nvidia_smi_path, "-i", "0", "-pl", "215"])
    open_process = None
  time.sleep(60 * 1)
