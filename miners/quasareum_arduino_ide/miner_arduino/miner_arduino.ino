#include <Arduino.h>
#include <EEPROM.h>
#include <string.h>

bool hexCharToByte(char c, uint8_t &out) {
  if (c >= '0' && c <= '9') { out = c - '0'; return true; }
  if (c >= 'a' && c <= 'f') { out = c - 'a' + 10; return true; }
  if (c >= 'A' && c <= 'F') { out = c - 'A' + 10; return true; }
  return false;
}

bool parseEthereumAddress(const char* addrStr, uint8_t out[20]) {
  if (strlen(addrStr) != 42 || addrStr[0] != '0' || addrStr[1] != 'x') return false;
  for (int i = 0; i < 40; i += 2) {
    uint8_t hi, lo;
    if (!hexCharToByte(addrStr[2 + i], hi)) return false;
    if (!hexCharToByte(addrStr[2 + i + 1], lo)) return false;
    out[i / 2] = (hi << 4) | lo;
  }
  return true;
}

uint32_t quasareumHash(const uint8_t address[20], const char* input) {
  const uint64_t OFFSET = 0xcbf29ce484222325ULL;
  const uint64_t FNV_PRIME = 0x100000001b3ULL;
  const uint64_t MIX_A = 0xbf58476d1ce4e5b9ULL;
  const uint64_t MIX_B = 0x94d049bb133111ebULL;
  uint64_t h = OFFSET;
  for (int i = 0; i < 20; i++) {
    h ^= (uint64_t)address[i];
    h *= FNV_PRIME;
  }
  for (int i = 0; input[i] != '\0'; i++) {
    h ^= (uint64_t)(uint8_t)input[i];
    h *= FNV_PRIME;
  }
  int total_len = 20 + strlen(input);
  h ^= (uint64_t)total_len;
  h ^= (h >> 30);
  h *= MIX_A;
  h ^= (h >> 27);
  h *= MIX_B;
  h ^= (h >> 31);
  const uint64_t M = 1000000ULL;
  uint64_t hi = M >> 32;
  uint64_t lo = M & 0xFFFFFFFFULL;
  uint64_t h_hi = h >> 32;
  uint64_t h_lo = h & 0xFFFFFFFFULL;
  uint64_t part1 = h_hi * hi;
  uint64_t part2 = (h_hi * lo) >> 32;
  uint64_t part3 = (h_lo * hi) >> 32;
  uint64_t reduced = part1 + part2 + part3 + 1;
  return (uint32_t)reduced;
}

char charset[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
int charsetLen = sizeof(charset) - 1;

String randomSolution(int length) {
  String s = "";
  for (int i = 0; i < length; i++) {
    s += charset[random(charsetLen)];
  }
  return s;
}

struct Solution {
  char text[9];
  uint32_t hash;
};

const int MAX_SOLUTIONS = 20;
Solution foundSolutions[MAX_SOLUTIONS];
int solutionIndex = 0;
int solutionCount = 0;

void loadSolutions() {
  EEPROM.get(0, foundSolutions);
  EEPROM.get(sizeof(foundSolutions), solutionIndex);
  EEPROM.get(sizeof(foundSolutions) + sizeof(solutionIndex), solutionCount);
  if (solutionIndex < 0 || solutionIndex >= MAX_SOLUTIONS) solutionIndex = 0;
  if (solutionCount < 0 || solutionCount > MAX_SOLUTIONS) solutionCount = 0;
}

void saveSolutions() {
  EEPROM.put(0, foundSolutions);
  EEPROM.put(sizeof(foundSolutions), solutionIndex);
  EEPROM.put(sizeof(foundSolutions) + sizeof(solutionIndex), solutionCount);
}

void addSolution(const String &sol, uint32_t h) {
  memset(foundSolutions[solutionIndex].text, 0, 9);
  sol.substring(0, 8).toCharArray(foundSolutions[solutionIndex].text, 9);
  foundSolutions[solutionIndex].hash = h;
  solutionIndex = (solutionIndex + 1) % MAX_SOLUTIONS;
  if (solutionCount < MAX_SOLUTIONS) solutionCount++;
  saveSolutions();
}

void printSolutions() {
  Serial.println("Last solutions:");
  for (int i = 0; i < solutionCount; i++) {
    int idx = (solutionIndex - 1 - i + MAX_SOLUTIONS) % MAX_SOLUTIONS;
    Serial.print("  ");
    Serial.print(foundSolutions[idx].text);
    Serial.print(" -> ");
    Serial.println(foundSolutions[idx].hash);
  }
}

char addrStr[43] = "0x0000000000000000000000000000000000000000";
uint8_t addr[20];
const uint32_t target = 992199;
unsigned long count = 0;
unsigned long startTime;

void setup() {
  Serial.begin(115200);
  loadSolutions();
  if (!parseEthereumAddress(addrStr, addr)) {
    Serial.println("Invalid Ethereum address!");
    while (true);
  }
  Serial.println("Quasareum miner started...");
  startTime = millis();
}

void loop() {
  String sol = randomSolution(8);
  uint32_t h = quasareumHash(addr, sol.c_str());
  count++;
  if (h == target) {
    Serial.print("[FOUND] Solution=");
    Serial.print(sol);
    Serial.print(" -> ");
    Serial.println(h);
    addSolution(sol, h);
  }
  
  if (count % 5000 == 0) {
    unsigned long elapsed = millis() - startTime;
    float speed = (count * 1000.0) / elapsed;
    Serial.print("Checked ");
    Serial.print(count);
    Serial.print(" hashes, speed = ");
    Serial.print(speed);
    Serial.println(" h/s");
  }

  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();

    if (cmd == "solutions") {
      printSolutions();
    } else if (cmd == "rate") {
      unsigned long elapsed = millis() - startTime;
      float speed = (count * 1000.0) / elapsed;
      Serial.print("Current hashrate: ");
      Serial.print(speed);
      Serial.println(" h/s");
    } else if (cmd == "clear") {
      for (int i = 0; i < EEPROM.length(); i++) {
        EEPROM.write(i, 0xFF);
      }
      solutionIndex = 0;
      solutionCount = 0;
      Serial.println("EEPROM cleared, solutions reset!");
    } else if (cmd.startsWith("addr ")) {
      String newAddr = cmd.substring(5);
      newAddr.trim();
      if (parseEthereumAddress(newAddr.c_str(), addr)) {
        newAddr.toCharArray(addrStr, sizeof(addrStr));
        Serial.print("New address set: ");
        Serial.println(newAddr);
        count = 0;
        startTime = millis();
      } else {
        Serial.println("Invalid Ethereum address!");
      }
    }
  }
}
