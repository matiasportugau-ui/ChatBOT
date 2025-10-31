import os, json, time, requests, psycopg2
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher

PG_DSN = os.getenv("PG_DSN","dbname=atcdb user=atc password=atc_pass host=postgres")

class ActionRegisterQuote(Action):
    def name(self):
        return "action_register_quote"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain):
        producto = tracker.get_slot("producto")
        sku = tracker.get_slot("sku")
        cantidad = tracker.get_slot("cantidad")
        sender = tracker.sender_id
        ts = int(time.time())

        conn = psycopg2.connect(PG_DSN); conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(
              "INSERT INTO interactions(conversation_id,resumen,productos,created_at) VALUES(%s,%s,%s,now())",
              (sender, f"Cotización {producto} x {cantidad}", json.dumps([{{"producto":producto,"sku":sku,"cantidad":cantidad}}]))
            )
        conn.close()

        if os.getenv("GOOGLE_SHEET_ID") and os.getenv("GOOGLE_API_KEY"):
            payload = {{"values": [[ts, sender, producto, sku, cantidad]]}}
            rng = "Cotizaciones!A1"
            url = f"https://sheets.googleapis.com/v4/spreadsheets/{{os.getenv('GOOGLE_SHEET_ID')}}/values/{{rng}}:append?valueInputOption=USER_ENTERED&key={{os.getenv('GOOGLE_API_KEY')}}"
            try:
                requests.post(url, json=payload, timeout=8)
            except Exception:
                pass

        dispatcher.utter_message("¡Listo! Registré tu solicitud de cotización.")
        return []

# EXPORT_SEAL v1
# project: auto-atc
# prompt_id: rasa-actions-v3
# version: 3.0.0
# file: rasa/actions.py
# lang: py
# created_at: 2025-10-31T00:10:55Z
# author: GPT-5 Thinking
# origin: rasa-impl
# body_sha256: 042a5186e559e23d70fa46dd6220c5a9caf6f55e65d34ebc829d9783d7ed1232
