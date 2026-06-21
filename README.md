# HSMetric Stack

**Plataforma self-hosted para automação, dados, BI e desenvolvimento**

[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-v2-blue.svg)](https://docs.docker.com/compose/)
[![Traefik](https://img.shields.io/badge/Traefik-v3.6-blue.svg)](https://traefik.io/)
[![n8n](https://img.shields.io/badge/n8n-v1.82-orange.svg)](https://n8n.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org/)

> Stack completo construída em Docker Compose para centralizar automação, dados, business intelligence, desenvolvimento remoto e operação de infraestrutura.

**Versão:** 1.0  
**Compatibilidade validada:** Debian 12+, Ubuntu 22.04+, openSUSE Leap 15+

---

## 📋 Sumário

- [Visão Executiva](#-visão-executiva)
- [Arquitetura](#-arquitetura)
- [Requisitos](#-requisitos)
- [Instalação Rápida](#-instalação-rápida)
- [Serviços e Profiles](#-serviços-e-profiles)
- [Configuração Detalhada](#-configuração-detalhada)
- [Operação e Gerenciamento](#-operação-e-gerenciamento)
- [Segurança](#-segurança)
- [Backup e Recuperação](#-backup-e-recuperação)
- [Troubleshooting](#-troubleshooting)
- [Expansão e Roadmap](#-expansão-e-roadmap)
- [Versionamento Git](#-versionamento-com-git)
- [Referências](#-referências)

---

## 🎯 Visão Executiva

A HSMetric Stack é uma plataforma modular, multi-serviço e orientada a perfis, desenhada para reunir em um único ambiente:

- ✅ **Camada de entrada segura** (Traefik com SSL automático)
- ✅ **Automação de workflows** (n8n com queue mode)
- ✅ **Banco de dados relacional** (PostgreSQL multi-database)
- ✅ **Cache e fila** (Redis)
- ✅ **Object storage** (MinIO S3-compatible)
- ✅ **Notebooks e experimentação** (Jupyter)
- ✅ **Processamento distribuído** (Apache Spark)
- ✅ **Business Intelligence** (Metabase)
- ✅ **Administração** (pgAdmin, Portainer)
- ✅ **Desenvolvimento remoto** (Code Server)

### Objetivos do Projeto

1. Concentrar operação de dados, automação e analytics em base própria e controlada
2. Padronizar deploy e manutenção com único `docker-compose.yml` e profiles opcionais
3. Publicar serviços apenas por HTTPS via Traefik, evitando exposição direta de portas
4. Manter separação lógica entre plano de entrada (`proxy`) e plano interno (`internal`)
5. Criar vitrine técnica utilizável tanto como ambiente real quanto como material de portfólio

---

## 🏗️ Arquitetura

### Visão Lógica em Camadas

```
┌─────────────────────────────────────────────────────────────┐
│  CAMADA DE ENTRADA (Rede: proxy)                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Traefik (80/443)                                   │    │
│  │  • Reverse Proxy                                    │    │
│  │  • SSL Automático (Let's Encrypt)                   │    │
│  │  • Roteamento por Subdomínio                        │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  CAMADA CORE (Redes: proxy + internal)                      │
│  ┌──────────────┐  ┌──────────┐  ┌─────────────────────┐    │
│  │ PostgreSQL   │  │  Redis   │  │  n8n + n8n-worker   │    │
│  │ (multi-db)   │  │ (queue)  │  │  (queue mode)       │    │
│  └──────────────┘  └──────────┘  └─────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  CAMADAS OPCIONAIS (Profiles)                               │
│                                                             │
│  [apps]  pgAdmin                                            │
│  [ops]   Portainer                                          │
│  [data]  MinIO + Jupyter + Spark (master/worker)            │
│  [bi]    Metabase                                           │
│  [lab]   Code Server                                        │
└─────────────────────────────────────────────────────────────┘
```

### Topologia de Redes

- **`proxy`**: Tráfego publicado e resolvido pelo Traefik
- **`internal`**: Comunicação privada entre serviços (PostgreSQL, Redis, etc.)

### Catálogo Completo de Serviços

| Serviço | Profile | Portas | Função | Por que existe |
|---------|---------|--------|--------|----------------|
| **Traefik** | Core | 80, 443 | Reverse proxy e SSL | Centraliza entrada segura, emite TLS, roteia por subdomínio |
| **PostgreSQL** | Core | 5432 (interno) | Banco relacional | Persistência de n8n e Metabase com bancos separados |
| **Redis** | Core | 6379 (interno) | Cache e fila | Suporte ao queue mode do n8n |
| **n8n** | Core | 5678 (interno) | Automação de workflows | Integrações, webhooks, IA, low-code |
| **n8n-worker** | Core | - | Execução assíncrona | Escala e separa execução do editor |
| **pgAdmin** | apps | 80 (interno) | Admin PostgreSQL | Operação visual do banco |
| **Portainer** | ops | 9000 (interno) | Admin Docker | Troubleshooting visual de containers |
| **MinIO** | data | 9000, 9001 (internos) | Object storage S3 | Camada de arquivos/objetos para dados |
| **Jupyter** | data | 8888 (interno) | Notebooks Python | Análises, protótipos, exploração técnica |
| **Spark Master** | data | 7077, 8080 (internos) | Coordenação Spark | Agenda e expõe UI do cluster |
| **Spark Worker** | data | 8081 (interno) | Execução distribuída | Processamento e expansão computacional |
| **Metabase** | bi | 3000 (interno) | Business Intelligence | Dashboards e consultas self-service |
| **Code Server** | lab | 8080 (interno) | VS Code Web | Desenvolvimento remoto centralizado |

---

## 📦 Requisitos

### Hardware Mínimo

- **CPU**: 2 vCPUs
- **RAM**: 4GB
- **Disco**: 40GB SSD

### Hardware Recomendado

- **CPU**: 4 vCPUs
- **RAM**: 8GB
- **Disco**: 100GB SSD

### Software

- Docker Engine 24.0+
- Docker Compose V2
- Sistema Operacional: Debian 12+, Ubuntu 22.04+, openSUSE Leap 15+

### Rede

- DNS configurado com registros A apontando para o IP do servidor
- Portas 80 e 443 liberadas no firewall
- Domínio ou subdomínios configurados

---

## 🚀 Instalação Rápida

### 1. Clone ou copie os arquivos

```bash
# Criar estrutura
mkdir -p /opt/hsmetric-stack
cd /opt/hsmetric-stack

# Fazer upload dos arquivos:
# - docker-compose.yml
# - .env.example
# - setup.sh
# - README.md
# - .gitignore
```

### 2. Configure credenciais

```bash
# Copiar template
cp .env.example .env

# Editar e substituir todos os <PLACEHOLDERS>
nano .env

# Verificar placeholders restantes
grep "<" .env
```

### 3. Execute o setup automatizado

```bash
# Tornar executável
chmod +x setup.sh

# Executar
./setup.sh
```

O script irá:
- ✅ Verificar pré-requisitos (Docker, Compose)
- ✅ Criar estrutura de diretórios
- ✅ Gerar script de inicialização do PostgreSQL
- ✅ Ajustar permissões
- ✅ Iniciar os serviços

### 4. Acompanhe os logs

```bash
# Logs gerais
docker compose logs -f

# Logs do Traefik (certificados SSL)
docker logs traefik -f

# Status dos containers
docker compose ps
```

---

## 🎮 Serviços e Profiles

### Profiles Disponíveis

| Profile | Comando | Serviços Ativados |
|---------|---------|-------------------|
| **Core** (padrão) | `docker compose up -d` | Traefik, PostgreSQL, Redis, n8n, n8n-worker |
| **apps** | `docker compose --profile apps up -d` | + pgAdmin |
| **ops** | `docker compose --profile ops up -d` | + Portainer |
| **data** | `docker compose --profile data up -d` | + MinIO, Jupyter, Spark |
| **bi** | `docker compose --profile bi up -d` | + Metabase |
| **lab** | `docker compose --profile lab up -d` | + Code Server |

### Combinando Profiles

```bash
# Ativar múltiplos profiles
docker compose --profile apps --profile bi --profile data up -d

# Ativar TUDO
docker compose --profile apps --profile ops --profile data --profile bi --profile lab up -d
```

### Domínios e Acessos

| URL | Serviço | Profile | Credenciais |
|-----|---------|---------|-------------|
| `https://traefik.<seu-dominio>` | Traefik Dashboard | Core | Basic Auth (ver `.env`) |
| `https://n8n.<seu-dominio>` | n8n Editor | Core | `N8N_BASIC_AUTH_USER` / `PASSWORD` |
| `https://pgadmin.<seu-dominio>` | pgAdmin | apps | `PGADMIN_EMAIL` / `PASSWORD` |
| `https://portainer.<seu-dominio>` | Portainer | ops | Criar admin no primeiro acesso |
| `https://minio.<seu-dominio>` | MinIO Console | data | `MINIO_ROOT_USER` / `PASSWORD` |
| `https://s3.<seu-dominio>` | MinIO API S3 | data | Endpoint para clientes S3 |
| `https://jupyter.<seu-dominio>` | JupyterLab | data | Token: `JUPYTER_TOKEN` |
| `https://spark.<seu-dominio>` | Spark Master UI | data | Sem autenticação |
| `https://bi.<seu-dominio>` | Metabase | bi | Criar conta no primeiro acesso |
| `https://code.<seu-dominio>` | Code Server | lab | `CODE_SERVER_PASSWORD` |

---

## ⚙️ Configuração Detalhada

### Estrutura de Diretórios

```
/opt/hsmetric-stack/
├── docker-compose.yml          # Definição dos serviços
├── .env                        # Variáveis de ambiente (SENSÍVEL!)
├── .env.example                # Template seguro para Git
├── .gitignore                  # Proteção de arquivos sensíveis
├── README.md                   # Este arquivo
├── setup.sh                    # Script de inicialização
├── initdb/                     # Scripts SQL de bootstrap
│   └── 01-create-databases.sh  # Criação de roles e databases
├── volumes/                    # Dados persistentes
│   ├── traefik/               # Certificados SSL (acme.json)
│   ├── postgres/              # Dados do PostgreSQL
│   ├── redis/                 # Dados do Redis (AOF)
│   ├── n8n/                   # Workflows e credenciais
│   ├── pgadmin/               # Config do pgAdmin
│   ├── portainer/             # Config do Portainer
│   ├── minio/                 # Buckets e objetos S3
│   ├── jupyter/               # Notebooks
│   ├── spark/                 # Workdir do Spark
│   ├── metabase/              # Dados internos do Metabase
│   └── code-server/           # Config do VS Code
└── workspace/                  # Área compartilhada entre serviços
```

### Persistência e Volumes

| Volume no Host | Destino no Container | Serviço | Papel |
|----------------|---------------------|---------|-------|
| `./volumes/traefik` | `/letsencrypt` | Traefik | Certificados ACME |
| `./volumes/postgres` | `/var/lib/postgresql/data` | PostgreSQL | Dados persistentes |
| `./initdb` | `/docker-entrypoint-initdb.d` | PostgreSQL | Scripts de bootstrap |
| `./volumes/redis` | `/data` | Redis | Persistência AOF |
| `./volumes/n8n` | `/home/node/.n8n` | n8n | Workflows e dados |
| `./workspace` | `/files`, `/workspace` | Vários | Área compartilhada |
| `./volumes/minio` | `/data` | MinIO | Buckets e objetos |
| `./volumes/jupyter` | `/home/jovyan/work` | Jupyter | Notebooks |
| `./volumes/spark` | `/opt/spark/work-dir` | Spark | Artefatos |
| `./volumes/metabase` | `/metabase-data` | Metabase | Dados internos |

### Lógica de Bootstrap do Banco

O script `initdb/01-create-databases.sh` executa no primeiro start do PostgreSQL:

1. **Cria roles** (usuários) se não existirem:
   - `n8n_user` com senha
   - `metabase_user` com senha

2. **Cria bancos** com owners dedicados:
   - `n8n` (owner: n8n_user)
   - `metabaseappdb` (owner: metabase_user)

3. **Concede privilégios** explícitos em cada base

**Vantagens:**
- ✅ Isolamento entre aplicações
- ✅ Menor acoplamento
- ✅ Segurança aprimorada
- ✅ Idempotente (pode executar múltiplas vezes)

---

## 🔧 Operação e Gerenciamento

### Rotina Operacional Oficial

#### Subida por Perfil

```bash
# Apenas Core (base mínima)
docker compose up -d

# Adicionar profile específico
docker compose --profile apps up -d
docker compose --profile ops up -d
docker compose --profile data up -d
docker compose --profile bi up -d
docker compose --profile lab up -d
```

#### Subida Completa da Plataforma

```bash
docker compose --profile lab --profile ops --profile apps --profile bi --profile data up -d
```

#### Atualização Oficial Completa da Stack

```bash
docker compose --profile lab --profile ops --profile apps --profile bi --profile data pull && \
docker compose --profile lab --profile ops --profile apps --profile bi --profile data up -d && \
docker image prune -f
```

#### Conferência Após Atualização

```bash
# Verificar status
docker compose --profile lab --profile ops --profile apps --profile bi --profile data ps

# Ver logs recentes
docker compose logs --tail=50

# Conferir recursos
docker stats --no-stream
```

### Comandos Básicos

```bash
# Ver status
docker compose ps

# Ver logs
docker compose logs -f [serviço]

# Parar tudo
docker compose down

# Iniciar tudo
docker compose up -d

# Reiniciar serviço específico
docker compose restart n8n

# Ver uso de recursos
docker stats

# Validar configuração sem executar
docker compose config
```

### Atualizar Versões

```bash
# 1. Editar versão no .env
nano .env
# Ex: N8N_VERSION=1.83.0

# 2. Pull da nova imagem
docker compose pull n8n

# 3. Recriar container
docker compose up -d --force-recreate n8n

# 4. Verificar logs
docker logs n8n -f
```

---

## 🔒 Segurança

### Checklist de Segurança

- [ ] **Senhas alteradas** - Todas as credenciais padrão foram trocadas
- [ ] **Firewall configurado** - Apenas portas 80, 443 e SSH abertas
- [ ] **.env protegido** - Arquivo fora do Git e com permissão 600
- [ ] **Backups configurados** - Rotina automática de backup
- [ ] **Certificados SSL válidos** - Let's Encrypt funcionando
- [ ] **N8N_ENCRYPTION_KEY fixo** - Nunca alterado após primeiro deploy
- [ ] **Portas internas isoladas** - PostgreSQL, Redis, Spark não expostos
- [ ] **Basic Auth no Traefik** - Dashboard protegido
- [ ] **Logs monitorados** - Sistema de alerta configurado

### Gerar Credenciais Seguras

```bash
# Chave de criptografia (33 chars base64)
openssl rand -base64 33 | tr -d '\n'

# Senha forte (48 chars hex)
openssl rand -hex 24

# Hash para Basic Auth do Traefik
printf 'SUA_SENHA' | openssl passwd -apr1 -stdin
# Resultado: usuario:$$apr1$$hash...
```

---

## 💾 Backup e Recuperação

### Script de Backup Completo

```bash
#!/bin/bash
# backup-hsmetric.sh

BACKUP_DIR="/backup/hsmetric/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "🔄 Iniciando backup HSMetric Stack..."

# 1. Backup dos volumes
echo "📦 Backing up volumes..."
tar -czf "$BACKUP_DIR/volumes.tar.gz" volumes/

# 2. Backup do workspace
echo "📁 Backing up workspace..."
tar -czf "$BACKUP_DIR/workspace.tar.gz" workspace/

# 3. Backup das configurações
echo "⚙️  Backing up configs..."
cp docker-compose.yml "$BACKUP_DIR/"
cp .env "$BACKUP_DIR/.env.backup"

# 4. Dump do PostgreSQL
echo "🗄️  Backing up PostgreSQL..."
docker compose exec -T postgres pg_dumpall -U postgres | gzip > "$BACKUP_DIR/postgres_dump.sql.gz"

echo "✅ Backup concluído: $BACKUP_DIR"
```

### Restaurar Backup

```bash
# 1. Parar serviços
docker compose down

# 2. Restaurar volumes
tar xzf backup_volumes_YYYYMMDD.tar.gz

# 3. Iniciar PostgreSQL
docker compose up -d postgres

# 4. Restaurar dump
zcat postgres_dump.sql.gz | docker compose exec -T postgres psql -U postgres

# 5. Iniciar todos os serviços
docker compose up -d
```

---

## 🔍 Troubleshooting

### Problemas Comuns Resolvidos

Durante o desenvolvimento da HSMetric Stack, os seguintes problemas foram identificados e resolvidos:

| Problema | Causa | Solução |
|----------|-------|---------|
| Certificado ACME falhando com NXDOMAIN | DNS não resolvia antes do challenge | Criar registro DNS antes de iniciar Traefik |
| n8n: invalid timestamp N8N_RELEASE_DATE | Substituição shell `$(date)` não avaliada | Fixar timestamp ISO-8601 estático |
| n8n: permission denied schema public | Usuário sem ownership correto | Criar banco dedicado com owner no script init |
| pgAdmin: permission denied em sessions | Volume sem permissões adequadas | Corrigir ownership/permissões do volume |
| Portainer: flags inválidas | Parâmetros incompatíveis com versão | Remover flags não suportadas |
| Spark: bitnami/spark not found | Tag não existia | Migrar para apache/spark oficial |
| Compose: mapping key duplicado | Merge manual incorreto | Substituir serviço inteiro |
| Spark worker: connection refused | Worker iniciava antes do master | Adicionar delay e parâmetros explícitos |
| MinIO: 404 no navegador | Console e API no mesmo endpoint | Separar subdomínios (API vs Console) |
| MinIO API: 400/403 | Comportamento esperado de endpoint S3 | Documentar e usar console para UI |

### Comandos de Diagnóstico

```bash
# Ver todos os containers e saúde
docker compose ps -a

# Logs de todos os serviços
docker compose logs -f

# Inspecionar rede
docker network inspect proxy
docker network inspect internal

# Ver uso de recursos
docker stats

# Verificar conectividade entre containers
docker compose exec n8n ping postgres
docker compose exec n8n ping redis
```

---

## 🚀 Expansão e Roadmap

### Possibilidades de Expansão

- **Observabilidade**: Prometheus + Grafana + Loki
- **Backup automatizado**: rclone/restic com retenção definida
- **CI/CD**: Pipelines para atualização controlada do Compose
- **Pipelines analíticos**: Integração Jupyter → Spark → MinIO → Metabase
- **SSO/IdP**: Keycloak para reduzir senhas locais
- **Políticas de bucket**: Usuários e chaves dedicadas no MinIO

---

## 🔄 Versionamento com Git

### Arquivos Seguros para Versionar

```bash
# Inicializar repositório
git init

# Adicionar arquivos seguros
git add docker-compose.yml .env.example .gitignore README.md setup.sh initdb/

# Commit
git commit -m "Initial HSMetric Stack setup"

# Push
git remote add origin https://github.com/seu-usuario/hsmetric-stack.git
git push -u origin main
```

### ⚠️ NUNCA Versione

- ❌ `.env` (senhas reais!)
- ❌ `volumes/` (dados do banco e certificados)
- ❌ `workspace/` (arquivos de trabalho)
- ❌ Backups (`.sql`, `.dump`)

---

## 📚 Referências

### Documentação Oficial

- [Docker Compose](https://docs.docker.com/compose/)
- [Traefik with Docker](https://doc.traefik.io/traefik/setup/docker/)
- [n8n Queue Mode](https://docs.n8n.io/hosting/scaling/queue-mode/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MinIO Console](https://docs.min.io/)
- [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/)
- [Apache Spark Standalone](https://spark.apache.org/docs/latest/spark-standalone.html)
- [Metabase Documentation](https://www.metabase.com/docs/latest/)

---

**Desenvolvido com ❤️ para automação, dados e BI**

*Última atualização: Março 2026*
