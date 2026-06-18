# DjoulaGest Mobile — CLAUDE.md

> CDC v1.0 — Mars 2026 | Groupe 1 | Deadline livraison : **20/06/2026** | Mis à jour : 18/06/2026 (session 2)

## ⛔ RÈGLE ABSOLUE — À lire avant toute action

> **Ne jamais modifier, créer ou supprimer un fichier sans autorisation explicite de l'utilisateur.**
> Rôle par défaut : lire, analyser, rapporter. Attendre un "vas-y", "corrige", "fixe" ou "applique" explicite avant tout Edit/Write.

## État d'avancement (17/06/2026)

### ✅ Terminé

| Couche | Ce qui est fait |
|--------|----------------|
| **App Shell** | `AppScaffold`, `BottomNavBar`, `AppDrawer`, navigation par rôle, bannière simulation |
| **Core** | `ApiClient` (Dio + JWT interceptor), `SecureStorage`, `LocalStorage`, `AppTheme`, `AppColors`, `AppSizes`, `AppTextStyles`, `AppValidators`, `AppFormatters`, `GoRouter`, `AppRoutes` |
| **Shared Widgets** | `AppButton`, `AppTextField`, `AppSnackbar`, `AppLoader`, `ConfirmDialog` |
| **Onboarding** | Écran 3 pages, stockage `onboardingDone` |
| **Auth — Login** | Écran connexion, `AuthNotifier`, `authRepositoryImpl`, interceptor JWT refresh |
| **Auth — Mot de passe oublié** | `ForgotPasswordScreen` (formulaire + état succès) |
| **Auth — Réinitialisation** | `ResetPasswordScreen` (token via query param ou saisie manuelle) |
| **Auth — Premier login** | `FirstLoginScreen` (token pré-rempli via query param ou saisie) |
| **Profil** | `ProfileScreen` : carte utilisateur (avatar, nom, email, badge rôle), changement mot de passe (accordion), déconnexion |
| **Simulation de rôle** | Admin uniquement (`canSimulateProvider`), bannière amber, `simulatorUsersProvider`, retour rôle réel |
| **Admin — Entreprises** | `AdminScreen` : liste paginée (infinite scroll), recherche (debounce 400ms), `CompanyFormSheet` (créer/éditer), toggle actif/suspendu, CRUD complet via `CompaniesNotifier` |
| **Dashboard** | `DashboardScreen` : 7 rôles (superadmin/admin/stock/caissier/chauffeur/maintenancier/commercial), KPI grid 2 col, shortcuts 3 col, skeleton loading, alertes, retry — `DashboardDataEntity`, `KpiEntity`, `AlertEntity`, `kpi_card.dart` |
| **Finance — Sessions caisse** | `CashSessionScreen` : session active (gradient card), historique paginé, `_OpenSessionDialog`, `_CloseSessionSheet` avec écart live + motif obligatoire — `FinanceNotifier`, `CashSessionEntity`, `TransactionEntity` |
| **Finance — Transactions** | `TransactionsScreen` : résumé session (solde calculé, entrées/sorties), liste transactions, `_AddTransactionSheet` (type toggle, montant, description) |
| **Inventory — Stocks** | `StockScreen` : recherche live, filtre "En alerte", tuiles couleur-codées (rouge si `enAlerte`), infinite scroll, refresh — `InventoryNotifier`, `StockEntity`, `StockModel` |
| **Inventory — Mouvements** | `MovementsScreen` : filtres type (tous/entrée/sortie/transfert/ajustement), tuiles avec badge type coloré, signe +/−, infinite scroll — `MovementsNotifier`, `MovementEntity`, `MovementModel` |
| **Inventory — Scanner** | `BarcodeScanScreen` : placeholder "coming soon" (fonctionnalité différée) |
| **Inventory — Transferts** | `TransferScreen` : liste transferts inter-dépôts, filtre statut, FAB "Nouveau transfert" (admin/gestionnaire_stock), formulaire avec lignes dynamiques (dépôt source/destination, produits, quantités) — `createTransfert` chaîne complète |
| **Inventory — Ajustements** | `AjustementsScreen` : liste paginée, filtres statut, FAB "Demander un ajustement" (admin/gestionnaire_stock), boutons Approuver/Refuser avec dialog motif (admin/superviseur) — `AjustementEntity`, `AjustementsNotifier`, chaîne complète |
| **Notifications** | `NotificationsScreen` : liste paginée, badge non-lus, "Tout lire", tap → markAsRead (optimiste) — `NotificationsNotifier`, `NotificationEntity`, `NotificationModel`, datasource + repo impl |
| **RH — Employés** | `EmployeesScreen` : liste paginée, recherche, filtre statut (actifs/inactifs/en congé), avatar initiales, badge statut — `HrNotifier`, `EmployeeEntity`, `EmployeeModel`, datasource + repo impl |
| **Logistique — Missions** | `MissionsScreen` : liste avec filtre statut (incl. `chargement_en_cours`), FAB "Créer une mission" (admin/superviseur/gestionnaire_stock), formulaire (véhicule/chauffeur/dépôts) — `createMission` chaîne complète, `vehiculesSimpleProvider`, `chauffeursSimpleProvider` |
| **Logistique — Détail mission** | `MissionDetailScreen` : sections trajet/ressources/dates/marchandises/notes/litige, boutons action chauffeur (chargement → transit → arrivée) avec confirmation — `missionDetailProvider` |
| **Logistique — QR Scan** | `QrScanScreen` : placeholder "coming soon" (nécessite `mobile_scanner`) |
| **Ventes — Liste** | `SalesListScreen` : liste commandes, filtre statut (en cours/livrée/annulée), montant TTC, reste à payer — `SalesNotifier`, `SaleEntity`, `SaleModel`, datasource + repo impl |
| **Ventes — Clients** | `ClientsScreen` : liste clients, recherche live, avatar initiales, points fidélité, solde crédit — `ClientsNotifier`, `ClientEntity`, `ClientModel` |
| **Ventes — Nouvelle vente** | `NewSaleScreen` : sélecteur client (modal), ajout produits (modal recherche), gestion quantités, mode paiement (4 modes), remise, récapitulatif live, `createSale()` — `productsSearchProvider` |
| **Router** | Toutes les routes câblées. `_PlaceholderScreen` supprimé — plus aucun placeholder. |
| **Produits — Liste** | `ProductsListScreen` : recherche live, infinite scroll, `ProductCard` (référence, catégorie, prix vente, badge périmable) — `ProductsNotifier`, `ProductEntity`, `ProductModel`, datasource + repo impl |
| **Produits — Détail** | `ProductDetailScreen` : en-tête gradient, bloc Prix (achat/vente/marge), infos (catégorie, unité, fournisseur, TVA), seuils, description, dates — `productDetailProvider` |
| **RH — Présences & Congés** | `AttendanceScreen` : onglets Présences/Congés, liste paginée, filtres statut, formulaires d'ajout (date picker, type), boutons Approuver/Refuser (admin/superviseur) — `PresenceEntity`, `CongeEntity`, `PresencesNotifier`, `CongesNotifier` |
| **Fournisseurs** | `SuppliersScreen` : liste paginée, recherche live, badge dette, FAB "Ajouter" (gestionnaire_stock/admin) — `SupplierDetailScreen` : en-tête gradient, coordonnées, commandes récentes, évaluations étoiles — Clean Arch complète : entity/model/datasource/repo/provider |
| **Finance — Dépenses** | `DepensesScreen` : filtres catégorie (carburant/maintenance/salaires…), liste paginée, FAB "Ajouter" (caissier/admin), formulaire avec date picker — `DepenseEntity` inline |
| **Finance — Mobile Money** | `MobileMoneyScreen` : liste comptes Orange/MTN avec solde coloré, `_CompteDetailSheet` : historique transactions + toggle Entrée/Sortie, formulaire transaction avec référence opérateur obligatoire |
| **CRUD boutons rôle-conditionnel** | FAB "Créer un employé" (admin/superadmin) dans `EmployeesScreen` → `POST /users/` (email, prénom, nom, téléphone, **rôle dropdown**, **dépôt dropdown**, mot de passe) • FAB "Ajouter un produit" (gestionnaire_stock/admin) dans `ProductsListScreen` + formulaire • FAB "Ajouter un client" (commercial/caissier/admin) dans `ClientsScreen` + formulaire |
| **EmployeesScreen → /users/** | Écran réécrit : liste depuis `GET /users/` (employees = utilisateurs système), avatar coloré par rôle, badge rôle, email + dépôt affiché. Création via `POST /users/` avec tous les champs. `hrProvider` (employes RH) conservé pour AttendanceScreen. |
| **Drawer mis à jour** | Fournisseurs, Dépenses, Mobile Money ajoutés dans les menus admin/superviseur/caissier/gestionnaire_stock |
| **Auth — 2FA** | `TwoFactorScreen` (6 boîtes OTP, resend 60s), `TwoFactorSetupScreen` (choix méthode → QR/email → vérification), `_TwoFactorCard` dans `ProfileScreen` (activer/désactiver), router redirige auto vers `/two-factor` si 2FA pending — `twoFactorPendingProvider`, `TwoFactorPending`, `TwoFactorRequiredException` |

### 🔲 Fonctionnalités différées (hors scope deadline)

| Feature | Raison |
|---------|--------|
| **Signature numérique** | Implémentée (16/06) — `SignatureScreen` avec package `signature` |
| **QR scan réel logistique** | Implémenté (16/06) — `QrScanScreen` avec `mobile_scanner` |
| **Scanner code-barres stock** | Implémenté (16/06) — `BarcodeScanScreen` avec `mobile_scanner` |
| **GPS tracking missions** | Implémenté (16/06) — `GpsService` + Timer 60s dans `MissionDetailScreen` |
| **Génération PDF** | Implémentée (16/06) — `PdfService` avec package `pdf` + `open_filex` |
| **Bandeau offline** | Implémenté (16/06) — `_OfflineBanner` dans `AppScaffold` |
| **Devis & Retours ventes** | Route `/sales/devis` définie, écrans non implémentés |

### ⚠️ Fonctionnalités différées

| Feature | Raison |
|---------|--------|
| **Deep linking** (`/reset-password?token=`, `/first-login?token=`) | Nécessite configuration app scheme Android/iOS — déprioritisé par l'équipe |
| **First login auto-connexion** | Après `firstLogin()`, l'user doit se reconnecter manuellement (la réponse contient `access`+`refresh` mais on redirige vers `/login` pour simplifier) |

---

## 📋 Règle de mise à jour — À faire après chaque session de travail

> **Après chaque implémentation de feature, correction de bug ou fin de prompt, mettre à jour la section "État d'avancement" ci-dessus.**

- Déplacer les items terminés de 🔲 vers ✅ avec la date
- Ajouter les bugs corrigés dans la section correspondante des règles
- Documenter toute décision technique importante
- **Ne jamais laisser le CLAUDE.md désynchronisé avec le code réel** — c'est la première chose qu'un agent lit au début d'une session

---

## ⚠️ Règle fondamentale — Backend déployé, source de vérité absolue

> **Le backend Django (`back_fac`) est déjà déployé en production sur `https://gestion.kingreys.fr/api`. C'est lui la source de vérité. Cette app mobile doit s'adapter au backend, jamais l'inverse.**

### Ce que cela signifie concrètement

1. **Ne jamais modifier le backend pour accommoder le mobile.** Si un champ s'appelle `password_confirm` côté backend, le mobile envoie `password_confirm` — pas `confirmPassword`, pas `confirm_password`, exactement ce que le backend attend.

2. **Avant tout appel API — vérifier le backend en premier.** Avant d'implémenter une datasource ou un modèle, consulter dans cet ordre :
   - Le serializer Django correspondant (`back_fac/apps/.../serializers*.py`) → noms exacts des champs request/response
   - La view Django (`back_fac/apps/.../views*.py`) → méthode HTTP, URL, logique de validation
   - Le Swagger : `https://gestion.kingreys.fr/api/schema/docs/`
   - **Ne jamais deviner un nom de champ.** Un écart = erreur 400 silencieuse difficile à déboguer.

3. **Exceptions (cas où on peut demander une modif backend) :** uniquement si le backend a un bug avéré, une donnée manquante indispensable, ou un endpoint absent du tout. Dans ce cas, coordonner avec l'équipe backend et documenter ici.

### Auth flow corrigé (source de vérité — 15/06/2026)

```
POST /auth/login/                body: {email, password}
                                 ← {access, refresh, user: {id, email, first_name, last_name, role, company_id, depot_id, avatar}}
POST /auth/refresh/              body: {refresh}
                                 ← {access, refresh}
POST /auth/logout/               body: {refresh}   ← OBLIGATOIRE, ne pas omettre
GET  /auth/me/                   ← user object (format DRF direct)
POST /auth/first-login/          body: {token, password, password_confirm}
                                 ← {success, data: {access, refresh, user: {...}}, message}
POST /auth/password-reset/       body: {email}
POST /auth/password-reset/confirm/  body: {token, new_password, new_password_confirm}
```

### 2FA flow (17/06/2026)

```
── Connexion avec 2FA ──────────────────────────────────────────────────────────
POST /auth/login/                body: {email, password}
                                 ← {requires_2fa: true, temp_token, method, message}
                                    → TwoFactorRequiredException lancée dans AuthRepositoryImpl
                                    → twoFactorPendingProvider renseigné
                                    → Router redirige vers /two-factor

POST /auth/2fa/login-verify/     body: {temp_token, code}
                                 ← {access, refresh, user}
                                    → JWT sauvegardés, authProvider mis à jour
                                    → Router redirige vers /dashboard

POST /auth/2fa/resend/           body: {temp_token}   (méthode email uniquement)

── Configuration 2FA (depuis /profile) ─────────────────────────────────────────
POST /auth/2fa/setup/            body: {method: 'totp'|'email'}
                                 ← totp: {qr_code: 'data:image/png;base64,...', secret}
                                 ← email: {message}

POST /auth/2fa/setup-verify/     body: {method, code}
                                 → active two_factor_enabled + two_factor_method sur le user

POST /auth/2fa/disable/          body: {password}
                                 → efface totp_secret, remet two_factor_enabled=False
```

**Champs UserEntity/UserModel ajoutés :** `twoFactorEnabled` (bool), `twoFactorMethod` (String?)

### Corrections permissions superadmin (17/06/2026) — Audit skill gestion-multisites

**Problème :** Le superadmin pouvait naviguer vers Zones, Dépôts et Utilisateurs via le nav/drawer mobile, et le backend lui retournait les données (violation du CDC : le superadmin gère la plateforme SaaS, pas les opérations internes des entreprises).

**Root cause backend :** `HasRole.has_permission()` bypassait automatiquement le superadmin (`if user.is_superadmin: return True`), lui donnant accès à tous les endpoints opérationnels.

| Fichier | Anomalie | Correction |
|---------|----------|------------|
| `bottom_nav_bar.dart` — section `superadmin` | "Utilisateurs" (`AppRoutes.hr`) dans la nav | Retiré — périmètre admin d'entreprise, pas superadmin |
| `app_drawer.dart` — section `superadmin` | "Utilisateurs" dans "Plateforme SaaS" | Retiré |
| `app_drawer.dart` — section `superadmin` | Section "Configuration" avec Zones + Dépôts | Retirée — périmètre admin d'entreprise |

### Corrections spec fonctionnelle (17/06/2026) — Audit skill gestion-multisites

| Fichier | Anomalie | Correction |
|---------|----------|------------|
| `mobile_money_screen.dart` | `reference_operateur` optionnel — envoyé conditionnellement | Validator obligatoire + envoi systématique (règle universelle anti-fraude) |
| `app_drawer.dart` — section `gestionnaire_stock` | Logistique absente du menu (gestionnaire peut créer des missions) | Ajout section "Logistique" avec lien Missions |
| `app_drawer.dart` — section `gestionnaire_stock` | Ajustements absents | Ajout lien "Ajustements stock" |
| `app_drawer.dart` — sections `admin` + `superviseur` | Transferts et ajustements absents | Ajout liens Transferts inter-dépôts + Ajustements stock |
| `missions_screen.dart` | Filtre `chargement_en_cours` manquant (statut backend existant) | Ajout du tuple `('Chargement', 'chargement_en_cours')` dans `_filters` |
| `missions_screen.dart` | Pas de FAB pour créer une mission (admin/superviseur/gestionnaire_stock peuvent créer) | FAB + `_CreateMissionSheet` (véhicule, chauffeur, dépôts, notes) |
| `transfer_screen.dart` | Pas de FAB pour créer un transfert (admin/gestionnaire_stock peuvent créer) | FAB + `_CreateTransfertSheet` avec lignes dynamiques (produit + quantité) |
| `CLAUDE.md` §3.9 | "responsable logistique" — rôle inexistant dans le système | Corrigé en "gestionnaire_stock" |
| Nouveau : `ajustements_screen.dart` | Écran manquant — workflow ajustement (demander → approuver/refuser) non implémenté | Créé : liste paginée, filtres, FAB demande (gestionnaire_stock/admin), boutons approuver/refuser (admin/superviseur) |

### Bugs corrigés (18/06/2026) — Audit YAML systématique (session 2)

| Fichier | Bug | Correction |
|---------|-----|------------|
| `sales_list_screen.dart` | `GestureDetector` non fermé autour du `Container` de `_SaleTile` | Ajout `)` manquant + correction indentation |
| `sales_list_screen.dart` | `_showSaleActions` référencé mais non défini | Ajout fonction top-level + `_SaleActionsSheet` (payer/annuler, role-gated) |
| `logistics_sub_screens.dart` | `date_planifiee` requise (`MaintenanceRequest`) mais champ sans validator et envoi conditionnel | Validator + envoi systématique |
| `products_list_screen.dart` | `reference` requise (`ProduitDetailRequest`) mais envoyée conditionnellement | Validator + envoi systématique |
| `zones_screen.dart` | `code` requis (`ZoneCreateUpdateRequest`) mais sans validator dans le formulaire | Validator + envoi systématique |
| `zones_provider.dart` | `code` paramètre `String?` nullable → peut être omis | Changé en `required String code` |
| `zones_remote_datasource.dart` | `code` paramètre `String?` nullable → peut être omis | Changé en `required String code` |
| `zone_model.dart` | `toJson` envoyait `code` conditionnellement (`if code != null && isNotEmpty`) | Toujours inclure `code` |

### Bugs corrigés (17/06/2026) — Module Finance (audit cross-platform)

| Fichier | Bug | Correction |
|---------|-----|------------|
| `cash_session_model.dart` `fromJson` | Lisait `date_ouverture` → champ inexistant | → `ouvert_le` |
| `cash_session_model.dart` `fromJson` | Lisait `date_fermeture` → champ inexistant | → `ferme_le` |
| `cash_session_model.dart` `fromJson` | Lisait `solde_fermeture` → champ inexistant | → `solde_fermeture_theorique` |
| `cash_session_model.dart` `fromJson` | Lisait `solde_reel` comme solde fermeture réel | → `solde_fermeture_reel` |
| `transaction_model.dart` `fromJson` | Lisait `json['type']` → champ inexistant | → `json['type_transaction']` |
| `transaction_model.dart` `fromJson` | Lisait `json['reference']` → champ inexistant | → `json['reference_doc']` |
| `finance_remote_datasource.dart` `openSession` | N'envoyait pas `caisse` (ID requis par `OuvrirSessionSerializer`) | Ajout lookup `getCaisseIdForDepot(depotId)` + envoi `{caisse, solde_ouverture}` |
| `finance_remote_datasource.dart` `closeSession` | Envoyait `solde_fermeture` → champ inexistant | → `solde_reel` (champ exact de `FermerSessionSerializer`) |
| `finance_remote_datasource.dart` `addTransaction` | Envoyait `type` → champ inexistant | → `type_transaction` |
| `finance_remote_datasource.dart` `getSessions` | Paramètre `ordering: '-date_ouverture'` incohérent | → `'-ouvert_le'` (nom du champ réel) |
| `finance_provider.dart` `openSession` | N'avait pas `caisseId` en paramètre → erreur compilation | Réécrit : lit `depotId` depuis `authProvider`, résout `caisseId` via `getCaisseIdForDepot` |
| `finance_repository.dart` | Interface manquait `getCaisseIdForDepot` et signature `openSession` incorrecte | Ajout méthode + mise à jour signature |
| `finance_repository_impl.dart` | Implémentation manquante pour les nouvelles méthodes | Délégation vers datasource |

#### Flow `openSession` corrigé (source de vérité)
```
1. Lire depotId depuis authProvider.valueOrNull?.depotId
2. GET /caisses/?depot={depotId}&page_size=1 → extraire results[0]['id']
3. POST /sessions-caisse/ouvrir/ body: {caisse: caisseId, solde_ouverture: x}
```

### Bugs corrigés (16/06/2026) — Zones & Dépôts

| Fichier | Bug | Correction |
|---------|-----|------------|
| `zone_model.dart` `fromJson` | Lisait `nombre_depots` → champ inexistant côté backend | → `depot_count` (champ réel du `ZoneListSerializer`) |
| `zone_model.dart` `toJson` | Envoyait `'nom': name` au lieu de `'name': name` | → `'name': name` |
| `zone_model.dart` `toJson` | Envoyait `'description': code` au lieu de `'code': code` | → `'code': code` |
| `zones_screen.dart` | Formulaire édition : `code: code.isEmpty ? null : name` (typo — envoyait le nom) | → `code: code.isEmpty ? null : code` |
| `depot_model.dart` `fromJson` | Lisait `json['nom']`, `json['adresse']`, `zone['nom']`, `json['zone_nom']` | → `json['name']`, `json['address']`, `zone['name']`, `json['zone_name']` |
| `depot_model.dart` `toJson` | Envoyait `'nom'`, `'zone'`, `'adresse'`, `'gestionnaire'` | → `'name'`, `'zone_id'`, `'address'`, `'gestionnaire_id'` (champs exacts du `DepotCreateUpdateSerializer`) |

### Bugs corrigés suite à l'audit (15/06/2026)

| Endpoint | Bug | Correction |
|----------|-----|------------|
| `POST /auth/logout/` | N'envoyait pas le `refresh` token dans le body → token non blacklisté | `auth_remote_datasource.dart` + `auth_repository_impl.dart` |
| `POST /auth/password-reset/confirm/` | Envoyait `uid` + `token` au lieu de `token` seul, manquait `new_password_confirm` | `auth_remote_datasource.dart`, repository, provider, screen |
| `POST /auth/first-login/` | Envoyait `new_password` au lieu de `password` + `password_confirm` | `auth_remote_datasource.dart`, repository, provider, screen |

---

## Contexte projet

DjoulaGest est un ERP multi-sites conçu pour les entreprises guinéennes (Guinée Conakry).
Problème résolu : entreprises qui gèrent leurs activités via des tableurs/registres papier disparates → erreurs, fraudes, manque de traçabilité.

Ce dépôt (`mobile_fac`) est l'application **Flutter** du projet. Elle partage :
- Le même **backend** : Django REST Framework déployé sur `https://gestion.kingreys.fr/api`
- Le même **design system** que le frontend Angular (`front_fac`)
- Le même **nom et logo** « DJ »

## Architecture générale

```
mobile_fac/
├── lib/
│   ├── core/               ← Infrastructure partagée
│   │   ├── constants/      ← AppColors, AppSizes, AppStrings
│   │   ├── di/             ← Providers Riverpod globaux (providers.dart)
│   │   ├── errors/         ← Failure sealed class, AppException hierarchy
│   │   ├── network/        ← Dio ApiClient, interceptors, ApiEndpoints
│   │   ├── router/         ← GoRouter + AppRoutes constants
│   │   ├── storage/        ← SecureStorage (JWT), LocalStorage (prefs)
│   │   ├── theme/          ← AppTheme (Material 3), AppTextStyles
│   │   └── utils/          ← AppFormatters, AppValidators, Extensions
│   ├── features/           ← Clean Architecture par feature
│   │   ├── auth/
│   │   ├── onboarding/
│   │   ├── dashboard/
│   │   ├── finance/
│   │   ├── hr/
│   │   ├── inventory/
│   │   ├── logistics/
│   │   ├── notifications/
│   │   ├── products/
│   │   ├── profile/
│   │   └── sales/
│   ├── shared/             ← Widgets réutilisables, layouts
│   │   ├── layout/         ← AppScaffold, AppDrawer, BottomNavBar
│   │   └── widgets/        ← AppButton, AppTextField, AppLoader, etc.
│   └── main.dart
```

## Clean Architecture (par feature)

```
feature/
├── data/
│   ├── datasources/    ← Appels API Dio
│   ├── models/         ← JSON serialization (fromJson/toEntity)
│   └── repositories/   ← Implémentation des interfaces domain
├── domain/
│   ├── entities/       ← Objets métier purs (Equatable)
│   ├── repositories/   ← Interfaces abstraites
│   └── usecases/       ← Une action = un usecase
└── presentation/
    ├── providers/      ← Riverpod AsyncNotifierProvider
    └── screens/        ← Widgets Flutter
```

## API Backend

**Base URL :** `https://gestion.kingreys.fr/api`  
**Swagger :** `https://gestion.kingreys.fr/api/schema/docs/`  
**Auth :** JWT Bearer token (SimpleJWT)

### Formats de réponse

- **Endpoints accounts/companies :** `{"success": bool, "data": T, "message": string}`
- **DRF standard (listes paginées) :** `{"count": int, "next": url|null, "previous": url|null, "results": [...]}`
- **Page size :** 25 items par défaut
- **Filtres :** `?search=xxx`, `?ordering=-created_at`, `?company_id=1`

### Auth flow

> ⚠️ Endpoints corrects — vérifiés contre `back_fac` le 15/06/2026. Voir aussi "Auth flow corrigé" plus haut.

```
POST /auth/login/                    body: {email, password}
                                     ← {success, data: {access, refresh, user}}
POST /auth/refresh/                  body: {refresh}
                                     ← {access, refresh}
POST /auth/logout/                   body: {refresh}  ← OBLIGATOIRE pour blacklister le token
GET  /auth/me/                       ← user object
POST /auth/first-login/              body: {token, password, password_confirm}
                                     ← {success, data: {access, refresh, user}, message}
POST /auth/password-reset/           body: {email}
POST /auth/password-reset/confirm/   body: {token, new_password, new_password_confirm}
```

### Tokens
- **access** : 60 min — stocké dans `flutter_secure_storage`
- **refresh** : rotation automatique à chaque usage
- **first_login_token** : créé par admin, valable une seule fois

## Design System

### Palette de couleurs (identique à front_fac)

| Nom | Hex | Usage |
|-----|-----|-------|
| primary | `#1A56A0` | Bleu institutionnel, boutons principaux |
| primaryLight | `#2563EB` | Variante claire |
| secondary | `#0E9F6E` | Vert validation, succès |
| accent | `#F59E0B` | Ambre, alertes, avertissements |
| danger | `#EF4444` | Rouge erreurs |
| backgroundLight | `#F4F6FA` | Fond général |
| surface | `#FFFFFF` | Cartes, modals |
| backgroundDark | `#0F1117` | Fond nuit |
| surfaceDark | `#1A1D27` | Cartes nuit |
| orangeMoney | `#F97316` | Badge Orange Money |
| mtnMoney | `#EAB308` | Badge MTN Money |

### Typographie — AppTextStyles
- `h1` → bold 28, `h2` → bold 24, `h3` → bold 20, `h4` → semibold 18
- `body` → regular 14, `bodyLarge` → regular 16
- `label` → medium 12
- `amount` → bold 24, monospace (pour les montants GNF)

## State Management — Riverpod 2.x

| Provider | Usage |
|----------|-------|
| `Provider` | Services sans état (ApiClient, Storage) |
| `FutureProvider` | Données async one-shot (profil, config) |
| `AsyncNotifierProvider` | État async avec actions (auth, listes) |
| `ChangeNotifierProvider` | RouterNotifier (GoRouter refresh) |

Règles :
- `ref.watch` dans `build()`, `ref.read` dans les callbacks
- Invalider les providers connexes après mutation : `ref.invalidate(isAuthenticatedProvider)`

## Navigation — GoRouter 14.x

Routes définies dans `core/router/app_routes.dart` et `core/router/app_router.dart`.

| Path | Description | Auth |
|------|-------------|------|
| `/onboarding` | 3 écrans d'intro (premier lancement) | Non |
| `/login` | Connexion | Non |
| `/forgot-password` | Mot de passe oublié | Non |
| `/reset-password` | Réinitialisation | Non |
| `/first-login` | Première connexion (token admin) | Non |
| `/dashboard` | KPIs personnalisés par rôle | Oui |
| `/inventory` | Stocks et mouvements | Oui |
| `/inventory/movements` | Historique mouvements | Oui |
| `/inventory/scan` | Scanner code-barres | Oui |
| `/inventory/transfer` | Transfert inter-dépôts | Oui |
| `/inventory/ajustements` | Ajustements de stock | Oui |
| `/sales` | Ventes | Oui |
| `/sales/new` | Nouvelle commande | Oui |
| `/sales/clients` | Gestion clients | Oui |
| `/finance` | Caisses (sessions) | Oui |
| `/finance/transactions` | Transactions | Oui |
| `/logistics` | Liste missions | Oui |
| `/logistics/:id` | Détail mission | Oui |
| `/logistics/qr-scan` | Scanner QR mission | Oui |
| `/hr` | Ressources Humaines | Oui |
| `/products` | Catalogue produits | Oui |
| `/notifications` | Notifications | Oui |
| `/profile` | Profil utilisateur | Oui |

## Périmètre Fonctionnel (CDC §3)

### 3.1 Zones et Dépôts
- Zones géographiques nommées (ex : Coyah, Kaloum) avec coordonnées GPS (latitude/longitude)
- Carte OpenStreetMap : marqueurs des zones et dépôts
- Chaque dépôt : gestionnaire assigné, caisse physique, comptes mobile money
- Tableau de bord par dépôt : stock disponible, solde caisse, historique des opérations

### 3.2 Produits
- Fiche produit : nom, référence, catégorie, unité de mesure, prix achat/vente
- Prix différenciés par zone
- Seuils de stock minimum avec alertes automatiques
- Variantes (taille, couleur, conditionnement)
- Produits périmables : suivi FEFO (First Expired, First Out)
- Import/export catalogue CSV/Excel

### 3.3 Stocks et Mouvements
- Approvisionnement (achats fournisseurs + bons de réception)
- Transferts inter-dépôts : demande → validation → expédition → réception (traçabilité complète)
- Inventaires physiques périodiques + détection d'écarts
- Ajustements de stock : motif obligatoire + validation superviseur
- Gestion FIFO (First In, First Out) par défaut

### 3.4 Fournisseurs
- Fiche fournisseur : contacts, conditions de paiement
- Suivi commandes et livraisons attendues
- Gestion avances et dettes fournisseurs
- Évaluation et comparaison (délais, qualité, coût)

### 3.5 Ventes et Clients
- Fiche client : particulier ou entreprise
- Commandes avec sélection dépôt source
- Factures PDF numérotées automatiquement + bons de livraison
- Paiements : comptant, partiel, à crédit
- Suivi créances et relances automatiques
- Devis avec conversion en commande
- Application automatique TVA
- Remises et promotions (par produit / client / période)

### 3.6 Finance — CRITIQUE

#### Hiérarchie des caisses physiques (4 niveaux)
```
Caisse Entreprise (permanente)
  └─ Caisse Zone
       └─ Caisse Dépôt
            └─ Session Caissier
```

Règles immuables :
| Règle | Détail |
|-------|--------|
| Jamais supprimée | Une caisse fermée reste en base définitivement |
| Jamais réouverte | Une caisse fermée ne peut plus être modifiée |
| Motif obligatoire | Tout écart à la fermeture exige un motif saisi |
| Double comptage | Le receveur compte lui-même et saisit son propre montant |
| Justificatif | Tout versement inter-niveau nécessite un justificatif joint |
| Blocage | Impossible de fermer une caisse si des sous-caisses sont ouvertes |

#### Comptes de paiement mobile (Orange Money, MTN Money)
- Même hiérarchie que les caisses physiques
- ID de transaction opérateur **obligatoire** pour chaque transaction
- À la fermeture : capture du relevé de compte opérateur
- Comparaison solde virtuel calculé vs relevé réel — tout écart exige un motif

#### Autres fonctionnalités financières
- Dépenses opérationnelles par catégorie (carburant, maintenance, salaires)
- Rapports : journal de caisse, bilan recettes/dépenses, état des créances
- Multi-devises : GNF (défaut), USD, EUR — taux configurables avec date d'expiration
- Alerte automatique à l'expiration d'un taux de change

### 3.7 Logistique (Flotte et Transport)

#### Modes de transport
| Mode | Processus |
|------|-----------|
| **Standard (obligatoire)** | Création mission → QR généré → chauffeur scanne QR → démarrage → GPS toutes les 1 min → signature à l'arrivée |
| **Avancé NFC (optionnel)** | Idem + scan puce NFC véhicule pour vérifier présence physique |

#### Suivi GPS (Standard)
- QR code unique généré à la création de la mission
- Chauffeur scanne QR depuis son téléphone pour démarrer
- GPS activé : position envoyée toutes les **1 minute**
- Système enregistre : heure départ, trajet, distance, heure arrivée

#### Signature numérique de réception
- Destinataire signe directement sur l'écran du téléphone du chauffeur
- Signature horodatée et rattachée définitivement à la mission
- Bon de livraison PDF généré automatiquement
- En cas de produits manquants : signature avec réserve + motif + alerte responsable
- En cas de refus : mission → statut **Litige** + alerte immédiate superviseur

#### Statuts de mission
| Statut | Description |
|--------|-------------|
| Planifiée | Créée, transport pas encore démarré |
| Chargement en cours | Chargement des marchandises |
| Transport en cours | Camion en route |
| Arrivé à destination | En attente de signature |
| Litige | Refus de signature ou problème signalé |
| Terminée | Signature validée, mission clôturée |

#### Gestion de la flotte
- Fiche véhicule : immatriculation, marque, modèle, capacité, statut NFC
- Kilométrage et consommation carburant
- Maintenance préventive et corrective avec alertes
- Documents véhicule (assurance, visite technique) avec rappels d'expiration

### 3.8 Tableau de Bord Logistique
- Carte OpenStreetMap : positions camions en mission en temps réel
- Liste missions actives avec statuts
- Alertes : arrêt prolongé, retard, perte signal GPS, mission en litige

### 3.9 Planification des Transferts de Stock
- Mode automatique : recommandations de transfert basées sur niveaux de stock
- Mode manuel : transferts créés par admin ou **gestionnaire_stock** (pas "responsable logistique")
- Un transfert validé déclenche la création d'une mission logistique

### 3.10 Ressources Humaines
- Fiche employé : informations personnelles, poste, dépôt d'affectation
- Gestion présences, absences et congés
- Historique des mutations entre dépôts

### 3.11 Rôles utilisateur

| Rôle | Modules principaux sur mobile |
|------|-------------------------------|
| **superadmin** | Tout + gestion multi-entreprise (SaaS) |
| **admin** | Configuration, utilisateurs, validation caisses de zone |
| **superviseur** | Vue globale multi-sites, validation opérations sensibles, rapports consolidés |
| **gestionnaire_stock** | Stocks, produits, approvisionnements, transferts |
| **caissier** | Ouverture/fermeture session caisse, saisie ventes/paiements |
| **chauffeur** | Missions assignées, scan QR, GPS, signature de réception, déclaration pannes |
| **maintenancier** | Interventions et maintenance véhicules |
| **commercial** | Clients, devis, commandes |

Permissions granulaires : lecture seule / écriture / validation — gérées côté backend.  
Journal d'audit : toutes les actions sont tracées (qui, quand, quelle action).  
Blocage du compte après plusieurs tentatives de connexion échouées.

### 3.12 Fidélité Client
- Attribution automatique de points à chaque achat (barème configurable)
- Conversion points → réductions ou bons d'achat (ex : 100 points = réduction)
- Notifications automatiques au client à l'atteinte d'un seuil

### 3.13 Gestion Documentaire
- Stockage contrats fournisseurs/clients, factures, bons de livraison
- Rattachement documents à une opération (commande, transfert, mission)

### 3.14 Taxes (TVA)
- Taux TVA global et par catégorie de produit (configurable)
- Application automatique sur les factures
- Rapports de TVA collectée par période

### 3.15 Multi-Entreprise (SaaS)
- Isolation complète des données entre entreprises (aucun accès croisé)
- Chaque entreprise : ses propres zones, dépôts, produits, utilisateurs, paramètres financiers
- Activation/désactivation d'une entreprise sans perte de données
- Tableau de bord superadmin : vue globale toutes entreprises

## Fonctionnalités Transversales (CDC §4)

### Dashboard & Analytique
- KPIs personnalisés par rôle : chiffre d'affaires (jour/semaine/mois), bénéfices, dépenses, stock critique
- Graphiques : évolution ventes, top produits, taux de rotation stocks
- Comparaison performances entre zones/dépôts
- Export rapports PDF et Excel

### Notifications et Alertes
- Temps réel (in-app) : rupture de stock, échéance client, maintenance véhicule, expiration documents
- Alertes : écarts de caisse, missions en litige, caisse négative
- Centre de notifications avec historique

### Messagerie Interne
- Communication entre utilisateurs du système
- Discussions liées à une opération spécifique (commande, transfert, panne)

## Fonctionnalités Optionnelles (CDC §5)

À implémenter uniquement si le temps le permet après le cœur du projet :

| Feature | Note |
|---------|------|
| **NFC véhicules** | Requiert puce NFC physique sur chaque véhicule |
| **Scan code-barres** | Via caméra téléphone (API caméra navigateur mobile) |
| **IA / prévisions** | Nécessite historique de données suffisant |
| ~~**2FA**~~ | ✅ Implémenté (17/06) — TOTP (QR Authy) + OTP email, voir section "Auth — 2FA" dans état d'avancement |
| **Cartographie avancée** | Polygones zones sur carte (Leaflet.draw) |

## Exigences Non Fonctionnelles (CDC §6)

- **Performance** : temps de réponse < 2 secondes, 50 utilisateurs simultanés minimum
- **Sécurité** : JWT + refresh, CSRF/XSS/SQL injection protection, sessions avec expiration après inactivité, sauvegardes quotidiennes
- **Disponibilité** : 99% (hors maintenance planifiée)
- **Offline partiel** : enregistrement des opérations sans connexion + synchronisation ultérieure
- **Langue** : interface entièrement en **français**
- **Connectivité instable** : UI résiliente (gestion timeouts, messages d'erreur clairs)
- **Hébergement** : données hébergées localement (on-premise) ou cloud contrôlé par l'entreprise

## Commandes utiles

```bash
# Lancer l'app (dev)
flutter run

# Générer le code (json_serializable, riverpod_annotation)
flutter pub run build_runner build --delete-conflicting-outputs

# Vérifier le code (doit retourner "No issues found!")
flutter analyze

# Lancer les tests
flutter test

# Mettre à jour les dépendances
flutter pub upgrade
```

## Notes importantes

1. **Monnaie** : L'unité par défaut est le **GNF** (Franc Guinéen). Utiliser `AppFormatters.gnf()` pour tous les montants. Gérer aussi USD et EUR avec taux configurables.
2. **GPS** : Tracking missions = polling ~1 min via `geolocator`. Demander les permissions au premier lancement. Envoi position vers backend : `POST /api/missions/:id/position/`.
3. **QR Code** : Les missions logistiques utilisent un QR UUID auto-généré côté backend. Scan : `POST /api/missions/scanner-qr/`. Package : `mobile_scanner`.
4. **Signature** : Réception mission → signature numérique (package `signature`) envoyée en base64. Obligatoire dans tous les cas.
5. **PDF** : Factures et bons de livraison générés en PDF (`pdf` + `open_filex`).
6. **Caisses** : Jamais supprimées, jamais réouvertes. Ne pas implémenter de bouton "supprimer" sur une caisse.
7. **First login** : Le superadmin crée les utilisateurs avec un `first_login_token`. Rediriger vers `/first-login` pour définir le mot de passe.
8. **Pagination** : Toujours paginer les listes (25 items/page). Pagination infinie avec `ScrollController`.
9. **Offline** : Package `connectivity_plus`. Vérifier la connexion avant les appels critiques, afficher un bandeau offline.
10. **`withOpacity()` déprécié** : Toujours utiliser `.withValues(alpha: x)` dans tout le code Flutter.
11. **Déploiement** : Docker + Nginx côté backend. Mobile via flutter build apk/ios.

## Variables d'environnement

Pas de fichier `.env` côté Flutter. Les URLs sont dans `lib/core/network/api_endpoints.dart`.

```bash
# Multi-environnement via dart-define
flutter run --dart-define=API_URL=https://gestion.kingreys.fr/api
```
