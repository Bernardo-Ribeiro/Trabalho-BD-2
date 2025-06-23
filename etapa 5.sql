-- ETAPA 5 - FUNCTIONS, PROCEDURES E TRIGGERS (MYSQL)

-- a) Criar cinco funções (Function)

-- 1. FUNÇÃO: Calcular Idade do Pet
-- DESCRIÇÃO: Retorna a idade atual de um pet em anos, com base em sua data de nascimento. Útil para ser exibida em telas e relatórios.
DELIMITER $$
CREATE FUNCTION fn_CalcularIdadePet(p_data_nascimento DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, p_data_nascimento, CURDATE());
END$$
DELIMITER ;
-- Exemplo de uso: 
SELECT nome, fn_CalcularIdadePet(data_nascimento) AS idade FROM Pets;


-- 2. FUNÇÃO: Calcular Total Gasto por um Cliente
-- DESCRIÇÃO: Retorna a soma de todos os valores de atendimentos para todos os pets de um determinado cliente. Essencial para relatórios financeiros.
DELIMITER $$
CREATE FUNCTION fn_TotalGastoCliente(p_cliente_id INT)
RETURNS DECIMAL(10, 2)
READS SQL DATA
BEGIN
    DECLARE total_gasto DECIMAL(10, 2);
    SELECT SUM(S.preco) INTO total_gasto
    FROM Atendimentos AS A
    JOIN Pets AS P ON A.pet_id = P.pet_id
    JOIN Servicos AS S ON A.servico_id = S.servico_id
    WHERE P.cliente_id = p_cliente_id;
    RETURN IFNULL(total_gasto, 0.00);
END$$
DELIMITER ;
-- Exemplo de uso:
SELECT nome, fn_TotalGastoCliente(cliente_id) FROM Clientes;


-- 3. FUNÇÃO: Obter o Nome do Último Serviço de um Pet
-- DESCRIÇÃO: Retorna o nome do serviço mais recente que um pet realizou. Útil para um acesso rápido ao último procedimento feito.
DELIMITER $$
CREATE FUNCTION fn_UltimoServicoRealizado(p_pet_id INT)
RETURNS VARCHAR(100)
READS SQL DATA
BEGIN
    DECLARE nome_servico VARCHAR(100);
    SELECT S.nome_servico INTO nome_servico
    FROM Atendimentos AS A
    JOIN Servicos AS S ON A.servico_id = S.servico_id
    WHERE A.pet_id = p_pet_id
    ORDER BY A.data_hora DESC
    LIMIT 1;
    RETURN nome_servico;
END$$
DELIMITER ;
-- Exemplo de uso:
SELECT nome, fn_UltimoServicoRealizado(pet_id) FROM Pets;


-- 4. FUNÇÃO: Contar o Número de Atendimentos de um Pet
-- DESCRIÇÃO: Retorna a quantidade total de atendimentos que um pet já teve. Ajuda a identificar rapidamente pets com maior frequência.
DELIMITER $$
CREATE FUNCTION fn_ContarAtendimentosPet(p_pet_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE total_atendimentos INT;
    SELECT COUNT(*) INTO total_atendimentos
    FROM Atendimentos
    WHERE pet_id = p_pet_id;
    RETURN total_atendimentos;
END$$
DELIMITER ;
-- Exemplo de uso:
SELECT nome, fn_ContarAtendimentosPet(pet_id) FROM Pets;


-- 5. FUNÇÃO: Verificar Disponibilidade de Funcionário
-- DESCRIÇÃO: Verifica se um funcionário já tem um atendimento agendado em um horário específico. Retorna 'Disponível' ou 'Ocupado'.
DELIMITER $$
CREATE FUNCTION fn_VerificarAgendaFuncionario(p_funcionario_id INT, p_data_hora TIMESTAMP)
RETURNS VARCHAR(10)
READS SQL DATA
BEGIN
    DECLARE contador INT;
    SELECT COUNT(*) INTO contador
    FROM Atendimentos
    WHERE funcionario_id = p_funcionario_id AND data_hora = p_data_hora;
    IF contador > 0 THEN
        RETURN 'Ocupado';
    ELSE
        RETURN 'Disponível';
    END IF;
END$$
DELIMITER ;
-- Exemplo de uso:
SELECT fn_VerificarAgendaFuncionario(1, '2025-06-22 11:00:00');


-- b) Criar cinco procedimentos (Procedure)

-- 1. PROCEDIMENTO: Cadastrar Cliente e seu Primeiro Pet
-- DESCRIÇÃO: Em uma única chamada, cadastra um novo cliente e, em seguida, cadastra o seu primeiro animal de estimação, já fazendo o vínculo.
DELIMITER $$
CREATE PROCEDURE sp_CadastrarClienteComPet(
    IN p_nome_cliente VARCHAR(100), IN p_tel_cliente VARCHAR(20), IN p_end_cliente VARCHAR(255),
    IN p_nome_pet VARCHAR(100), IN p_especie_pet ENUM('Cachorro', 'Gato', 'Pássaro', 'Peixe', 'Roedor', 'Outro'),
    IN p_raca_pet VARCHAR(50), IN p_nasc_pet DATE
)
BEGIN
    DECLARE v_cliente_id INT;
    INSERT INTO Clientes (nome, telefone, endereco)
    VALUES (p_nome_cliente, p_tel_cliente, p_end_cliente);
    SET v_cliente_id = LAST_INSERT_ID();
    INSERT INTO Pets (nome, especie, raca, data_nascimento, cliente_id)
    VALUES (p_nome_pet, p_especie_pet, p_raca_pet, p_nasc_pet, v_cliente_id);
END$$
DELIMITER ;
-- Exemplo de uso:
CALL sp_CadastrarClienteComPet('Novo Cliente', '(11) 5555-4444', 'Rua Nova, 10', 'Bolinha', 'Cachorro', 'Poodle', '2023-01-01');


-- 2. PROCEDIMENTO: Reagendar um Atendimento
-- DESCRIÇÃO: Atualiza a data e a hora de um atendimento já existente.
DELIMITER $$
CREATE PROCEDURE sp_ReagendarAtendimento(IN p_atendimento_id INT, IN p_nova_data_hora TIMESTAMP)
BEGIN
    UPDATE Atendimentos SET data_hora = p_nova_data_hora WHERE atendimento_id = p_atendimento_id;
END$$
DELIMITER ;
-- Exemplo de uso:
CALL sp_ReagendarAtendimento(1, '2025-06-16 09:00:00');


-- 3. PROCEDIMENTO: Gerar Relatório Mensal de Serviços
-- DESCRIÇÃO: Exibe um resumo de quantos serviços de cada tipo foram realizados e qual o faturamento de cada um em um dado mês/ano.
DELIMITER $$
CREATE PROCEDURE sp_RelatorioMensalServicos(IN p_ano INT, IN p_mes INT)
BEGIN
    SELECT
        S.nome_servico,
        COUNT(A.atendimento_id) AS 'Quantidade',
        SUM(S.preco) AS 'Faturamento Total (R$)'
    FROM Atendimentos AS A
    JOIN Servicos AS S ON A.servico_id = S.servico_id
    WHERE YEAR(A.data_hora) = p_ano AND MONTH(A.data_hora) = p_mes
    GROUP BY S.nome_servico
    ORDER BY `Faturamento Total (R$)` DESC;
END$$
DELIMITER ;
-- Exemplo de uso:
CALL sp_RelatorioMensalServicos(2025, 6);


-- 4. PROCEDIMENTO: Listar Top 5 Clientes por Gastos
-- DESCRIÇÃO: Gera um relatório com os 5 clientes que mais gastaram no pet shop.
DELIMITER $$
CREATE PROCEDURE sp_ListarTopClientes()
BEGIN
    SELECT
        C.nome,
        fn_TotalGastoCliente(C.cliente_id) AS TotalGasto
    FROM Clientes AS C
    ORDER BY TotalGasto DESC
    LIMIT 5;
END$$
DELIMITER ;
-- Exemplo de uso:
CALL sp_ListarTopClientes();


-- 5. PROCEDIMENTO: Deletar Cliente e Todos os Seus Registros
-- DESCRIÇÃO: Remove um cliente, seus pets e todos os atendimentos associados. A constraint ON DELETE CASCADE já remove os pets, mas este procedimento garante que os atendimentos também sejam limpos.
DELIMITER $$
CREATE PROCEDURE sp_DeletarClienteCompletamente(IN p_cliente_id INT)
BEGIN
    -- Deleta os atendimentos dos pets do cliente primeiro
    DELETE FROM Atendimentos WHERE pet_id IN (SELECT pet_id FROM Pets WHERE cliente_id = p_cliente_id);
    -- Deleta os pets (também pode ser feito por cascade)
    DELETE FROM Pets WHERE cliente_id = p_cliente_id;
    -- Deleta o cliente
    DELETE FROM Clientes WHERE cliente_id = p_cliente_id;
END$$
DELIMITER ;
-- Exemplo de uso:
CALL sp_DeletarClienteCompletamente(3);


-- c) Criar cinco gatilhos (Trigger)

-- SETUP: Tabela de Log para Auditoria
CREATE TABLE IF NOT EXISTS Auditoria (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    tabela_afetada VARCHAR(50) NOT NULL,
    acao VARCHAR(255) NOT NULL,
    data_hora_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario_db VARCHAR(100) NOT NULL
);

-- 1. GATILHO: Auditar a Alteração de Preços de Serviços
-- DESCRIÇÃO: Sempre que o preço de um serviço for atualizado, um registro é inserido na tabela de auditoria com o valor antigo e o novo.
DELIMITER $$
CREATE TRIGGER trg_AuditaPrecoServico
AFTER UPDATE ON Servicos
FOR EACH ROW
BEGIN
    IF OLD.preco <> NEW.preco THEN
        INSERT INTO Auditoria (tabela_afetada, acao, usuario_db)
        VALUES (
            'Servicos',
            CONCAT('Preco do servico ID ', OLD.servico_id, ' alterado de R$', OLD.preco, ' para R$', NEW.preco),
            USER()
        );
    END IF;
END$$
DELIMITER ;
-- Teste:
UPDATE Servicos SET preco = 90.00 WHERE servico_id = 2;


-- 2. GATILHO: Impedir a Exclusão de um Funcionário com Agenda Futura
-- DESCRIÇÃO: Antes de deletar um funcionário, o gatilho verifica se ele tem atendimentos marcados no futuro. Se tiver, a exclusão é bloqueada.
DELIMITER $$
CREATE TRIGGER trg_ImpedeExclusaoFuncionarioComAgenda
BEFORE DELETE ON Funcionarios
FOR EACH ROW
BEGIN
    DECLARE agenda_existente INT;
    SELECT COUNT(*) INTO agenda_existente
    FROM Atendimentos
    WHERE funcionario_id = OLD.funcionario_id;
    IF agenda_existente > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERRO: Este funcionário não pode ser excluído pois possui atendimentos futuros agendados.';
    END IF;
END$$
DELIMITER ;
-- Teste:
DELETE FROM Funcionarios WHERE funcionario_id = 1;


-- 3. GATILHO: Manter o Nome do Pet em Maiúsculas
-- DESCRIÇÃO: Antes de inserir um novo pet, este gatilho converte automaticamente o nome dele para letras maiúsculas, garantindo a padronização.
DELIMITER $$
CREATE TRIGGER trg_PadronizaNomePet
BEFORE INSERT ON Pets
FOR EACH ROW
BEGIN
    SET NEW.nome = UPPER(NEW.nome);
END$$
DELIMITER ;
-- Teste:
INSERT INTO Pets(nome, especie, raca, data_nascimento, cliente_id) VALUES ('fido', 'Cachorro', 'Vira-lata', '2022-01-01', 1);


-- 4. GATILHO: Impedir Agendamento em Data Passada
-- DESCRIÇÃO: Bloqueia a inserção de um atendimento se a data/hora for anterior ao momento atual, prevenindo erros de agendamento.
DELIMITER $$
CREATE TRIGGER trg_VerificaDataAgendamento
BEFORE INSERT ON Atendimentos
FOR EACH ROW
BEGIN
    IF NEW.data_hora < NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERRO: Não é possível agendar um atendimento em uma data ou hora passada.';
    END IF;
END$$
DELIMITER ;
-- Teste:
CALL sp_AgendarAtendimento(1, 1, 1, '2020-01-01 10:00:00', 'Teste de erro');


-- 5. GATILHO: Logar Exclusão de Atendimentos
-- DESCRIÇÃO: Registra na tabela de auditoria sempre que um atendimento agendado é cancelado (deletado da tabela).
DELIMITER $$
CREATE TRIGGER trg_LogCancelamentoAtendimento
AFTER DELETE ON Atendimentos
FOR EACH ROW
BEGIN
    INSERT INTO Auditoria (tabela_afetada, acao, usuario_db)
    VALUES (
        'Atendimentos',
        CONCAT('Atendimento ID ', OLD.atendimento_id, ' para o pet ID ', OLD.pet_id, ' foi cancelado.'),
        USER()
    );
END$$
DELIMITER ;
-- Teste:
DELETE FROM Atendimentos WHERE atendimento_id = 1;