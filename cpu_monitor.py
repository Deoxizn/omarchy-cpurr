#!/usr/bin/env python3
"""cpurr CPU monitor: sample /proc/stat and print overall CPU usage percent.

Prints one line per sample (every 200ms) with the usage as a float, e.g. "12.3".
The bar widget reads these lines and drives the cat's run speed. Stdlib only.
"""

import sys
import time

SAMPLE_INTERVAL = 0.2  # seconds
STAT_PATH = "/proc/stat"


def read_cpu_times(path=STAT_PATH):
    """Return (idle, total) jiffies from the aggregate cpu line."""
    with open(path, "r", encoding="utf-8") as f:
        fields = f.readline().split()
    # cpu user nice system idle iowait irq softirq steal guest guest_nice
    values = [int(v) for v in fields[1:]]
    idle = values[3] + values[4]  # idle + iowait
    total = sum(values)
    return idle, total


def usage_between(prev, cur):
    """CPU usage percent between two (idle, total) snapshots."""
    prev_idle, prev_total = prev
    cur_idle, cur_total = cur
    total_delta = cur_total - prev_total
    idle_delta = cur_idle - prev_idle
    if total_delta <= 0:
        return 0.0
    return 100.0 * (1.0 - idle_delta / total_delta)


def main():
    try:
        prev = read_cpu_times()
    except (OSError, ValueError, IndexError) as e:
        print(f"cpu_monitor: cannot read {STAT_PATH}: {e}", file=sys.stderr)
        return 1
    while True:
        time.sleep(SAMPLE_INTERVAL)
        try:
            cur = read_cpu_times()
        except (OSError, ValueError, IndexError) as e:
            print(f"cpu_monitor: cannot read {STAT_PATH}: {e}", file=sys.stderr)
            return 1
        print(f"{usage_between(prev, cur):.1f}", flush=True)
        prev = cur


if __name__ == "__main__":
    sys.exit(main())
