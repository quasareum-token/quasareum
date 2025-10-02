# QUASAREUM

Quasareum is a project focused on accessible cryptocurrency mining. Its unique hashing algorithm is specifically designed for high efficiency on low-energy (LE) devices, allowing anyone to participate. The token also features a fully on-chain, built-in market for decentralized trading.

---

## Repository layout

```
quasareum-main/
├─ contracts/
│  └─ quasareum_token.sol
│
├─ miners/
│  ├─ quasareum_arduino_ide/
│  │  ├─ miner_arduino/
│  │  │  └─ miner_arduino.ino
│  │  │
│  │  └─ miner_esp/
│  │     └─ miner_esp.ino
│  │
│  └─ quasareum_python/
│     └─ miner.py
│
├─ whitepaper/
│  └─ Quasareum.pdf
│
└─ README.md
```

---

## Installation & Usage

### 🔹 Arduino Miner (Arduino IDE)

You can use either the **Arduino** or **ESP** miner depending on your board.

#### Arduino board
1. Open **Arduino IDE** → File → Open → select  
   `miners/quasareum_arduino_ide/miner_arduino/miner_arduino.ino`
2. Select your board (Tools → Board) and port (Tools → Port).
3. Click **Upload**.
4. Open **Serial Monitor** (115200 baud).

#### ESP board
1. Open **Arduino IDE** → File → Open → select  
   `miners/quasareum_arduino_ide/miner_esp/miner_esp.ino`
2. Select your ESP board (e.g., ESP32/ESP8266) and port.
3. Click **Upload**.
4. Open **Serial Monitor** (115200 baud).

**Serial commands**
- `solutions` – print last stored solutions
- `rate` – show current hashrate
- `clear` – clear EEPROM and reset stored solutions
- `addr 0x...` – set a new Ethereum address for mining

**Example session**
```
Quasareum miner started...
Checked 100000 hashes, speed = 1000.0 h/s
addr 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
New address set: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
solutions
Last solutions:
  AbC123xy -> 992199
```

---

### 🔹 Python Miner

#### Windows PowerShell

```powershell
git clone https://github.com/quasareum-token/quasareum-main.git
cd quasareum-main\miners\quasareum_python

python -m venv .venv
.\.venv\Scripts\Activate.ps1

python .\miner.py 0xYourEthereumAddressHere
```

#### macOS / Linux

```bash
git clone https://github.com/quasareum-token/quasareum-main.git
cd quasareum-main/miners/quasareum_python

python3 -m venv .venv
source .venv/bin/activate

python3 miner.py 0xYourEthereumAddressHere
```

**Output**
- Every 100,000 attempts, the miner prints current hashrate (h/s).
- When a solution is found, it appends a line to `solutions.txt` like:  
  `YYYY-MM-DD HH:MM:SS | address=0x... | solution=AbC123xy | hash=992199`

---

## Average Hashrates (reference)

| Device  | Approx. hashrate |
|--------|-------------------|
| PC     | ~50,000+ h/s      |
| ESP32  | ~20,000 h/s       |
| ESP8266| ~11,000 h/s       |
| Arduino| ~1,000 h/s        |

---
