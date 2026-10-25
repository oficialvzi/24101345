-- MySQL dump 10.13  Distrib 8.4.11, for macos26.6 (arm64)
--
-- Host: localhost    Database: aeroporto
-- ------------------------------------------------------
-- Server version	8.4.11

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `AERONAVE`
--

DROP TABLE IF EXISTS `AERONAVE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AERONAVE` (
  `numero_aeronave` int NOT NULL,
  `fabricante` varchar(45) DEFAULT NULL,
  `modelo` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`numero_aeronave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `AERONAVE`
--

LOCK TABLES `AERONAVE` WRITE;
/*!40000 ALTER TABLE `AERONAVE` DISABLE KEYS */;
INSERT INTO `AERONAVE` VALUES (1,'Airbus','A320'),(2,'Boeing','737-800'),(3,'Embraer','E195');
/*!40000 ALTER TABLE `AERONAVE` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auditoria`
--

DROP TABLE IF EXISTS `auditoria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auditoria` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tabela` varchar(50) NOT NULL,
  `registro_id` int NOT NULL,
  `acao` varchar(20) NOT NULL,
  `usuario_id` int NOT NULL,
  `dados_antes` json DEFAULT NULL,
  `criado_em` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_auditoria_registro` (`tabela`,`registro_id`),
  CONSTRAINT `chk_auditoria_acao` CHECK ((`acao` in (_utf8mb4'excluir',_utf8mb4'restaurar')))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auditoria`
--

LOCK TABLES `auditoria` WRITE;
/*!40000 ALTER TABLE `auditoria` DISABLE KEYS */;
INSERT INTO `auditoria` VALUES (1,'VOO',7,'excluir',1,'{\"origem\": \"Brasília\", \"destino\": \"Recife\", \"deleted_at\": null, \"numero_voo\": 7, \"horario_chegada\": \"2026-11-20 12:40:00\", \"horario_partida\": \"2026-11-20 10:00:00\", \"AERONAVE_numero_aeronave\": 2}','2026-10-25 13:45:37'),(2,'VOO',7,'restaurar',1,'{\"origem\": \"Brasília\", \"destino\": \"Recife\", \"deleted_at\": \"2026-10-25 13:45:37\", \"numero_voo\": 7, \"horario_chegada\": \"2026-11-20 12:40:00\", \"horario_partida\": \"2026-11-20 10:00:00\", \"AERONAVE_numero_aeronave\": 2}','2026-10-25 13:45:48');
/*!40000 ALTER TABLE `auditoria` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `PASSAGEIRO`
--

DROP TABLE IF EXISTS `PASSAGEIRO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `PASSAGEIRO` (
  `cpf` char(11) NOT NULL,
  `nome_completo` varchar(100) NOT NULL,
  `data_nasc` date NOT NULL,
  `genero` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`cpf`),
  CONSTRAINT `chk_passageiro_cpf` CHECK (regexp_like(`cpf`,_utf8mb4'^[0-9]{11}$')),
  CONSTRAINT `chk_passageiro_genero` CHECK (((`genero` is null) or (`genero` in (_utf8mb4'Feminino',_utf8mb4'Masculino',_utf8mb4'Outro',_utf8mb4'Não informado')))),
  CONSTRAINT `chk_passageiro_nasc` CHECK ((`data_nasc` >= _utf8mb4'1900-01-01'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `PASSAGEIRO`
--

LOCK TABLES `PASSAGEIRO` WRITE;
/*!40000 ALTER TABLE `PASSAGEIRO` DISABLE KEYS */;
INSERT INTO `PASSAGEIRO` VALUES ('12345678901','Maria Oliveira','1995-04-20','Feminino');
/*!40000 ALTER TABLE `PASSAGEIRO` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `PASSAGEM`
--

DROP TABLE IF EXISTS `PASSAGEM`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `PASSAGEM` (
  `id_passagem` int NOT NULL AUTO_INCREMENT,
  `numero_assento` varchar(5) NOT NULL,
  `classe` varchar(20) NOT NULL DEFAULT 'Econômica',
  `status_checkin` varchar(20) NOT NULL DEFAULT 'pendente',
  `valor_pago` decimal(10,2) NOT NULL,
  `data_reserva` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `PASSAGEIRO_cpf` char(11) NOT NULL,
  `VOO_numero_voo` int NOT NULL,
  PRIMARY KEY (`id_passagem`),
  UNIQUE KEY `uq_passagem_assento_voo` (`VOO_numero_voo`,`numero_assento`),
  UNIQUE KEY `uq_passagem_passageiro_voo` (`VOO_numero_voo`,`PASSAGEIRO_cpf`),
  KEY `fk_passagem_passageiro` (`PASSAGEIRO_cpf`),
  CONSTRAINT `fk_passagem_passageiro` FOREIGN KEY (`PASSAGEIRO_cpf`) REFERENCES `PASSAGEIRO` (`cpf`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_passagem_voo` FOREIGN KEY (`VOO_numero_voo`) REFERENCES `VOO` (`numero_voo`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_passagem_assento` CHECK (regexp_like(`numero_assento`,_utf8mb4'^[0-9]{1,3}[A-F]$')),
  CONSTRAINT `chk_passagem_classe` CHECK ((`classe` in (_utf8mb4'Econômica',_utf8mb4'Executiva',_utf8mb4'Primeira'))),
  CONSTRAINT `chk_passagem_status` CHECK ((`status_checkin` in (_utf8mb4'pendente',_utf8mb4'realizado',_utf8mb4'no-show',_utf8mb4'cancelado'))),
  CONSTRAINT `chk_passagem_valor` CHECK ((`valor_pago` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `PASSAGEM`
--

LOCK TABLES `PASSAGEM` WRITE;
/*!40000 ALTER TABLE `PASSAGEM` DISABLE KEYS */;
INSERT INTO `PASSAGEM` VALUES (1,'12A','Econômica','pendente',650.00,'2026-10-14 11:15:02','12345678901',1);
/*!40000 ALTER TABLE `PASSAGEM` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `USUARIO`
--

DROP TABLE IF EXISTS `USUARIO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `USUARIO` (
  `id_usuario` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `uq_usuario_email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `USUARIO`
--

LOCK TABLES `USUARIO` WRITE;
/*!40000 ALTER TABLE `USUARIO` DISABLE KEYS */;
INSERT INTO `USUARIO` VALUES (1,'Administrador','admin@aeroporto.local');
/*!40000 ALTER TABLE `USUARIO` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `VOO`
--

DROP TABLE IF EXISTS `VOO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `VOO` (
  `numero_voo` int NOT NULL AUTO_INCREMENT,
  `origem` varchar(45) NOT NULL,
  `destino` varchar(45) NOT NULL,
  `horario_partida` datetime NOT NULL,
  `horario_chegada` datetime NOT NULL,
  `AERONAVE_numero_aeronave` int NOT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`numero_voo`),
  KEY `fk_voo_aeronave` (`AERONAVE_numero_aeronave`),
  KEY `idx_voo_deleted_at` (`deleted_at`),
  CONSTRAINT `fk_voo_aeronave` FOREIGN KEY (`AERONAVE_numero_aeronave`) REFERENCES `AERONAVE` (`numero_aeronave`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_voo_horarios` CHECK ((`horario_chegada` > `horario_partida`)),
  CONSTRAINT `chk_voo_rota` CHECK ((`origem` <> `destino`))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `VOO`
--

LOCK TABLES `VOO` WRITE;
/*!40000 ALTER TABLE `VOO` DISABLE KEYS */;
INSERT INTO `VOO` VALUES (1,'Brasília','São Paulo','2026-11-10 08:00:00','2026-11-10 09:45:00',1,NULL),(2,'São Paulo','Rio de Janeiro','2026-11-10 14:00:00','2026-11-10 15:10:00',2,NULL),(3,'Brasília','Salvador','2026-11-11 07:15:00','2026-11-11 09:20:00',3,NULL),(4,'Rio de Janeiro','Brasília','2026-11-12 18:00:00','2026-11-12 19:50:00',1,NULL),(7,'Brasília','Recife','2026-11-20 10:00:00','2026-11-20 12:40:00',2,NULL);
/*!40000 ALTER TABLE `VOO` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'aeroporto'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-25 13:46:10
