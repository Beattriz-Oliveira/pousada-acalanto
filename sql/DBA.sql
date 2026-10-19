USE acalanto;

-- -----------------------------------------------------
-- Viwes
-- -----------------------------------------------------
-- Fato Venda
CREATE OR REPLACE VIEW vw_vendas AS SELECT
	v.id_venda,
    v.id_cliente,
    v.dt_venda,
    v.origem,
    v.valor_total AS receita,
    SUM(iv.quantidade * p.valor_custo) AS custo_total,
    v.valor_total - SUM(iv.quantidade * p.valor_custo) AS lucro_bruto,
    ROUND(
		(v.valor_total - SUM(iv.quantidade * p.valor_custo))
        / v.valor_total * 100, 2
) AS margem_perc
FROM venda v 
JOIN itens_venda iv ON v.id_venda = iv.id_venda
JOIN produto p ON p.id_produto = iv.id_produto
GROUP BY v.id_venda, v.id_cliente, v.dt_venda, v.origem, v.valor_total;

-- Dim Cliente
CREATE OR REPLACE VIEW vw_cliente AS SELECT
	c.id_cliente,
    CONCAT(c.nome, ' ', c.sobrenome) AS nome_completo,
    CONCAT(
		SUBSTRING(c.cpf, 1, 3), '.',
        SUBSTRING(c.cpf, 4, 3), '.',
        SUBSTRING(c.cpf, 7, 3), '-',
        SUBSTRING(c.cpf, 10, 2)
	) AS cpf_formatado,
    CONCAT(
		'(', SUBSTRING(c.telefone, 1, 2), ') ',
        SUBSTRING(c.telefone, 3, 5), '-',
        SUBSTRING(c.telefone, 8, 4)
	) AS telefone_formatado,
    c.email,
    c.estado,
    c.dt_cadastro
FROM cliente c;

-- Dim Produto
CREATE OR REPLACE VIEW vw_produto AS SELECT
	p.id_produto,
    c.nome_categoria,
    s.nome_subcategoria,
    p.nome_produto,
    p.estoque_atual,
    p.preco_unitario,
    p.valor_custo,
    p.ativo,
    CASE
		WHEN p.estoque_atual = 0 THEN "Sem estoque"
        WHEN p.estoque_atual < 0 THEN "Critico"
        WHEN p.estoque_atual < 30 THEN "Atencao"
        ELSE "Normal"
	END AS status_estoque
FROM produto p
JOIN categoria c ON p.id_categoria = c.id_categoria
JOIN subcategoria s ON p.id_subcategoria = s.id_subcategoria;

-- Dim quarto
CREATE OR REPLACE VIEW vw_quarto AS SELECT
	q.id_quarto,
    tq.descricao AS tipo_quarto,
    tq.valor_diaria,
    tq.capacidade_max,
    q.num_quarto,
    q.situacao
FROM quarto q
JOIN tipo_quarto tq ON q.id_tipo = tq.id_tipo;

-- Fato Hospedagem
CREATE OR REPLACE VIEW vw_hospedagem AS SELECT
	h.id_hospedagem,
    h.id_cliente,
    h.id_quarto,
    h.dt_checkin,
    h.dt_checkout,
    h.valor_total,
    CASE
		WHEN h.dt_checkout < '2026-05-27' THEN 'finalizada'
        WHEN h.dt_checkin <= '2026-05-27'
        AND h.dt_checkout >= '2026-05-27' THEN 'ativa'
        WHEN h.dt_checkin > '2026-05-27' THEN 'confirmada'
        ELSE h.status
	END AS status_hospedagem,
    DATEDIFF(h.dt_checkout, h.dt_checkin) AS qtde_dias,
    (DATEDIFF(h.dt_checkout, h.dt_checkin) * tq.valor_diaria) AS valor_projetado,
    r.dt_reserva,
    r.dt_entrada_prev,
    r.dt_saida_prev, 
	r.status
FROM hospedagem h
LEFT JOIN reserva r ON h.id_reserva = r.id_reserva
JOIN quarto q ON r.id_quarto  = q.id_quarto
JOIN tipo_quarto tq ON q.id_tipo    = tq.id_tipo;

-- Fato Reservas
CREATE OR REPLACE VIEW vw_reservas AS SELECT
	r.id_reserva,
    r.id_cliente,
    r.id_quarto,
    r.dt_entrada_prev,
    r.dt_saida_prev,
    DATEDIFF(r.dt_saida_prev, r.dt_entrada_prev) AS qtde_dias,
	DATEDIFF(r.dt_entrada_prev, '2026-05-27') AS dias_ate_checkin,
    ROUND(
        DATEDIFF(r.dt_saida_prev, r.dt_entrada_prev) * tq.valor_diaria, 2
    ) AS valor_estimado,
	r.status
FROM reserva r
JOIN quarto q ON r.id_quarto  = q.id_quarto
JOIN tipo_quarto tq ON q.id_tipo    = tq.id_tipo
WHERE r.status = 'confirmada'
AND r.dt_entrada_prev >= '2026-05-27'
AND NOT EXISTS (
	SELECT 1 FROM hospedagem h
	WHERE h.id_reserva = r.id_reserva
  );
  
CREATE OR REPLACE VIEW vw_ficha_hospede AS 
SELECT
    h.id_cliente,
    COUNT(h.id_hospedagem) AS qtde_estadia,
    MAX(h.dt_checkout) AS ultima_estadia,
    
    -- Subquery simples e direta para pegar o número do último quarto ocupado
    (
        SELECT q2.num_quarto
        FROM hospedagem h2
        JOIN quarto q2 ON h2.id_quarto = q2.id_quarto
        WHERE h2.id_cliente = h.id_cliente
        ORDER BY h2.dt_checkout DESC
        LIMIT 1
    ) AS ultimo_quarto,
    
    -- Agrupamento correto dos quartos utilizados no histórico válido
    GROUP_CONCAT(DISTINCT q.num_quarto ORDER BY q.num_quarto SEPARATOR ', ') AS quartos_utilizados,
    
    ROUND(SUM(h.valor_total), 2) AS total_gasto,
    ROUND(SUM(h.valor_total) / COUNT(h.id_hospedagem), 2) AS tiket_medio,
    DATEDIFF('2026-05-27', MAX(h.dt_checkout)) AS dias_ultima_estadia,
    
    CASE
        WHEN COUNT(h.id_hospedagem) >= 3 THEN 'fidelizado'
        WHEN COUNT(h.id_hospedagem) = 2 THEN 'regular'
        ELSE 'visitante'
    END AS tipo_cliente

FROM hospedagem h
JOIN quarto q ON h.id_quarto = q.id_quarto
WHERE h.dt_checkout < '2026-05-27'
  AND h.status = 'finalizada' -- Garante que estamos contando apenas estadias concluídas
GROUP BY h.id_cliente;

-- -----------------------------------------------------
--  Procedure
-- -----------------------------------------------------
DELIMITER $$

CREATE PROCEDURE sp_checkin(
	IN p_id_reserva INT,
    IN p_dt_checkin DATE
)

BEGIN
	DECLARE v_id_quarto INT;
    DECLARE v_id_cliente INT;
    
    -- Busca os dados da reserva
    SELECT id_quarto, id_cliente INTO v_id_quarto, v_id_cliente 
    FROM reserva WHERE id_reserva = p_id_reserva;
    
    -- Cria a nova hospedagem
    INSERT INTO hospedagem(id_reserva, id_quarto, id_cliente, dt_checkin, status)
    VALUES (p_id_reserva, v_id_quarto, v_id_cliente, p_dt_checkin, "ativa");
    
    -- Altera a situação do quarto
    UPDATE quarto SET situacao = "ocupado"
    WHERE id_quarto = v_id_quarto;
    
    -- Finaliza a reserva
    UPDATE reserva SET status = "concluida"
    WHERE id_reserva = p_id_reserva;
    
    SELECT "Checkin realizado com sucesso!" AS resultado;
END$$

CREATE PROCEDURE sp_checkout(
	IN p_id_hospedagem INT,
    IN p_dt_checkout DATE
)

BEGIN
	DECLARE v_id_quarto INT;
    DECLARE v_preco DECIMAL(10,2);
    DECLARE v_dias INT;
    DECLARE v_valor DECIMAL(10,2);
    
    -- Busca os dados e calcula o valor
    SELECT h.id_quarto, tq.valor_diaria, DATEDIFF(p_dt_checkout, h.dt_checkin)
    INTO v_id_quarto, v_preco, v_dias FROM hospedagem h
    JOIN quarto q ON h.id_quarto = q.id_quarto
    JOIN tipo_quarto tq ON q.id_tipo = tq.id_tipo
    WHERE h.id_hospedagem = p_id_hospedagem;
    
    SET v_valor = v_dias * v_preco;
    
    -- Finaliza a hospedagem
    UPDATE hospedagem SET dt_checkout = p_dt_checkout, valor_total = v_valor, status = "finalizada"
    WHERE id_hospedagem = p_id_hospedagem;
    
    -- Altera a situação do quarto
    UPDATE quarto SET situacao = "em limpeza"
    WHERE id_quarto = v_id_quarto;
    
    SELECT CONCAT ("Checkout realizado, valor total da hospedagem: ", v_valor) AS resultado;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- Triggres
-- -----------------------------------------------------

DELIMITER $$
	-- Decrementa o produto no estoque
CREATE TRIGGER trg_decrementa_estoque
	AFTER INSERT ON itens_venda
	FOR EACH ROW
BEGIN
	UPDATE produto
	SET estoque_atual = estoque_atual - NEW.quantidade
	WHERE id_produto = NEW.id_produto;
END$$

	-- Impende vendas com produtos sem estoques
CREATE TRIGGER trg_valida_estoque
	BEFORE INSERT ON itens_venda
    FOR EACH ROW 
BEGIN
	DECLARE v_estoque INT;
    
    SELECT estoque_atual INTO v_estoque
    FROM produto
    WHERE id_produto = NEW.id_produto;
    
    IF v_estoque < NEW.quantidade THEN
    SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "Estoque insuficiente para este produto.";
    END IF;
END$$

DELIMITER ; 