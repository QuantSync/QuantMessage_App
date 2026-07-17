import os
import re

def check_imports():
    lib_dir = 'lib'
    all_files = []
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                all_files.append(os.path.join(root, file))

    actual_files = set([f.replace('\\', '/') for f in all_files])
    
    import_pattern = re.compile(r"import\s+['\"]package:quantmessage_app/([^'\"]+)['\"]")
    relative_import_pattern = re.compile(r"import\s+['\"]([^'\"]+\.dart)['\"]")

    errors = []
    for filepath in all_files:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Check package imports
            for match in import_pattern.findall(content):
                expected_path = 'lib/' + match
                if expected_path not in actual_files:
                    errors.append(f"{filepath}: Invalid import package:quantmessage_app/{match}")

            # Check relative imports
            for match in relative_import_pattern.findall(content):
                # Ignore dart: and package: (except our own handled above)
                if match.startswith('dart:') or match.startswith('package:'):
                    continue
                
                base_dir = os.path.dirname(filepath).replace('\\', '/')
                expected_path = os.path.normpath(os.path.join(base_dir, match)).replace('\\', '/')
                
                if expected_path not in actual_files:
                    errors.append(f"{filepath}: Invalid relative import {match}")

    if errors:
        for err in errors:
            print(err)
        print("Found case-sensitivity or missing import issues!")
    else:
        print("All imports valid and case-correct.")

check_imports()
