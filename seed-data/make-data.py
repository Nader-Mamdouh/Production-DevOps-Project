#!/usr/bin/env python3

print("Creating vote data files...")

# Create posta file
with open('posta', 'w') as f:
    f.write('vote=a')

# Create postb file  
with open('postb', 'w') as f:
    f.write('vote=b')

print("Created posta and postb files")