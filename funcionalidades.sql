-- Etapa 4: FUNCIONALIDADES, CONSULTAS E RELATÓRIOS (MySQL)


-- FUNCIONALIDADE 1: Agendar um Novo Atendimento

-- DESCRIÇÃO:
-- Esta é a principal funcionalidade da recepcionista. Permite registrar um novo agendamento no sistema, vinculando um pet a um serviço, um funcionário e uma data/hora. Usamos uma Stored Procedure para encapsular a lógica e facilitar a chamada pela aplicação.

DELIMITER $$
CREATE PROCEDURE sp_AgendarAtendimento(
    IN p_pet_id INT,
    IN p_servico_id INT,
    IN p_funcionario_id INT,
    IN p_data_hora TIMESTAMP,
    IN p_observacoes TEXT
)
BEGIN
    INSERT INTO Atendimentos (pet_id, servico_id, funcionario_id, data_hora, observacoes)
    VALUES (p_pet_id, p_servico_id, p_funcionario_id, p_data_hora, p_observacoes);
END$$
DELIMITER ;

-- EXEMPLO DE USO:
-- CALL sp_AgendarAtendimento(1, 2, 2, '2025-07-10 15:00:00', 'Cliente pediu tosa bem curta.');


-- FUNCIONALIDADE 2: Consultar Agenda do Dia

-- DESCRIÇÃO:
-- Exibe todos os atendimentos agendados para uma data específica.
-- Essencial para a organização diária dos funcionários e da recepção.
-- A consulta une 5 tabelas para mostrar informações completas.

SELECT
    TIME(A.data_hora) AS 'Hora',
    P.nome AS 'Pet',
    C.nome AS 'Dono',
    S.nome_servico AS 'Serviço',
    F.nome AS 'Funcionário Responsável'
FROM Atendimentos AS A
JOIN Pets AS P ON A.pet_id = P.pet_id
JOIN Clientes AS C ON P.cliente_id = C.cliente_id
JOIN Servicos AS S ON A.servico_id = S.servico_id
JOIN Funcionarios AS F ON A.funcionario_id = F.funcionario_id
WHERE DATE(A.data_hora) = CURDATE() -- CURDATE() busca a data atual, mas pode ser trocada por qualquer data.
ORDER BY A.data_hora ASC;


-- FUNCIONALIDADE 3: Ver Histórico Completo de um Pet

-- DESCRIÇÃO:
-- Permite que um veterinário ou recepcionista visualize todos os serviços que um pet já realizou, incluindo data, serviço, preço e quem o atendeu.
-- Crucial para análise clínica e para responder a perguntas de clientes.

SELECT
    A.data_hora AS 'Data e Hora',
    S.nome_servico AS 'Serviço Realizado',
    S.preco AS 'Valor Cobrado',
    F.nome AS 'Profissional',
    A.observacoes AS 'Observações'
FROM Atendimentos AS A
JOIN Servicos AS S ON A.servico_id = S.servico_id
JOIN Funcionarios AS F ON A.funcionario_id = F.funcionario_id
WHERE A.pet_id = 3 -- ID do pet (Ex: Thor)
ORDER BY A.data_hora DESC;


-- FUNCIONALIDADE 4: Gerar Relatório de Faturamento por Período

-- DESCRIÇÃO:
-- Funcionalidade gerencial para calcular o faturamento total do pet shop em um intervalo de datas. A consulta soma o preço de todos os serviços realizados no período especificado.

SELECT
    COUNT(A.atendimento_id) AS 'Total de Atendimentos',
    SUM(S.preco) AS 'Faturamento Total (R$)'
FROM Atendimentos AS A
JOIN Servicos AS S ON A.servico_id = S.servico_id
WHERE A.data_hora BETWEEN '2025-06-01 00:00:00' AND '2025-06-30 23:59:59';


-- FUNCIONALIDADE 5: Encontrar Cliente pelo Nome do Pet

-- DESCRIÇÃO:
-- Ferramenta útil para a recepção. Quando um cliente liga e se identifica apenas pelo nome do pet, esta consulta rapidamente localiza os dados do dono (nome, telefone, endereço).

SELECT
    C.nome AS 'Nome do Dono',
    C.telefone AS 'Telefone',
    C.endereco AS 'Endereço',
    P.nome AS 'Nome do Pet',
    P.especie AS 'Espécie'
FROM Clientes AS C
JOIN Pets AS P ON C.cliente_id = P.cliente_id
WHERE P.nome LIKE '%Rex%'; -- Nome (ou um pedaço do nome) do pet que deve ser pesquisado.


-- FUNCIONALIDADE 6: Listar Todos os Pets de um Determinado Cliente

-- DESCRIÇÃO:
-- Ao selecionar um cliente, o sistema deve exibir uma lista de todos os animais de estimação que ele possui cadastrados no sistema.

SELECT
    P.pet_id,
    P.nome AS 'Nome do Pet',
    P.especie AS 'Espécie',
    P.raca AS 'Raça'
FROM Pets AS P
JOIN Clientes AS C ON P.cliente_id = C.cliente_id
WHERE C.cliente_id = 1; -- ID do cliente a ser consultado.


-- FUNCIONALIDADE 7: Relatório de Produtividade por Funcionário

-- DESCRIÇÃO:
-- Relatório gerencial que mostra quantos atendimentos cada funcionário realizou e o valor total que ele gerou em serviços dentro de um período, permitindo analisar a performance da equipe.

SELECT
    F.nome AS 'Funcionário',
    F.cargo AS 'Cargo',
    COUNT(A.atendimento_id) AS 'Nº de Atendimentos Realizados',
    SUM(S.preco) AS 'Valor Total Gerado (R$)'
FROM Funcionarios AS F
JOIN Atendimentos AS A ON F.funcionario_id = A.funcionario_id
JOIN Servicos AS S ON A.servico_id = S.servico_id
WHERE A.data_hora BETWEEN '2025-01-01 00:00:00' AND '2025-12-31 23:59:59' -- Período de análise.
GROUP BY F.funcionario_id, F.nome, F.cargo
ORDER BY `Valor Total Gerado (R$)` DESC;


-- FUNCIONALIDADE 8: Identificar Serviços Nunca Utilizados por um Pet

-- DESCRIÇÃO:
-- Ajuda a equipe a sugerir novos serviços. A consulta retorna uma lista de todos os serviços oferecidos pelo pet shop que um pet específico ainda não realizou. Utiliza uma subquery.

SELECT
    S.nome_servico AS 'Serviço a Sugerir',
    S.descricao,
    S.preco
FROM Servicos AS S
WHERE S.servico_id NOT IN (
    -- Subconsulta que busca todos os IDs de serviços que o pet já fez.
    SELECT A.servico_id
    FROM Atendimentos AS A
    WHERE A.pet_id = 1 -- ID do pet a ser consultado.
);


-- FUNCIONALIDADE 9: Atualizar o Cadastro de um Cliente

-- DESCRIÇÃO:
-- Funcionalidade básica de CRUD. Permite alterar os dados cadastrais (telefone, endereço) de um cliente existente.
-- Envolve a tabela Clientes e Pets para mostrar a quem as alterações se aplicam.

-- 1. Localizar o cliente e seus pets para confirmar a seleção.
SELECT C.nome, C.telefone, C.endereco, P.nome AS nome_pet
FROM Clientes C
LEFT JOIN Pets P ON C.cliente_id = P.cliente_id
WHERE C.cliente_id = 3; -- ID do cliente a ser atualizado.

-- 2. Executar a atualização.
UPDATE Clientes
SET
    telefone = '(55) 98888-9999',
    endereco = 'Rua Nova, 1010, Bairro Novo'
WHERE
    cliente_id = 3;


-- FUNCIONALIDADE 10: Cancelar um Atendimento Agendado

-- DESCRIÇÃO:
-- Permite que a recepção remova um agendamento futuro. Uma consulta prévia é executada para garantir que o agendamento correto está sendo cancelado antes da exclusão definitiva.

-- Visualizar o agendamento a ser cancelado para confirmação.
SELECT
    A.atendimento_id AS 'ID do Agendamento',
    A.data_hora AS 'Data Agendada',
    P.nome AS 'Pet',
    C.nome AS 'Dono',
    S.nome_servico AS 'Serviço'
FROM Atendimentos AS A
JOIN Pets AS P ON A.pet_id = P.pet_id
JOIN Clientes AS C ON P.cliente_id = C.cliente_id
JOIN Servicos AS S ON A.servico_id = S.servico_id
WHERE A.atendimento_id = 4; -- ID do atendimento a ser cancelado.

-- Se confirmado pelo usuário, deletar o agendamento.
DELETE FROM Atendimentos
WHERE atendimento_id = 4;

