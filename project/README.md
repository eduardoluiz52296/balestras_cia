# Balestras & Cia — Loja de Armamento Branco (Balestras)

Projeto acadêmico full-stack: **MariaDB (Views/CTEs/Triggers) + PHP (API/PDO)
+ Bootstrap 5 + TypeScript**.

## 📁 Estrutura

```
project/
├── index.html                 <- página principal (abrir no navegador)
├── sql/
│   ├── 01_schema.sql           tabelas + dados de exemplo
│   ├── 02_views_ctes.sql       Views analíticas com CTE (limpeza/consolidação)
│   └── 03_triggers.sql         Triggers BEFORE UPDATE (valores sempre positivos)
├── backend/
│   ├── config/db.php           conexão PDO com o MariaDB
│   └── api/
│       ├── produtos.php        GET -> catálogo (JSON)
│       └── dashboard.php       GET -> métricas brutas + views consolidadas (JSON)
└── frontend/
    ├── css/style.css
    ├── img/placeholder.svg
    ├── ts/app.ts               código-fonte TypeScript
    ├── js/app.js (+ .map)      JS já compilado (gerado por tsc)
    └── tsconfig.json
```

## 🚀 Como rodar no XAMPP

1. **Copie a pasta inteira** `project/` para dentro de `htdocs`, por exemplo:
   `C:\xampp\htdocs\balestras_cia\` (Windows) ou `/opt/lampp/htdocs/balestras_cia/` (Linux).

2. **Abra o XAMPP Control Panel** e inicie os módulos **Apache** e **MySQL**.

3. **Crie o banco de dados** — abra o phpMyAdmin (`http://localhost/phpmyadmin`)
   e execute, na aba "SQL", os três arquivos **nesta ordem**:
   1. `sql/01_schema.sql`
   2. `sql/02_views_ctes.sql`
   3. `sql/03_triggers.sql`

   (Ou via terminal: `mysql -u root -p < sql/01_schema.sql` e assim por diante.)

4. **Confira as credenciais** em `backend/config/db.php`. Por padrão o XAMPP
   usa usuário `root` sem senha — se você configurou senha, ajuste a
   variável `$pass`.

5. **Acesse no navegador:**
   `http://localhost/balestras_cia/index.html`

   A aba **Loja** carrega o catálogo via `backend/api/produtos.php`.
   A aba **Dashboard** carrega as métricas via `backend/api/dashboard.php`.

## 🛠️ Recompilando o TypeScript

O JS já vem compilado em `frontend/js/app.js`, mas se você editar
`frontend/ts/app.ts`, recompile com:

```bash
cd frontend
npx tsc -p tsconfig.json
```

(ou apenas `tsc -p tsconfig.json` se o TypeScript estiver instalado
globalmente: `npm install -g typescript`).

## ✅ Checklist de requisitos atendidos

| Requisito | Onde está |
|---|---|
| CTEs e Views analíticas que limpam/consolidam dados brutos | `sql/02_views_ctes.sql` — `vw_vendas_limpas` (CTE `vendas_saneadas` remove quantidade/valor negativos), `vw_faturamento_por_produto`, `vw_faturamento_por_categoria`, `vw_estoque_saude`, `vw_dashboard_raw` |
| Trigger BEFORE UPDATE para padronizar valores positivos | `sql/03_triggers.sql` — `trg_produtos_before_update` e `trg_vendas_before_update` usam `ABS()` |
| Interface amigável / usabilidade | `index.html` — navbar fixa, abas Loja/Dashboard, cards, busca visual por categoria (badges) |
| Bootstrap com 3+ componentes | Navbar, Nav-pills (tabs), Cards, Modal, Table, Alerts, Spinner, Badges |
| Agregações financeiras com `.reduce()` | `frontend/ts/app.ts` → `renderCardsMetricas()`: um único `.reduce()` sobre o array bruto de vendas calcula faturamento total (`quantidade * valor_unitario`), unidades vendidas, nº de vendas e maior venda |
| Tratamento de edge cases (dados vazios / NaN) | `carregarProdutos()` e `carregarDashboard()` checam array vazio e exibem "Nenhum dado registrado"; `toNumber()` e `Math.max(0, ...)` evitam NaN; ticket médio só divide se `numeroVendas > 0` |
| Consumo de API com fetch + async/await + try/catch | Todas as chamadas em `app.ts` (`carregarProdutos`, `carregarDashboard`) usam `async/await` dentro de `try/catch`, tratando falha de rede/HTTP e de backend |
| PHP resiliente a falha de banco | `backend/api/*.php` envolvem as queries em `try/catch (PDOException)` e retornam JSON de erro com HTTP 500, sem quebrar a aplicação |
| Integração XAMPP + compilação TypeScript | Instruções acima; `frontend/js/app.js` é o artefato compilado de `frontend/ts/app.ts` via `tsc` |

## 🧪 Testando os triggers manualmente (phpMyAdmin ou console MySQL)

```sql
UPDATE produtos SET preco_unitario = -50 WHERE id = 1;
SELECT preco_unitario FROM produtos WHERE id = 1; -- volta 50.00

UPDATE vendas SET quantidade = -3 WHERE id = 1;
SELECT quantidade FROM vendas WHERE id = 1; -- volta 3
```

## 🧪 Testando o cenário "banco vazio"

```sql
DELETE FROM vendas;
```

Recarregue a aba Dashboard: em vez de quebrar ou mostrar `NaN`, o sistema
exibirá a mensagem "Nenhum dado registrado."
