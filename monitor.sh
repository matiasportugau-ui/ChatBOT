#!/bin/bash#!/bin/bash



# Colores para output# Colores para output

GREEN='\033[0;32m'GREEN='\033[0;32m'

BLUE='\033[0;34m'BLUE='\033[0;34m'

YELLOW='\033[1;33m'YELLOW='\033[1;33m'

RED='\033[0;31m'RED='\033[0;31m'

NC='\033[0m' # No ColorNC='\033[0m' # No Color



echo -e "${BLUE}🔍 Monitor AUTO-ATC ChatBot${NC}"echo -e "${BLUE}🔍 Monitor AUTO-ATC ChatBot${NC}"

echo "=========================="echo "=========================="



# Verificar estado de contenedores# Verificar estado de contenedores

echo -e "\n${BLUE}📦 Estado de contenedores:${NC}"echo -e "\n${BLUE}📦 Estado de contenedores:${NC}"

docker-compose psdocker-compose ps



echo -e "\n${BLUE}💾 Uso de recursos:${NC}"echo -e "\n${BLUE}💾 Uso de recursos:${NC}"

docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"



echo -e "\n${BLUE}🔗 Verificando conectividad de servicios:${NC}"echo -e "\n${BLUE}🔗 Verificando conectividad de servicios:${NC}"



# Verificar Rasa# Verificar Rasa

if curl -s http://localhost:5005/status > /dev/null; thenif curl -s http://localhost:5005/status > /dev/null; then

    echo -e "${GREEN}✅ Rasa: OK${NC}"    echo -e "${GREEN}✅ Rasa: OK${NC}"

elseelse

    echo -e "${RED}❌ Rasa: Error${NC}"    echo -e "${RED}❌ Rasa: Error${NC}"

fifi



# Verificar n8n# Verificar n8n

if curl -s http://localhost:5678 > /dev/null; thenif curl -s http://localhost:5678 > /dev/null; then

    echo -e "${GREEN}✅ n8n: OK${NC}"    echo -e "${GREEN}✅ n8n: OK${NC}"

elseelse

    echo -e "${RED}❌ n8n: Error${NC}"    echo -e "${RED}❌ n8n: Error${NC}"

fifi



# Verificar Chatwoot# Verificar Chatwoot

if curl -s http://localhost:3000 > /dev/null; thenif curl -s http://localhost:3000 > /dev/null; then

    echo -e "${GREEN}✅ Chatwoot: OK${NC}"    echo -e "${GREEN}✅ Chatwoot: OK${NC}"

elseelse

    echo -e "${RED}❌ Chatwoot: Error${NC}"    echo -e "${RED}❌ Chatwoot: Error${NC}"

fifi



# Verificar Qdrant# Verificar Qdrant

if curl -s http://localhost:6333/collections > /dev/null; thenif curl -s http://localhost:6333/collections > /dev/null; then

    echo -e "${GREEN}✅ Qdrant: OK${NC}"    echo -e "${GREEN}✅ Qdrant: OK${NC}"

elseelse

    echo -e "${RED}❌ Qdrant: Error${NC}"    echo -e "${RED}❌ Qdrant: Error${NC}"

fifi



# Verificar PostgreSQL# Verificar PostgreSQL

if docker exec chatbot-postgres-1 pg_isready -U postgres > /dev/null 2>&1; thenif docker exec chatbot-postgres-1 pg_isready -U postgres > /dev/null 2>&1; then

    echo -e "${GREEN}✅ PostgreSQL: OK${NC}"    echo -e "${GREEN}✅ PostgreSQL: OK${NC}"

elseelse

    echo -e "${RED}❌ PostgreSQL: Error${NC}"    echo -e "${RED}❌ PostgreSQL: Error${NC}"

fifi



# Verificar Redis# Verificar Redis

if docker exec chatbot-redis-1 redis-cli ping > /dev/null 2>&1; thenif docker exec chatbot-redis-1 redis-cli ping > /dev/null 2>&1; then

    echo -e "${GREEN}✅ Redis: OK${NC}"    echo -e "${GREEN}✅ Redis: OK${NC}"

elseelse

    echo -e "${RED}❌ Redis: Error${NC}"    echo -e "${RED}❌ Redis: Error${NC}"

fifi



echo -e "\n${BLUE}📊 Logs recientes (últimas 5 líneas por servicio):${NC}"echo -e "\n${BLUE}📊 Logs recientes (últimas 5 líneas por servicio):${NC}"



echo -e "\n${YELLOW}--- Rasa ---${NC}"echo -e "\n${YELLOW}--- Rasa ---${NC}"

docker-compose logs --tail=5 rasa 2>/dev/null || echo "Rasa no está corriendo"docker-compose logs --tail=5 rasa 2>/dev/null || echo "Rasa no está corriendo"



echo -e "\n${YELLOW}--- n8n ---${NC}"echo -e "\n${YELLOW}--- n8n ---${NC}"

docker-compose logs --tail=5 n8n 2>/dev/null || echo "n8n no está corriendo"docker-compose logs --tail=5 n8n 2>/dev/null || echo "n8n no está corriendo"



echo -e "\n${YELLOW}--- Chatwoot ---${NC}"echo -e "\n${YELLOW}--- Chatwoot ---${NC}"

docker-compose logs --tail=5 chatwoot 2>/dev/null || echo "Chatwoot no está corriendo"docker-compose logs --tail=5 chatwoot 2>/dev/null || echo "Chatwoot no está corriendo"



echo -e "\n${YELLOW}--- Qdrant ---${NC}"echo -e "\n${YELLOW}--- Qdrant ---${NC}"

docker-compose logs --tail=5 qdrant 2>/dev/null || echo "Qdrant no está corriendo"docker-compose logs --tail=5 qdrant 2>/dev/null || echo "Qdrant no está corriendo"



echo -e "\n${BLUE}🏥 Health Check Endpoints:${NC}"echo -e "\n${BLUE}🏥 Health Check Endpoints:${NC}"

echo "- Rasa Status: http://localhost:5005/status"echo "- Rasa Status: http://localhost:5005/status"

echo "- Qdrant Collections: http://localhost:6333/collections"echo "- Qdrant Collections: http://localhost:6333/collections"

echo "- n8n Health: http://localhost:5678/healthz"echo "- n8n Health: http://localhost:5678/healthz"



echo -e "\n${BLUE}📈 Para ver logs en tiempo real:${NC}"echo -e "\n${BLUE}📈 Para ver logs en tiempo real:${NC}"

echo "docker-compose logs -f [servicio]"echo "docker-compose logs -f [servicio]"

echo ""echo ""

echo -e "${BLUE}🔄 Para reiniciar un servicio:${NC}"echo -e "${BLUE}🔄 Para reiniciar un servicio:${NC}"

echo "docker-compose restart [servicio]"echo "docker-compose restart [servicio]"
