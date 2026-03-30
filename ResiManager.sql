-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.annonces (
  id bigint NOT NULL DEFAULT nextval('annonces_id_seq'::regclass),
  titre character varying NOT NULL,
  contenu text NOT NULL,
  type USER-DEFINED NOT NULL DEFAULT 'normale'::type_annonce_enum,
  tranche_id bigint,
  inter_syndic_id bigint NOT NULL,
  date_expiration date,
  statut USER-DEFINED NOT NULL DEFAULT 'publiee'::statut_annonce_enum,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT annonces_pkey PRIMARY KEY (id),
  CONSTRAINT fk_annonce_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id),
  CONSTRAINT fk_annonce_inter_syndic FOREIGN KEY (inter_syndic_id) REFERENCES public.users(id)
);
CREATE TABLE public.appartements (
  id bigint NOT NULL DEFAULT nextval('appartements_id_seq'::regclass),
  numero character varying NOT NULL,
  immeuble_id bigint NOT NULL,
  statut USER-DEFINED NOT NULL DEFAULT 'libre'::statut_appart_enum,
  resident_id bigint,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT appartements_pkey PRIMARY KEY (id),
  CONSTRAINT fk_appart_immeuble FOREIGN KEY (immeuble_id) REFERENCES public.immeubles(id),
  CONSTRAINT fk_appart_resident FOREIGN KEY (resident_id) REFERENCES public.users(id)
);
CREATE TABLE public.beneficiaires (
  id bigint NOT NULL DEFAULT nextval('beneficiaires_id_seq'::regclass),
  nom character varying NOT NULL,
  prenom character varying NOT NULL,
  telephone character varying,
  resident_id bigint,
  tranche_id bigint,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT beneficiaires_pkey PRIMARY KEY (id),
  CONSTRAINT fk_benef_resident FOREIGN KEY (resident_id) REFERENCES public.users(id),
  CONSTRAINT fk_benef_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id)
);
CREATE TABLE public.boxes (
  id bigint NOT NULL DEFAULT nextval('boxes_id_seq'::regclass),
  numero character varying NOT NULL,
  residence_id bigint NOT NULL,
  tranche_id bigint,
  immeuble_id bigint,
  prix_annuel numeric NOT NULL DEFAULT 0.00,
  statut USER-DEFINED NOT NULL DEFAULT 'disponible'::statut_espace_enum,
  beneficiaire_id bigint,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT boxes_pkey PRIMARY KEY (id),
  CONSTRAINT fk_box_beneficiaire FOREIGN KEY (beneficiaire_id) REFERENCES public.beneficiaires(id),
  CONSTRAINT fk_box_residence FOREIGN KEY (residence_id) REFERENCES public.residences(id),
  CONSTRAINT fk_box_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id),
  CONSTRAINT fk_box_immeuble FOREIGN KEY (immeuble_id) REFERENCES public.immeubles(id)
);
CREATE TABLE public.categories (
  id bigint NOT NULL DEFAULT nextval('categories_id_seq'::regclass),
  nom character varying NOT NULL,
  description text,
  type USER-DEFINED NOT NULL,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.demandes_inscription (
  id integer NOT NULL DEFAULT nextval('demandes_inscription_id_seq'::regclass),
  nom text NOT NULL,
  prenom text NOT NULL,
  email text NOT NULL,
  telephone text,
  password text NOT NULL,
  statut text DEFAULT 'en_attente'::text,
  motif_refus text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT demandes_inscription_pkey PRIMARY KEY (id)
);
CREATE TABLE public.depenses (
  id bigint NOT NULL DEFAULT nextval('depenses_id_seq'::regclass),
  montant numeric NOT NULL,
  categorie_id bigint,
  residence_id bigint NOT NULL,
  syndic_general_id bigint,
  inter_syndic_id bigint,
  tranche_id bigint,
  immeuble_id bigint,
  personnel_id bigint,
  date date NOT NULL,
  annee integer NOT NULL,
  mois smallint,
  facture_path character varying,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  description text,
  CONSTRAINT depenses_pkey PRIMARY KEY (id),
  CONSTRAINT fk_depense_categorie FOREIGN KEY (categorie_id) REFERENCES public.categories(id),
  CONSTRAINT fk_depense_residence FOREIGN KEY (residence_id) REFERENCES public.residences(id),
  CONSTRAINT fk_depense_syndic_general FOREIGN KEY (syndic_general_id) REFERENCES public.users(id),
  CONSTRAINT fk_depense_inter_syndic FOREIGN KEY (inter_syndic_id) REFERENCES public.users(id),
  CONSTRAINT fk_depense_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id),
  CONSTRAINT fk_depense_immeuble FOREIGN KEY (immeuble_id) REFERENCES public.immeubles(id),
  CONSTRAINT fk_depense_personnel FOREIGN KEY (personnel_id) REFERENCES public.personnel(id)
);
CREATE TABLE public.finances_summary (
  id bigint NOT NULL DEFAULT nextval('finances_summary_id_seq'::regclass),
  tranche_id bigint NOT NULL UNIQUE,
  revenus_charges numeric NOT NULL DEFAULT 0.00,
  revenus_parkings numeric NOT NULL DEFAULT 0.00,
  revenus_garages numeric NOT NULL DEFAULT 0.00,
  revenus_boxes numeric NOT NULL DEFAULT 0.00,
  revenus_total numeric NOT NULL DEFAULT 0.00,
  depenses_personnel numeric NOT NULL DEFAULT 0.00,
  depenses_entretien numeric NOT NULL DEFAULT 0.00,
  depenses_total numeric NOT NULL DEFAULT 0.00,
  solde numeric NOT NULL DEFAULT 0.00,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT finances_summary_pkey PRIMARY KEY (id),
  CONSTRAINT fk_finances_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id)
);
CREATE TABLE public.garages (
  id bigint NOT NULL DEFAULT nextval('garages_id_seq'::regclass),
  numero character varying NOT NULL,
  residence_id bigint NOT NULL,
  tranche_id bigint NOT NULL,
  prix_annuel numeric NOT NULL DEFAULT 0.00,
  surface numeric,
  statut USER-DEFINED NOT NULL DEFAULT 'disponible'::statut_espace_enum,
  beneficiaire_id bigint,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT garages_pkey PRIMARY KEY (id),
  CONSTRAINT fk_garage_residence FOREIGN KEY (residence_id) REFERENCES public.residences(id),
  CONSTRAINT fk_garage_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id),
  CONSTRAINT fk_garage_beneficiaire FOREIGN KEY (beneficiaire_id) REFERENCES public.beneficiaires(id)
);
CREATE TABLE public.historique_affectations (
  id bigint NOT NULL DEFAULT nextval('historique_affectations_id_seq'::regclass),
  tranche_id bigint NOT NULL,
  inter_syndic_id bigint NOT NULL,
  date_debut date NOT NULL DEFAULT CURRENT_DATE,
  date_fin date,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT historique_affectations_pkey PRIMARY KEY (id),
  CONSTRAINT fk_hist_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id),
  CONSTRAINT fk_hist_syndic FOREIGN KEY (inter_syndic_id) REFERENCES public.users(id)
);
CREATE TABLE public.historique_paiements (
  id bigint NOT NULL DEFAULT nextval('historique_paiements_id_seq'::regclass),
  resident_id bigint NOT NULL,
  paiement_id bigint,
  montant numeric NOT NULL,
  date date NOT NULL,
  type USER-DEFINED NOT NULL,
  description text,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT historique_paiements_pkey PRIMARY KEY (id),
  CONSTRAINT fk_historique_resident FOREIGN KEY (resident_id) REFERENCES public.users(id),
  CONSTRAINT fk_historique_paiement FOREIGN KEY (paiement_id) REFERENCES public.paiements(id)
);
CREATE TABLE public.immeubles (
  id bigint NOT NULL DEFAULT nextval('immeubles_id_seq'::regclass),
  nom character varying NOT NULL,
  adresse character varying,
  tranche_id bigint NOT NULL,
  nombre_appartements integer NOT NULL DEFAULT 0,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT immeubles_pkey PRIMARY KEY (id),
  CONSTRAINT fk_immeuble_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id)
);
CREATE TABLE public.liens_syndics (
  id bigint NOT NULL DEFAULT nextval('liens_syndics_id_seq'::regclass),
  syndic_general_id bigint,
  inter_syndic_id bigint,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  residence_id bigint,
  CONSTRAINT liens_syndics_pkey PRIMARY KEY (id),
  CONSTRAINT liens_syndics_syndic_general_id_fkey FOREIGN KEY (syndic_general_id) REFERENCES public.users(id),
  CONSTRAINT liens_syndics_inter_syndic_id_fkey FOREIGN KEY (inter_syndic_id) REFERENCES public.users(id),
  CONSTRAINT liens_syndics_residence_id_fkey FOREIGN KEY (residence_id) REFERENCES public.residences(id)
);
CREATE TABLE public.notifications (
  id bigint NOT NULL DEFAULT nextval('notifications_id_seq'::regclass),
  user_id bigint NOT NULL,
  titre character varying NOT NULL,
  message text NOT NULL,
  type USER-DEFINED NOT NULL,
  lu boolean NOT NULL DEFAULT false,
  annonce_id bigint,
  reunion_id bigint,
  paiement_id bigint,
  reclamation_id bigint,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT fk_notif_annonce FOREIGN KEY (annonce_id) REFERENCES public.annonces(id),
  CONSTRAINT fk_notif_reunion FOREIGN KEY (reunion_id) REFERENCES public.reunions(id),
  CONSTRAINT fk_notif_paiement FOREIGN KEY (paiement_id) REFERENCES public.paiements(id),
  CONSTRAINT fk_notif_reclamation FOREIGN KEY (reclamation_id) REFERENCES public.reclamations(id)
);
CREATE TABLE public.paiements (
  id bigint NOT NULL DEFAULT nextval('paiements_id_seq'::regclass),
  appartement_id bigint NOT NULL,
  inter_syndic_id bigint NOT NULL,
  montant_total numeric NOT NULL,
  montant_paye numeric NOT NULL DEFAULT 0.00,
  type_paiement USER-DEFINED NOT NULL,
  date_paiement date,
  statut USER-DEFINED NOT NULL DEFAULT 'impaye'::statut_paiement_enum,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  resident_id bigint,
  residence_id bigint,
  annee integer,
  mois integer,
  mandat_id bigint,
  CONSTRAINT paiements_pkey PRIMARY KEY (id),
  CONSTRAINT fk_paiement_appartement FOREIGN KEY (appartement_id) REFERENCES public.appartements(id),
  CONSTRAINT fk_paiement_intersyndic FOREIGN KEY (inter_syndic_id) REFERENCES public.users(id),
  CONSTRAINT paiements_resident_id_fkey FOREIGN KEY (resident_id) REFERENCES public.users(id),
  CONSTRAINT paiements_residence_id_fkey FOREIGN KEY (residence_id) REFERENCES public.residences(id),
  CONSTRAINT paiements_mandat_id_fkey FOREIGN KEY (mandat_id) REFERENCES public.historique_affectations(id)
);
CREATE TABLE public.parkings (
  id bigint NOT NULL DEFAULT nextval('parkings_id_seq'::regclass),
  numero character varying NOT NULL,
  residence_id bigint NOT NULL,
  tranche_id bigint,
  prix_annuel numeric NOT NULL DEFAULT 0.00,
  statut USER-DEFINED NOT NULL DEFAULT 'disponible'::statut_espace_enum,
  beneficiaire_id bigint,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT parkings_pkey PRIMARY KEY (id),
  CONSTRAINT fk_parking_residence FOREIGN KEY (residence_id) REFERENCES public.residences(id),
  CONSTRAINT fk_parking_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id),
  CONSTRAINT fk_parking_beneficiaire FOREIGN KEY (beneficiaire_id) REFERENCES public.beneficiaires(id)
);
CREATE TABLE public.personnel (
  id bigint NOT NULL DEFAULT nextval('personnel_id_seq'::regclass),
  nom character varying NOT NULL,
  prenom character varying NOT NULL,
  telephone character varying,
  type USER-DEFINED NOT NULL,
  residence_id bigint NOT NULL,
  tranche_id bigint,
  salaire_annuel numeric NOT NULL DEFAULT 0.00,
  statut USER-DEFINED NOT NULL DEFAULT 'actif'::statut_personnel_enum,
  date_embauche date,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT personnel_pkey PRIMARY KEY (id),
  CONSTRAINT fk_personnel_residence FOREIGN KEY (residence_id) REFERENCES public.residences(id),
  CONSTRAINT fk_personnel_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id)
);
CREATE TABLE public.reclamations (
  id bigint NOT NULL DEFAULT nextval('reclamations_id_seq'::regclass),
  titre character varying NOT NULL,
  description text NOT NULL,
  resident_id bigint NOT NULL,
  inter_syndic_id bigint,
  tranche_id bigint,
  statut USER-DEFINED NOT NULL DEFAULT 'en_cours'::statut_reclam_enum,
  document_path character varying,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT reclamations_pkey PRIMARY KEY (id),
  CONSTRAINT fk_reclam_resident FOREIGN KEY (resident_id) REFERENCES public.users(id),
  CONSTRAINT fk_reclam_inter_syndic FOREIGN KEY (inter_syndic_id) REFERENCES public.users(id),
  CONSTRAINT fk_reclam_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id)
);
CREATE TABLE public.residences (
  id bigint NOT NULL DEFAULT nextval('residences_id_seq'::regclass),
  nom character varying NOT NULL,
  adresse text NOT NULL,
  nombre_tranches integer NOT NULL DEFAULT 0,
  syndic_general_id bigint NOT NULL,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT residences_pkey PRIMARY KEY (id),
  CONSTRAINT fk_residence_syndic_general FOREIGN KEY (syndic_general_id) REFERENCES public.users(id)
);
CREATE TABLE public.residents (
  id bigint NOT NULL DEFAULT nextval('residents_id_seq'::regclass),
  user_id bigint NOT NULL UNIQUE,
  appartement_id bigint,
  type USER-DEFINED NOT NULL,
  date_arrivee date,
  statut USER-DEFINED NOT NULL DEFAULT 'actif'::statut_user_enum,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT residents_pkey PRIMARY KEY (id),
  CONSTRAINT fk_resident_user FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT fk_resident_appartement FOREIGN KEY (appartement_id) REFERENCES public.appartements(id)
);
CREATE TABLE public.reunion_resident (
  id bigint NOT NULL DEFAULT nextval('reunion_resident_id_seq'::regclass),
  reunion_id bigint NOT NULL,
  resident_id bigint NOT NULL,
  confirmation USER-DEFINED NOT NULL DEFAULT 'en_attente'::confirmation_enum,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT reunion_resident_pkey PRIMARY KEY (id),
  CONSTRAINT fk_rr_reunion FOREIGN KEY (reunion_id) REFERENCES public.reunions(id),
  CONSTRAINT fk_rr_resident FOREIGN KEY (resident_id) REFERENCES public.users(id)
);
CREATE TABLE public.reunions (
  id bigint NOT NULL DEFAULT nextval('reunions_id_seq'::regclass),
  titre character varying NOT NULL,
  description text,
  date date NOT NULL,
  heure time without time zone NOT NULL,
  lieu character varying NOT NULL,
  tranche_id bigint,
  inter_syndic_id bigint NOT NULL,
  statut USER-DEFINED NOT NULL DEFAULT 'planifiee'::statut_reunion_enum,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT reunions_pkey PRIMARY KEY (id),
  CONSTRAINT fk_reunion_tranche FOREIGN KEY (tranche_id) REFERENCES public.tranches(id),
  CONSTRAINT fk_reunion_inter_syndic FOREIGN KEY (inter_syndic_id) REFERENCES public.users(id)
);
CREATE TABLE public.tranches (
  id bigint NOT NULL DEFAULT nextval('tranches_id_seq'::regclass),
  nom character varying NOT NULL,
  description text,
  residence_id bigint NOT NULL,
  inter_syndic_id bigint,
  nombre_immeubles integer NOT NULL DEFAULT 0,
  nombre_appartements integer NOT NULL DEFAULT 0,
  nombre_parkings integer NOT NULL DEFAULT 0,
  nombre_garages integer NOT NULL DEFAULT 0,
  nombre_boxes integer NOT NULL DEFAULT 0,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  prix_annuel double precision CHECK (prix_annuel > 0.0::double precision),
  statut USER-DEFINED,
  CONSTRAINT tranches_pkey PRIMARY KEY (id),
  CONSTRAINT fk_tranche_residence FOREIGN KEY (residence_id) REFERENCES public.residences(id),
  CONSTRAINT fk_tranche_inter_syndic FOREIGN KEY (inter_syndic_id) REFERENCES public.users(id)
);
CREATE TABLE public.users (
  id bigint NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  nom character varying NOT NULL,
  prenom character varying NOT NULL,
  email character varying NOT NULL UNIQUE,
  password character varying NOT NULL,
  telephone character varying,
  role USER-DEFINED NOT NULL,
  statut USER-DEFINED NOT NULL DEFAULT 'actif'::statut_user_enum,
  remember_token character varying,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT users_pkey PRIMARY KEY (id)
);