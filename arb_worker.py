import urllib.request, json, time, os

def fetch(symbol):
    url = f"https://api.binance.com/api/v3/ticker/price?symbol={symbol}"
    proxy = urllib.request.ProxyHandler({"https": "http://127.0.0.1:7890", "http": "http://127.0.0.1:7890"})
    opener = urllib.request.build_opener(proxy)
    r = opener.open(url, timeout=8)
    d = json.loads(r.read())
    return float(d["price"])

pairs = ["BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT"]
logf = open(os.path.dirname(os.path.abspath(__file__)) + "/arb.log", "a")
while True:
    for p in pairs:
        try:
            px = fetch(p)
            logf.write(f"{p}: ${px}\n")
        except Exception as e:
            logf.write(f"{p}: ERROR {e}\n")
    logf.write("---\n")
    logf.flush()
    time.sleep(5)
