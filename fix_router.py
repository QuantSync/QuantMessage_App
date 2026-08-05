import os

file_path = r"c:\Users\anubh\StudioProjects\QuantMessage_App\backend\pathways\router.py"
with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(lines[:180])
