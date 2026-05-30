import urllib.request, json, time, os, logging

logging.basicConfig(
    filename=os.path.join(os.path.dirname(os.path.abspath(__file__)), "arb_worker.log"),
    level=logging.INFO,
    format="%(asctime)s %(message)s",
)
log = logging.getLogger("arb")

def fetch(symbol):
    url = f"https://api.binance.com/api/v3/ticker/price?symbol={symbol}"
    proxy = urllib.request.ProxyHandler({"https": "http://127.0.0.1:7890", "http": "http://127.0.0.1:7890"})
    opener = urllib.request.build_opener(proxy)
    r = opener.open(url, timeout=8)
    d = json.loads(r.read())
    return float(d["price"])

pairs = ["BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT"]
while True:
    for p in pairs:
        try:
            px = fetch(p)
            log.info(f"{p}: ${px}")
        except Exception as e:
            log.info(f"{p}: ERROR {e}")
    log.info("---")
