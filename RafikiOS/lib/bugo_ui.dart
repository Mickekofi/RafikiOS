import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bugo_service.dart';

class BugoDashboard extends StatefulWidget {
  @override
  _BugoDashboardState createState() => _BugoDashboardState();
}

class _BugoDashboardState extends State<BugoDashboard> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.microphone,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    final bugo = context.watch<BugoService>();

    return Scaffold(
      backgroundColor: Colors.black,

      // --- DYNAMIC EXPANSION BUTTON ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showAddDeviceModal(context, bugo),
      ),

      // --- SIDE MENUBAR (DRAWER) ---
      drawer: Drawer(
        backgroundColor: Colors.grey.shade900,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.greenAccent.withOpacity(0.5),
                  ),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "SYSTEM MENU",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "RAFIKI OS CONFIGURATION",
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // --- WAKE-WORD TOGGLE ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ValueListenableBuilder<bool>(
                valueListenable: bugo.isWakeWordActive,
                builder: (context, isWakeWordActive, child) {
                  return SwitchListTile(
                    title: const Text(
                      "HANDS-FREE MODE",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      isWakeWordActive
                          ? "Active: Listening for 'Rafiki'..."
                          : "Disabled: System requires manual tap",
                      style: TextStyle(
                        color: isWakeWordActive ? Colors.white : Colors.grey,
                        fontFamily: 'Courier',
                        fontSize: 11,
                      ),
                    ),
                    value: isWakeWordActive,
                    activeColor: Colors.cyanAccent,
                    onChanged: (val) {
                      bugo.toggleWakeWordMode(val);
                    },
                  );
                },
              ),
            ),
            const Divider(color: Colors.grey),

            // --- HELP MENU TRIGGER ---
            ListTile(
              leading: const Icon(
                Icons.help_outline,
                color: Colors.amberAccent,
              ),
              title: const Text(
                "TEAM & MANUAL",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showHelpMenu(context);
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "RAFIKI OS",
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.greenAccent),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.greenAccent.withOpacity(0.5),
            height: 1.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- BLUETOOTH CONNECTION BAR ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<BugoState>(
                  valueListenable: bugo.connectionState,
                  builder: (context, state, child) {
                    Color statusColor = Colors.grey;
                    String statusText = "STANDBY";

                    if (state == BugoState.connected) {
                      statusColor = Colors.greenAccent;
                      statusText = "LINK ESTABLISHED";
                    } else if (state == BugoState.connecting) {
                      statusColor = Colors.amberAccent;
                      statusText = "HANDSHAKING...";
                    } else {
                      statusColor = Colors.redAccent;
                      statusText = "LINK SEVERED";
                    }

                    return Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<BugoState>(
                  valueListenable: bugo.connectionState,
                  builder: (context, state, child) {
                    bool isConnecting = state == BugoState.connecting;
                    bool isConnected = state == BugoState.connected;

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnected
                            ? Colors.redAccent.withOpacity(0.2)
                            : Colors.grey.shade900,
                        side: BorderSide(
                          color: isConnected
                              ? Colors.redAccent
                              : Colors.greenAccent,
                        ),
                      ),
                      onPressed: isConnecting
                          ? null
                          : () {
                              if (isConnected) {
                                bugo.disconnect();
                              } else {
                                _openBluetoothSettings(context, bugo);
                              }
                            },
                      child: isConnecting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.amberAccent,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isConnected ? "DISCONNECT" : "CONNECT",
                              style: TextStyle(
                                color: isConnected
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontFamily: 'Courier',
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- TERMINAL WINDOW ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "> ${bugo.statusMessage.value}",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'Courier',
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- HARDWARE TOGGLES ---
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildGamingToggle(
                    "RED ALERT",
                    bugo.isRedOn,
                    Colors.redAccent,
                    () => bugo.sendCommand(bugo.isRedOn ? 'a' : 'A'),
                  ),
                  _buildGamingToggle(
                    "YELLOW WARN",
                    bugo.isYellowOn,
                    Colors.amberAccent,
                    () => bugo.sendCommand(bugo.isYellowOn ? 'b' : 'B'),
                  ),
                  _buildGamingToggle(
                    "GREEN SAFE",
                    bugo.isGreenOn,
                    Colors.greenAccent,
                    () => bugo.sendCommand(bugo.isGreenOn ? 'c' : 'C'),
                  ),
                  _buildGamingToggle(
                    "COOLING",
                    bugo.isFanOn,
                    Colors.cyanAccent,
                    () => bugo.sendCommand(bugo.isFanOn ? 'f' : 'F'),
                  ),

                  // --- INJECT DYNAMIC DEVICES WITH LONG-PRESS DELETE ---
                  ...bugo.customDevices
                      .map(
                        (dev) => _buildGamingToggle(
                          dev.name.toUpperCase(),
                          dev.isOn,
                          Colors.purpleAccent,
                          () => bugo.toggleCustomDevice(dev),
                          onLongPress: () =>
                              _confirmDeleteDevice(context, bugo, dev),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),

            // --- VOICE COMMAND BUTTON (MANUAL CLUTCH) ---
            ValueListenableBuilder<bool>(
              valueListenable: bugo.isListening,
              builder: (context, isListening, child) {
                return GestureDetector(
                  onTap: () => bugo.toggleListening(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening
                          ? Colors.redAccent.withOpacity(0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: isListening
                            ? Colors.redAccent
                            : Colors.amberAccent,
                        width: isListening ? 4 : 2,
                      ),
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: isListening ? Colors.white : Colors.amberAccent,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<bool>(
              valueListenable: bugo.isListening,
              builder: (context, isListening, child) {
                return Text(
                  isListening ? "LISTENING... TAP TO CANCEL" : "TAP TO SPEAK",
                  style: TextStyle(
                    color: isListening ? Colors.redAccent : Colors.amberAccent,
                    fontFamily: 'Courier',
                    letterSpacing: 2,
                    fontWeight: isListening
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamingToggle(
    String title,
    bool isOn,
    Color activeColor,
    VoidCallback onTap, {
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: isOn ? activeColor.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isOn ? activeColor : Colors.grey.shade800,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.power_settings_new,
              color: isOn ? activeColor : Colors.grey.shade800,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isOn ? activeColor : Colors.grey.shade600,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onLongPress != null) ...[
              const SizedBox(height: 6),
              const Text(
                "HOLD TO UNBIND",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Courier',
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- DE-PROVISIONING CONFIRMATION MODAL ---
  void _confirmDeleteDevice(
    BuildContext context,
    BugoService bugo,
    CustomDevice device,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(8),
        ),
        title: const Text(
          "DE-PROVISION PORT",
          style: TextStyle(
            color: Colors.redAccent,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Unbind hardware port for '${device.name}'?\n\nThis will safely disengage the pin and recycle commands ('${device.onChar}'/'${device.offChar}') back to system memory.",
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Courier',
            fontSize: 12,
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.grey, fontFamily: 'Courier'),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "UNBIND",
              style: TextStyle(
                color: Colors.redAccent,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              bugo.removeCustomDevice(device);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // --- DYNAMIC HARDWARE PROVISIONING MODAL ---
  void _showAddDeviceModal(BuildContext context, BugoService bugo) {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.cyanAccent),
          borderRadius: BorderRadius.circular(8),
        ),
        title: const Text(
          "PROVISION HARDWARE",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: "Device Name (e.g., Main Door)",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.grey, fontFamily: 'Courier'),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "LINK PORT",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                bugo.addCustomDevice(nameController.text.trim());
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _openBluetoothSettings(BuildContext context, BugoService bugo) async {
    List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance
        .getBondedDevices();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          "Select Core",
          style: TextStyle(color: Colors.greenAccent, fontFamily: 'Courier'),
        ),
        content: SizedBox(
          height: 300,
          width: 300,
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  devices[index].name ?? "Unknown Device",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  devices[index].address,
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  bugo.connect(devices[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showHelpMenu(BuildContext context) {
    final List<Map<String, dynamic>> team = [
      {
        "name": "MICHAEL APPIAH",
        "role": "Project Lead & Architecture",
        "icon": Icons.engineering,
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.amberAccent),
          borderRadius: BorderRadius.circular(8),
        ),
        title: const Text(
          "RAFIKI OS: MANUAL & CORE TEAM",
          style: TextStyle(
            color: Colors.amberAccent,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MANUAL OVERRIDE:",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Tap any hardware module tile to immediately toggle its power state.",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "HANDS-FREE PROTOCOL:",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Open the side menu (top left) and toggle 'Hands-Free Mode'. The system will continuously listen for 'Rafiki'. Once detected, state your command.",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "VOICE PROTOCOL (MANUAL CLUTCH):",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "1. Tap the Mic icon once to open the channel.\n2. Speak your command.\n3. Tap the Mic again to EXECUTE.",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Valid Targets: Red, Yellow, Green, Fan\nValid States: On, Off",
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "GOD MODE COMMAND:",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "> \"Let there be light\"\nInstantly triggers all LED arrays and the Cooling Fan.",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.greenAccent),
                const SizedBox(height: 8),
                const Text(
                  "PROJECT CONTRIBUTORS:",
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...team
                    .map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Icon(
                              member['icon'],
                              color: Colors.greenAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    member['role'],
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontFamily: 'Courier',
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ACKNOWLEDGE",
              style: TextStyle(
                color: Colors.amberAccent,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
