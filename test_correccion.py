#!/usr/bin/env python3
"""
Script de prueba para el sistema de corrección y base de conocimiento
"""

import requests
import json
import time

RASA_URL = "http://localhost:5005"

def test_message(sender_id, message):
    """Envía un mensaje a Rasa y muestra la respuesta"""
    print(f"\n{'='*60}")
    print(f"👤 Usuario: {message}")
    print(f"{'='*60}")
    
    response = requests.post(
        f"{RASA_URL}/webhooks/rest/webhook",
        json={"sender": sender_id, "message": message},
        headers={"Content-Type": "application/json"}
    )
    
    if response.ok:
        data = response.json()
        for msg in data:
            print(f"🤖 Bot: {msg.get('text', '')}")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")
    
    time.sleep(1)

def main():
    print("🧪 Probando Sistema de Corrección y Base de Conocimiento\n")
    
    sender_id = f"test_user_{int(time.time())}"
    
    # Test 1: Saludo
    test_message(sender_id, "hola")
    
    # Test 2: Corrección simple
    test_message(sender_id, "eso está mal")
    
    # Test 3: Corrección específica de precio
    test_message(sender_id, "el precio está mal, debería ser $100")
    
    # Test 4: Corrección de producto
    test_message(sender_id, "el producto se llama diferente, en realidad es Remera Premium")
    
    # Test 5: Buscar en conocimiento
    test_message(sender_id, "buscar en la base de conocimiento sobre precios")
    
    print(f"\n{'='*60}")
    print("✅ Pruebas completadas")
    print(f"{'='*60}\n")

if __name__ == "__main__":
    main()

