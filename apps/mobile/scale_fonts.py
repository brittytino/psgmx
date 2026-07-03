import os
import re

def scale_down(match):
    prefix = match.group(1)
    size = int(match.group(2))
    suffix = match.group(3)
    
    # Scale down logic matching Home Screen typography
    if size >= 22:
        new_size = 16
    elif size >= 18:
        new_size = 12
    elif size >= 15:
        new_size = 11
    elif size >= 13:
        new_size = 11
    elif size == 12:
        new_size = 9
    elif size == 11:
        new_size = 9
    elif size == 10:
        new_size = 8
    else:
        new_size = size
        
    return f"{prefix}{new_size}{suffix}"

def scale_icon_size(match):
    prefix = match.group(1)
    size = int(match.group(2))
    suffix = match.group(3)
    
    if size >= 24:
        new_size = 16
    elif size >= 20:
        new_size = 16
    elif size >= 16:
        new_size = 12
    elif size >= 14:
        new_size = 12
    else:
        new_size = size
        
    return f"{prefix}{new_size}{suffix}"

folders_to_update = [
    'attendance', 'auth', 'placement_log', 'profile', 
    'reports', 'sessions', 'settings', 'tasks', 'update', 'widgets', 'admin', 'bunker'
]

for root, _, files in os.walk('lib/ui'):
    if not any(f"/{folder}" in root for folder in folders_to_update) and root != 'lib/ui':
        pass

    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
                
            # Replace font sizes
            new_content = re.sub(r'(fontSize:\s*)(\d+)(,?)', scale_down, content)
            
            # Replace icon sizes
            new_content = re.sub(r'(size:\s*)(\d+)(,?)', scale_icon_size, new_content)
            
            if content != new_content:
                with open(filepath, 'w') as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
