import subprocess

# Get short path for JAVA_HOME
result = subprocess.run(
    ['cmd', '/c', 'for %I in ("C:\\Program Files\\Eclipse Adoptium\\jdk-25.0.4.7-hotspot") do @echo %~sI'],
    capture_output=True, text=True
)
java_short = result.stdout.strip()
print(f"JAVA short path: {java_short}")
print(f"Exists: {__import__('os').path.exists(java_short)}")

# Write to a temp file
with open('/tmp/java_home.txt', 'w') as f:
    f.write(java_short)
