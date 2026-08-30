# PROJECT_CONTEXT.md

# Meus Recibos — Aplicativo Mobile Offline

## 1. Visão geral

Desenvolver um aplicativo mobile simples para Android destinado à criação, gerenciamento e geração de documentos profissionais em PDF.

O aplicativo deve funcionar 100% offline.

Não haverá:
- Backend
- API própria
- Login
- Cadastro de usuário
- Servidor
- Sincronização obrigatória
- Assinatura
- Planos
- Créditos
- Limite de documentos
- Dependência de internet

Todos os dados devem permanecer armazenados localmente no dispositivo.

O projeto será desenvolvido inicialmente para Android utilizando Flutter/Dart.

---

# 2. Stack

## Aplicação
- Flutter
- Dart

## Persistência
- SQLite
- sqflite

## Bibliotecas previstas
- sqflite
- path
- path_provider
- intl
- uuid
- image_picker
- pdf
- printing
- share_plus
- provider

Adicionar outras dependências somente quando houver necessidade clara.

---

# 3. Objetivo do MVP

O usuário deve conseguir:

1. Configurar o perfil da empresa/prestador.
2. Cadastrar/reutilizar clientes.
3. Criar recibos.
4. Criar orçamentos.
5. Criar comprovantes.
6. Adicionar múltiplos itens aos documentos.
7. Calcular valores automaticamente.
8. Aplicar desconto.
9. Visualizar o documento antes de salvar.
10. Gerar PDF localmente.
11. Salvar o documento.
12. Consultar documentos anteriores.
13. Compartilhar o PDF pelo compartilhamento nativo do Android.
14. Acompanhar informações básicas em um painel.
15. Fazer backup/restauração local futuramente.

---

# 4. Princípios do projeto

O aplicativo deve priorizar:

- Simplicidade
- Funcionamento offline
- Poucas dependências
- Código organizado
- Componentes reutilizáveis
- Interface mobile limpa
- Facilidade de manutenção
- Persistência confiável
- Boa experiência para preenchimento rápido

Evitar overengineering.

Não criar backend ou arquitetura distribuída.

---

# 5. Estrutura sugerida

lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── database/
│   │   └── app_database.dart
│   │
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   │
│   ├── utils/
│   │   ├── currency_utils.dart
│   │   └── date_utils.dart
│   │
│   └── widgets/
│       ├── app_button.dart
│       ├── app_input.dart
│       └── app_card.dart
│
├── models/
│   ├── profile.dart
│   ├── client.dart
│   ├── document.dart
│   └── document_item.dart
│
├── repositories/
│   ├── profile_repository.dart
│   ├── client_repository.dart
│   └── document_repository.dart
│
├── services/
│   ├── pdf_service.dart
│   ├── document_number_service.dart
│   └── backup_service.dart
│
└── screens/
    ├── home/
    ├── profiles/
    ├── clients/
    ├── receipt/
    ├── budget/
    ├── proof/
    ├── documents/
    └── dashboard/

A estrutura pode evoluir durante o desenvolvimento, mas deve continuar simples.

---

# 6. Home

A tela inicial deve possuir:

## Criar documento

Cards para:

### Recibo
Descrição:
"Pagamento recebido"

### Orçamento
Descrição:
"Proposta de serviço"

### Comprovante
Descrição:
"Serviço prestado"

Não implementar "Criar com IA" no MVP.

---

Também apresentar:

### Painel
Atalho para dashboard.

### Documentos recentes
Mostrar documentos criados recentemente.

Cada documento recente deve apresentar aproximadamente:

- Cliente
- Tipo
- Valor
- Status
- Abrir
- Alterar status, quando aplicável

---

# 7. Menu

Menu principal contendo inicialmente:

- Painel
- Meus Perfis
- Clientes
- Backup e restauração

Não implementar:

- Planos
- Créditos
- Compras
- Assinaturas

---

# 8. Perfil

O aplicativo deve permitir pelo menos um perfil.

Estrutura preparada para suportar múltiplos perfis.

Campos:

- Logo
- Nome / Razão Social
- Nome fantasia (opcional)
- Tipo de documento (CPF/CNPJ)
- CPF/CNPJ
- Tipo de serviço prestado
- Telefone / WhatsApp
- E-mail (opcional)
- Endereço (opcional)
- Cidade
- Estado
- Chave PIX (futuro)
- Tipo da chave PIX (futuro)
- Cor principal
- Perfil padrão

A cor selecionada poderá ser utilizada nos PDFs.

O logo deve ser armazenado localmente.

---

# 9. Clientes

Campos:

- id
- nome
- CPF/CNPJ
- endereço
- created_at
- updated_at

O usuário deve conseguir:

- visualizar clientes;
- pesquisar por nome;
- pesquisar por CPF/CNPJ;
- selecionar cliente ao criar documento.

Ao emitir um documento para um cliente ainda inexistente, o cliente poderá ser salvo automaticamente.

Evitar duplicação quando possível.

---

# 10. Tipos de documentos

Existem três tipos principais:

- Recibo
- Orçamento
- Comprovante

Utilizar uma estrutura comum para documentos sempre que possível, evitando duplicar código e tabelas desnecessariamente.

---

# 11. Recibo

Campos:

- Data do documento
- Vencimento opcional
- Cliente
- CPF/CNPJ
- Endereço
- Descrição do serviço
- Itens
- Desconto
- Forma de pagamento
- Observações
- Total

Itens possuem:

- Descrição
- Quantidade
- Unidade
- Valor unitário
- Total

Permitir adicionar/remover múltiplos itens.

O total deve ser calculado automaticamente.

Fluxo:

Novo Recibo
    ↓
Preencher dados
    ↓
Visualizar e Gerar
    ↓
Preview
    ↓
Editar OU Salvar
    ↓
Gerar PDF
    ↓
Salvar histórico

---

# 12. Orçamento

Campos:

- Data
- Validade opcional
- Cliente
- CPF/CNPJ
- Endereço
- Descrição do serviço
- Itens
- Desconto
- Forma de pagamento
- Observações
- Total

Status possíveis:

- Pendente
- Aprovado
- Pago
- Recusado

Fluxo:

Novo Orçamento
    ↓
Preencher
    ↓
Preview
    ↓
Salvar
    ↓
Pendente

O status poderá posteriormente ser alterado.

---

# 13. Conversão de orçamento

Uma funcionalidade importante:

Quando um orçamento for marcado como:

PAGO

perguntar:

"Gerar comprovante?"

Mensagem aproximada:

"O orçamento foi marcado como pago. Deseja emitir um comprovante de pagamento com os mesmos dados?"

Opções:

- Agora não
- Gerar comprovante

Ao gerar comprovante, copiar:

- cliente
- CPF/CNPJ
- endereço
- descrição
- itens
- quantidades
- valores
- desconto
- total
- forma de pagamento
- observações pertinentes

Não alterar o orçamento original.

Criar um novo documento do tipo COMPROVANTE.

---

# 14. Comprovante

Pode ser criado:

1. Diretamente pela Home.
2. A partir de um orçamento pago.

Campos semelhantes aos demais documentos.

Quando criado a partir de orçamento, registrar a relação entre os documentos.

Exemplo:

ORC-005/2026
    ↓
COMP-003/2026

---

# 15. Numeração

Cada tipo possui sequência independente.

Formato:

REC-001/2026
REC-002/2026

ORC-001/2026
ORC-002/2026

COMP-001/2026
COMP-002/2026

Ao trocar o ano, iniciar nova sequência:

REC-001/2027

Não utilizar simplesmente o ID da tabela como número público do documento.

Criar um DocumentNumberService responsável pela geração segura da numeração.

---

# 16. Modelo de dados inicial

## PROFILE

- id
- name
- trade_name
- document_type
- document_number
- service_type
- phone
- email
- address
- city
- state
- pix_key
- pix_type
- logo_path
- color
- is_default
- created_at
- updated_at

---

## CLIENT

- id
- name
- document
- address
- created_at
- updated_at

---

## DOCUMENT

- id
- number
- type
- profile_id
- client_id
- date
- due_date
- valid_until
- service_description
- payment_method
- notes
- subtotal
- discount
- total
- status
- source_document_id
- created_at
- updated_at

source_document_id deve permitir relacionar, por exemplo:

Comprovante → Orçamento original

---

## DOCUMENT_ITEM

- id
- document_id
- description
- quantity
- unit
- unit_price
- total

---

# 17. Valores monetários

IMPORTANTE:

Evitar erros de ponto flutuante em valores financeiros.

Preferencialmente armazenar valores monetários no SQLite como INTEGER representando centavos.

Exemplo:

R$ 95,00

deve ser armazenado como:

9500

A interface é responsável por converter/formartar para:

R$ 95,00

---

# 18. PDF

O PDF deve ser gerado totalmente offline.

Formato inicialmente:

A4.

Deve possuir aproximadamente:

- Logo
- Nome da empresa
- CPF/CNPJ
- Tipo do documento
- Número
- Data
- Dados do cliente
- Descrição
- Tabela de itens
- Quantidade
- Unidade
- Valor unitário
- Total por item
- Desconto, quando existente
- Valor total
- Forma de pagamento
- Observações
- Área de assinatura/identificação
- Informações da empresa

A cor principal do perfil deve influenciar a identidade visual do PDF.

Tipos terão cores padrão inicialmente:

- Recibo: azul
- Orçamento: roxo
- Comprovante: verde

Se o perfil possuir uma cor personalizada, ela poderá sobrescrever a padrão.

---

# 19. Preview

Antes de salvar definitivamente:

Visualizar e Gerar
    ↓
Preview PDF
    ↓
Editar | Salvar

Editar retorna ao formulário mantendo os dados.

Salvar:

- persiste documento;
- persiste itens;
- gera PDF;
- adiciona ao histórico.

---

# 20. Compartilhamento

Depois da geração:

- Abrir PDF
- Compartilhar
- Imprimir

Usar mecanismos nativos do Android.

O aplicativo em si continua offline.

WhatsApp/e-mail/etc. são responsabilidades do aplicativo escolhido pelo usuário no compartilhamento.

---

# 21. Dashboard

Criar painel utilizando somente dados do SQLite.

Mostrar inicialmente:

## Resumo do mês

- Faturado
- A receber
- Quantidade de documentos
- Clientes ativos

## Documentos por tipo

- Recibos
- Orçamentos
- Comprovantes

## Top clientes do ano

Exemplo:

1. Cliente A — R$ 1.250,00
2. Cliente B — R$ 950,00

Não é necessário implementar gráficos complexos inicialmente.

---

# 22. Backup

Funcionalidade posterior.

Objetivo:

Exportar os dados locais para backup e permitir restauração.

O backup deve considerar:

- banco SQLite;
- logos;
- arquivos necessários;
- eventualmente PDFs, dependendo da estratégia adotada.

Não depende de servidor.

---

# 23. Android

Priorizar Android no MVP.

Objetivo final:

flutter build apk

Gerar APK instalável diretamente no dispositivo.

Não adicionar permissão INTERNET sem necessidade.

---

# 24. Etapas de desenvolvimento

Não tentar implementar tudo simultaneamente.

## Marco 1 — Fundação

- Criar projeto Flutter
- Tema
- Navegação
- Componentes básicos
- SQLite
- Home
- Perfil

Critério de aceite:

Home
    ↓
Meus Perfis
    ↓
Novo Perfil
    ↓
Preencher
    ↓
Selecionar logo
    ↓
Salvar
    ↓
Fechar app
    ↓
Abrir novamente
    ↓
Perfil continua salvo

---

## Marco 2 — Clientes

- CRUD
- Pesquisa
- Seleção
- Persistência

---

## Marco 3 — Recibo

- Formulário
- Itens dinâmicos
- Valores
- Desconto
- Total
- Persistência

---

## Marco 4 — PDF

- Template
- Preview
- Geração
- Salvar
- Compartilhar
- Imprimir

---

## Marco 5 — Orçamento

- Formulário
- Status
- Histórico
- PDF

---

## Marco 6 — Comprovante

- Criação direta
- Conversão de orçamento
- source_document_id
- PDF

---

## Marco 7 — Dashboard

- Resumo mensal
- A receber
- Documentos
- Clientes
- Ranking

---

## Marco 8 — Backup

- Exportar
- Importar
- Validar restauração

---

# 25. UX

Existe um design de referência criado previamente.

O objetivo NÃO é copiar outro aplicativo comercial.

O design fornecido serve como referência para:

- organização das telas;
- hierarquia;
- cards;
- formulários;
- experiência de criação de documentos;
- preview;
- dashboard.

Criar identidade própria para este projeto.

Manter uma UI:

- moderna;
- limpa;
- simples;
- mobile-first;
- com cantos arredondados;
- bom espaçamento;
- inputs grandes;
- botões claros;
- ícones intuitivos.

---

# 26. Regras para implementação com Codex

Ao trabalhar neste projeto:

1. Leia este PROJECT_CONTEXT.md antes de alterações relevantes.

2. Não adicionar backend.

3. Não adicionar autenticação.

4. Não adicionar serviços cloud sem solicitação.

5. Não adicionar analytics ou tracking.

6. Não adicionar monetização.

7. O aplicativo deve continuar funcional sem internet.

8. Preferir SQLite para dados estruturados.

9. Reutilizar componentes.

10. Evitar duplicação entre Recibo, Orçamento e Comprovante.

11. Não implementar vários marcos de uma vez sem solicitação.

12. Antes de grandes mudanças arquiteturais, explicar o motivo.

13. Manter código simples e legível.

14. Executar:
   flutter analyze
   após alterações relevantes.

15. Corrigir erros encontrados antes de considerar uma etapa concluída.

16. Quando possível, executar testes existentes.

17. Não apagar funcionalidades existentes sem necessidade.

18. Manter compatibilidade com Android.

19. Valores monetários devem ser tratados com segurança.

20. Migrações do SQLite devem preservar dados existentes quando o schema evoluir.

---

# 27. Estado atual

O projeto está no início.

A prioridade atual é:

MARCO 1 — FUNDAÇÃO

Implementar somente:

- estrutura inicial;
- dependências necessárias;
- tema;
- navegação;
- Home;
- SQLite;
- Profile model;
- ProfileRepository;
- tela Meus Perfis;
- tela Novo/Editar Perfil;
- seleção local de logo;
- persistência;
- perfil padrão.

Ainda NÃO implementar:

- PDF
- dashboard completo
- orçamento
- recibo completo
- comprovante
- backup
- PIX QR Code

Essas funcionalidades serão implementadas incrementalmente.

---

# 28. Próxima tarefa recomendada ao Codex

Antes de escrever código:

1. Inspecione o projeto Flutter atual.
2. Leia este PROJECT_CONTEXT.md.
3. Verifique pubspec.yaml.
4. Verifique a estrutura existente.
5. Execute flutter analyze.
6. Informe brevemente o estado atual.

Depois implemente o Marco 1 incrementalmente.

Não reescreva arquivos desnecessariamente.
Não avance para os Marcos 2+.