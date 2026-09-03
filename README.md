# Meus Recibos

Aplicativo Flutter Android, simples e totalmente offline, para criação e organização de documentos profissionais.

## Desenvolvimento

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Estado atual:

- Marco 1: fundação, Home e cadastro persistente de perfis locais;
- Marco 2: cadastro, edição, exclusão, pesquisa e seleção de clientes locais.
- Marco 3: criação e persistência de recibos com itens e cálculos em inteiros.
- Marco 4: preview A4, geração local de PDF personalizado, compartilhamento e impressão de recibos.
- Marco 5: criação, histórico, PDF e alteração de status de orçamentos.
- Marco 6: criação direta de comprovantes e conversão de orçamentos pagos com vínculo de origem.
- Marco 7: painel local com resumo mensal, documentos por tipo e ranking anual de clientes.
- Marco 8: exportação e restauração de backup local com banco, logos e PDFs.
- Marco 9: estabilização dos PDFs com fonte Unicode offline e preparação para release.

## Privacidade e funcionamento offline

- O aplicativo não possui backend, login, analytics ou permissão de internet.
- Dados, logos e PDFs permanecem no armazenamento privado do aplicativo.
- O backup automático do Android está desativado; exportações ocorrem somente quando solicitadas pelo usuário.

## Release Android

Antes da distribuição pública, crie uma chave de assinatura própria e configure-a fora do repositório. Nunca versione o arquivo da chave ou suas senhas. Depois execute:

```sh
flutter analyze
flutter test
flutter build apk --release
```
