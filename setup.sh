#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# HSMetric Stack - Script de Inicialização
# ══════════════════════════════════════════════════════════════════════════════
# Prepara o ambiente e inicia os serviços corretamente
# ══════════════════════════════════════════════════════════════════════════════

set -e  # Para em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# ──────────────────────────────────────────────────────────────────────────────
# BANNER
# ──────────────────────────────────────────────────────────────────────────────

echo "═══════════════════════════════════════════════════════════════════════════"
echo "  HSMetric Stack - Inicialização"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# PRÉ-REQUISITOS
# ──────────────────────────────────────────────────────────────────────────────

log_info "Verificando pré-requisitos..."

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    log_error "Docker não encontrado! Instale o Docker primeiro."
    exit 1
fi
log_success "Docker encontrado: $(docker --version)"

# Verificar se Docker Compose está instalado
if ! command -v docker compose &> /dev/null; then
    log_error "Docker Compose V2 não encontrado! Instale primeiro."
    exit 1
fi
log_success "Docker Compose encontrado: $(docker compose version)"

# Verificar se arquivo .env existe
if [ ! -f .env ]; then
    log_error "Arquivo .env não encontrado!"
    log_warning "Copie o arquivo _env para .env e configure as variáveis."
    exit 1
fi
log_success "Arquivo .env encontrado"

echo ""

# ──────────────────────────────────────────────────────────────────────────────
# ESTRUTURA DE DIRETÓRIOS
# ──────────────────────────────────────────────────────────────────────────────

log_info "Criando estrutura de diretórios..."

# Diretórios principais
mkdir -p volumes/{traefik,postgres,redis,n8n,pgadmin,portainer,minio,jupyter,spark,metabase,code-server}
mkdir -p workspace
mkdir -p initdb

log_success "Diretórios criados"

# ──────────────────────────────────────────────────────────────────────────────
# PERMISSÕES
# ──────────────────────────────────────────────────────────────────────────────

log_info "Ajustando permissões..."

# Proteger arquivo .env
chmod 600 .env

# Volumes
chmod -R 755 volumes/

log_success "Permissões ajustadas"

echo ""

# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT DE INICIALIZAÇÃO DO BANCO
# ──────────────────────────────────────────────────────────────────────────────

log_info "Criando script de inicialização do PostgreSQL..."

cat > initdb/01-create-databases.sh << 'EOF'
#!/bin/sh
set -eu

echo "Criando roles (usuários) e bancos de dados..."

# Criar roles (usuários) se não existirem
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<SQL
DO
\$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${N8N_DB_USER}') THEN
      CREATE ROLE ${N8N_DB_USER} LOGIN PASSWORD '${N8N_DB_PASSWORD}';
   END IF;
END
\$\$;

DO
\$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${METABASE_DB_USER}') THEN
      CREATE ROLE ${METABASE_DB_USER} LOGIN PASSWORD '${METABASE_DB_PASSWORD}';
   END IF;
END
\$\$;
SQL

echo "Roles criados com sucesso!"

# Criar banco do n8n se não existir
echo "Criando banco ${N8N_DB_NAME}..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -tc "SELECT 1 FROM pg_database WHERE datname = '${N8N_DB_NAME}'" | grep -q 1 || \
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -c "CREATE DATABASE ${N8N_DB_NAME} OWNER ${N8N_DB_USER};"

# Criar banco do Metabase se não existir
echo "Criando banco ${METABASE_DB_NAME}..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -tc "SELECT 1 FROM pg_database WHERE datname = '${METABASE_DB_NAME}'" | grep -q 1 || \
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -c "CREATE DATABASE ${METABASE_DB_NAME} OWNER ${METABASE_DB_USER};"

# Garantir privilégios
echo "Garantindo privilégios..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<SQL
GRANT ALL PRIVILEGES ON DATABASE ${N8N_DB_NAME} TO ${N8N_DB_USER};
GRANT ALL PRIVILEGES ON DATABASE ${METABASE_DB_NAME} TO ${METABASE_DB_USER};
SQL

echo "Bancos de dados criados e configurados com sucesso!"
EOF

chmod +x initdb/01-create-databases.sh

log_success "Script de inicialização criado"

echo ""

# ──────────────────────────────────────────────────────────────────────────────
# VERIFICAR CONFIGURAÇÕES
# ──────────────────────────────────────────────────────────────────────────────

log_info "Verificando configurações do .env..."

# Carregar variáveis
source .env

# Verificar variáveis críticas
CRITICAL_VARS=(
    "TZ"
    "ACME_EMAIL"
    "N8N_HOST"
    "N8N_ENCRYPTION_KEY"
    "POSTGRES_SUPERUSER"
    "POSTGRES_SUPERPASSWORD"
    "REDIS_PASSWORD"
)

MISSING_VARS=0
for var in "${CRITICAL_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        log_error "Variável $var não está definida no .env"
        MISSING_VARS=$((MISSING_VARS + 1))
    fi
done

if [ $MISSING_VARS -gt 0 ]; then
    log_error "Corrija as variáveis faltantes no .env antes de continuar"
    exit 1
fi

log_success "Configurações verificadas"

# Avisos de segurança
echo ""
log_warning "═══ IMPORTANTE - SEGURANÇA ═══"
echo ""
log_warning "Antes de usar em PRODUÇÃO:"
echo "  1. Altere TODAS as senhas no arquivo .env"
echo "  2. Use senhas fortes e únicas"
echo "  3. NÃO commite o arquivo .env no Git"
echo "  4. Configure backups automáticos"
echo "  5. Configure firewall (apenas portas 80, 443, SSH)"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# PERGUNTA AO USUÁRIO
# ──────────────────────────────────────────────────────────────────────────────

echo ""
log_info "Profiles disponíveis:"
echo "  - Núcleo (sempre ativo): Traefik, n8n, PostgreSQL, Redis"
echo "  - apps: pgAdmin"
echo "  - ops: Portainer"
echo "  - data: MinIO, Jupyter, Spark"
echo "  - bi: Metabase"
echo "  - lab: Code Server"
echo ""

read -p "Deseja iniciar apenas o NÚCLEO agora? (S/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    log_info "Informe os profiles que deseja ativar (separados por espaço):"
    log_info "Ex: apps bi data"
    read -p "Profiles: " PROFILES
    
    if [ -n "$PROFILES" ]; then
        PROFILE_ARGS=""
        for p in $PROFILES; do
            PROFILE_ARGS="$PROFILE_ARGS --profile $p"
        done
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# INICIALIZAR SERVIÇOS
# ──────────────────────────────────────────────────────────────────────────────

echo ""
log_info "Iniciando serviços..."
echo ""

if [ -n "$PROFILE_ARGS" ]; then
    docker compose $PROFILE_ARGS up -d
else
    docker compose up -d
fi

echo ""
log_success "Serviços iniciados!"

# ──────────────────────────────────────────────────────────────────────────────
# STATUS
# ──────────────────────────────────────────────────────────────────────────────

echo ""
log_info "Status dos containers:"
echo ""
docker compose ps

# ──────────────────────────────────────────────────────────────────────────────
# PRÓXIMOS PASSOS
# ──────────────────────────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
log_success "Stack iniciado com sucesso!"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
log_info "Próximos passos:"
echo ""
echo "  1. Aguarde alguns minutos para os certificados SSL serem gerados"
echo "     $ docker logs traefik -f"
echo ""
echo "  2. Acesse seus serviços:"
echo "     - Traefik: https://${TRAEFIK_HOST}"
echo "     - n8n: https://${N8N_HOST}"
echo ""
echo "  3. Monitore os logs:"
echo "     $ docker compose logs -f"
echo ""
echo "  4. Ativar profiles adicionais:"
echo "     $ docker compose --profile apps up -d"
echo ""
echo "  5. Ver o README.md para mais comandos e troubleshooting"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
