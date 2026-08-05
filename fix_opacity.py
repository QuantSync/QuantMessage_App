import os
import re

directory = r'c:\Users\anubh\StudioProjects\QuantMessage_App\lib\screens\animated_dropdown'

for fname in os.listdir(directory):
    if fname.endswith('.dart'):
        fpath = os.path.join(directory, fname)
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
        # Replace .withOpacity(x) with .withValues(alpha: x)
        new_content = re.sub(
            r'\.withOpacity\(([^)]+)\)',
            lambda m: f'.withValues(alpha: {m.group(1)})',
            content
        )
        if new_content != content:
            with open(fpath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Fixed: {fname}')
