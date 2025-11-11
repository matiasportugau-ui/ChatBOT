#!/usr/bin/env python3
"""
Training Interface for Chatbot
Allows you to add new training examples and retrain the model
"""

import yaml
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional

class ChatbotTrainer:
    def __init__(self, project_dir: str = "."):
        self.project_dir = Path(project_dir)
        self.nlu_file = self.project_dir / "data" / "nlu.yml"
        self.stories_file = self.project_dir / "data" / "stories.yml"
        self.rules_file = self.project_dir / "data" / "rules.yml"
        
    def load_nlu_data(self) -> Dict:
        """Load NLU training data"""
        if not self.nlu_file.exists():
            return {"version": "3.1", "nlu": []}
        
        with open(self.nlu_file, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f) or {"version": "3.1", "nlu": []}
    
    def save_nlu_data(self, data: Dict):
        """Save NLU training data"""
        self.nlu_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(self.nlu_file, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, allow_unicode=True, sort_keys=False, default_flow_style=False)
    
    def add_example(self, intent: str, example: str, entities: Optional[List[Dict]] = None):
        """Add a new training example to an intent"""
        data = self.load_nlu_data()
        
        # Find or create intent
        intent_found = False
        for item in data.get('nlu', []):
            if item.get('intent') == intent:
                # Add example to existing intent
                examples = item.get('examples', '')
                if entities:
                    # Format with entities: [text](entity)
                    formatted_example = example
                    for entity in entities:
                        entity_text = entity.get('text', '')
                        entity_name = entity.get('entity', '')
                        if entity_text in formatted_example:
                            formatted_example = formatted_example.replace(
                                entity_text, 
                                f"[{entity_text}]({entity_name})"
                            )
                    examples += f"\n    - {formatted_example}"
                else:
                    examples += f"\n    - {example}"
                
                item['examples'] = examples
                intent_found = True
                break
        
        if not intent_found:
            # Create new intent
            if 'nlu' not in data:
                data['nlu'] = []
            
            example_text = example
            if entities:
                formatted_example = example
                for entity in entities:
                    entity_text = entity.get('text', '')
                    entity_name = entity.get('entity', '')
                    if entity_text in formatted_example:
                        formatted_example = formatted_example.replace(
                            entity_text,
                            f"[{entity_text}]({entity_name})"
                        )
                example_text = f"    - {formatted_example}"
            else:
                example_text = f"    - {example}"
            
            data['nlu'].append({
                'intent': intent,
                'examples': example_text
            })
        
        self.save_nlu_data(data)
        print(f"✅ Added example to intent '{intent}'")
    
    def list_intents(self) -> List[str]:
        """List all available intents"""
        data = self.load_nlu_data()
        intents = []
        
        for item in data.get('nlu', []):
            if 'intent' in item:
                intent_name = item['intent']
                examples_count = item.get('examples', '').count('\n    -')
                intents.append((intent_name, examples_count))
        
        return intents
    
    def show_intent_examples(self, intent: str):
        """Show all examples for an intent"""
        data = self.load_nlu_data()
        
        for item in data.get('nlu', []):
            if item.get('intent') == intent:
                examples = item.get('examples', '')
                print(f"\n📝 Examples for '{intent}':")
                print("-" * 60)
                print(examples)
                print("-" * 60)
                return
        
        print(f"❌ Intent '{intent}' not found")
    
    def train_model(self, output_dir: Optional[str] = None):
        """Train the Rasa model"""
        if output_dir is None:
            output_dir = self.project_dir / "models"
        
        print("\n🚀 Training model...")
        print("=" * 60)
        
        try:
            cmd = [
                "rasa", "train",
                "--domain", str(self.project_dir / "domain.yml"),
                "--data", str(self.project_dir / "data"),
                "--config", str(self.project_dir / "config.yml"),
                "--out", str(output_dir),
                "--fixed-model-name", f"model_{datetime.now().strftime('%Y%m%d-%H%M%S')}"
            ]
            
            result = subprocess.run(cmd, cwd=self.project_dir, check=True, 
                                   capture_output=True, text=True)
            
            print(result.stdout)
            print("\n✅ Training completed successfully!")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"\n❌ Training failed:")
            print(e.stderr)
            return False
        except FileNotFoundError:
            print("\n❌ Error: 'rasa' command not found.")
            print("   Make sure Rasa is installed and activated in your virtual environment.")
            return False
    
    def interactive_add_example(self):
        """Interactive interface to add training examples"""
        print("\n" + "="*60)
        print("🎓 CHATBOT TRAINING INTERFACE")
        print("="*60)
        
        while True:
            print("\n📋 Available intents:")
            intents = self.list_intents()
            for i, (intent, count) in enumerate(intents, 1):
                print(f"   {i}. {intent} ({count} examples)")
            
            print("\n💡 Options:")
            print("   1. Add new example to existing intent")
            print("   2. Create new intent with example")
            print("   3. View examples for an intent")
            print("   4. Train model")
            print("   5. Exit")
            
            choice = input("\n👉 Choose an option (1-5): ").strip()
            
            if choice == '1':
                if not intents:
                    print("❌ No intents found. Create one first (option 2).")
                    continue
                
                print("\nSelect intent:")
                for i, (intent, _) in enumerate(intents, 1):
                    print(f"   {i}. {intent}")
                
                try:
                    idx = int(input("👉 Intent number: ")) - 1
                    if 0 <= idx < len(intents):
                        intent_name = intents[idx][0]
                        example = input("👉 Enter example text: ").strip()
                        
                        if example:
                            # Check for entities in format [text](entity)
                            entities = []
                            if '[' in example and '](' in example:
                                # Parse entities from example
                                import re
                                matches = re.findall(r'\[([^\]]+)\]\(([^\)]+)\)', example)
                                for text, entity_name in matches:
                                    entities.append({'text': text, 'entity': entity_name})
                            
                            self.add_example(intent_name, example, entities if entities else None)
                        else:
                            print("❌ Example text cannot be empty")
                    else:
                        print("❌ Invalid selection")
                except ValueError:
                    print("❌ Invalid input")
            
            elif choice == '2':
                intent_name = input("👉 Enter new intent name: ").strip()
                if not intent_name:
                    print("❌ Intent name cannot be empty")
                    continue
                
                example = input("👉 Enter example text: ").strip()
                if not example:
                    print("❌ Example text cannot be empty")
                    continue
                
                # Parse entities if present
                entities = []
                if '[' in example and '](' in example:
                    import re
                    matches = re.findall(r'\[([^\]]+)\]\(([^\)]+)\)', example)
                    for text, entity_name in matches:
                        entities.append({'text': text, 'entity': entity_name})
                
                self.add_example(intent_name, example, entities if entities else None)
            
            elif choice == '3':
                if not intents:
                    print("❌ No intents found.")
                    continue
                
                print("\nSelect intent to view:")
                for i, (intent, _) in enumerate(intents, 1):
                    print(f"   {i}. {intent}")
                
                try:
                    idx = int(input("👉 Intent number: ")) - 1
                    if 0 <= idx < len(intents):
                        self.show_intent_examples(intents[idx][0])
                    else:
                        print("❌ Invalid selection")
                except ValueError:
                    print("❌ Invalid input")
            
            elif choice == '4':
                confirm = input("\n⚠️  This will train a new model. Continue? (y/n): ").strip().lower()
                if confirm == 'y':
                    self.train_model()
                else:
                    print("❌ Training cancelled")
            
            elif choice == '5':
                print("\n👋 Goodbye!")
                break
            
            else:
                print("❌ Invalid option")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Chatbot Training Interface')
    parser.add_argument('--project-dir', default='.',
                       help='Project directory (default: current directory)')
    parser.add_argument('--train', action='store_true',
                       help='Train model directly without interactive mode')
    
    args = parser.parse_args()
    
    trainer = ChatbotTrainer(project_dir=args.project_dir)
    
    if args.train:
        trainer.train_model()
    else:
        trainer.interactive_add_example()

if __name__ == "__main__":
    main()

