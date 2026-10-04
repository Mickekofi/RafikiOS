<p align="center">
  <img src="https://github.com/Mickekofi/RafikiOS/blob/master/logo.png?raw=true" width="130">
</p>

<h1 align="center"><strong>A Smart Home Robotics: An Adaptable Environment Control Unit</strong></h1>

<p align="center">
  <a href="">
    <img src="https://img.shields.io/badge/Join-Community-blue.svg" alt="Join Community">
  </a>
  <a href="https://wa.me/233507326320?text=*RafikiOS_From_Github_User_💬Message_:*%20">
    <img src="https://img.shields.io/badge/Contact-Engineers-red.svg" alt="Contact Engineers">
  </a>
</p>

---

# RAFIKI OS

Rafiki Is An Adaptive Environment Control Unit that transforms any electrical appliance into a Smart Controllable Device Without Requiring the User to replace them

![Preview](https://github.com/Mickekofi/RafikiOS/blob/master/Rafiki_Image.png?raw=true)

We will Be Doing an MVP of it Today with Ardiuno Microcontroller and some electrical substances and modules and Our Own Customized Flutter Software... So that You Can Practice Too

**How To Build The Flutter Software** → See [Software](./SOFTWARE.md)

---

# Components Needed



| Component | Qty | Used For | Image |
|---|:---:|---|---|
| **Arduino Uno** | 1 | The microcontroller (logic board) | <img src="./images/components/arduino-uno.jpg" width="120" alt="Arduino Uno"> |
| **Breadboard** | 1 | Power bus (5V and GND rails) and circuit building | <img src="./images/components/breadboard.jpg" width="120" alt="Breadboard"> |
| **HC-05 Bluetooth Module** | 1 | Telemetry link between the app and the Arduino | <img src="./images/components/hc05.jpg" width="120" alt="HC-05 Bluetooth Module"> |
| **1kΩ Resistors** | 2 | Voltage divider on the HC-05 RXD pin (5V → 2.5V) | <img src="./images/components/resistor-1k.jpg" width="120" alt="1k Ohm Resistors"> |
| **LEDs (Red, Yellow, Green)** | 3 | Diagnostic LEDs (Slots 1 to 3) | <img src="./images/components/leds.jpg" width="120" alt="Red, Yellow and Green LEDs"> |
| **Resistors (220Ω to 1kΩ)** | 3 | Current limiting for each LED | <img src="./images/components/resistors-led.jpg" width="120" alt="LED Current Limiting Resistors"> |
| **Tongling Relay Module** | 1 | Switches the motor load (Slot 4, Muscle Actuator) | <img src="./images/components/relay.jpg" width="120" alt="Tongling Relay Module"> |
| **Flyback Diode** | 1 | Protects the relay and Arduino from the motor's Back EMF | <img src="./images/components/diode.jpg" width="120" alt="Flyback Diode"> |
| **DC Motor** | 1 | The load being switched | <img src="./images/components/dc-motor.jpg" width="120" alt="DC Motor"> |
| **External Battery** | 1 | Powers the motor (kept separate from the Arduino) | <img src="./images/components/external-battery.jpg" width="120" alt="External Battery"> |
| **Jumper Wires** | as needed | Connections between all parts | <img src="./images/components/jumper-wires.jpg" width="120" alt="Jumper Wires"> |
| **7V to 12V Battery** (e.g. 9V battery or 12V LiPo) | 1 | Optional: powers the Arduino independently via **Vin** | <img src="./images/components/arduino-battery.jpg" width="120" alt="7V to 12V Battery"> |

**Software needed**
- Arduino IDE (to upload the code)
- The Flutter app (see [Software](./SOFTWARE.md))

---

# Building The Hardware
## Step 1: The Power Bus

Take your empty breadboard and your Arduino.

>1. Connect the **5V pin** on the Arduino to the **Red (+)** rail running down the side of your breadboard.

>2. Connect the **GND pin** on the Arduino to the **Blue/Black (-)** rail right next to it.

```WHY
The WHY: An amateur runs individual power wires for every single component back to the Arduino. This creates a rat's nest, causes wires to pull loose, and creates ground loops (electrical noise). A professional builds a unified "bus"—a single clean power line that all future modules tap into.
```

---


## Step 2: The Telemetry Link (HC-05)
Take your HC-05 Bluetooth module. It has four pins we care about right now: VCC, GND, TXD, and RXD.

> 1. Connect **VCC** to the Red (+) rail on your breadboard.
> 2. Connect **GND** to the Blue/Black (-) rail on your breadboard.
> 3. Connect **TXD** (Transmit) on the HC-05 to **Arduino Digital Pin 10**.
> 4. Connect **RXD** (Receive) on the HC-05 to **Arduino Digital Pin 11**.

##### NOTE BEFORE CONTINUE: 
The Arduino Uno's digital pins output $5\text{V}$. The HC-05's RXD pin expects $3.3\text{V}$.
If you connect a $5\text{V}$ line directly to a $3.3\text{V}$ input, it usually works—for a while. But you are over-pressurizing the silicon inside the Bluetooth chip. Over time, that overvoltage generates microscopic heat, degrades the silicon, and eventually causes the RXD pin to fail. If this A-ECU is meant to be a reliable medical device, you cannot design it with built-in hardware degradation.

`A voltage divider takes advantage of Ohm's Law to drop voltage precisely. The formula is:`

$$V_{out} = V_{in} \cdot \left(\frac{R_2}{R_1 + R_2}\right)$$

`By placing two identical $1\text{k}\Omega$ resistors in series, you split the voltage exactly in half:`

$$V_{out} = 5\text{V} \cdot \left(\frac{1000}{1000 + 1000}\right) = 2.5\text{V}$$
*The HC-05 considers anything above $\sim2.0\text{V}$ as a logical `HIGH`, so $2.5\text{V}$ triggers the data read perfectly without stressing the chip.*

Here is how you physically wire this "middle tap" on your breadboard.

>1. Place Resistor 1 (R1):
Take a $1\text{k}\Omega$ resistor. Plug one end into **Arduino Pin 11**. Plug the other end into an **empty row** on your breadboard (let's say Row 20).

> 2. Place Resistor 2 (R2):
Take the second $1\text{k}\Omega$ resistor. Plug one end into that exact same **empty row** (Row 20). Plug the other end directly into the **GND Rail**.

> 3. Connect the HC-05 RXD Pin: **The 2.5V Tap.**
Take a jumper wire. Plug one end into that same **empty row** (Row 20) right between the two resistors. Plug the other end into the **RXD pin** on the HC-05.

If you have already wired Pin 11 directly to RXD from Step 2, pull that wire out and rebuild it with this voltage divider.
Do not proceed until you have protected that module.


---

## Step 3: The Expansion Slots (Diagnostic LEDs)
Take your three LEDs (Red, Yellow, Green) and three resistors (anything from 220Ω to 1kΩ will work).

> 1. **Slot 1 (Red):** Connect **Arduino Pin 2** to one side of a resistor. Connect the other side of the resistor to the **Long Leg (Anode)** of the Red LED. Plug the **Short Leg (Cathode)** of the LED directly into the **Blue/Black (-)** ground rail.
> 2. **Slot 2 (Yellow):** Repeat this process for **Arduino Pin 3** using the Yellow LED.
> 3. **Slot 3 (Green):** Repeat this process for **Arduino Pin 4** using the Green LED.

The WHY: Current Limiting
An LED is a diode. It has almost zero internal electrical resistance. If you connect an LED directly from Pin 2 to Ground without a resistor, it acts like an open pipe. It will pull maximum current from the Arduino, flash very brightly for a fraction of a second, and then burn out permanently. The resistor acts as a valve, choking the current down to a safe 20 milliamps. If you want a system to survive a 72-hour burn-in, you never skip current limiting.

---
## Step 4: The Actuation Core (Relay, Diode, Motor, Battery)
Keep the external battery disconnected until the very last step.

#### 1. Wire the Relay to the Arduino Bus: 
Look at the small pins on the Tongling Relay module.
> 1. Connect **VCC** to the breadboard **5V Rail**.
> 2. Connect **GND** to the breadboard **GND Rail**.
> 3. Connect **IN** to **Arduino Digital Pin 5**.
 
#### 2. Install the Flyback Diode on the Motor
Take your DC motor and the diode.
>1. Connect the **Striped End (Cathode)** of the diode directly to the **Positive (Red)** wire of your motor.
> 2. Connect the **Solid Black End (Anode)** of the diode directly to the **Negative (Black)** wire of your motor.


#### 3. Wire the Load Side
Look at the heavy green screw terminals on the relay.

>1. Connect the **Positive (Red) wire** of your external battery to the **COM (Common)** terminal.
>2. Connect the **Positive (Red) wire** of your motor (the side with the striped diode end) to the **NO (Normally Open)** terminal.
>3. Twist the **Negative (Black) wire** of your motor directly to the **Negative (Black) wire** of your external battery.

**The WHY: Galvanic Isolation**
Look at your breadboard. The battery and the motor power do not touch the Arduino. They do not touch the breadboard rails. They only touch the green screw terminals on the relay.
This is Galvanic Isolation. When Pin 5 sends a 5V signal, it powers a tiny electromagnet inside the blue relay box. That magnet pulls a physical metal lever closed, which completes the battery-motor circuit. If the motor jams and tries to pull 5 amps, it pulls it from the battery, not the Arduino. The logic board remains perfectly safe. This is exactly how you safely switch a 220V ceiling fan.

**The WHY: The Inductive Kickback**
Motors are giant coils of wire. When you turn the motor on, a magnetic field builds up inside it. When you turn the relay off, that magnetic field violently collapses. Because of the laws of electromagnetism, that collapsing field generates a massive voltage spike that shoots backward through the wires. This is called **Back EMF**.

If you do not have that Flyback Diode installed, that high-voltage spike will hit the metal contacts inside the relay, cause a literal electrical spark, create a burst of electromagnetic interference (EMI), and instantly freeze or reset your Arduino. The diode acts as a one-way pressure valve. It catches that backwards spike and loops it harmlessly around the motor until it burns out as heat.

Double-check the diode direction. Striped end to positive. If you put it in backward, you will create a direct short circuit across the battery the second the relay clicks on.


---

# Arduino Code

COPY AND PASTE THESE CODES IN YOUR Arduino IDE
```c++
#include <SoftwareSerial.h>

// ==========================================
// CONFIGURATION & CALIBRATION
// ==========================================

// Relay Logic Inversion
// If the app is backward, flip HIGH and LOW right here.
const int RELAY_ON = HIGH;  
const int RELAY_OFF = LOW; 

// ==========================================
// HARDWARE PINS
// ==========================================
SoftwareSerial BTSerial(10, 11); // RX, TX

const int SLOT_1_RED   = 2; // Diagnostic
const int SLOT_2_YEL   = 3; // Diagnostic
const int SLOT_3_GRN   = 4; // Diagnostic
const int SLOT_4_RELAY = 5; // Muscle Actuator

void setup() {
  pinMode(SLOT_1_RED, OUTPUT);
  pinMode(SLOT_2_YEL, OUTPUT);
  pinMode(SLOT_3_GRN, OUTPUT);
  pinMode(SLOT_4_RELAY, OUTPUT);

  // Initialize all slots OFF
  digitalWrite(SLOT_1_RED, LOW);
  digitalWrite(SLOT_2_YEL, LOW);
  digitalWrite(SLOT_3_GRN, LOW);
  
  // Initialize Relay OFF using our configuration variable
  digitalWrite(SLOT_4_RELAY, RELAY_OFF); 

  BTSerial.begin(9600);
}

void loop() {
  // Listen for App Commands
  if (BTSerial.available()) {
    char cmd = BTSerial.read();
    executeCommand(cmd);
  }
}

// ==========================================
// ROUTER: COMMAND PARSER
// ==========================================
void executeCommand(char cmd) {
  switch (cmd) {
    case 'A': digitalWrite(SLOT_1_RED, HIGH); break;
    case 'a': digitalWrite(SLOT_1_RED, LOW); break;
    case 'B': digitalWrite(SLOT_2_YEL, HIGH); break;
    case 'b': digitalWrite(SLOT_2_YEL, LOW); break;
    case 'C': digitalWrite(SLOT_3_GRN, HIGH); break;
    case 'c': digitalWrite(SLOT_3_GRN, LOW); break;
    
    // Use the Configuration variables for Actuation
    case 'F': digitalWrite(SLOT_4_RELAY, RELAY_ON); break;  
    case 'f': digitalWrite(SLOT_4_RELAY, RELAY_OFF); break; 
  }
}
```

---

## Now Its Time to Power You Arduino Board with a Battery to Work Independently 

`Never connect a battery directly to the 5V pin.`
The `5V` pin on your breadboard and the Arduino bypasses the voltage regulator completely. If your battery outputs 5.5V or 6V, that raw voltage goes straight into the microcontroller's brain and permanently destroys the silicon. The `5V` pin is strictly an **output** to power your sensors, not an input for raw batteries.

##### If your battery is between 7V and 12V (e.g., a 9V battery or a 12V LiPo):
You must use the onboard regulator. This acts as a shield, burning off the excess voltage as heat and delivering exactly 5V to the logic board.

>1. Connect the Ground: Connect the battery's Negative (Black) wire to any **GND** pin on the Arduino (or your breadboard's ground rail).
>2. Connect the Positive Wire to Vin: Connect the battery's Positive (Red) wire strictly to the **Vin** pin on the Arduino.

---

# Building The Software
**How To Build The Flutter Software** → See [Software](./SOFTWARE.md)

## 📞 CONTACT & SUPPORT

For questions or support:
- **WhatsApp**: [Contact Engineers](https://wa.me/233507326320?text=*RAFIKI_From_Github_💬Message_:*%20)
- **GitHub**: Open an issue in the repository

---
