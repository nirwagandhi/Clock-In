# Setup Instructions for Clock'In App

## Adding the Anurati-Regular Font

To use the Anurati-Regular font in your app, follow these steps:

1. **Download the font**: Get the Anurati-Regular.ttf font file
2. **Add to Xcode**:
   - Drag the .ttf file into your Xcode project navigator
   - Make sure "Copy items if needed" is checked
   - Ensure the target membership includes "Clock'In"

3. **Register the font in Info.plist**:
   - Open Info.plist
   - Add a new row with key: `Fonts provided by application` (or `UIAppFonts`)
   - Add an item to the array: `Anurati-Regular.ttf`

## Alternative: If you don't have Anurati font

If you don't have the Anurati font, you can use system fonts. Replace the `.custom()` calls with:
- `.system(size: 28, weight: .bold, design: .rounded)` for the day
- `.system(size: 48, weight: .bold, design: .rounded)` for the time

Or use SF Pro Display:
- `.system(size: 28, weight: .ultraLight, design: .default)`

## Important: Info.plist Configuration

The Info.plist file must be linked to your target:

1. In Xcode, select your project in the navigator
2. Select the "Clock'In" target
3. Go to the "Info" tab
4. At the bottom, you should see the Info.plist entries
5. Make sure `LSUIElement` is set to `YES` (this hides the dock icon)

## Features

### Current Implementation:
- ✅ Transparent window with no frame
- ✅ Clock stays at desktop level (behind other windows)
- ✅ Shows current day and time
- ✅ No dock icon (LSUIElement = true)
- ✅ Reposition mode (double-tap to enable/disable)
- ✅ Saves position between launches
- ✅ Lock/unlock button appears in reposition mode

### How to Use:
1. **Move the clock**: Double-tap the clock to enter reposition mode
2. **Drag to position**: Click and drag the clock to your desired location
3. **Lock position**: Click the lock button or double-tap again to lock
4. **Position is saved**: Your clock position persists after app restart

### Additional Customizations:

**To change clock position behavior** (edit Clock_InApp.swift):
- Change window level to stay on top: `.normal` instead of `.desktopWindow`
- Add to all spaces: Already configured with `.canJoinAllSpaces`

**To change appearance** (edit ContentView.swift):
- Adjust font sizes in `.font(.custom())` calls
- Change colors in `.foregroundColor()` calls
- Modify shadow effects
- Adjust spacing and padding
