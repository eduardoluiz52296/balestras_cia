<?php
/**
 * Conexão central com o banco balestras_cia (MariaDB via XAMPP).
 * Usa PDO + modo de exceção para permitir try/catch limpo nas
 * camadas de API.
 */

declare(strict_types=1);

function getConnection(): PDO
{
    $host = '127.0.0.1';
    $port = '3306';
    $db   = 'balestras_cia';
    $user = 'root';
    $pass = ''; // padrão do XAMPP; ajuste se você configurou senha no MySQL/MariaDB

    $dsn = "mysql:host={$host};port={$port};dbname={$db};charset=utf8mb4";

    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];

    // Deixa a exceção subir; quem chama decide como tratar (try/catch)
    return new PDO($dsn, $user, $pass, $options);
}
