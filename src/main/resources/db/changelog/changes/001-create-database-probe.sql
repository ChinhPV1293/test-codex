--liquibase formatted sql

--changeset chinhpv:001-create-database-probe
--comment: Small example table for verifying migrations against local MySQL.
CREATE TABLE database_probe (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
--rollback DROP TABLE database_probe;
