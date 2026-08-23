<?php
/**
 * GET /backend/api/produtos.php
 * Retorna o catálogo de produtos (balestras, arcos, facas, etc.)
 * já com nome da categoria, pronto para renderizar os cards
 * Bootstrap no front-end.
 */

declare(strict_types=1);

header('Content-Type: application/json; charset=utf8mb4');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../config/db.php';

try {
    $pdo = getConnection();

    $sql = "SELECT
                p.id,
                p.nome,
                c.nome AS categoria,
                p.preco_unitario,
                p.estoque,
                p.imagem,
                p.descricao
            FROM produtos p
            INNER JOIN categorias c ON c.id = p.categoria_id
            WHERE p.ativo = 1
            ORDER BY c.nome, p.nome";

    $stmt = $pdo->query($sql);
    $produtos = $stmt->fetchAll();

    echo json_encode([
        'success' => true,
        'data'    => $produtos, // já vem [] vazio se não houver produtos - edge case tratado no front
    ], JSON_UNESCAPED_UNICODE);

} catch (PDOException $e) {
    // Falha de banco/conexão: nunca deixa a API quebrar sem resposta
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Falha ao consultar o banco de dados.',
        'error'   => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
