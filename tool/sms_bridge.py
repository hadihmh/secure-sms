#!/usr/bin/env python3
"""Test-only "carrier" between two Android emulators.

Emulator 37 no longer routes SMS between instances (the radio reports success, nothing arrives).
This polls each emulator's sent box and injects new messages into the other one via the console.
Usage: python3 tool/sms_bridge.py [5554 5556]
"""
import os, re, subprocess, sys, time

ADB = os.path.expanduser('~/Library/Android/sdk/platform-tools/adb')
a, b = (sys.argv[1:3] if len(sys.argv) > 2 else ['5554', '5556'])
peer = {a: b, b: a}


def sent(port):
    out = subprocess.run(
        [ADB, '-s', f'emulator-{port}', 'shell', 'content', 'query', '--uri', 'content://sms/sent',
         '--projection', '_id:body'], capture_output=True, text=True).stdout
    # Rows: "Row: N _id=12, body=..." ; a body may span lines, so split on row markers.
    return {int(m.group(1)): m.group(2).rstrip('\n')
            for m in re.finditer(r'_id=(\d+), body=(.*?)(?=\nRow: |\Z)', out, re.S)}


seen = {p: set(sent(p)) for p in peer}  # don't replay history
print(f'bridging {a} <-> {b}; Ctrl+C to stop', flush=True)
while True:
    for p, q in peer.items():
        for i, body in sorted(sent(p).items()):
            if i in seen[p]:
                continue
            seen[p].add(i)
            subprocess.run([ADB, '-s', f'emulator-{q}', 'emu', 'sms', 'send', p, body], capture_output=True)
            print(f'{p} -> {q}: {body[:60]}', flush=True)
    time.sleep(2)
