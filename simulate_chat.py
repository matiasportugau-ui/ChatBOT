#!/usr/bin/env python3
"""
Interactive Chat Simulation Environment
Allows you to chat with the Rasa chatbot in a simulated environment
"""

import requests
import json
import sys
from datetime import datetime
from typing import Optional, Dict, List

class ChatSimulator:
    def __init__(self, rasa_url: str = "http://localhost:5005"):
        self.rasa_url = rasa_url
        self.sender_id = f"sim_user_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        self.conversation_history: List[Dict] = []
        
    def check_server(self) -> bool:
        """Check if Rasa server is running"""
        try:
            response = requests.get(f"{self.rasa_url}/status", timeout=5)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False
    
    def send_message(self, message: str) -> Optional[List[Dict]]:
        """Send a message to the chatbot"""
        url = f"{self.rasa_url}/webhooks/rest/webhook"
        payload = {
            "sender": self.sender_id,
            "message": message
        }
        
        try:
            response = requests.post(url, json=payload, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ Error sending message: {e}")
            return None
    
    def parse_intent(self, text: str) -> Optional[Dict]:
        """Parse intent and entities from text"""
        url = f"{self.rasa_url}/model/parse"
        payload = {"text": text}
        
        try:
            response = requests.post(url, json=payload, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ Error parsing intent: {e}")
            return None
    
    def get_conversation_tracker(self) -> Optional[Dict]:
        """Get current conversation tracker state"""
        url = f"{self.rasa_url}/conversations/{self.sender_id}/tracker"
        
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ Error getting tracker: {e}")
            return None
    
    def print_response(self, responses: List[Dict], intent_info: Optional[Dict] = None):
        """Print chatbot responses in a formatted way"""
        print("\n" + "="*60)
        print("🤖 CHATBOT:")
        print("="*60)
        
        if intent_info:
            print(f"📊 Intent: {intent_info.get('intent', {}).get('name', 'unknown')}")
            print(f"   Confidence: {intent_info.get('intent', {}).get('confidence', 0):.2%}")
            
            entities = intent_info.get('entities', [])
            if entities:
                print(f"📦 Entities:")
                for entity in entities:
                    print(f"   - {entity.get('entity')}: {entity.get('value')}")
        
        for response in responses:
            text = response.get('text', '')
            if text:
                print(f"\n💬 {text}")
        
        print("="*60 + "\n")
    
    def save_conversation(self, filename: Optional[str] = None):
        """Save conversation history to a file"""
        if not filename:
            filename = f"conversation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.conversation_history, f, indent=2, ensure_ascii=False)
        
        print(f"💾 Conversation saved to {filename}")
    
    def run_interactive(self):
        """Run interactive chat session"""
        print("\n" + "="*60)
        print("🚀 CHATBOT SIMULATION ENVIRONMENT")
        print("="*60)
        print(f"📡 Connecting to: {self.rasa_url}")
        print(f"👤 User ID: {self.sender_id}")
        print("="*60)
        
        # Check server
        if not self.check_server():
            print("\n❌ ERROR: Rasa server is not running!")
            print(f"   Please start the server first:")
            print(f"   rasa run --model models/ --enable-api --cors '*' --port 5005")
            return
        
        print("✅ Server is running!\n")
        print("💡 Commands:")
        print("   - Type your message to chat")
        print("   - Type '/parse <text>' to see intent/entity analysis")
        print("   - Type '/tracker' to see conversation state")
        print("   - Type '/save' to save conversation history")
        print("   - Type '/exit' or '/quit' to exit")
        print("\n" + "-"*60 + "\n")
        
        while True:
            try:
                user_input = input("👤 You: ").strip()
                
                if not user_input:
                    continue
                
                # Handle commands
                if user_input.lower() in ['/exit', '/quit', 'exit', 'quit']:
                    print("\n👋 Goodbye!")
                    break
                
                elif user_input.startswith('/parse '):
                    text = user_input[7:].strip()
                    intent_info = self.parse_intent(text)
                    if intent_info:
                        print("\n" + "="*60)
                        print("📊 INTENT ANALYSIS:")
                        print("="*60)
                        print(json.dumps(intent_info, indent=2, ensure_ascii=False))
                        print("="*60 + "\n")
                    continue
                
                elif user_input == '/tracker':
                    tracker = self.get_conversation_tracker()
                    if tracker:
                        print("\n" + "="*60)
                        print("📊 CONVERSATION TRACKER:")
                        print("="*60)
                        print(json.dumps(tracker, indent=2, ensure_ascii=False))
                        print("="*60 + "\n")
                    continue
                
                elif user_input == '/save':
                    self.save_conversation()
                    continue
                
                # Regular message
                intent_info = self.parse_intent(user_input)
                responses = self.send_message(user_input)
                
                if responses:
                    self.print_response(responses, intent_info)
                    
                    # Save to history
                    self.conversation_history.append({
                        "timestamp": datetime.now().isoformat(),
                        "user_message": user_input,
                        "intent": intent_info.get('intent', {}).get('name') if intent_info else None,
                        "entities": intent_info.get('entities', []) if intent_info else [],
                        "bot_responses": responses
                    })
                else:
                    print("❌ No response from chatbot\n")
            
            except KeyboardInterrupt:
                print("\n\n👋 Goodbye!")
                break
            except Exception as e:
                print(f"\n❌ Error: {e}\n")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Interactive Chat Simulation Environment')
    parser.add_argument('--url', default='http://localhost:5005',
                       help='Rasa server URL (default: http://localhost:5005)')
    parser.add_argument('--sender', default=None,
                       help='Custom sender ID (default: auto-generated)')
    
    args = parser.parse_args()
    
    simulator = ChatSimulator(rasa_url=args.url)
    if args.sender:
        simulator.sender_id = args.sender
    
    simulator.run_interactive()

if __name__ == "__main__":
    main()

