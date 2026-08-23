-- ============================================================
-- Balestras & Cia - Schema principal (MariaDB)
-- Loja especializada em armamento branco, com foco em balestras
-- (crossbows), arcos, facas e espadas de coleção.
-- ============================================================

CREATE DATABASE IF NOT EXISTS balestras_cia
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE balestras_cia;

-- ------------------------------------------------------------
-- Categorias de produtos
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(60) NOT NULL,
    descricao VARCHAR(255) DEFAULT NULL
) ENGINE=InnoDB;

INSERT INTO categorias (nome, descricao) VALUES
  ('Balestras', 'Balestras recreativas e de tiro esportivo'),
  ('Arcos', 'Arcos recurvos e longbows'),
  ('Facas de Coleção', 'Facas para colecionadores, camping e outdoor'),
  ('Espadas Decorativas', 'Réplicas e espadas decorativas'),
  ('Acessórios', 'Virotes, cordas, estojos e manutenção');

-- ------------------------------------------------------------
-- Produtos (dados brutos - podem vir "sujos" de integrações)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    categoria_id INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    estoque INT NOT NULL DEFAULT 0,
    imagem VARCHAR(255) DEFAULT NULL,
    descricao TEXT,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_produto_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias(id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Vendas (dados brutos de vendas — origem: PDV/e-commerce)
-- Propositalmente pode conter ruído (valores nulos, negativos
-- por erro de digitação, duplicidade) para justificar a
-- necessidade das Views/CTEs de limpeza.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS vendas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    produto_id INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 0,
    valor_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    data_venda DATE NOT NULL DEFAULT (CURRENT_DATE),
    canal VARCHAR(40) DEFAULT 'site',
    CONSTRAINT fk_venda_produto
        FOREIGN KEY (produto_id) REFERENCES produtos(id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Dados de exemplo
-- ------------------------------------------------------------
INSERT INTO produtos (nome, categoria_id, preco_unitario, estoque, imagem, descricao) VALUES
('Balestra Recurva TR-150', 1, 899.90, 12, 'balestra1.jpg', 'Balestra recurva de alta precisão, 150 lbs, ideal para tiro esportivo.'),
('Balestra Compound Predator', 1, 1590.00, 5, 'balestra2.jpg', 'Balestra compound com mira 4x32 e case rígido incluso.'),
('Mini Balestra de Pulso', 1, 249.90, 20, 'balestra3.jpg', 'Balestra de pulso compacta para uso recreativo.'),
('Arco Recurvo 62"', 2, 620.00, 8, 'arco1.jpg', 'Arco recurvo tradicional em madeira laminada.'),
('Faca Bowie Tática', 3, 189.90, 30, 'faca1.jpg', 'Faca estilo Bowie com lâmina em aço inox 440C.'),
('Espada Katana Decorativa', 4, 459.00, 10, 'espada1.jpg', 'Réplica decorativa de katana com suporte de madeira.'),
('Pack 12 Virotes Alumínio', 5, 89.90, 50, 'virote1.jpg', 'Virotes em alumínio 6061, compatíveis com balestras recurvas.');

INSERT INTO vendas (produto_id, quantidade, valor_unitario, data_venda, canal) VALUES
(1, 2, 899.90, '2026-07-02', 'site'),
(1, 1, 899.90, '2026-07-10', 'loja'),
(2, 1, 1590.00, '2026-07-15', 'site'),
(3, 5, 249.90, '2026-07-18', 'site'),
(4, 2, 620.00, '2026-07-20', 'loja'),
(5, 8, 189.90, '2026-08-01', 'site'),
(6, 1, 459.00, '2026-08-03', 'loja'),
(7, 10, 89.90, '2026-08-05', 'site'),
-- linhas "sujas" propositalmente inseridas para validar as Views/Triggers
(3, -2, 249.90, '2026-08-06', 'site'),   -- quantidade negativa (erro de digitação)
(1, 1, -899.90, '2026-08-07', 'loja');   -- valor negativo (erro de digitação)
