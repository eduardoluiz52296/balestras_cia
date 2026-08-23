<?php
/**
 * GET /backend/api/dashboard.php
 *
 * Entrega o array "bruto" de vendas (já saneado pela
 * vw_dashboard_raw, que usa CTE para remover ruído) para o
 * front-end TypeScript. O front é responsável por rodar
 * .reduce() em cima deste array e extrair as métricas globais
 * (faturamento total, unidades vendidas, ticket médio etc.),
 * conforme pedido do requisito de "Agregações via reduce()".
 *
 * Também expõe a consolidação por categoria e por produto,
 * já prontas pela camada de View, para os gráficos secundários.
 */

declare(strict_types=1);

header('Content-Type: application/json; charset=utf8mb4');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../config/db.php';

try {
    $pdo = getConnection();

    // 1) Array bruto de vendas (linha a linha) para o reduce() do front
    $vendas = $pdo->query("SELECT
                                venda_id,
                                produto_id,
                                produto_nome,
                                categoria_nome,
                                quantidade,
                                valor_unitario,
                                data_venda
                            FROM vw_dashboard_raw")->fetchAll();

    // 2) Consolidado por categoria (para gráfico de participação)
    $porCategoria = $pdo->query("SELECT * FROM vw_faturamento_por_categoria")->fetchAll();

    // 3) Consolidado por produto (top produtos)
    $porProduto = $pdo->query("SELECT * FROM vw_faturamento_por_produto")->fetchAll();

    // 4) Saúde de estoque
    $estoque = $pdo->query("SELECT * FROM vw_estoque_saude")->fetchAll();

    echo json_encode([
        'success' => true,
        'data' => [
            'vendas'        => $vendas,       // pode vir [] -> edge case tratado no TS
            'por_categoria' => $porCategoria,
            'por_produto'   => $porProduto,
            'estoque'       => $estoque,
        ],
    ], JSON_UNESCAPED_UNICODE);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Não foi possível carregar os dados do dashboard.',
        'error'   => $e->getMessage(),
    ], JSON_UNESCAPED_UNICODE);
}
