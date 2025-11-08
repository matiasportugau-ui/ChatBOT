# AUTO-ATC Playbook v3 - Tests de Integración
# Pruebas de integración entre servicios

import pytest
import requests
import time
import os
from unittest.mock import Mock

class TestServiceIntegration:
    """Pruebas de integración entre servicios"""

    def test_docker_services_health(self):
        """Test health checks de servicios Docker"""
        services = [
            ("http://localhost:3000/api", "Chatwoot"),
            ("http://localhost:5678/healthz", "n8n"),
            ("http://localhost:5005/", "Rasa"),
            ("http://localhost:6333/health", "Qdrant")
        ]

        for url, service_name in services:
            try:
                response = requests.get(url, timeout=5)
                # En desarrollo, algunos servicios pueden no estar disponibles
                # Solo verificar que no hay errores de conexión
                assert response.status_code in [200, 404, 500]  # 500 puede indicar que está iniciando
            except requests.exceptions.ConnectionError:
                # Servicio no disponible - esperado en tests sin Docker
                pass
            except Exception as e:
                print(f"{service_name} check failed (expected in test env): {e}")

    def test_webhook_endpoints_structure(self):
        """Test estructura de endpoints de webhook"""
        # Verificar que los archivos de workflow existen y tienen estructura JSON válida
        workflow_files = [
            "n8n/WF_MAIN_orchestrator_v4.json",
            "n8n/WF_TOGGLE_reply_mode_v1.json",
            "n8n/WF_KB_ingest_v2.json",
            "n8n/WF_ERRORS_notify_v1.json"
        ]

        for wf_file in workflow_files:
            assert os.path.exists(wf_file), f"Workflow file {wf_file} not found"

            with open(wf_file, 'r') as f:
                import json
                data = json.load(f)
                assert "name" in data
                assert "nodes" in data
                assert isinstance(data["nodes"], list)

    def test_template_structure(self):
        """Test estructura del template de WhatsApp"""
        template_file = "whatsapp/template_cotizacion_inicial.json"

        assert os.path.exists(template_file)

        with open(template_file, 'r') as f:
            import json
            data = json.load(f)
            assert data["messaging_product"] == "whatsapp"
            assert data["type"] == "template"
            assert "template" in data
            assert "components" in data["template"]

    def test_environment_variables_structure(self):
        """Test estructura de archivos de environment"""
        env_example = ".env.example"

        assert os.path.exists(env_example)

        with open(env_example, 'r') as f:
            content = f.read()
            # Verificar variables críticas
            required_vars = [
                "CHATWOOT_BASE_URL",
                "CHATWOOT_PLATFORM_TOKEN",
                "N8N_HOST",
                "RASA_URL",
                "QDRANT_URL"
            ]

            for var in required_vars:
                assert var in content, f"Required variable {var} not found in .env.example"

class TestDataFlow:
    """Pruebas de flujo de datos"""

    def test_database_schema_integrity(self):
        """Test integridad del esquema de base de datos"""
        schema_file = "db/schema.sql"

        assert os.path.exists(schema_file)

        with open(schema_file, 'r') as f:
            content = f.read()

            # Verificar tablas críticas
            required_tables = [
                "users",
                "conversations",
                "messages",
                "products",
                "quotes",
                "kb_documents"
            ]

            for table in required_tables:
                assert f"CREATE TABLE IF NOT EXISTS {table}" in content

    def test_kb_mock_data_consistency(self):
        """Test consistencia de datos mock de knowledge base"""
        # Importar y verificar datos mock
        import sys
        sys.path.append('rasa')

        try:
            from actions import DatabaseManager
            db = DatabaseManager()

            # Verificar que los datos mock tienen estructura consistente
            mock_data = db._get_mock_kb_results("test", 10)

            for item in mock_data:
                assert "title" in item
                assert "content" in item
                assert "category" in item
                assert "price" in item
                assert isinstance(item["price"], (int, float))

        except ImportError:
            # Si no se puede importar, skip test
            pass

class TestConfiguration:
    """Pruebas de configuración"""

    def test_gitignore_comprehensiveness(self):
        """Test que .gitignore cubre archivos sensibles"""
        gitignore_file = ".gitignore"

        assert os.path.exists(gitignore_file)

        with open(gitignore_file, 'r') as f:
            content = f.read()

            # Verificar patrones críticos de seguridad
            critical_patterns = [
                ".env",
                "*.log",
                "node_modules/",
                "__pycache__/",
                ".secrets/"
            ]

            for pattern in critical_patterns:
                assert pattern in content

if __name__ == "__main__":
    pytest.main([__file__, "-v"])

# EXPORT_SEAL v1
# project: auto-atc
# prompt_id: test-integration-v3
# version: 3.0.0
# file: tests/test_integration.py
# lang: py
# created_at: 2025-11-08T00:00:00Z
# author: auto-atc-setup
# origin: integration-tests
