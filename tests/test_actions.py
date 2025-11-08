# AUTO-ATC Playbook v3 - Tests para Actions de Rasa
# Pruebas unitarias para validar funcionalidad de actions.py

import pytest
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'rasa'))

from actions import DatabaseManager
from unittest.mock import Mock, patch

class TestDatabaseManager:
    """Pruebas para DatabaseManager"""

    def setup_method(self):
        """Configurar entorno de prueba"""
        self.db = DatabaseManager()

    def test_validate_input_valid_text(self):
        """Test validación de texto válido"""
        assert self.db.validate_input("Laptop Dell", "text") == True

    def test_validate_input_empty_text(self):
        """Test validación de texto vacío"""
        assert self.db.validate_input("", "text") == False
        assert self.db.validate_input("   ", "text") == False

    def test_validate_input_malicious_text(self):
        """Test validación de texto con caracteres maliciosos"""
        assert self.db.validate_input("<script>alert('xss')</script>", "text") == False

    def test_validate_input_valid_email(self):
        """Test validación de email válido"""
        assert self.db.validate_input("test@example.com", "email") == True
        assert self.db.validate_input("user.name+tag@domain.co.uk", "email") == True

    def test_validate_input_invalid_email(self):
        """Test validación de email inválido"""
        assert self.db.validate_input("invalid-email", "email") == False
        assert self.db.validate_input("@domain.com", "email") == False

    def test_validate_input_valid_phone(self):
        """Test validación de teléfono válido"""
        assert self.db.validate_input("+59899123456", "phone") == True
        assert self.db.validate_input("099123456", "phone") == True

    def test_validate_input_invalid_phone(self):
        """Test validación de teléfono inválido"""
        assert self.db.validate_input("abc123", "phone") == False
        assert self.db.validate_input("123", "phone") == False

    def test_validate_input_valid_quantity(self):
        """Test validación de cantidad válida"""
        assert self.db.validate_input("5", "quantity") == True
        assert self.db.validate_input("100", "quantity") == True

    def test_validate_input_invalid_quantity(self):
        """Test validación de cantidad inválida"""
        assert self.db.validate_input("0", "quantity") == False
        assert self.db.validate_input("1001", "quantity") == False
        assert self.db.validate_input("abc", "quantity") == False

    @patch('qdrant_client.QdrantClient.collection_exists')
    def test_search_knowledge_base_mock(self, mock_exists):
        """Test búsqueda en knowledge base con datos mock"""
        mock_exists.return_value = False  # Simular que no existe colección

        results = self.db.search_knowledge_base("laptop")

        assert len(results) > 0
        assert "title" in results[0]
        assert "content" in results[0]

    def test_mock_kb_results_filtering(self):
        """Test filtrado de resultados mock"""
        results = self.db._get_mock_kb_results("laptop", 5)

        # Debería encontrar productos relacionados con "laptop"
        laptop_related = [r for r in results if "laptop" in r["title"].lower()]
        assert len(laptop_related) > 0

class TestActionValidation:
    """Pruebas para validaciones de actions"""

    def test_action_input_sanitization(self):
        """Test sanitización de inputs en actions"""
        db = DatabaseManager()

        # Test sanitización básica
        assert db.validate_input("  test input  ", "text") == True

        # Test longitud máxima
        long_input = "a" * 501
        assert db.validate_input(long_input, "text") == False

if __name__ == "__main__":
    pytest.main([__file__])

# EXPORT_SEAL v1
# project: auto-atc
# prompt_id: test-actions-v3
# version: 3.0.0
# file: tests/test_actions.py
# lang: py
# created_at: 2025-11-08T00:00:00Z
# author: auto-atc-setup
# origin: test-suite
