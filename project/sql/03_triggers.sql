-- ============================================================
-- Triggers BEFORE UPDATE
-- Objetivo: garantir que, independentemente do que o sistema
-- (ou um UPDATE manual) tente gravar, os valores numéricos
-- sensíveis (preço, estoque, quantidade, valor unitário) sejam
-- sempre padronizados como positivos antes de irem para o disco.
-- ============================================================

USE balestras_cia;

DELIMITER $$

-- ------------------------------------------------------------
-- trg_produtos_before_update
-- Antes de qualquer UPDATE em "produtos", força:
--   - preco_unitario >= 0 (usa ABS caso venha negativo)
--   - estoque >= 0 (usa ABS; nunca permite estoque negativo)
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_produtos_before_update$$
CREATE TRIGGER trg_produtos_before_update
BEFORE UPDATE ON produtos
FOR EACH ROW
BEGIN
    IF NEW.preco_unitario < 0 THEN
        SET NEW.preco_unitario = ABS(NEW.preco_unitario);
    END IF;

    IF NEW.estoque < 0 THEN
        SET NEW.estoque = ABS(NEW.estoque);
    END IF;
END$$


-- ------------------------------------------------------------
-- trg_vendas_before_update
-- Antes de qualquer UPDATE em "vendas", força:
--   - quantidade >= 1 (ABS; se vier 0, assume 1 para não gerar
--     venda "fantasma" com quantidade zero)
--   - valor_unitario >= 0 (ABS)
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_vendas_before_update$$
CREATE TRIGGER trg_vendas_before_update
BEFORE UPDATE ON vendas
FOR EACH ROW
BEGIN
    IF NEW.quantidade < 0 THEN
        SET NEW.quantidade = ABS(NEW.quantidade);
    END IF;
    IF NEW.quantidade = 0 THEN
        SET NEW.quantidade = 1;
    END IF;

    IF NEW.valor_unitario < 0 THEN
        SET NEW.valor_unitario = ABS(NEW.valor_unitario);
    END IF;
END$$

DELIMITER ;

-- ------------------------------------------------------------
-- Teste rápido dos triggers (opcional - rode manualmente):
--
--   UPDATE produtos SET preco_unitario = -50 WHERE id = 1;
--   SELECT preco_unitario FROM produtos WHERE id = 1; -- retorna 50
--
--   UPDATE vendas SET quantidade = -3 WHERE id = 1;
--   SELECT quantidade FROM vendas WHERE id = 1; -- retorna 3
-- ------------------------------------------------------------
