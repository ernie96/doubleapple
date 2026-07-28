# DoubleTalk PC for iOS & VoiceOver (DoubleTalkApple)

**DoubleTalkApple** brings the iconic **DoubleTalk PC** hardware speech synthesizer to iOS and macOS as a native system voice via Apple's `AVSpeechSynthesisProviderAudioUnit` framework (introduced in iOS 16+).

It allows blind and low-vision users to use DoubleTalk PC's classic voices (*Perfect Paul, Vader, Big Bob, Precise Pete, Ricochet, Biff, Skip, Robo Robert*) directly with **VoiceOver** across iOS apps, system UI, and screen reading navigation.

---

## Technical Architecture

```
+-----------------------------------------------------------------------------------+
|                              DoubleTalk iOS Engine                                |
+-----------------------------------------------------------------------------------+
|  +---------------------------+             +----------------------------------+  |
|  |       DoubleTalkApp       |             |     DoubleTalkVoiceExtension     |  |
|  |     (SwiftUI iOS App)     |             | (AVSpeechSynthesisProviderAU)    |  |
|  | - Test & preview speech   |             | - System VoiceOver integration   |  |
|  | - Voice & parameter UI    |             | - 8 DoubleTalk hardware voices   |  |
|  | - Firmware ROM manager    |             | - Real-time Float32 PCM renderer |  |
|  +-------------+-------------+             +----------------+-----------------+  |
|                |                                            |                    |
|                +--------------------+-----------------------+                    |
|                                     |                                            |
|                                     v                                            |
|                        +--------------------------+                              |
|                        |      DoubleTalkKit       |                              |
|                        | (Swift Engine Framework) |                              |
|                        | - DoubleTalkSynthesizer  |                              |
|                        | - DoubleTalkSettings     |                              |
|                        | - DoubleTalkVoice        |                              |
|                        +------------+-------------+                              |
|                                     |                                            |
|                                     v                                            |
|                        +--------------------------+                              |
|                        |       CDoubleTalk        |                              |
|                        | (C/C++ Emulator Engine)  |                              |
|                        | - 80C188EB CPU emulation |                              |
|                        | - Low-pass biquad filter |                              |
|                        +--------------------------+                              |
+-----------------------------------------------------------------------------------+
```

### Components

1. **CDoubleTalk (`Sources/CDoubleTalk`)**
   - Core C API shim (`dtalk_shim.h` / `dtalk_shim.c`) emulating the Intel 80C188EB microprocessor and RC8650 speech synthesizer hardware.
   - Renders 16-bit PCM mono audio at 10,504 Hz.
   - Includes modeled low-pass reconstruction filter (2.0 kHz to 5.0 kHz) and index mark tracking (`dtalk_read_index_marks`).

2. **DoubleTalkKit (`Sources/DoubleTalkKit`)**
   - High-level Swift API wrapping the C emulator core.
   - Defines the 8 built-in DoubleTalk hardware voices (*Perfect Paul, Vader, Big Bob, Precise Pete, Ricochet, Biff, Skip, Robo Robert*) and firmware ROM presets.
   - Formats ASCII command sequences (`\x010O`, `\x0114B`, `\x015S`, `\x0150P`, `\x015V`, `\x011X`, `\x015A`, `\x015E`, `\x015F`, `\x010R`).
   - Synchronizes voice parameters and ROM data across App and Extension using App Group shared storage (`group.com.doubletalk.app`).

3. **DoubleTalkVoiceExtension (`Apps/DoubleTalkVoiceExtension`)**
   - Apple `AVSpeechSynthesisProviderAudioUnit` system speech extension.
   - Registers all 8 DoubleTalk voices in iOS Accessibility settings.
   - Parses SSML requests from VoiceOver, translates text to DoubleTalk commands, resamples PCM from 10,504 Hz -> 22,050 Hz Float32 using Accelerate/vDSP, and streams audio to CoreAudio in real-time.

4. **DoubleTalkApp (`Apps/DoubleTalkApp`)**
   - SwiftUI iOS application featuring:
     - Live Speech Sandbox for testing text-to-speech previews.
     - Fine-grained controls for Speech Rate, Pitch, Volume, Tone, Articulation, Expression, Formant Frequency, Reverb, Low-Pass Filter Corner, and Turbo Rate Boost.
     - Firmware ROM Status Manager for baking/loading `doubletalkpc.bin`.
     - Step-by-step VoiceOver setup guide.

---

## Firmware ROM (`doubletalkpc.bin`)

DoubleTalk PC requires the 512KB proprietary hardware firmware ROM (`doubletalkpc.bin`, 524,288 bytes).

- The working `doubletalkpc.bin` file in `d:\doubletalk\doubletalkpc.bin` is automatically bundled with the app targets and copied to the shared App Group container (`group.com.doubletalk.app`).
- The iOS App also includes a **Firmware Manager** UI with Document Picker support to import or update `doubletalkpc.bin` at any time.

---

## How to Enable in VoiceOver

1. Build and install **DoubleTalkApp** on your iOS device (iOS 16.0+).
2. Open **DoubleTalkApp** once to verify firmware status and test audio.
3. Open iOS **Settings** app -> **Accessibility** -> **VoiceOver** -> **Speech**.
4. Tap **Voice** -> scroll to **DoubleTalk**.
5. Select your preferred DoubleTalk speaker voice (e.g. *Perfect Paul*, *Vader*, *Big Bob*, *Precise Pete*).
