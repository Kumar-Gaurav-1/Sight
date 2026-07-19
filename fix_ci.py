import re

with open("Sources/Sight/Preferences/SightTheme.swift", "r") as f:
    content = f.read()

# Let's read SightTheme.swift to see where accent is declared.
