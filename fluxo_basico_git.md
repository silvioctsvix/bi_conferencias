# Fluxo Básico de Atualização do Projeto com Git e GitHub

Este documento descreve o fluxo recomendado para manter seu projeto versionado com o Git durante o desenvolvimento ativo.

## ✅ Etapas Diárias

### 1. Atualize seu repositório local (se estiver trabalhando em equipe)
```bash
git pull
```

### 2. Faça alterações no projeto
Crie, edite ou remova arquivos conforme necessário.

### 3. Adicione os arquivos alterados ao controle de versão
```bash
git add .
```

### 4. Faça um commit com uma mensagem descritiva
```bash
git commit -m "Descrição breve e clara da alteração"
```

Exemplos:
```bash
git commit -m "Adiciona geração de PDF com nova biblioteca"
git commit -m "Corrige erro na visualização do relatório"
```

### 5. Envie as alterações para o GitHub
```bash
git push
```

---

## 📅 Rotina Sugerida

| Etapa               | Comando                          |
|---------------------|----------------------------------|
| Antes de começar    | `git pull`                       |
| Durante o desenvolvimento | Commits pequenos e frequentes |
| Ao fim do dia       | `git add .`, `git commit`, `git push` |

---

## 🧠 Boas Práticas

- Faça **commits pequenos e frequentes**
- Use mensagens **claras e significativas**
- Evite subir arquivos desnecessários (`.log`, `.bak`, etc.)
- Mantenha seu `.gitignore` sempre atualizado
- Sempre use `git pull` antes de começar o trabalho do dia

---

**Manter esse fluxo ajuda a evitar conflitos, perdas de código e facilita o histórico do projeto.**