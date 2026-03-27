-- ============================================================
-- RESIMANAGER - Script Supabase
-- Sans données de test
-- ============================================================

-- ============================================================
-- TYPES ENUM
-- ============================================================
CREATE TYPE role_enum             AS ENUM ('super_admin','syndic_general','inter_syndic','resident');
CREATE TYPE statut_user_enum      AS ENUM ('actif','inactif');
CREATE TYPE statut_appart_enum    AS ENUM ('occupe','libre');
CREATE TYPE statut_espace_enum    AS ENUM ('disponible','occupe');
CREATE TYPE type_resident_enum    AS ENUM ('proprietaire','locataire');
CREATE TYPE type_depense_enum     AS ENUM ('globale','individuelle');
CREATE TYPE type_personnel_enum   AS ENUM ('gardien','jardinier','femme_de_menage','securite','autre');
CREATE TYPE statut_personnel_enum AS ENUM ('actif','inactif');
CREATE TYPE type_paiement_enum    AS ENUM ('charges','parking','garage','box');
CREATE TYPE statut_paiement_enum  AS ENUM ('complet','partiel','impaye');
CREATE TYPE type_annonce_enum     AS ENUM ('normale','urgente','information');
CREATE TYPE statut_annonce_enum   AS ENUM ('publiee','archivee');
CREATE TYPE statut_reunion_enum   AS ENUM ('planifiee','confirmee','terminee','annulee');
CREATE TYPE confirmation_enum     AS ENUM ('en_attente','confirme','absent');
CREATE TYPE statut_reclam_enum    AS ENUM ('en_cours','resolue','rejetee');
CREATE TYPE type_notif_enum       AS ENUM ('annonce','reunion','paiement','reclamation','general');

-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE users (
    id             BIGSERIAL        PRIMARY KEY,
    nom            VARCHAR(100)     NOT NULL,
    prenom         VARCHAR(100)     NOT NULL,
    email          VARCHAR(191)     NOT NULL UNIQUE,
    password       VARCHAR(255)     NOT NULL,
    telephone      VARCHAR(20)      NULL,
    role           role_enum        NOT NULL,
    statut         statut_user_enum NOT NULL DEFAULT 'actif',
    remember_token VARCHAR(100)     NULL,
    created_at     TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP        DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. RESIDENCES
-- ============================================================
CREATE TABLE residences (
    id                BIGSERIAL    PRIMARY KEY,
    nom               VARCHAR(150) NOT NULL,
    adresse           TEXT         NOT NULL,
    nombre_tranches   INT          NOT NULL DEFAULT 0,
    syndic_general_id BIGINT       NOT NULL,
    created_at        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_residence_syndic_general
        FOREIGN KEY (syndic_general_id) REFERENCES users(id) ON DELETE RESTRICT
);

-- ============================================================
-- 3. TRANCHES
-- ============================================================
CREATE TABLE tranches (
    id                  BIGSERIAL    PRIMARY KEY,
    nom                 VARCHAR(100) NOT NULL,
    description         TEXT         NULL,
    residence_id        BIGINT       NOT NULL,
    inter_syndic_id     BIGINT       NULL,
    nombre_immeubles    INT          NOT NULL DEFAULT 0,
    nombre_appartements INT          NOT NULL DEFAULT 0,
    nombre_parkings     INT          NOT NULL DEFAULT 0,
    nombre_garages      INT          NOT NULL DEFAULT 0,
    nombre_boxes        INT          NOT NULL DEFAULT 0,
    created_at          TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    prix_annuel         NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    date_affectation    DATE          NULL,

    CONSTRAINT fk_tranche_residence
        FOREIGN KEY (residence_id)    REFERENCES residences(id) ON DELETE CASCADE,
    CONSTRAINT fk_tranche_inter_syndic
        FOREIGN KEY (inter_syndic_id) REFERENCES users(id)      ON DELETE SET NULL
);

-- ============================================================
-- 4. IMMEUBLES
-- ============================================================
CREATE TABLE immeubles (
    id                  BIGSERIAL     PRIMARY KEY,
    nom                 VARCHAR(100)  NOT NULL,
    adresse             VARCHAR(255)  NULL,
    tranche_id          BIGINT        NOT NULL,
    nombre_appartements INT           NOT NULL DEFAULT 0,
    created_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_immeuble_tranche
        FOREIGN KEY (tranche_id) REFERENCES tranches(id) ON DELETE CASCADE
);

-- ============================================================
-- 5. APPARTEMENTS
-- ============================================================
CREATE TABLE appartements (
    id          BIGSERIAL          PRIMARY KEY,
    numero      VARCHAR(20)        NOT NULL,
    immeuble_id BIGINT             NOT NULL,
    statut      statut_appart_enum NOT NULL DEFAULT 'libre',
    resident_id BIGINT             NULL,
    created_at  TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_appart_immeuble
        FOREIGN KEY (immeuble_id) REFERENCES immeubles(id) ON DELETE CASCADE,
    CONSTRAINT fk_appart_resident
        FOREIGN KEY (resident_id) REFERENCES users(id)     ON DELETE SET NULL
);

-- ============================================================
-- 6. RESIDENTS
-- ============================================================
CREATE TABLE residents (
    id             BIGSERIAL          PRIMARY KEY,
    user_id        BIGINT             NOT NULL UNIQUE,
    appartement_id BIGINT             NULL,
    type           type_resident_enum NOT NULL,
    date_arrivee   DATE               NULL,
    statut         statut_user_enum   NOT NULL DEFAULT 'actif',
    created_at     TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_resident_user
        FOREIGN KEY (user_id)        REFERENCES users(id)        ON DELETE CASCADE,
    CONSTRAINT fk_resident_appartement
        FOREIGN KEY (appartement_id) REFERENCES appartements(id) ON DELETE SET NULL
);

-- ============================================================
-- 7. BENEFICIAIRES
-- ============================================================
CREATE TABLE beneficiaires (
    id          BIGSERIAL    PRIMARY KEY,
    nom         VARCHAR(100) NOT NULL,
    prenom      VARCHAR(100) NOT NULL,
    telephone   VARCHAR(20)  NULL,
    resident_id BIGINT       NULL,
    tranche_id  BIGINT       NULL,
    created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_benef_resident
        FOREIGN KEY (resident_id) REFERENCES users(id)    ON DELETE SET NULL,
    CONSTRAINT fk_benef_tranche
        FOREIGN KEY (tranche_id)  REFERENCES tranches(id) ON DELETE SET NULL
);

-- ============================================================
-- 8. PARKINGS
-- ============================================================
CREATE TABLE parkings (
    id              BIGSERIAL          PRIMARY KEY,
    numero          VARCHAR(20)        NOT NULL,
    residence_id    BIGINT             NOT NULL,
    tranche_id      BIGINT             NULL,
    prix_annuel     NUMERIC(10,2)      NOT NULL DEFAULT 0.00,
    statut          statut_espace_enum NOT NULL DEFAULT 'disponible',
    beneficiaire_id BIGINT             NULL,
    created_at      TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_parking_residence
        FOREIGN KEY (residence_id)    REFERENCES residences(id)    ON DELETE CASCADE,
    CONSTRAINT fk_parking_tranche
        FOREIGN KEY (tranche_id)      REFERENCES tranches(id)      ON DELETE SET NULL,
    CONSTRAINT fk_parking_beneficiaire
        FOREIGN KEY (beneficiaire_id) REFERENCES beneficiaires(id) ON DELETE SET NULL
);

-- ============================================================
-- 9. GARAGES
-- ============================================================
CREATE TABLE garages (
    id              BIGSERIAL          PRIMARY KEY,
    numero          VARCHAR(20)        NOT NULL,
    residence_id    BIGINT             NOT NULL,
    tranche_id      BIGINT             NOT NULL,
    prix_annuel     NUMERIC(10,2)      NOT NULL DEFAULT 0.00,
    surface         NUMERIC(6,2)       NULL,
    statut          statut_espace_enum NOT NULL DEFAULT 'disponible',
    beneficiaire_id BIGINT             NULL,
    created_at      TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_garage_residence
        FOREIGN KEY (residence_id)    REFERENCES residences(id)    ON DELETE CASCADE,
    CONSTRAINT fk_garage_tranche
        FOREIGN KEY (tranche_id)      REFERENCES tranches(id)      ON DELETE CASCADE,
    CONSTRAINT fk_garage_beneficiaire
        FOREIGN KEY (beneficiaire_id) REFERENCES beneficiaires(id) ON DELETE SET NULL
);

-- ============================================================
-- 10. BOXES
-- ============================================================
CREATE TABLE boxes (
    id              BIGSERIAL          PRIMARY KEY,
    numero          VARCHAR(20)        NOT NULL,
    residence_id    BIGINT             NOT NULL,
    tranche_id      BIGINT             NULL,
    immeuble_id     BIGINT             NULL,
    prix_annuel     NUMERIC(10,2)      NOT NULL DEFAULT 0.00,
    statut          statut_espace_enum NOT NULL DEFAULT 'disponible',
    beneficiaire_id BIGINT             NULL,
    created_at      TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_box_residence
        FOREIGN KEY (residence_id)    REFERENCES residences(id)    ON DELETE CASCADE,
    CONSTRAINT fk_box_tranche
        FOREIGN KEY (tranche_id)      REFERENCES tranches(id)      ON DELETE SET NULL,
    CONSTRAINT fk_box_immeuble
        FOREIGN KEY (immeuble_id)     REFERENCES immeubles(id)     ON DELETE SET NULL,
    CONSTRAINT fk_box_beneficiaire
        FOREIGN KEY (beneficiaire_id) REFERENCES beneficiaires(id) ON DELETE SET NULL
);

-- ============================================================
-- 11. CATEGORIES
-- ============================================================
CREATE TABLE categories (
    id          BIGSERIAL         PRIMARY KEY,
    nom         VARCHAR(100)      NOT NULL,
    description TEXT              NULL,
    type        type_depense_enum NOT NULL,
    created_at  TIMESTAMP         DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP         DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 12. PERSONNEL
-- ============================================================
CREATE TABLE personnel (
    id             BIGSERIAL             PRIMARY KEY,
    nom            VARCHAR(100)          NOT NULL,
    prenom         VARCHAR(100)          NOT NULL,
    telephone      VARCHAR(20)           NULL,
    type           type_personnel_enum   NOT NULL,
    residence_id   BIGINT                NOT NULL,
    tranche_id     BIGINT                NULL,
    salaire_annuel NUMERIC(10,2)         NOT NULL DEFAULT 0.00,
    statut         statut_personnel_enum NOT NULL DEFAULT 'actif',
    date_embauche  DATE                  NULL,
    created_at     TIMESTAMP             DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP             DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_personnel_residence
        FOREIGN KEY (residence_id) REFERENCES residences(id) ON DELETE RESTRICT,
    CONSTRAINT fk_personnel_tranche
        FOREIGN KEY (tranche_id)   REFERENCES tranches(id)   ON DELETE SET NULL
);

-- ============================================================
-- 13. DEPENSES
-- ============================================================
CREATE TABLE depenses (
    id                BIGSERIAL     PRIMARY KEY,
    montant           NUMERIC(10,2) NOT NULL,
    categorie_id      BIGINT        NULL,
    residence_id      BIGINT        NOT NULL,
    syndic_general_id BIGINT        NULL,
    inter_syndic_id   BIGINT        NULL,
    tranche_id        BIGINT        NULL,
    immeuble_id       BIGINT        NULL,
    personnel_id      BIGINT        NULL,
    date              DATE          NOT NULL,
    annee             INT           NOT NULL,
    mois              SMALLINT      NULL,
    facture_path      VARCHAR(255)  NULL,
    created_at        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_depense_categorie
        FOREIGN KEY (categorie_id)      REFERENCES categories(id)  ON DELETE SET NULL,
    CONSTRAINT fk_depense_residence
        FOREIGN KEY (residence_id)      REFERENCES residences(id)  ON DELETE RESTRICT,
    CONSTRAINT fk_depense_syndic_general
        FOREIGN KEY (syndic_general_id) REFERENCES users(id)       ON DELETE RESTRICT,
    CONSTRAINT fk_depense_inter_syndic
        FOREIGN KEY (inter_syndic_id)   REFERENCES users(id)       ON DELETE RESTRICT,
    CONSTRAINT fk_depense_tranche
        FOREIGN KEY (tranche_id)        REFERENCES tranches(id)    ON DELETE SET NULL,
    CONSTRAINT fk_depense_immeuble
        FOREIGN KEY (immeuble_id)       REFERENCES immeubles(id)   ON DELETE SET NULL,
    CONSTRAINT fk_depense_personnel
        FOREIGN KEY (personnel_id)      REFERENCES personnel(id)   ON DELETE SET NULL
);

-- ============================================================
-- 14. PAIEMENTS
-- ============================================================
CREATE TABLE paiements (
    id              BIGSERIAL            PRIMARY KEY,
    resident_id     BIGINT               NOT NULL,
    appartement_id  BIGINT               NOT NULL,
    inter_syndic_id BIGINT               NOT NULL,
    residence_id    BIGINT               NOT NULL,
    montant_total   NUMERIC(10,2)        NOT NULL,
    montant_paye    NUMERIC(10,2)        NOT NULL DEFAULT 0.00,
    type_paiement   type_paiement_enum   NOT NULL,
    date_paiement   DATE                 NULL,
    statut          statut_paiement_enum NOT NULL DEFAULT 'impaye',
    annee           INT                  NOT NULL,
    mois            SMALLINT             NULL,
    created_at      TIMESTAMP            DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP            DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_paiement_resident
        FOREIGN KEY (resident_id)     REFERENCES users(id)        ON DELETE RESTRICT,
    CONSTRAINT fk_paiement_appartement
        FOREIGN KEY (appartement_id)  REFERENCES appartements(id) ON DELETE RESTRICT,
    CONSTRAINT fk_paiement_intersyndic
        FOREIGN KEY (inter_syndic_id) REFERENCES users(id)        ON DELETE RESTRICT,
    CONSTRAINT fk_paiement_residence
        FOREIGN KEY (residence_id)    REFERENCES residences(id)   ON DELETE RESTRICT
);

-- ============================================================
-- 15. HISTORIQUE PAIEMENTS
-- ============================================================
CREATE TABLE historique_paiements (
    id          BIGSERIAL          PRIMARY KEY,
    resident_id BIGINT             NOT NULL,
    paiement_id BIGINT             NULL,
    montant     NUMERIC(10,2)      NOT NULL,
    date        DATE               NOT NULL,
    type        type_paiement_enum NOT NULL,
    description TEXT               NULL,
    created_at  TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_historique_resident
        FOREIGN KEY (resident_id) REFERENCES users(id)     ON DELETE RESTRICT,
    CONSTRAINT fk_historique_paiement
        FOREIGN KEY (paiement_id) REFERENCES paiements(id) ON DELETE SET NULL
);

-- ============================================================
-- 16. FINANCES SUMMARY
-- ============================================================
CREATE TABLE finances_summary (
    id                 BIGSERIAL     PRIMARY KEY,
    tranche_id         BIGINT        NOT NULL UNIQUE,
    revenus_charges    NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    revenus_parkings   NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    revenus_garages    NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    revenus_boxes      NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    revenus_total      NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    depenses_personnel NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    depenses_entretien NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    depenses_total     NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    solde              NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    updated_at         TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_finances_tranche
        FOREIGN KEY (tranche_id) REFERENCES tranches(id) ON DELETE CASCADE
);

-- ============================================================
-- 17. ANNONCES
-- ============================================================
CREATE TABLE annonces (
    id              BIGSERIAL           PRIMARY KEY,
    titre           VARCHAR(200)        NOT NULL,
    contenu         TEXT                NOT NULL,
    type            type_annonce_enum   NOT NULL DEFAULT 'normale',
    tranche_id      BIGINT              NULL,
    inter_syndic_id BIGINT              NOT NULL,
    date_expiration DATE                NULL,
    statut          statut_annonce_enum NOT NULL DEFAULT 'publiee',
    created_at      TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_annonce_tranche
        FOREIGN KEY (tranche_id)      REFERENCES tranches(id) ON DELETE SET NULL,
    CONSTRAINT fk_annonce_inter_syndic
        FOREIGN KEY (inter_syndic_id) REFERENCES users(id)    ON DELETE RESTRICT
);

-- ============================================================
-- 18. REUNIONS
-- ============================================================
CREATE TABLE reunions (
    id              BIGSERIAL           PRIMARY KEY,
    titre           VARCHAR(200)        NOT NULL,
    description     TEXT                NULL,
    date            DATE                NOT NULL,
    heure           TIME                NOT NULL,
    lieu            VARCHAR(255)        NOT NULL,
    tranche_id      BIGINT              NULL,
    inter_syndic_id BIGINT              NOT NULL,
    statut          statut_reunion_enum NOT NULL DEFAULT 'planifiee',
    created_at      TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reunion_tranche
        FOREIGN KEY (tranche_id)      REFERENCES tranches(id) ON DELETE SET NULL,
    CONSTRAINT fk_reunion_inter_syndic
        FOREIGN KEY (inter_syndic_id) REFERENCES users(id)    ON DELETE RESTRICT
);

-- ============================================================
-- 19. REUNION_RESIDENT
-- ============================================================
CREATE TABLE reunion_resident (
    id           BIGSERIAL         PRIMARY KEY,
    reunion_id   BIGINT            NOT NULL,
    resident_id  BIGINT            NOT NULL,
    confirmation confirmation_enum NOT NULL DEFAULT 'en_attente',
    created_at   TIMESTAMP         DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (reunion_id, resident_id),
    CONSTRAINT fk_rr_reunion
        FOREIGN KEY (reunion_id)  REFERENCES reunions(id) ON DELETE CASCADE,
    CONSTRAINT fk_rr_resident
        FOREIGN KEY (resident_id) REFERENCES users(id)   ON DELETE CASCADE
);

-- ============================================================
-- 20. RECLAMATIONS
-- ============================================================
CREATE TABLE reclamations (
    id              BIGSERIAL          PRIMARY KEY,
    titre           VARCHAR(200)       NOT NULL,
    description     TEXT               NOT NULL,
    resident_id     BIGINT             NOT NULL,
    inter_syndic_id BIGINT             NULL,
    tranche_id      BIGINT             NULL,
    statut          statut_reclam_enum NOT NULL DEFAULT 'en_cours',
    document_path   VARCHAR(255)       NULL,
    created_at      TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP          DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reclam_resident
        FOREIGN KEY (resident_id)     REFERENCES users(id)    ON DELETE RESTRICT,
    CONSTRAINT fk_reclam_inter_syndic
        FOREIGN KEY (inter_syndic_id) REFERENCES users(id)    ON DELETE SET NULL,
    CONSTRAINT fk_reclam_tranche
        FOREIGN KEY (tranche_id)      REFERENCES tranches(id) ON DELETE SET NULL
);

-- ============================================================
-- 21. NOTIFICATIONS
-- ============================================================
CREATE TABLE notifications (
    id             BIGSERIAL       PRIMARY KEY,
    user_id        BIGINT          NOT NULL,
    titre          VARCHAR(200)    NOT NULL,
    message        TEXT            NOT NULL,
    type           type_notif_enum NOT NULL,
    lu             BOOLEAN         NOT NULL DEFAULT FALSE,
    annonce_id     BIGINT          NULL,
    reunion_id     BIGINT          NULL,
    paiement_id    BIGINT          NULL,
    reclamation_id BIGINT          NULL,
    created_at     TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_notif_user
        FOREIGN KEY (user_id)        REFERENCES users(id)        ON DELETE CASCADE,
    CONSTRAINT fk_notif_annonce
        FOREIGN KEY (annonce_id)     REFERENCES annonces(id)     ON DELETE SET NULL,
    CONSTRAINT fk_notif_reunion
        FOREIGN KEY (reunion_id)     REFERENCES reunions(id)     ON DELETE SET NULL,
    CONSTRAINT fk_notif_paiement
        FOREIGN KEY (paiement_id)    REFERENCES paiements(id)    ON DELETE SET NULL,
    CONSTRAINT fk_notif_reclamation
        FOREIGN KEY (reclamation_id) REFERENCES reclamations(id) ON DELETE SET NULL
);

-- ============================================================
-- 22. STORAGE (BUCKET POUR FACTURES)
-- ============================================================
-- Création du bucket (S'assurer que l'extension pg_cron ou pgsodium ne bloque pas, utiliser l'interface Supabase Storage si la requête échoue)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('resimanager_bucket', 'resimanager_bucket', true)
ON CONFLICT (id) DO NOTHING;

-- Autoriser l'accès public en lecture
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'resimanager_bucket');
-- Autoriser l'insertion pour tout le monde (ou spécifier des règles plus strictes si authentification)
CREATE POLICY "Public Insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'resimanager_bucket');
-- Autoriser la mise à jour
CREATE POLICY "Public Update" ON storage.objects FOR UPDATE USING (bucket_id = 'resimanager_bucket');
-- Autoriser la suppression
CREATE POLICY "Public Delete" ON storage.objects FOR DELETE USING (bucket_id = 'resimanager_bucket');


