# Guide d'installation

Ce guide vous accompagne pour installer l'application sur Android ou iOS.

---

| Méthode | Appareil | Difficulté | Temps estimé |
| :--- | :--- | :--- | :--- |
| **Installation APK** | Android | Très facile | 2 minutes |
| **AltStore (.ipa)** | iOS | Modérée | 15 minutes |

---

## Installation via APK (méthode rapide)

*Si vous souhaitez tester l'application sans configurer un environnement de développement.*

1. Rendez-vous sur le dépôt GitHub : [ResiManager](https://github.com/Nouhaerr404/ResiManager) 
2. Téléchargez le fichier `app-release.apk` situé à la racine du projet.
3. Transférez et installez le fichier sur votre appareil Android.

---

## Android

### Étape 1 — Télécharger l’APK

Téléchargez le fichier `.apk` sur votre téléphone Android.

> Astuce : Si vous téléchargez depuis un lien, cliquez directement dessus dans votre navigateur. Le fichier apparaîtra dans le dossier **Téléchargements**.

---

### Étape 2 — Autoriser les sources inconnues

L'application n'étant pas installée via le Play Store, vous devez autoriser l’installation manuellement.

**Android 8 et versions supérieures :**

1. Ouvrez **Paramètres**
2. Allez dans **Applications** → **Accès spécial** → **Installer des applications inconnues**
3. Sélectionnez votre navigateur ou gestionnaire de fichiers
4. Activez **Autoriser depuis cette source**

**Anciennes versions Android :**

1. Ouvrez **Paramètres**
2. Allez dans **Sécurité**
3. Activez **Sources inconnues**

---

### Étape 3 — Installer l’APK

1. Ouvrez le dossier **Téléchargements**
2. Cliquez sur le fichier `.apk`
3. Cliquez sur **Installer**
4. Attendez la fin de l’installation
5. Cliquez sur **Ouvrir**

---

### Accès rapide et configuration

| Élément | Source / Détails |
| :--- | :--- |
| **Base de données** | Supabase (déjà configurée via `.env`) |
| **Schéma SQL** | Fichier `ResiManager.sql` à la racine |
| **Code Source** | [Dépôt GitHub](https://github.com/Nouhaerr404/ResiManager) |

---

### Résolution des problèmes (Android)

| Problème                   | Solution                                |
| -------------------------- | --------------------------------------- |
| Installation bloquée       | Vérifier l’étape 2                      |
| Application introuvable    | Chercher dans la liste des applications |
| Erreur d’analyse (Parsing) | Re-télécharger le fichier APK           |

---

## iOS

### Avant de commencer

iOS ne permet pas d’installer directement des fichiers APK. Vous devez utiliser **AltStore** avec un fichier `.ipa`.

**Prérequis pour iOS :**

| Composant | Description |
| :--- | :--- |
| **Matériel** | Ordinateur (Windows/Mac) + Câble USB |
| **Logiciels** | AltServer + iTunes & iCloud (si Windows) |
| **Fichiers** | Fichier `.ipa` de l'application |
| **Compte** | Identifiant Apple (Apple ID) |

---

### Étape 1 — Installer AltStore sur ordinateur

1. Aller sur [https://altstore.io](https://altstore.io)
2. Télécharger **AltServer**
3. Installer le logiciel

**Sur Windows :** installer également **iTunes** et **iCloud**

---

### Étape 2 — Installer AltStore sur iPhone

1. Connecter l’iPhone à l’ordinateur
2. Autoriser l’accès si demandé
3. Installer AltStore via AltServer
4. Saisir votre Apple ID

---

### Étape 3 — Autoriser l’application

1. Aller dans **Paramètres** → **Général** → **VPN et gestion de l’appareil**
2. Sélectionner votre Apple ID
3. Cliquer sur **Faire confiance**

---

### Étape 4 — Installer l’application

1. Copier le fichier `.ipa` sur l’iPhone
2. Ouvrir **AltStore**
3. Cliquer sur **+**
4. Sélectionner le fichier `.ipa`
5. Installer l’application

---

### Important (iOS)

Les applications installées avec AltStore expirent après **7 jours**.

Pour éviter cela :

1. Connecter l’iPhone au même réseau que l’ordinateur
2. Lancer AltServer
3. Ouvrir AltStore → **My Apps**
4. Cliquer sur **Refresh All**

---

### Résolution des problèmes (iOS)

| Problème                 | Solution                                    |
| ------------------------ | ------------------------------------------- |
| AltStore absent          | Redémarrer l’iPhone                         |
| Développeur non approuvé | Suivre l’étape 3                            |
| Application expirée      | Actualiser via AltStore                     |
| iPhone non détecté       | Vérifier câble, iTunes et iCloud            |
| Échec de l’installation  | Vérifier Apple ID et déverrouiller l’iPhone |

---

## Besoin d’aide

En cas de problème non couvert, envoyez une capture d’écran de l’erreur rencontrée.
