CREATE DATABASE IF NOT EXISTS PetShop;
USE PetShop;

-- Clientes
-- Armazena os dados dos donos dos pets.
CREATE TABLE Clientes (
    cliente_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    telefone VARCHAR(20),
    endereco VARCHAR(255)
);

-- Funcionarios
-- Armazena os dados dos funcionários do Pet Shop.
CREATE TABLE Funcionarios (
    funcionario_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    telefone VARCHAR(20)
);

-- Servicos
-- Armazena os serviços oferecidos.
CREATE TABLE Servicos (
    servico_id INT AUTO_INCREMENT PRIMARY KEY,
    nome_servico VARCHAR(100) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10, 2) NOT NULL
);

-- Pets
-- Armazena os dados dos animais, com referência ao dono.
CREATE TABLE Pets (
    pet_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    especie ENUM('Cachorro', 'Gato', 'Pássaro', 'Peixe', 'Roedor', 'Outro'),
    raca VARCHAR(50),
    data_nascimento DATE,
    cliente_id INT NOT NULL,
    CONSTRAINT fk_cliente_pets
        FOREIGN KEY (cliente_id)
        REFERENCES Clientes(cliente_id)
        ON DELETE CASCADE
);

-- Atendimentos
-- Tabela principal que relaciona pets, serviços e funcionários.
CREATE TABLE Atendimentos (
    atendimento_id INT AUTO_INCREMENT PRIMARY KEY,
    data_hora TIMESTAMP NOT NULL,
    observacoes TEXT,
    pet_id INT NOT NULL,
    servico_id INT NOT NULL,
    funcionario_id INT NOT NULL,
    CONSTRAINT fk_pet_atendimentos
        FOREIGN KEY (pet_id)
        REFERENCES Pets(pet_id),
    CONSTRAINT fk_servico_atendimentos
        FOREIGN KEY (servico_id)
        REFERENCES Servicos(servico_id),
    CONSTRAINT fk_funcionario_atendimentos
        FOREIGN KEY (funcionario_id)
        REFERENCES Funcionarios(funcionario_id)
);

-- Inserindo dados iniciais nas tabelas
-- Clientes
INSERT INTO Clientes (nome, telefone, endereco) VALUES
('Ana Silva', '(55) 99988-7766', 'Rua das Flores, 123, Centro'),
('Bruno Costa', '(55) 98877-6655', 'Avenida Principal, 456, Bairro Norte'),
('Carlos Dias', '(55) 97766-5544', 'Travessa dos Animais, 789, Vila Sul');

-- Funcionarios
INSERT INTO Funcionarios (nome, cargo, telefone) VALUES
('Fernanda Lima', 'Veterinária', '(55) 91122-3344'),
('Roberto Souza', 'Tosador', '(55) 92233-4455'),
('Mariana Alves', 'Recepcionista', '(55) 93344-5566');

-- Serviços
INSERT INTO Servicos (nome_servico, descricao, preco) VALUES
('Consulta Veterinária', 'Avaliação geral da saúde do pet.', 150.00),
('Banho e Tosa', 'Higienização completa com banho e tosa da raça.', 85.50),
('Vacinação V10', 'Aplicação de vacina polivalente importada.', 120.00),
('Banho Simples', 'Banho com produtos hipoalergênicos e secagem.', 60.00);

-- Pets
INSERT INTO Pets (nome, especie, raca, data_nascimento, cliente_id) VALUES
('Rex', 'Cachorro', 'Labrador', '2022-05-10', 1), 
('Mia', 'Gato', 'Siamês', '2023-01-20', 1),
('Thor', 'Cachorro', 'Golden Retriever', '2021-11-15', 2);

-- Atendimentos
INSERT INTO Atendimentos (data_hora, observacoes, pet_id, servico_id, funcionario_id) VALUES
('2025-06-15 10:00:00', 'Check-up anual, tudo certo.', 1, 1, 1),
('2025-06-20 14:30:00', 'Tosa verão, pelo curto.', 3, 2, 2),
('2025-06-22 11:00:00', 'Reforço anual da vacina V10.', 2, 3, 1),
('2025-06-23 09:00:00', 'Cliente pediu para usar shampoo especial para pelos claros.', 1, 4, 2);