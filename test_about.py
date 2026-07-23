import re
with open('./Sources/Sight/Preferences/SightAboutView.swift', 'r') as f:
    text = f.read()

# Let's revert the @MainActor additions we previously added automatically
text = re.sub(r'@MainActor struct SightAboutView', r'struct SightAboutView', text)

with open('./Sources/Sight/Preferences/SightAboutView.swift', 'w') as f:
    f.write(text)

with open('./Sources/Sight/Preferences/InteractiveCharts.swift', 'r') as f:
    text2 = f.read()

text2 = re.sub(r'@MainActor struct', r'struct', text2)
with open('./Sources/Sight/Preferences/InteractiveCharts.swift', 'w') as f:
    f.write(text2)
