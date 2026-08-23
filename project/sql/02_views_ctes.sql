-- ============================================================
-- Views analíticas + CTEs (Common Table Expressions)
-- Objetivo: limpar e consolidar os dados brutos de "vendas" e
-- "produtos", entregando-os perfeitamente estruturados para o
-- backend/dashboard consumir via API.
-- ============================================================

USE balestras_cia;

-- ------------------------------------------------------------
-- 1) vw_vendas_limpas
--    CTE que remove ruído de digitação (quantidade/valor
--    negativos ou zerados) e junta com o produto/categoria.
--    É a "fonte da verdade" para qualquer agregação financeira.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_vendas_limpas AS
WITH vendas_saneadas AS (
    SELECT
        v.id,
        v.produto_id,
        -- protege contra digitação errada: sempre valor absoluto
        ABS(v.quantidade)      AS quantidade,
        ABS(v.valor_unitario)  AS valor_unitario,
        v.data_venda,
        COALESCE(v.canal, 'site') AS canal
    FROM vendas v
    WHERE v.quantidade <> 0
      AND v.valor_unitario > 0
)
SELECT
    vs.id                                   AS venda_id,
    vs.produto_id,
    p.nome                                  AS produto_nome,
    c.nome                                  AS categoria_nome,
    vs.quantidade,
    vs.valor_unitario,
    (vs.quantidade * vs.valor_unitario)     AS subtotal,
    vs.data_venda,
    vs.canal
FROM vendas_saneadas vs
INNER JOIN produtos p   ON p.id = vs.produto_id
INNER JOIN categorias c ON c.id = p.categoria_id;


-- ------------------------------------------------------------
-- 2) vw_faturamento_por_produto
--    CTE que consolida (agrupa) as vendas limpas por produto,
--    já entregando total de unidades vendidas e faturamento.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_faturamento_por_produto AS
WITH base AS (
    SELECT * FROM vw_vendas_limpas
)
SELECT
    produto_id,
    produto_nome,
    categoria_nome,
    SUM(quantidade)                         AS unidades_vendidas,
    SUM(subtotal)                           AS faturamento_total,
    ROUND(AVG(valor_unitario), 2)           AS ticket_medio_unitario,
    COUNT(DISTINCT venda_id)                AS numero_vendas
FROM base
GROUP BY produto_id, produto_nome, categoria_nome
ORDER BY faturamento_total DESC;


-- ------------------------------------------------------------
-- 3) vw_faturamento_por_categoria
--    Consolidação em nível de categoria (para gráficos de
--    participação/pizza no dashboard).
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_faturamento_por_categoria AS
WITH base AS (
    SELECT * FROM vw_vendas_limpas
)
SELECT
    categoria_nome,
    SUM(quantidade)       AS unidades_vendidas,
    SUM(subtotal)         AS faturamento_total
FROM base
GROUP BY categoria_nome
ORDER BY faturamento_total DESC;


-- ------------------------------------------------------------
-- 4) vw_estoque_saude
--    Consolida estoque atual x vendas, sinalizando produtos com
--    risco de ruptura (estoque baixo) — dado já "pronto" para a
--    tela, sem o front precisar calcular nada.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_estoque_saude AS
WITH vendidos AS (
    SELECT produto_id, SUM(quantidade) AS total_vendido
    FROM vw_vendas_limpas
    GROUP BY produto_id
)
SELECT
    p.id                                     AS produto_id,
    p.nome                                   AS produto_nome,
    p.estoque                                AS estoque_atual,
    COALESCE(vd.total_vendido, 0)            AS total_vendido,
    CASE
        WHEN p.estoque <= 5 THEN 'CRITICO'
        WHEN p.estoque <= 15 THEN 'ATENCAO'
        ELSE 'OK'
    END                                       AS status_estoque
FROM produtos p
LEFT JOIN vendidos vd ON vd.produto_id = p.id
WHERE p.ativo = 1
ORDER BY p.estoque ASC;


-- ------------------------------------------------------------
-- 5) vw_dashboard_raw
--    View "achatada" (flat) usada pelo endpoint da API que
--    alimenta o front-end em TypeScript. Entrega uma linha por
--    venda já limpa, pronta para o .reduce() no cliente.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_dashboard_raw AS
SELECT
    venda_id,
    produto_id,
    produto_nome,
    categoria_nome,
    quantidade,
    valor_unitario,
    data_venda
FROM vw_vendas_limpas
ORDER BY data_venda DESC;
