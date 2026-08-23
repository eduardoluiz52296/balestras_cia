"use strict";
// ============================================================
// Balestras & Cia - app.ts
// Consome a API PHP (async/await + try/catch), calcula métricas
// da dashboard com .reduce() e trata cenários de exceção (sem
// dados, falha de rede, falha de banco) sem quebrar a tela.
// ============================================================
// ---------- Config ----------
const API_BASE = 'backend/api';
// ---------- Helpers ----------
/** Converte string/number vindo do PHP em number seguro (0 se inválido). */
function toNumber(value) {
    const n = typeof value === 'string' ? parseFloat(value) : value;
    return Number.isFinite(n) ? n : 0;
}
function formatBRL(value) {
    return value.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}
function el(id) {
    const found = document.getElementById(id);
    if (!found) {
        throw new Error(`Elemento #${id} não encontrado no DOM.`);
    }
    return found;
}
function showAlert(containerId, message, type = 'warning') {
    const container = el(containerId);
    container.innerHTML = `
        <div class="alert alert-${type} d-flex align-items-center gap-2" role="alert">
            <i class="bi bi-info-circle"></i>
            <span>${message}</span>
        </div>`;
}
// ------------------------------------------------------------
// 1) CARREGAR CATÁLOGO (Loja)
// ------------------------------------------------------------
async function carregarProdutos() {
    var _a, _b;
    const grid = el('produtos-grid');
    try {
        const resp = await fetch(`${API_BASE}/produtos.php`);
        if (!resp.ok) {
            throw new Error(`Falha HTTP ${resp.status} ao buscar produtos.`);
        }
        const json = (await resp.json());
        if (!json.success) {
            throw new Error((_a = json.message) !== null && _a !== void 0 ? _a : 'Erro desconhecido ao carregar produtos.');
        }
        const produtos = (_b = json.data) !== null && _b !== void 0 ? _b : [];
        // Edge case: banco vazio / nenhum produto ativo
        if (produtos.length === 0) {
            grid.innerHTML = `
                <div class="col-12">
                    <div class="alert alert-info text-center">
                        Nenhum produto cadastrado no momento.
                    </div>
                </div>`;
            return;
        }
        grid.innerHTML = produtos.map(renderCardProduto).join('');
        anexarEventosDeModal(produtos);
    }
    catch (erro) {
        // Edge case: falha de rede / backend fora do ar
        console.error('Erro ao carregar produtos:', erro);
        grid.innerHTML = `
            <div class="col-12">
                <div class="alert alert-danger text-center">
                    Não foi possível carregar o catálogo agora. Tente novamente em instantes.
                </div>
            </div>`;
    }
}
function renderCardProduto(p) {
    const preco = toNumber(p.preco_unitario);
    const imgSrc = p.imagem ? `frontend/img/${p.imagem}` : 'frontend/img/placeholder.svg';
    const semEstoque = p.estoque <= 0;
    return `
    <div class="col-sm-6 col-lg-4 col-xl-3">
        <div class="card h-100 shadow-sm produto-card">
            <div class="ratio ratio-4x3 bg-light">
                <img src="${imgSrc}" class="card-img-top object-fit-cover" alt="${p.nome}"
                     onerror="this.src='frontend/img/placeholder.svg'">
            </div>
            <div class="card-body d-flex flex-column">
                <span class="badge text-bg-secondary mb-2 align-self-start">${p.categoria}</span>
                <h6 class="card-title">${p.nome}</h6>
                <p class="fw-bold text-success mb-1">${formatBRL(preco)}</p>
                <p class="small text-muted mb-3">
                    ${semEstoque ? '<span class="text-danger">Fora de estoque</span>' : `${p.estoque} un. disponíveis`}
                </p>
                <button class="btn btn-outline-dark mt-auto btn-detalhes"
                        data-id="${p.id}" ${semEstoque ? 'disabled' : ''}>
                    Ver detalhes
                </button>
            </div>
        </div>
    </div>`;
}
function anexarEventosDeModal(produtos) {
    const botoes = document.querySelectorAll('.btn-detalhes');
    const modalEl = el('produtoModal');
    // @ts-ignore - bootstrap é carregado via CDN (script global)
    const modal = new bootstrap.Modal(modalEl);
    botoes.forEach((btn) => {
        btn.addEventListener('click', () => {
            const id = Number(btn.dataset.id);
            const produto = produtos.find((p) => p.id === id);
            if (!produto)
                return;
            el('modalProdutoNome').textContent = produto.nome;
            el('modalProdutoCategoria').textContent = produto.categoria;
            el('modalProdutoDescricao').textContent = produto.descricao || 'Sem descrição cadastrada.';
            el('modalProdutoPreco').textContent = formatBRL(toNumber(produto.preco_unitario));
            el('modalProdutoEstoque').textContent = `${produto.estoque} unidades em estoque`;
            modal.show();
        });
    });
}
// ------------------------------------------------------------
// 2) CARREGAR DASHBOARD (agregações via reduce)
// ------------------------------------------------------------
async function carregarDashboard() {
    var _a;
    const cardsWrap = el('dashboard-cards');
    const tabelaWrap = el('dashboard-tabela-wrap');
    const alertWrap = el('dashboard-alert');
    alertWrap.innerHTML = '';
    try {
        const resp = await fetch(`${API_BASE}/dashboard.php`);
        if (!resp.ok) {
            throw new Error(`Falha HTTP ${resp.status} ao buscar dashboard.`);
        }
        const json = (await resp.json());
        if (!json.success) {
            throw new Error((_a = json.message) !== null && _a !== void 0 ? _a : 'Erro desconhecido ao carregar a dashboard.');
        }
        const { vendas, por_produto, estoque } = json.data;
        // Edge case: nenhuma venda registrada no banco
        if (!vendas || vendas.length === 0) {
            cardsWrap.innerHTML = '';
            tabelaWrap.innerHTML = '';
            showAlert('dashboard-alert', 'Nenhum dado registrado. Assim que houver vendas, as métricas aparecerão aqui.', 'info');
            return;
        }
        renderCardsMetricas(vendas);
        renderTabelaProdutos(por_produto !== null && por_produto !== void 0 ? por_produto : []);
        renderAlertasEstoque(estoque !== null && estoque !== void 0 ? estoque : []);
    }
    catch (erro) {
        console.error('Erro ao carregar dashboard:', erro);
        cardsWrap.innerHTML = '';
        tabelaWrap.innerHTML = '';
        showAlert('dashboard-alert', 'Não foi possível carregar os dados da dashboard. Verifique a conexão com o banco/API.', 'danger');
    }
}
/**
 * Núcleo do requisito de "Agregações via reduce()":
 * a partir do array bruto de vendas vindo do PHP, calcula:
 *  - faturamento total (quantidade * valor_unitario, acumulado)
 *  - total de unidades vendidas
 *  - ticket médio
 *  - venda de maior valor (subtotal)
 * tudo em um único reduce, sem risco de NaN mesmo com dados
 * "sujos" que eventualmente escapem da limpeza do banco.
 */
function renderCardsMetricas(vendas) {
    const cardsWrap = el('dashboard-cards');
    const acumuladorInicial = {
        faturamentoTotal: 0,
        unidadesVendidas: 0,
        numeroVendas: 0,
        maiorVenda: 0,
    };
    const resultado = vendas.reduce((acc, venda) => {
        // Defesa extra: mesmo com a View já limpando os dados,
        // nunca confiamos cegamente no que chega do PHP.
        const quantidade = Math.max(0, toNumber(venda.quantidade));
        const valorUnitario = Math.max(0, toNumber(venda.valor_unitario));
        const subtotal = quantidade * valorUnitario;
        return {
            faturamentoTotal: acc.faturamentoTotal + subtotal,
            unidadesVendidas: acc.unidadesVendidas + quantidade,
            numeroVendas: acc.numeroVendas + 1,
            maiorVenda: Math.max(acc.maiorVenda, subtotal),
        };
    }, acumuladorInicial);
    // Edge case: proteção contra divisão por zero (NaN) no ticket médio
    const ticketMedio = resultado.numeroVendas > 0
        ? resultado.faturamentoTotal / resultado.numeroVendas
        : 0;
    cardsWrap.innerHTML = `
        ${cardMetrica('Faturamento Total', formatBRL(resultado.faturamentoTotal), 'bi-cash-coin', 'success')}
        ${cardMetrica('Unidades Vendidas', resultado.unidadesVendidas.toLocaleString('pt-BR'), 'bi-box-seam', 'primary')}
        ${cardMetrica('Ticket Médio', formatBRL(ticketMedio), 'bi-graph-up', 'info')}
        ${cardMetrica('Maior Venda', formatBRL(resultado.maiorVenda), 'bi-trophy', 'warning')}
    `;
}
function cardMetrica(titulo, valor, icone, cor) {
    return `
    <div class="col-sm-6 col-lg-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="text-${cor} mb-2"><i class="bi ${icone} fs-3"></i></div>
                <p class="text-muted small mb-1">${titulo}</p>
                <h4 class="mb-0">${valor}</h4>
            </div>
        </div>
    </div>`;
}
function renderTabelaProdutos(porProduto) {
    const wrap = el('dashboard-tabela-wrap');
    if (porProduto.length === 0) {
        wrap.innerHTML = '';
        return;
    }
    const linhas = porProduto.map((p) => `
        <tr>
            <td>${p.produto_nome}</td>
            <td>${p.categoria_nome}</td>
            <td class="text-end">${toNumber(p.unidades_vendidas).toLocaleString('pt-BR')}</td>
            <td class="text-end">${formatBRL(toNumber(p.faturamento_total))}</td>
            <td class="text-end">${formatBRL(toNumber(p.ticket_medio_unitario))}</td>
        </tr>`).join('');
    wrap.innerHTML = `
    <div class="table-responsive">
        <table class="table table-hover align-middle">
            <thead class="table-dark">
                <tr>
                    <th>Produto</th>
                    <th>Categoria</th>
                    <th class="text-end">Unidades</th>
                    <th class="text-end">Faturamento</th>
                    <th class="text-end">Preço médio</th>
                </tr>
            </thead>
            <tbody>${linhas}</tbody>
        </table>
    </div>`;
}
function renderAlertasEstoque(estoque) {
    const criticos = estoque.filter((e) => e.status_estoque === 'CRITICO');
    if (criticos.length === 0)
        return;
    const lista = criticos.map((e) => `<li>${e.produto_nome} — ${e.estoque_atual} un. restantes</li>`).join('');
    const container = el('dashboard-alert');
    container.innerHTML += `
        <div class="alert alert-warning mt-3">
            <strong><i class="bi bi-exclamation-triangle"></i> Estoque crítico:</strong>
            <ul class="mb-0 mt-1">${lista}</ul>
        </div>`;
}
// ------------------------------------------------------------
// 3) Navegação entre abas (Loja / Dashboard) + inicialização
// ------------------------------------------------------------
function inicializarAbas() {
    const tabDashboard = document.getElementById('tab-dashboard');
    if (!tabDashboard)
        return;
    tabDashboard.addEventListener('shown.bs.tab', () => {
        void carregarDashboard();
    });
}
document.addEventListener('DOMContentLoaded', () => {
    inicializarAbas();
    void carregarProdutos();
});
//# sourceMappingURL=app.js.map