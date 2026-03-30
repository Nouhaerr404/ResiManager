# 🚀 ResiManager : Guide d'Installation et Guide de Production

Ce guide est divisé en deux parties : une pour l'utilisateur final (installation simple) et une pour le gestionnaire/développeur (mise en production).

---

## 🛠️ Partie 1 : Guide de Mise en Production (Pour le Développeur)
*À réaliser avant de distribuer l'application.*

### 1. Préparation du Backend (Supabase)
L'application utilise Supabase comme moteur de base de données.
- **Migration SQL** : Importez le contenu du fichier `ResiManager.sql` local dans l'onglet **SQL Editor** de votre projet Supabase de production pour recréer la structure identique.
- **Politiques de Sécurité (RLS)** : Activez le RLS sur toutes les tables pour que les résidents ne puissent pas modifier les données financières, par exemple.
- **Authentification** : Configurez les méthodes de connexion (Email/Pass) dans l'onglet **Auth** de Supabase.

### 2. Configuration Finale du Code
- Ouvrez le fichier `lib/config/supabase_config.dart`.
- Remplacez `supabaseUrl` et `supabaseAnonKey` par les clés de votre projet Supabase de **Production**.
- Désactivez le bandeau "Debug" dans `lib/main.dart` (déjà fait normalement via `debugShowCheckedModeBanner: false`).

### 3. Génération des fichiers d'installation
Exécutez l'une de ces commandes dans votre terminal à la racine du projet :

- **Pour Android (Fichier .apk)** :
  ```powershell
  flutter build apk --release
  ```
  Le fichier se trouvera dans : `build/app/outputs/flutter-apk/app-release.apk`

- **Pour Windows (Fichier .exe)** :
  ```powershell
  flutter build windows --release
  ```
  Le dossier complet se trouvera dans : `build/windows/runner/Release`. Compressez ce dossier en **.zip** pour le distribuer.

---

## 📱 Partie 2 : Guide d'Installation (Pour l'Utilisateur Final)
*Suivez ces étapes pour installer l'application sur votre appareil.*

### ✅ Sur Smartphone (Android)
1. **Réception du fichier** : Téléchargez le fichier `resimanager.apk` sur votre téléphone.
2. **Autoriser l'installation** : 
   - Lors de l'ouverture du fichier, si un message d'alerte apparaît, cliquez sur **Paramètres**.
   - Activez l'option **"Autoriser à partir de cette source"** (ou "Sources inconnues").
3. **Installer** : Revenez en arrière et cliquez sur **Installer**.
4. **Lancer** : Une fois terminé, cherchez l'icône **ResiManager** sur votre écran d'accueil.

### ✅ Sur Ordinateur (Windows)
1. **Téléchargement** : Téléchargez le dossier compressé (ZIP) fourni par l'administrateur.
2. **Extraction** : 
   - Faites un clic droit sur le fichier ZIP.
   - Choisissez **Extraire tout...** puis cliquez sur **Extraire**.
3. **Lancement** :
   - Entrez dans le dossier extrait.
   - Cherchez le fichier nommé `resimanager.exe` (Type : Application).
   - **Double-cliquez** dessus pour lancer l'application.

---

## 🔑 Guide d'utilisation rapide
1. **Choix du Rôle** : Au premier lancement, choisissez si vous êtes un **Résident**, un **Syndic**, ou un **Administrateur**.
2. **Connexion** :
   - Utilisez l'email et le mot de passe qui vous ont été attribués.
   - Si vous n'avez pas d'identifiants, contactez votre administrateur de résidence.
3. **Navigation** : Utilisez le menu (icône ≡ en haut à gauche) pour naviguer entre la gestion des appartements, les finances et les tranches de résidence.

> [!TIP]
> **Important pour les résidents** : Assurez-vous d'avoir une connexion internet active pour que les informations financières soient synchronisées en temps réel avec le syndic.
