# scrape_rewe_manual_step.py
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from bs4 import BeautifulSoup
import requests, json, re, pandas as pd, time, os

# === Einstellungen ===
PLZ = "50668"
OUTPUT = "rewe_obst_gemuese_komplett.xlsx"
CHROMEDRIVER_PATH = r"C:\plantyrecipes\chromedriver\chromedriver.exe"  # anpassen

# === Browser starten (sichtbar) ===
options = Options()
# options.add_argument("--headless")  # deaktiviert, damit du siehst was passiert
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

service = Service(CHROMEDRIVER_PATH)
driver = webdriver.Chrome(service=service, options=options)

def accept_cookies_and_set_plz():
    time.sleep(2)
    try:
        buttons = driver.find_elements(By.TAG_NAME, "button")
        for b in buttons:
            txt = (b.text or "").strip()
            if any(x in txt for x in ["Zustimmen", "Akzeptieren", "Alle akzeptieren"]):
                b.click()
                time.sleep(2)
                break
    except:
        pass
    try:
        inp = driver.find_element(By.XPATH, "//input[@name='zipCode' or @placeholder='PLZ']")
        inp.clear()
        inp.send_keys(PLZ)
        btns = driver.find_elements(By.TAG_NAME, "button")
        for b in btns:
            txt = (b.text or "").strip()
            if any(x in txt for x in ["Bestätigen", "Speichern"]):
                b.click()
                time.sleep(3)
                break
    except:
        pass

def wait_for_human_for_page(page):
    print(f"\n=== Seite {page} ===")
    print("Der Browser ist offen.")
    print("Löse bitte die Menschprüfung (Captcha, Cookies, PLZ) manuell, bis Produkte sichtbar sind.")
    input("Wenn du die Produkte siehst, drücke ENTER hier im Terminal...")

def scroll_page_slowly():
    for _ in range(10):
        driver.execute_script("window.scrollBy(0, document.body.scrollHeight/6);")
        time.sleep(1.5)
    time.sleep(2)

def collect_links_from_category_pages():
    links = []
    for page in range(1, 10):
        url = f"https://www.rewe.de/shop/c/obst-gemuese/?page={page}"
        driver.get(url)
        time.sleep(5)
        accept_cookies_and_set_plz()
        wait_for_human_for_page(page)
        scroll_page_slowly()
        soup = BeautifulSoup(driver.page_source, "html.parser")
        anchors = soup.select("a[href^='/shop/p/']")
        for a in anchors:
            href = a.get("href")
            if not href:
                continue
            href = href.split("?")[0]
            full = "https://www.rewe.de" + href
            if full not in links:
                links.append(full)
        print(f"Seite {page}: {len(links)} Links bisher")
        time.sleep(2)
    return links

def parse_product_via_json(html_text):
    m = re.search(r'<script[^>]*id="(pdpr-propstore[^"]*)"[^>]*>(.*?)</script>', html_text, re.S)
    if not m:
        return None
    try:
        data = json.loads(m.group(2))
        p = data["productData"]
        attrs = {a["label"]: a["value"] for g in p["attributeGroups"] for a in g["attributes"]}
        return {
            "Name": p.get("productName"),
            "Preis (€)": p.get("pricing", {}).get("price", 0) / 100,
            "Einheit": p.get("pricing", {}).get("grammage"),
            "Klasse": attrs.get("Klasse"),
            "Ursprung": attrs.get("Ursprung") or attrs.get("Herkunft"),
        }
    except Exception:
        return None

def parse_product(url):
    try:
        r = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=15)
        if r.status_code == 200:
            parsed = parse_product_via_json(r.text)
            if parsed:
                parsed["URL"] = url
                return parsed
    except:
        pass
    # Fallback via Selenium
    driver.get(url)
    time.sleep(4)
    soup = BeautifulSoup(driver.page_source, "html.parser")
    name = soup.select_one("h1.pdpr-Title")
    price = soup.select_one("mark[itemprop='price']")
    unit = soup.select_one("div.rs-qa-price-base")
    name = name.get_text(strip=True) if name else None
    price = price.get_text(strip=True) if price else None
    unit = unit.get_text(strip=True) if unit else None
    return {"Name": name, "Preis (€)": price, "Einheit": unit, "Klasse": None, "Ursprung": None, "URL": url}

# === Ablauf ===
try:
    print("Starte Browser und öffne REWE-Kategorie...")
    driver.get("https://www.rewe.de/shop/c/obst-gemuese/?source=homepage-category")
    time.sleep(5)
    accept_cookies_and_set_plz()

    print("Bitte löse ggf. initiale Menschprüfung manuell.")
    input("Wenn du die Seite siehst, drücke ENTER...")

    links = collect_links_from_category_pages()
    print(f"Gesamt: {len(links)} Produktlinks gesammelt.\n")

    results = []
    for i, link in enumerate(links, 1):
        print(f"[{i}/{len(links)}] {link}")
        try:
            results.append(parse_product(link))
        except Exception as e:
            print("Fehler bei", link, ":", e)
        time.sleep(1.5)

    df = pd.DataFrame(results)
    os.makedirs(os.path.dirname(OUTPUT) or ".", exist_ok=True)
    df.to_excel(OUTPUT, index=False)
    print("\nExport abgeschlossen:", OUTPUT)

finally:
    driver.quit()


# python scrape_rewe.py
