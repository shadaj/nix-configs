import sys
import time
import signal
import atexit
import subprocess
from subprocess import Popen, run
from datetime import datetime

open_process = None

miner_path = sys.argv[1]
nvidia_smi_path = sys.argv[2]
nvidia_settings_path = sys.argv[3]
pool_url = sys.argv[4]

def on_exit(sig_num):
  signal.signal(sig_num, lambda a, b: None)
  global open_process
  print(f"Shutting down for signal {sig_num}", flush=True)
  if open_process is not None:
    run([nvidia_smi_path, "-i", "0", "-pl", "215"])
    run([nvidia_settings_path, "-a", "[gpu:0]/GPUMemoryTransferRateOffsetAllPerformanceLevels=0", "-a", "[gpu:0]/GPUGraphicsClockOffsetAllPerformanceLevels=0"])
    print("Stopping mining process", flush=True)
    if open_process.poll() is None:
      open_process.terminate()
    open_process = None
  print("Finished shutting down")
  sys.exit(0)

# atexit.register(on_exit)
signal.signal(signal.SIGTERM, lambda a, b: on_exit(a))
signal.signal(signal.SIGINT, lambda a, b: on_exit(a))

while True:
  cur_time = datetime.now()
  print(f"Current time is {cur_time}", flush=True)
  should_run = not (cur_time.hour >= 17 and cur_time.hour < 20)
  if (open_process == None or open_process.poll() != None) and should_run:
    print("Starting mining process", flush=True)
    run([miner_path, "--list-devices"])
    run([nvidia_smi_path, "-i", "0", "-pl", "125"])
    run([nvidia_settings_path, "-a", "[gpu:0]/GPUMemoryTransferRateOffsetAllPerformanceLevels=1600", "-a", "[gpu:0]/GPUGraphicsClockOffsetAllPerformanceLevels=-100"])
    open_process = Popen([miner_path, "--report-hashrate", "--cuda", "--pool", pool_url])
  elif open_process != None and not should_run:
    print("Stopping mining process", flush=True)
    open_process.terminate()
    run([nvidia_smi_path, "-i", "0", "-pl", "215"])
    run([nvidia_settings_path, "-a", "[gpu:0]/GPUMemoryTransferRateOffsetAllPerformanceLevels=0", "-a", "[gpu:0]/GPUGraphicsClockOffsetAllPerformanceLevels=0"])
    open_process = None
  time.sleep(60 * 1)
