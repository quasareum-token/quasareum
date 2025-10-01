import random
import string
import time
import sys

def quasareum_hash(user_address: str, solution: str) -> int:
    if not user_address.startswith("0x") or len(user_address) != 42:
        raise ValueError("Ethereum address must be 0x-prefixed, 40 hex chars")

    addr_bytes = bytes.fromhex(user_address[2:])
    data = addr_bytes + solution.encode("utf-8")

    h = 0xcbf29ce484222325
    for b in data:
        h ^= b
        h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF

    h ^= len(data)
    h &= 0xFFFFFFFFFFFFFFFF

    h ^= (h >> 30) & 0xFFFFFFFFFFFFFFFF
    h = (h * 0xbf58476d1ce4e5b9) & 0xFFFFFFFFFFFFFFFF
    h ^= (h >> 27) & 0xFFFFFFFFFFFFFFFF
    h = (h * 0x94d049bb133111eb) & 0xFFFFFFFFFFFFFFFF
    h ^= (h >> 31) & 0xFFFFFFFFFFFFFFFF

    m = 1_000_000
    out = ((h * m) >> 64) + 1
    return int(out)

def random_solution(length=8):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 miner.py <Ethereum address>")
        sys.exit(1)

    addr = sys.argv[1].strip()
    target = 992199
    count = 0
    start = time.time()

    with open("solutions.txt", "a", encoding="utf-8") as f:
        while True:
            solution = random_solution()
            h = quasareum_hash(addr, solution)
            count += 1

            if h == target:
                ts = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
                record = f"{ts} | address={addr} | solution={solution} | hash={h}\n"
                f.write(record)
                f.flush()
                print("[FOUND]", record.strip())

            if count % 100000 == 0:
                elapsed = time.time() - start
                speed = count / elapsed
                print(f"Checked {count} hashes, speed = {speed:.2f} h/s")
