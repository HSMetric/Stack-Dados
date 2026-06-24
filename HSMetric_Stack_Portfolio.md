# HSMetric Stack
## Case técnico premium - plataforma self-hosted de dados, automação, BI e desenvolvimento

**Versão:** 1.1  
**Janela de referência:** março de 2026  
**Implantação-base:** Debian 13  
**Compatibilidade validada:** Debian, Ubuntu e openSUSE Leap 15  

> Uma plataforma modular, orientada a perfis, construída em Docker Compose para unificar automação, analytics, business intelligence, object storage, notebooks, desenvolvimento remoto e operação de infraestrutura sob uma única arquitetura self-hosted.

---

## 1. Resumo executivo

A HSMetric Stack foi concebida como uma plataforma unificada para projetos de automação, dados e analytics, com foco em três resultados práticos: **controle da infraestrutura**, **padronização operacional** e **velocidade de entrega**.

Em vez de manter ferramentas isoladas, a solução integra em uma única base:

- entrada segura por reverse proxy e TLS;
- automação de fluxos, integrações e webhooks;
- banco relacional e fila assíncrona;
- object storage compatível com S3;
- notebooks e processamento distribuído;
- business intelligence self-service;
- desenvolvimento remoto em navegador;
- operação e administração visual do ambiente.

O resultado é um ambiente que serve ao mesmo tempo como **plataforma real de trabalho**, **laboratório de evolução** e **case técnico de portfólio**.

---

## 2. O problema que o projeto resolve

Ambientes modernos de dados e automação costumam sofrer com quatro problemas recorrentes:

1. ferramentas dispersas e sem padrão de operação;
2. dependência excessiva de serviços externos para funções centrais;
3. dificuldade de documentar, manter e evoluir o ambiente;
4. baixa reprodutibilidade entre laboratório, prova de conceito e operação real.

A HSMetric Stack responde a isso com uma abordagem modular em Docker Compose, organizada por perfis e redes separadas, permitindo ligar apenas o que faz sentido em cada fase do projeto.

---

## 3. Visão da arquitetura

### 3.1 Princípios adotados

- **Self-hosted por padrão:** maior controle sobre dados, integrações e operação.
- **Publicação centralizada:** somente o Traefik expõe serviços publicamente.
- **Separação lógica de tráfego:** rede `proxy` para entrada e `internal` para comunicação interna.
- **Perfis do Compose:** ativação modular conforme o contexto.
- **Persistência por serviço:** cada componente mantém seu volume dedicado.
- **Escalabilidade gradual:** a base serve tanto para laboratório quanto para expansão controlada.

### 3.2 Arquitetura em camadas

**Camada de entrada**  
Traefik publica HTTP/HTTPS, emite certificados e roteia aplicações por subdomínio.

**Camada core**  
PostgreSQL, Redis, n8n e n8n-worker sustentam automação, persistência e execução assíncrona.

**Camada data**  
MinIO, Jupyter e Spark viabilizam armazenamento de objetos, análise exploratória e processamento distribuído.

**Camada BI e desenvolvimento**  
Metabase e code-server adicionam leitura analítica e desenvolvimento remoto.

**Camada operacional**  
pgAdmin e Portainer apoiam administração, troubleshooting e governança da plataforma.

---

## 4. Perfis da plataforma

| Perfil | Serviços | Propósito |
|---|---|---|
| Core (base) | traefik, postgres, redis, n8n, n8n-worker | Fundação da plataforma |
| apps | pgadmin | Administração de banco |
| ops | portainer | Operação e gestão Docker |
| data | minio, jupyter, spark-master, spark-worker | Camada de dados e processamento |
| bi | metabase | Business intelligence |
| lab | code-server | Desenvolvimento remoto |

Essa organização permite que a stack seja executada de forma enxuta ou completa, conforme a necessidade operacional.

---

## 5. Catálogo das aplicações e racional da escolha

| Aplicação | O que faz | Por que está no stack |
|---|---|---|
| Traefik | Reverse proxy e orquestração de rotas | Centraliza publicação segura, TLS e exposição por domínio |
| PostgreSQL | Banco relacional | Sustenta persistência confiável para aplicações da plataforma |
| Redis | Fila/cache | Habilita execução assíncrona e desacoplada no n8n |
| n8n | Orquestração de workflows | Automatiza integrações, webhooks, rotinas operacionais e fluxos com IA |
| n8n-worker | Executor assíncrono | Amplia resiliência e separa editor da carga de execução |
| pgAdmin | Administração visual de banco | Facilita manutenção e troubleshooting do PostgreSQL |
| Portainer | Administração visual de containers | Simplifica inspeção, operação e gestão da stack Docker |
| MinIO | Object storage compatível com S3 | Suporta buckets, artefatos, datasets e integrações modernas |
| Jupyter | Ambiente de notebooks | Permite exploração, prototipação e análise iterativa |
| Spark Master | Coordenação do cluster | Centraliza gestão do cluster Spark |
| Spark Worker | Processamento distribuído | Executa cargas de processamento e amplia poder computacional |
| Metabase | Plataforma de BI | Entrega dashboards e consultas self-service |
| code-server | VS Code no navegador | Leva desenvolvimento remoto para dentro da própria plataforma |

---

## 6. Redes, portas e domínios

### 6.1 Redes Docker

- **proxy** - tráfego publicado e resolvido pelo Traefik.
- **internal** - comunicação privada entre containers.

### 6.2 Domínios publicados

| Domínio | Serviço | Porta interna | Papel |
|---|---|---|---|
| traefik.hsmetric.ia.br | Traefik Dashboard | 8080 | Visão do proxy e roteamento |
| n8n.hsmetric.ia.br | n8n | 5678 | Editor e interface da automação |
| pgadmin.hsmetric.ia.br | pgAdmin | 80 | Administração PostgreSQL |
| portainer.hsmetric.ia.br | Portainer | 9000 | Gestão de containers |
| s3.hsmetric.ia.br | MinIO API | 9000 | Endpoint S3 |
| minio.hsmetric.ia.br | MinIO Console | 9001 | Console web do storage |
| jupyter.hsmetric.ia.br | JupyterLab | 8888 | Notebooks e exploração |
| spark.hsmetric.ia.br | Spark Master UI | 8080 | Interface do cluster |
| bi.hsmetric.ia.br | Metabase | 3000 | BI e dashboards |
| code.hsmetric.ia.br | code-server | 8080 | IDE web |

### 6.3 Portas internas estratégicas

| Serviço | Porta | Uso |
|---|---|---|
| PostgreSQL | 5432 | Persistência relacional |
| Redis | 6379 | Fila/cache |
| Spark Master | 7077 | RPC do cluster |
| Spark Worker | 8081 | UI local do worker |

---

## 7. Persistência e dados

| Volume local | Destino no container | Finalidade |
|---|---|---|
| `./volumes/traefik` | `/letsencrypt` | Certificados ACME e `acme.json` |
| `./volumes/postgres` | `/var/lib/postgresql/data` | Dados do PostgreSQL |
| `./initdb` | `/docker-entrypoint-initdb.d` | Bootstrap do banco |
| `./volumes/redis` | `/data` | Persistência do Redis |
| `./volumes/n8n` | `/home/node/.n8n` | Dados e configuração do n8n |
| `./workspace` | `/files`, `/workspace`, `/home/coder/project` | Área compartilhada de trabalho |
| `./volumes/pgadmin` | `/var/lib/pgadmin` | Estado do pgAdmin |
| `./volumes/portainer` | `/data` | Persistência do Portainer |
| `./volumes/minio` | `/data` | Buckets e objetos |
| `./volumes/jupyter` | `/home/jovyan/work` | Notebooks e artefatos |
| `./volumes/spark` | `/opt/spark/work-dir` | Workdir do Spark |
| `./volumes/metabase` | `/metabase-data` | Dados internos do Metabase |
| `./volumes/code-server` | `/home/coder/.local/share/code-server` | Configuração do editor |

A separação por volume foi adotada para favorecer backup, troubleshooting, restauração seletiva e evolução do ambiente com menor risco.

---

## 8. Variáveis críticas e política de segurança

Na documentação pública, os segredos devem permanecer redigidos. O portfólio usa exemplos seguros, sem exposição de senhas, tokens ou chaves reais.

Principais grupos críticos:

- credenciais de bootstrap e administração do PostgreSQL;
- chaves do n8n e senhas de integrações;
- senha do Redis;
- credenciais do MinIO;
- token do Jupyter;
- senha do code-server;
- `acme.json`, `.env` e hashes de autenticação do Traefik.

Exemplos adequados para publicação:

- `N8N_ENCRYPTION_KEY=<redacted_long_key>`
- `POSTGRES_SUPERPASSWORD=<redacted>`
- `MINIO_ROOT_PASSWORD=<redacted>`
- `CODE_SERVER_PASSWORD=<redacted>`

---

## 9. Rotina operacional oficial

### 9.1 Subida por perfil

```bash
docker compose up -d
docker compose --profile apps up -d
docker compose --profile ops up -d
docker compose --profile data up -d
docker compose --profile bi up -d
docker compose --profile lab up -d
```

### 9.2 Subida completa da plataforma

```bash
docker compose --profile lab --profile ops --profile apps --profile bi --profile data up -d
```

### 9.3 Atualização oficial completa da stack

```bash
docker compose --profile lab --profile ops --profile apps --profile bi --profile data pull && docker compose --profile lab --profile ops --profile apps --profile bi --profile data up -d && docker image prune -f
```

### 9.4 Conferência após atualização

```bash
docker compose --profile lab --profile ops --profile apps --profile bi --profile data ps
docker compose logs --tail=50
docker stats --no-stream
```

---

## 10. Comandos úteis de manutenção

```bash
docker compose ps
docker compose config
docker compose logs --tail=100 <servico>
docker compose restart <servico>
docker compose stop <servico>
docker compose start <servico>
docker compose up -d --force-recreate <servico>
docker compose exec <servico> sh
docker compose down
docker image prune -f
docker system df
docker inspect <container>
```

### 10.1 Backups recomendados

```bash
docker exec -t postgres pg_dump -U $POSTGRES_SUPERUSER $N8N_DB_NAME > backup_n8n.sql
docker exec -t postgres pg_dump -U $POSTGRES_SUPERUSER $METABASE_DB_NAME > backup_metabase.sql
tar czf backup_volumes_$(date +%F).tar.gz volumes workspace initdb
```

### 10.2 Restauração de referência

```bash
docker exec -i postgres psql -U $POSTGRES_SUPERUSER -d $N8N_DB_NAME < backup_n8n.sql
docker exec -i postgres psql -U $POSTGRES_SUPERUSER -d $METABASE_DB_NAME < backup_metabase.sql
tar xzf backup_volumes_YYYY-MM-DD.tar.gz
```

---

## 11. Problemas enfrentados e soluções adotadas

| Problema | Impacto | Solução aplicada |
|---|---|---|
| ACME falhando por NXDOMAIN | Domínio sem certificado | Ajuste prévio de DNS antes do challenge |
| `N8N_RELEASE_DATE` inválido | Inicialização inconsistente | Uso de timestamp ISO estático |
| `permission denied for schema public` no n8n | Banco indisponível para a aplicação | Banco dedicado com owner correto e privilégios explícitos |
| pgAdmin sem acesso a `/var/lib/pgadmin/sessions` | Falha de operação do serviço | Correção de permissões/ownership do volume |
| Flags inválidas no Portainer | Container não inicializava | Remoção de parâmetros incompatíveis com a versão |
| `bitnami/spark:3.5` inexistente | Falha de pull do profile data | Migração para `apache/spark:3.5.1-python3` |
| `mapping key environment already defined` | Compose inválido | Substituição limpa do bloco do serviço |
| `connection refused` do worker para o master | Cluster incompleto | Ajuste de inicialização do Spark e atraso controlado |
| MinIO retornando 404 no navegador | Interpretação incorreta do endpoint | Separação entre API S3 e console web |
| API S3 com 400/403 no navegador | Falso positivo de falha | Validação correta via console e cliente S3 |

Esse histórico é valioso porque transforma o projeto em um ativo de portfólio realista: não apenas um ambiente montado, mas um stack efetivamente depurado, corrigido e estabilizado.

---

## 12. Os três pilares operacionais do projeto

### 12.1 Sanidade

Após qualquer mudança relevante, devem ser conferidos:

- status dos serviços;
- consumo básico de recursos;
- logs recentes;
- validade do `docker compose config`.

### 12.2 Backup

Itens críticos a proteger:

- volumes persistentes;
- `.env`;
- `docker-compose.yml`;
- `acme.json`;
- dumps do PostgreSQL.

### 12.3 Segurança

Medidas permanentes:

- trocar credenciais padrão;
- manter apenas o Traefik exposto publicamente;
- não publicar PostgreSQL, Redis ou Spark RPC;
- tratar segredos e tokens como artefatos sensíveis;
- planejar atualizações com possibilidade de rollback.

---

## 13. Por que este projeto é forte como portfólio

A HSMetric Stack demonstra competências que vão além da simples subida de containers. Ela evidencia:

- desenho de arquitetura modular;
- domínio de Docker Compose com perfis;
- reverse proxy e publicação HTTPS com Traefik;
- integração entre automação, dados, BI e desenvolvimento;
- troubleshooting real de permissões, imagens, DNS e roteamento;
- preocupação com persistência, backup, segurança e operação;
- capacidade de transformar ambiente técnico em ativo apresentável.

Em portfólio, isso posiciona o projeto não apenas como laboratório, mas como **plataforma pronta para evoluir em direção a uso profissional, consultivo e comercial**.

---

## 14. Evoluções naturais do stack

Próximos passos possíveis:

- observabilidade com Prometheus, Grafana e Loki;
- rotinas automatizadas de backup e restore testado;
- CI/CD para versionamento e promoção de mudanças;
- endurecimento adicional de acesso e políticas;
- expansão do Spark e workloads mais pesados;
- integração com pipelines de dados e IA mais avançados.

---

## 15. Conclusão

A HSMetric Stack consolida uma arquitetura self-hosted moderna, modular e reutilizável, com capacidade de atender cenários de automação, dados, analytics, BI e desenvolvimento remoto em uma mesma fundação técnica.

Mais do que um stack funcional, o projeto se tornou um **case de engenharia aplicada**, unindo desenho arquitetural, troubleshooting, documentação, segurança operacional e potencial de expansão.

**Em uma frase:** é uma base técnica robusta o bastante para operar, clara o bastante para manter e apresentável o bastante para vender.
