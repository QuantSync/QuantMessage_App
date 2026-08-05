import os
import re

def replace_in_files(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Only replace exact case matches to avoid breaking imports/ids
                    new_content = content.replace("Claude", "QuantMessage")
                    new_content = new_content.replace("Anthropic", "QuantSync")

                    if new_content != content:
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        print(f"Updated: {filepath}")
                except Exception as e:
                    print(f"Failed {filepath}: {e}")

replace_in_files(r'c:\Users\anubh\StudioProjects\QuantMessage_App\lib')
