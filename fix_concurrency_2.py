import sys

def replace_in_file(filepath, old, new):
    with open(filepath, "r") as f:
        content = f.read()
    if old in content:
        content = content.replace(old, new)
        with open(filepath, "w") as f:
            f.write(content)
        print(f"Fixed {filepath}")
    else:
        print(f"Could not find exact text in {filepath}")

# Looking at the latest CI output, SightTheme.accent errors persist.
# We need to add @MainActor to the SightTheme enum itself, or remove it from the property if it's safe.
# Actually, the error is:
# /Sources/Sight/Preferences/InteractiveCharts.swift:246:31: error: main actor-isolated static property 'accent' can not be referenced from a non-isolated context
# Note: static property declared here (SightTheme.swift:29:16)
# `static var accent: Color {`
# The problem is `InteractiveCharts.swift` and `SightAboutView.swift` and others are calling `SightTheme.accent`.
# Our previous fix added `@MainActor` to `struct WellnessGaugeView` but missed others, or the build compiler requires the `body` itself to be marked or the struct. Wait, we added `@MainActor struct WellnessGaugeView`.
# Let's check `InteractiveCharts.swift` again.
