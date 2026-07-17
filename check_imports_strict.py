import os
import re
import sys

def check_imports_strict():
    lib_dir = 'lib'
    all_files_exact = set()
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                # store the exact relative path with forward slashes
                exact_path = os.path.relpath(os.path.join(root, file), start='.').replace('\\', '/')
                all_files_exact.add(exact_path)

    import_pattern = re.compile(r"import\s+['\"]package:[^/]+/([^'\"]+)['\"]")
    relative_import_pattern = re.compile(r"import\s+['\"]([^'\"]+\.dart)['\"]")

    errors = []
    for filepath in all_files_exact:
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
                # Check package imports
                for match in import_pattern.findall(content):
                    expected_path = 'lib/' + match
                    # Only check if it's pointing to our own lib (assuming it resolves to our own files)
                    if os.path.exists(expected_path):
                        if expected_path not in all_files_exact:
                            errors.append(f"{filepath}: Case mismatch in package import -> {match}")
                    elif os.path.exists(expected_path.lower()):
                         errors.append(f"{filepath}: Case mismatch in package import -> {match}")

                # Check relative imports
                for match in relative_import_pattern.findall(content):
                    if match.startswith('dart:') or match.startswith('package:'):
                        continue
                    
                    base_dir = os.path.dirname(filepath)
                    expected_path = os.path.normpath(os.path.join(base_dir, match)).replace('\\', '/')
                    
                    if os.path.exists(expected_path):
                        if expected_path not in all_files_exact:
                            errors.append(f"{filepath}: Case mismatch in relative import -> {match} (Expected exactly: {expected_path})")
        except Exception as e:
            pass

    if errors:
        for err in errors:
            print(err)
        print("Found case-sensitivity issues!")
        sys.exit(1)
    else:
        print("All imports valid and case-correct.")

check_imports_strict()
