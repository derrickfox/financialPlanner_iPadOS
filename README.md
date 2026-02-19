# RentVsBuyNativeiPad

Native iPadOS app written in SwiftUI that mirrors the React app behavior and style:

- Rent vs Buy calculator with live assumptions and charts
- Retirement calculator with live assumptions, charts, and monthly retirement budgeting
- Collapsible input sections on both calculators
- Top-right button to switch calculators while preserving entered values

## Project Layout

- `project.yml`: XcodeGen project definition
- `Sources/`: SwiftUI app code and calculator engines

## Generate and Open in Xcode

```bash
cd /Users/derrickfox/Desktop/REPOS/RentVsBuyNativeiPad
xcodegen generate
open RentVsBuyNativeiPad.xcodeproj
```

## Notes

- This is a native Swift app with no JavaScript runtime.
- Targeted for iPad (`TARGETED_DEVICE_FAMILY = 2`).
