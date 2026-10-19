-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema acalanto
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema acalanto
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `acalanto`;

CREATE SCHEMA IF NOT EXISTS `acalanto` DEFAULT CHARACTER SET utf8 ;
USE `acalanto` ;

-- -----------------------------------------------------
-- Table `acalanto`.`tipo_quarto`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`tipo_quarto` (
  `id_tipo` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `descricao` ENUM('individual', 'duplo', 'familiar', 'luxo') NOT NULL,
  `valor_diaria` DECIMAL(10,2) NOT NULL,
  `capacidade_max` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id_tipo`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`quarto`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`quarto` (
  `id_quarto` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_tipo` INT UNSIGNED NOT NULL,
  `num_quarto` VARCHAR(5) NOT NULL,
  `situacao` ENUM('disponivel', 'ocupado', 'em limpeza') NOT NULL,
  PRIMARY KEY (`id_quarto`),
  UNIQUE INDEX `id_quarto_UNIQUE` (`id_quarto` ASC) VISIBLE,
  CONSTRAINT `fk_quarto_tipo`
    FOREIGN KEY (`id_tipo`)
    REFERENCES `acalanto`.`tipo_quarto` (`id_tipo`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`cliente`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`cliente` (
  `id_cliente` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(45) NOT NULL,
  `sobrenome` VARCHAR(45) NOT NULL,
  `cpf` CHAR(11) NOT NULL,
  `telefone` VARCHAR(20) NOT NULL,
  `email` VARCHAR(100) NULL,
  `cidade` VARCHAR(45) NOT NULL,
  `estado` CHAR(2) NOT NULL,
  `dt_cadastro` DATE NOT NULL,
  PRIMARY KEY (`id_cliente`),
  UNIQUE INDEX `id_cliente_UNIQUE` (`id_cliente` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`reserva`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`reserva` (
  `id_reserva` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_cliente` INT UNSIGNED NOT NULL,
  `id_quarto` INT UNSIGNED NOT NULL,
  `dt_reserva` DATE NOT NULL,
  `dt_entrada_prev` DATE NOT NULL,
  `dt_saida_prev` DATE NOT NULL,
  `status` ENUM('confirmada', 'cancelada', 'concluida') NOT NULL,
  PRIMARY KEY (`id_reserva`),
  UNIQUE INDEX `id_reserva_UNIQUE` (`id_reserva` ASC) VISIBLE,
  CONSTRAINT `fk_res_cliente`
    FOREIGN KEY (`id_cliente`)
    REFERENCES `acalanto`.`cliente` (`id_cliente`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_res_quarto`
    FOREIGN KEY (`id_quarto`)
    REFERENCES `acalanto`.`quarto` (`id_quarto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`hospedagem`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`hospedagem` (
  `id_hospedagem` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_reserva` INT UNSIGNED NOT NULL,
  `id_cliente` INT UNSIGNED NOT NULL,
  `id_quarto` INT UNSIGNED NOT NULL,
  `dt_checkin` DATE NOT NULL,
  `dt_checkout` DATE NULL,
  `valor_total` DECIMAL(10,2) NULL,
  `status` ENUM('ativa', 'finalizada', 'cancelada') NOT NULL,
  PRIMARY KEY (`id_hospedagem`),
  UNIQUE INDEX `id_hospedagem_UNIQUE` (`id_hospedagem` ASC) VISIBLE,
  INDEX `id_quarto_idx` (`id_quarto` ASC) VISIBLE,
  CONSTRAINT `fk_hosp_reserva`
    FOREIGN KEY (`id_reserva`)
    REFERENCES `acalanto`.`reserva` (`id_reserva`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_hosp_quarto`
    FOREIGN KEY (`id_quarto`)
    REFERENCES `acalanto`.`quarto` (`id_quarto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_hosp_cliente`
    FOREIGN KEY (`id_cliente`)
    REFERENCES `acalanto`.`cliente` (`id_cliente`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`categoria`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`categoria` (
  `id_categoria` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nome_categoria` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id_categoria`),
  UNIQUE INDEX `id_categoria_UNIQUE` (`id_categoria` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`subcategoria`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`subcategoria` (
  `id_subcategoria` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_categoria` INT UNSIGNED NOT NULL,
  `nome_subcategoria` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id_subcategoria`),
  UNIQUE INDEX `id_sub_UNIQUE` (`id_subcategoria` ASC) VISIBLE,
  CONSTRAINT `fk_sub_categoria`
    FOREIGN KEY (`id_categoria`)
    REFERENCES `acalanto`.`categoria` (`id_categoria`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`produto`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`produto` (
  `id_produto` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_categoria` INT UNSIGNED NOT NULL,
  `id_subcategoria` INT UNSIGNED NOT NULL,
  `nome_produto` VARCHAR(100) NOT NULL,
  `estoque_atual` INT NOT NULL,
  `preco_unitario` DECIMAL(10,2) UNSIGNED NOT NULL,
  `valor_custo` DECIMAL(10,2) NOT NULL,
  `ativo` BIT(1) NOT NULL,
  PRIMARY KEY (`id_produto`),
  UNIQUE INDEX `id_produto_UNIQUE` (`id_produto` ASC) VISIBLE,
  CONSTRAINT `fk_prod_categoria`
    FOREIGN KEY (`id_categoria`)
    REFERENCES `acalanto`.`categoria` (`id_categoria`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_prod_subcategoria`
    FOREIGN KEY (`id_subcategoria`)
    REFERENCES `acalanto`.`subcategoria` (`id_subcategoria`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`venda`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`venda` (
  `id_venda` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_cliente` INT UNSIGNED NULL,
  `dt_venda` DATE NOT NULL,
  `valor_total` DECIMAL(10,2) UNSIGNED NOT NULL,
  `origem` ENUM('hospede', 'externo') NOT NULL,
  PRIMARY KEY (`id_venda`),
  UNIQUE INDEX `id_venda_UNIQUE` (`id_venda` ASC) VISIBLE,
  CONSTRAINT `fk_ven_cliente`
    FOREIGN KEY (`id_cliente`)
    REFERENCES `acalanto`.`cliente` (`id_cliente`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`itens_venda`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`itens_venda` (
  `id_item` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_produto` INT UNSIGNED NOT NULL,
  `id_venda` INT UNSIGNED NOT NULL,
  `quantidade` INT UNSIGNED NOT NULL,
  `preco_unit_momento` DECIMAL(10,2) UNSIGNED NOT NULL,
  PRIMARY KEY (`id_item`),
  UNIQUE INDEX `id_item_UNIQUE` (`id_item` ASC) VISIBLE,
  CONSTRAINT `fk_item_produto`
    FOREIGN KEY (`id_produto`)
    REFERENCES `acalanto`.`produto` (`id_produto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_item_venda`
    FOREIGN KEY (`id_venda`)
    REFERENCES `acalanto`.`venda` (`id_venda`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`pagamento`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`pagamento` (
  `id_pagamento` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_venda` INT UNSIGNED NOT NULL,
  `forma_pagamento` ENUM('pix', 'debito', 'dinheiro', 'credito') NOT NULL,
  `dt_pagamento` DATE NOT NULL,
  `valor` DECIMAL(10,2) UNSIGNED NOT NULL,
  PRIMARY KEY (`id_pagamento`),
  UNIQUE INDEX `id_pagamento_UNIQUE` (`id_pagamento` ASC) VISIBLE,
  CONSTRAINT `fk_paga_venda`
    FOREIGN KEY (`id_venda`)
    REFERENCES `acalanto`.`venda` (`id_venda`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `acalanto`.`etl_log`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `acalanto`.`etl_log` (
  `id_log` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `etapa` VARCHAR(45) NOT NULL,
  `executado_em` DATETIME NOT NULL,
  `status` ENUM('OK', 'ERRO') NOT NULL,
  `mensagem` TEXT NULL,
  `registro` INT NOT NULL,
  PRIMARY KEY (`id_log`),
  UNIQUE INDEX `id_log_UNIQUE` (`id_log` ASC) VISIBLE)
ENGINE = InnoDB;

ALTER TABLE `acalanto`.`tipo_quarto`
ADD CONSTRAINT chek_valor_diaria CHECK (valor_diaria > 0);

ALTER TABLE `acalanto`.`produto`
ADD CONSTRAINT chek_estoque CHECK (estoque_atual >= 0);

ALTER TABLE `acalanto`.`produto`
ADD CONSTRAINT chek_preco_unitario CHECK (preco_unitario > 0);

ALTER TABLE `acalanto`.`produto`
ADD CONSTRAINT chek_valor_custo CHECK (valor_custo > 0);

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;