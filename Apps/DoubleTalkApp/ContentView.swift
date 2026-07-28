/*
 * ContentView.swift - Main DoubleTalk iOS User Interface
 *
 * Provides Speech Testing, Voice Parameters Customization, Firmware ROM Status,
 * and VoiceOver Screen Reader Setup Instructions.
 */

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var settings = DoubleTalkSettingsStore.load()
    @State private var selectedSpeaker: DoubleTalkSpeaker = .paul
    @State private var testText = "Welcome to DoubleTalk PC for iOS and VoiceOver!"
    @State private var isPlaying = false
    @State private var statusMessage: String = ""
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showingFileImporter = false
    @State private var romLoaded: Bool = false
    @State private var romSize: Int = 0

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Firmware Status Section
                Section(header: Text("Firmware ROM Status")) {
                    HStack {
                        Image(systemName: romLoaded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(romLoaded ? .green : .orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text(romLoaded ? "Firmware Active (doubletalkpc.bin)" : "ROM Missing")
                                .fontWeight(.semibold)
                            Text(romLoaded ? "524,288 bytes (baked in bundle & App Group)" : "Import 512KB DoubleTalk PC binary ROM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Import") {
                            showingFileImporter = true
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // MARK: - Speech Sandbox & Voice Picker
                Section(header: Text("Live Speech Preview")) {
                    Picker("Speaker Voice", selection: $selectedSpeaker) {
                        ForEach(DoubleTalkSpeaker.allCases) { speaker in
                            Text(speaker.displayName).tag(speaker)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Text to speak", text: $testText)
                        .textFieldStyle(.roundedBorder)

                    Button(action: togglePlay) {
                        HStack {
                            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            Text(isPlaying ? "Stop Speaking" : "Speak Preview")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isPlaying ? .red : .blue)
                    .disabled(!romLoaded)
                }

                // MARK: - Synthesizer Parameters
                Section(header: Text("Voice Parameters")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Speech Rate")
                            Spacer()
                            Text("\(settings.rate)")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(get: { Double(settings.rate) }, set: { settings.rate = Int($0); saveSettings() }), in: 10...100, step: 10)
                    }

                    Toggle("Rate Boost (Turbo Fast Speech)", isOn: Binding(get: { settings.rateBoost }, set: { settings.rateBoost = $0; saveSettings() }))

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Base Pitch")
                            Spacer()
                            Text("\(settings.pitch)")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(get: { Double(settings.pitch) }, set: { settings.pitch = Int($0); saveSettings() }), in: 0...100, step: 1)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Volume")
                            Spacer()
                            Text("\(settings.volume)")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(get: { Double(settings.volume) }, set: { settings.volume = Int($0); saveSettings() }), in: 10...100, step: 10)
                    }

                    Picker("Tone Filter", selection: Binding(get: { settings.tone }, set: { settings.tone = $0; saveSettings() })) {
                        Text("Bass").tag(0)
                        Text("Normal").tag(1)
                        Text("Treble").tag(2)
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Articulation")
                            Spacer()
                            Text("\(settings.articulation)")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(get: { Double(settings.articulation) }, set: { settings.articulation = Int($0); saveSettings() }), in: 10...100, step: 10)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Expression (Intonation)")
                            Spacer()
                            Text("\(settings.expression)")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(get: { Double(settings.expression) }, set: { settings.expression = Int($0); saveSettings() }), in: 10...100, step: 10)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Formant Frequency")
                            Spacer()
                            Text("\(settings.formant)")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(get: { Double(settings.formant) }, set: { settings.formant = Int($0); saveSettings() }), in: 10...100, step: 10)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Reverb Level")
                            Spacer()
                            Text("\(settings.reverb)")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(get: { Double(settings.reverb) }, set: { settings.reverb = Int($0); saveSettings() }), in: 10...100, step: 10)
                    }

                    Picker("Reconstruction Low-Pass Corner", selection: Binding(get: { settings.lowpassHz }, set: { settings.lowpassHz = $0; saveSettings() })) {
                        Text("Muffled (2.0 kHz)").tag(2000)
                        Text("Classic (3.0 kHz)").tag(3000)
                        Text("Default (3.8 kHz)").tag(3800)
                        Text("Wide (4.8 kHz)").tag(4800)
                        Text("Widest (5.0 kHz)").tag(5000)
                    }
                }

                // MARK: - VoiceOver Integration Instructions
                Section(header: Text("VoiceOver Integration Guide")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Step 1: Open iOS Settings app", systemName: "gear")
                        Label("Step 2: Go to Accessibility -> VoiceOver -> Speech", systemName: "hand.tap")
                        Label("Step 3: Tap Voice -> Select DoubleTalk", systemName: "speaker.wave.3")
                        Label("Step 4: Pick your favorite speaker (e.g. Perfect Paul, Vader)", systemName: "person.circle")
                    }
                    .font(.subheadline)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("DoubleTalk PC")
            .onAppear(perform: checkROM)
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.bin, .data, .item],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
        }
    }

    private func checkROM() {
        if let data = DoubleTalkSettingsStore.loadROMData() {
            romLoaded = true
            romSize = data.count
        } else {
            romLoaded = false
            romSize = 0
        }
    }

    private func saveSettings() {
        DoubleTalkSettingsStore.save(settings)
    }

    private func togglePlay() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            return
        }

        guard let synth = DoubleTalkSynthesizer() else {
            statusMessage = "Synthesizer initialization failed."
            return
        }

        let pcmInt16 = synth.render(testText, settings: settings, speaker: selectedSpeaker)
        guard !pcmInt16.isEmpty else { return }

        // Create WAV audio buffer header for AVAudioPlayer
        let wavData = createWAVHeader(pcmData: pcmInt16, sampleRate: 10504)
        do {
            audioPlayer = try AVAudioPlayer(data: wavData)
            audioPlayer?.play()
            isPlaying = true
        } catch {
            statusMessage = "Audio playback error: \(error.localizedDescription)"
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let selectedURL = urls.first else { return }
        guard selectedURL.startAccessingSecurityScopedResource() else { return }
        defer { selectedURL.stopAccessingSecurityScopedResource() }

        if let data = try? Data(contentsOf: selectedURL), data.count == 524288 {
            try? DoubleTalkSettingsStore.saveROMData(data)
            checkROM()
        }
    }

    private func createWAVHeader(pcmData: [Int16], sampleRate: Int) -> Data {
        var data = Data()
        let numSamples = pcmData.count
        let dataSize = numSamples * 2
        let chunkSize = 36 + dataSize
        let byteRate = sampleRate * 2

        data.append(contentsOf: Array("RIFF".utf8))
        data.append(contentsOf: withUnsafeBytes(of: Int32(chunkSize).littleEndian) { Array($0) })
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        data.append(contentsOf: withUnsafeBytes(of: Int32(16).littleEndian) { Array($0) }) // Subchunk1Size (16 for PCM)
        data.append(contentsOf: withUnsafeBytes(of: Int16(1).littleEndian) { Array($0) })  // AudioFormat (1 for PCM)
        data.append(contentsOf: withUnsafeBytes(of: Int16(1).littleEndian) { Array($0) })  // NumChannels (1 mono)
        data.append(contentsOf: withUnsafeBytes(of: Int32(sampleRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: Int32(byteRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: Int16(2).littleEndian) { Array($0) })  // BlockAlign
        data.append(contentsOf: withUnsafeBytes(of: Int16(16).littleEndian) { Array($0) }) // BitsPerSample
        data.append(contentsOf: Array("data".utf8))
        data.append(contentsOf: withUnsafeBytes(of: Int32(dataSize).littleEndian) { Array($0) })

        pcmData.withUnsafeBufferPointer { ptr in
            data.append(UnsafeRawBufferPointer(ptr))
        }

        return data
    }
}
