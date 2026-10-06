import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

// --- DYNAMIC DATA MODEL ---
class CustomDevice {
  String name;
  String onChar;
  String offChar;
  bool isOn;

  CustomDevice({
    required this.name,
    required this.onChar,
    required this.offChar,
    this.isOn = false,
  });
}

enum BugoState { disconnected, connecting, connected }

class BugoService extends ChangeNotifier {
  BluetoothConnection? _connection;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  ValueNotifier<BugoState> connectionState = ValueNotifier(
    BugoState.disconnected,
  );
  ValueNotifier<String> statusMessage = ValueNotifier(
    "System Standby. Connect to Bugo Core.",
  );

  ValueNotifier<bool> isListening = ValueNotifier(
    false,
  ); // For manual/command dictation
  ValueNotifier<bool> isWakeWordActive = ValueNotifier(
    false,
  ); // Toggle for continuous listening

  bool isRedOn = false;
  bool isYellowOn = false;
  bool isGreenOn = false;
  bool isFanOn = false;

  // --- DYNAMIC HARDWARE EXPANSION ---
  List<CustomDevice> customDevices = [];

  // Pre-allocated Arduino command pairs waiting to be claimed
  List<List<String>> availablePorts = [
    ['X', 'x'],
    ['Y', 'y'],
    ['Z', 'z'],
  ];

  String _currentWords = "";
  bool _isProcessingCommand = false; // Prevents the loops from overlapping

  BugoService() {
    _initSpeech();
    _initTts();
  }

  // --- DYNAMIC PROVISIONING ENGINE ---
  void addCustomDevice(String name) {
    if (availablePorts.isEmpty) {
      _updateStatus("ERROR: All physical expansion ports exhausted.");
      _speak("Expansion ports full.");
      return;
    }
    // Claim the next available hardware port
    var port = availablePorts.removeAt(0);
    customDevices.add(
      CustomDevice(name: name, onChar: port[0], offChar: port[1]),
    );
    notifyListeners();
    _updateStatus("Port provisioned for: $name");
    _speak("$name added to system.");
  }

  void toggleCustomDevice(CustomDevice device) {
    device.isOn = !device.isOn;
    sendCommand(device.isOn ? device.onChar : device.offChar);
    notifyListeners();
  }

  // --- AUDIO ENGINE ---
  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (isListening.value) {
            isListening.value = false;
            _processVoiceCommand(_currentWords);
            _isProcessingCommand = false;

            if (isWakeWordActive.value) {
              Future.delayed(const Duration(seconds: 1), _huntForWakeWord);
            }
          } else if (isWakeWordActive.value && !_isProcessingCommand) {
            Future.delayed(const Duration(milliseconds: 500), _huntForWakeWord);
          }
        }
      },
      onError: (errorNotification) {
        _updateStatus("Speech Error: ${errorNotification.errorMsg}");
        isListening.value = false;
        _isProcessingCommand = false;
      },
    );
    if (!available) {
      _updateStatus("CRITICAL: Speech recognition hardware unavailable.");
    }
  }

  // --- WAKE WORD ENGINE ---
  void toggleWakeWordMode(bool enable) {
    isWakeWordActive.value = enable;
    if (enable) {
      _huntForWakeWord();
    } else {
      _speech.stop();
      _updateStatus("Hands-free mode disabled.");
    }
  }

  void _huntForWakeWord() async {
    if (!isWakeWordActive.value || _isProcessingCommand) return;

    if (await Permission.microphone.request().isGranted) {
      _updateStatus("Awaiting Wake Word: 'Rafiki'...");
      _speech.listen(
        onResult: (result) async {
          String words = result.recognizedWords.toLowerCase();
          if (words.contains("rafiki")) {
            _speech.stop();
            _isProcessingCommand = true;
            _updateStatus("Wake word detected!");

            await _speak("I am listening.");

            Future.delayed(const Duration(milliseconds: 1500), () {
              _startCommandDictation();
            });
          }
        },
        listenFor: const Duration(seconds: 30),
      );
    }
  }

  void _startCommandDictation() async {
    _currentWords = "";
    isListening.value = true;
    _updateStatus("Listening for command...");

    _speech.listen(
      onResult: (result) {
        _currentWords = result.recognizedWords.toLowerCase();
        _updateStatus("Hearing: \"$_currentWords\"");
      },
      listenFor: const Duration(seconds: 10),
    );
  }

  // --- MANUAL CLUTCH VOICE ENGINE ---
  void toggleListening() async {
    isWakeWordActive.value = false;

    if (isListening.value) {
      _speech.stop();
      isListening.value = false;
      _updateStatus("Processing...");
      _processVoiceCommand(_currentWords);
      _currentWords = "";
      return;
    }

    if (await Permission.microphone.request().isGranted) {
      _currentWords = "";
      isListening.value = true;
      _updateStatus("Listening...");

      await _tts.stop();

      _speech.listen(
        onResult: (result) {
          _currentWords = result.recognizedWords.toLowerCase();
          _updateStatus("Hearing: \"$_currentWords\"");
        },
        listenFor: const Duration(seconds: 15),
      );
    } else {
      _updateStatus("Microphone permission denied.");
    }
  }

  // --- BLUETOOTH CORE ---
  Future<void> connect(BluetoothDevice device) async {
    if (connectionState.value == BugoState.connecting) return;

    connectionState.value = BugoState.connecting;
    _updateStatus("Initiating handshake with ${device.name}...");

    try {
      _connection = await BluetoothConnection.toAddress(
        device.address,
      ).timeout(const Duration(seconds: 5));
      connectionState.value = BugoState.connected;
      _updateStatus("Bugo Online. Hardware link established.");
      _speak("Bugo core connected.");

      _connection!.input!.listen(null).onDone(() {
        _updateStatus("WARN: Connection physically dropped by hardware.");
        _speak("Hardware connection lost.");
        disconnect();
      });
    } on TimeoutException {
      connectionState.value = BugoState.disconnected;
      _updateStatus("FAIL: Connection timed out.");
      _speak("Connection timed out.");
    } catch (e) {
      connectionState.value = BugoState.disconnected;
      _updateStatus("FAIL: ${e.toString().split(':').last.trim()}");
      _speak("Connection failed.");
    }
  }

  void disconnect() {
    _connection?.close();
    _connection = null;
    connectionState.value = BugoState.disconnected;
    _updateStatus("Bugo Offline.");
    _speak("System offline.");
  }

  // --- HARDWARE TRANSMISSION ---
  void sendCommand(String charCommand) {
    if (_connection != null && _connection!.isConnected) {
      _connection!.output.add(ascii.encode(charCommand));
      _updateHardwareState(charCommand);
    } else {
      _updateStatus("ERROR: Cannot transmit. Link severed.");
      _speak("Error. Link severed.");
      connectionState.value = BugoState.disconnected;
    }
  }

  void _updateHardwareState(String cmd) {
    switch (cmd) {
      case 'A':
        isRedOn = true;
        break;
      case 'a':
        isRedOn = false;
        break;
      case 'B':
        isYellowOn = true;
        break;
      case 'b':
        isYellowOn = false;
        break;
      case 'C':
        isGreenOn = true;
        break;
      case 'c':
        isGreenOn = false;
        break;
      case 'F':
        isFanOn = true;
        break;
      case 'f':
        isFanOn = false;
        break;
    }
    // We do not map X, Y, Z here because toggleCustomDevice handles its own state
    notifyListeners();
  }

  // --- NATURAL LANGUAGE PROCESSING ---
  void _processVoiceCommand(String text) {
    if (text.isEmpty) {
      _updateStatus("No voice input detected.");
      return;
    }

    if (text.contains("let there be light")) {
      sendCommand('A');
      Future.delayed(const Duration(milliseconds: 100), () => sendCommand('B'));
      Future.delayed(const Duration(milliseconds: 200), () => sendCommand('C'));
      Future.delayed(const Duration(milliseconds: 300), () => sendCommand('F'));

      // Also turn on any dynamic devices if God Mode is triggered
      int delay = 400;
      for (var dev in customDevices) {
        dev.isOn = true;
        Future.delayed(
          Duration(milliseconds: delay),
          () => sendCommand(dev.onChar),
        );
        delay += 100;
      }

      _updateStatus("GOD MODE ACTIVATED.");
      _speak("And There Was Light.");
      notifyListeners();
      return;
    }

    if (text.contains("shut down") ||
        text.contains("everything off") ||
        text.contains("disengage") ||
        text.contains("kill all systems") ||
        text.contains("off everything")) {
      sendCommand('a');
      Future.delayed(const Duration(milliseconds: 100), () => sendCommand('b'));
      Future.delayed(const Duration(milliseconds: 200), () => sendCommand('c'));
      Future.delayed(const Duration(milliseconds: 300), () => sendCommand('f'));

      // Turn off any dynamic devices
      int delay = 400;
      for (var dev in customDevices) {
        dev.isOn = false;
        Future.delayed(
          Duration(milliseconds: delay),
          () => sendCommand(dev.offChar),
        );
        delay += 100;
      }

      _updateStatus("SYSTEM SHUTDOWN INITIATED.");
      _speak("All systems disengaged.");
      notifyListeners();
      return;
    }

    if (text.contains("all lights on") || text.contains("all light on")) {
      sendCommand('A');
      Future.delayed(const Duration(milliseconds: 100), () => sendCommand('B'));
      Future.delayed(const Duration(milliseconds: 200), () => sendCommand('C'));
      _updateStatus("LIGHTS ON.");
      _speak("Lights on.");
      return;
    }

    if (text.contains("all lights off") || text.contains("all light off")) {
      sendCommand('a');
      Future.delayed(const Duration(milliseconds: 100), () => sendCommand('b'));
      Future.delayed(const Duration(milliseconds: 200), () => sendCommand('c'));
      _updateStatus("LIGHTS OFF.");
      _speak("Lights off.");
      return;
    }

    bool turnOn = text.contains("on") || text.contains("open");
    bool turnOff = text.contains("off") || text.contains("close");

    if (!turnOn && !turnOff) {
      _updateStatus("Command unclear: Specify 'On' or 'Off'.");
      _speak("Specify on or off.");
      return;
    }

    // --- NEW: SCAN FOR DYNAMIC CUSTOM DEVICES FIRST ---
    for (var device in customDevices) {
      if (text.contains(device.name.toLowerCase())) {
        if (turnOn) {
          device.isOn = true;
          sendCommand(device.onChar);
        } else if (turnOff) {
          device.isOn = false;
          sendCommand(device.offChar);
        }
        _updateStatus("Executed: $text");
        _speak("${device.name} triggered.");
        notifyListeners();
        return;
      }
    }

    // --- FALLBACK TO HARDCODED HARDWARE ---
    bool hardwareTargeted = false;

    if (text.contains("red")) {
      sendCommand(turnOn ? 'A' : 'a');
      hardwareTargeted = true;
    }
    if (text.contains("yellow")) {
      sendCommand(turnOn ? 'B' : 'b');
      hardwareTargeted = true;
    }
    if (text.contains("green")) {
      sendCommand(turnOn ? 'C' : 'c');
      hardwareTargeted = true;
    }
    if (text.contains("fan") || text.contains("motor")) {
      sendCommand(turnOn ? 'F' : 'f');
      hardwareTargeted = true;
    }

    if (hardwareTargeted) {
      _updateStatus("Executed: $text");
      _speak("Command executed.");
    } else {
      _updateStatus("Target unrecognized in: \"$text\"");
      _speak("Target unrecognized.");
    }
  }

  void _updateStatus(String msg) {
    statusMessage.value = msg;
    notifyListeners();
  }

  // --- DE-PROVISIONING LOGIC ---
  void removeCustomDevice(CustomDevice device) {
    // 1. Safety disengage physical relay pin if active
    if (device.isOn) {
      sendCommand(device.offChar);
    }

    // 2. Unbind device and recycle physical serial command pair
    customDevices.remove(device);
    availablePorts.add([device.onChar, device.offChar]);

    _updateStatus("De-provisioned port: ${device.name}");
    _speak("${device.name} removed from system.");
    notifyListeners();
  }
}
