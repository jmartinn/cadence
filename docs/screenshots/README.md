# Screenshots

`home.png`, `subscriptions.png`, and `detail.png` are the README screenshots —
real captures of the app, each composited onto a consistent off-white background
with a subtle frame.

## How they were made

1. Boot an iPhone 17 Pro simulator, force a clean status bar, and start from an
   empty store:
   ```bash
   xcrun simctl ui <udid> appearance light
   xcrun simctl status_bar <udid> override --time "9:41" \
     --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
   ```
2. Launch the app, seed the DEBUG sample data (the ladybug button on the
   Subscriptions tab), and capture each screen at native resolution
   (1206×2622): Home, the Subscriptions list, and a subscription detail.
3. Composite each capture into an iPhone 17 Pro device frame — thin uniform
   bezel, Dynamic Island, titanium edge, and a soft shadow on a transparent
   background — via ImageMagick, then overwrite the file of the same name here.
   Keeping the filenames stable means the README needs no edits.
