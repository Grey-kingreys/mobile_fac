# DjoulaGest Mobile — CLAUDE.md

> CDC v1.0 — Mars 2026 | Groupe 1 | Deadline livraison : **20/06/2026** | Mis à jour : 18/06/2026 (session 3)

## ⛔ RÈGLE ABSOLUE — À lire avant toute action

> **Ne jamais modifier, créer ou supprimer un fichier sans autorisation explicite de l'utilisateur.**
> Rôle par défaut : lire, analyser, rapporter. Attendre un "vas-y", "corrige", "fixe" ou "applique" explicite avant tout Edit/Write.

## État d'avancement (17/06/2026)

### Vente — fix 400 mode_paiement + compte Mobile Money à l'encaissement (20/06/2026)

**(1) Fix 400 enregistrement vente** (`new_sale_screen.dart`) : le mobile envoyait le **canal**
(`especes`/`orange_money`/…) dans `mode_paiement`, or `Commande.ModePaiement` n'accepte que
`comptant`/`partiel`/`credit` → 400. Désormais `mode_paiement` est **dérivé du montant payé**
(`credit` si 0, `partiel` si < total, sinon `comptant`) ; le canal reste dans `mode_paiement_initial`.

**(2) Compte Mobile Money crédité** (parité web + CDC §3.6) : quand le mode est Orange/MTN, un
**sélecteur de compte** apparaît (en plus de la référence obligatoire). Comptes chargés via
`GET /comptes-mobile-money/?page_size=100` dans `initState` (`_loadMobileMoneyAccounts`,
`CompteMobileMoneyEntity`), filtrés client-side sur `is_active` + opérateur du mode choisi
(`_filteredAccounts`). `_selectedCompteMmId` reset à chaque changement d'opérateur ; validation
« compte obligatoire » avant envoi ; `compte_mobile_money` ajouté au payload (`createSale` threadé
datasource→repo→impl). Si aucun compte de l'opérateur → bandeau « Ajoutez-en un dans Finance → Mobile
Money ». ⚠️ Nécessite la migration backend **`ventes/0004`** déployée (FK `Paiement.compte_mobile_money`
+ crédit du solde + `TransactionMobileMoney` PAIEMENT_RECU). `flutter analyze lib` = **No issues found**.

### 🐞 Fix commande fournisseur — sélecteur « produit à commander » inerte (20/06/2026)

**Symptôme** : dans la création d'une commande fournisseur, taper sur « Choisir un produit »
ne faisait **rien** (le dialogue ne s'ouvrait jamais). Feature **mobile-only** (le web n'a aucune
gestion de commandes fournisseurs).

**Cause** (`commandes_fournisseurs_screen.dart`, `_LigneRow._pickProduit`) :
`ref.read(productsSearchProvider('')).valueOrNull ?? []` → `productsSearchProvider` est un
`FutureProvider.autoDispose` **jamais watché** dans cet écran. Au 1ᵉʳ tap il est en `AsyncLoading`
→ `valueOrNull == null` → liste vide → `if (all.isEmpty) return;` → dialogue jamais ouvert (et
autoDispose le jette aussitôt → ne se charge jamais).

**Correctif** : `await ref.read(productsSearchProvider('').future)` (attend réellement la donnée) +
messages si liste vide / erreur (snackbar) + **champ de recherche** dans le dialogue (liste plafonnée
à 50 produits) avec filtrage local nom/référence. `flutter analyze lib/features/suppliers` = **No issues found**.
⚠️ Pattern à surveiller : ne jamais lire `.valueOrNull` d'un FutureProvider autoDispose non watché —
utiliser `await ...future` ou `ref.watch`.

### 🐞 Fix ANR « Présences & Congés » + bouton de pointage toujours visible (20/06/2026)

**1. ANR à l'ouverture de Présences & Congés** (capturé via `flutter run` + logcat, device R94XC0DT1WJ).
Erreur Dart : `RenderFlex children have non-zero flex but incoming width constraints are unbounded`
puis `BoxConstraints forces an infinite width` sur l'`ElevatedButton` « Présent »
([attendance_screen.dart](features/hr/presentation/screens/attendance_screen.dart) `_PointageCard._buildBouton`).
La `Row` de la carte contient un `Expanded` ; sous `TabBarView`, la largeur entrante peut être **non bornée**
lors de certaines passes de layout → frame jamais peint → écran blanc + **ANR**. Bug **exposé** maintenant
que le backend renvoie `a_fiche_employe=true` pour tous (la carte s'affiche toujours).
**Correctif (2 temps)** :
- 1ʳᵉ passe : `_PointageCard.build` enveloppé dans un `LayoutBuilder` bornant sa largeur → réglait la
  carte **mais pas le reste** de l'onglet. La page replantait pour un **manager** (admin/superviseur) car
  l'onglet Présences affiche aussi `_RecapBanner` (Row + Spacer) et une **`ListView`** verticale — eux aussi
  victimes de la largeur infinie.
- ✅ **Correctif définitif** : `LayoutBuilder` au niveau du **`body` entier** de l'écran (au‑dessus du
  `TabBar`/`TabBarView`) → `SizedBox(width: maxWidth.isFinite ? maxWidth : MediaQuery.sizeOf(...).width)`.
  En bornant la largeur à la racine, **tout** le contenu des onglets (carte, récap, listes) est protégé d'un
  coup. Le `LayoutBuilder` interne de `_PointageCard` est conservé (défense en profondeur).

Règle : sous `TabBarView`, le contenu doit recevoir une largeur **bornée** — borner au niveau du body est
plus robuste que widget par widget (cf. aussi le fix Finance `_SessionKpi`).

**2. Bouton de pointage masqué pour certains comptes.** `_PointageCard` se masquait quand
`status.aFicheEmploye == false`. Or le modèle backend est « employés = utilisateurs » : la fiche `Employe`
est créée automatiquement au 1ᵉʳ pointage (`POST /presences/pointer/`, `_employe_du_user(create=True)`), et
`GET /presences/aujourdhui/` renvoie `a_fiche_employe=true` dès qu'un user a une entreprise. Le verrou
`aFicheEmploye` est donc obsolète. **Correctif** : retiré → la carte/bouton s'affiche à **tout** membre
d'entreprise ; seul `dejaPointe` bascule vers l'état « Présence enregistrée ». ⚠️ Nécessite le backend
auto-provision **déployé** (`back_fac` `apps/rh/views.py`, sans migration → `docker compose up -d --build`)
pour que le pointage aboutisse sur un compte sans fiche préexistante.

### RH — routage corrigé + présence 100% self-service + récap user-based (20/06/2026)

Bugs critiques corrigés après tests utilisateur.

- **Routage RH cassé** : `AppRoutes.hr` (`/hr`) charge **`EmployeesScreen`** (liste `/users/`), pas le pointage.
  Mes entrées de nav y pointaient → tout le monde tombait sur la liste des utilisateurs (403 non-admin).
  Corrigé : `AppRoutes.attendance` passé en **route top-level** (`/attendance`, plus sous `/hr` — évite
  d'instancier `EmployeesScreen` en parent via GoRouter). Drawer « Mon espace » + bottom bar « Présence »
  des rôles opérationnels → `AppRoutes.attendance` (`AttendanceScreen`). Admin/superviseur : entrée
  « Présences & Congés » → attendance **en plus** de « Ressources Humaines » → users.
- **Formulaire « Nouvelle présence » + FAB présence SUPPRIMÉS** (`attendance_screen.dart`) : présence
  100 % self-service ; le FAB n'apparaît que sur l'onglet Congés (`_AddPresenceSheet`/`_showAddPresenceSheet`/
  `_canCreatePresence` retirés).
- **Récap user-based** + **auto-provision backend** : l'effectif/absents = utilisateurs de l'entreprise ;
  un employé sans fiche peut pointer (fiche créée à la volée). `flutter analyze lib` = **No issues found**.

### 🐞 Fix ANR Finance — `Expanded` dans une `Column` de `ListView` (20/06/2026)

**Symptôme** : « dès que je rentre dans Finance, l'app se fige » (ANR « DjoulaGest ne répond pas »)
**dès qu'une session est ouverte** ; impossible de voir la session après l'avoir ouverte.

**Cause racine** (capturée via `flutter run` + logcat sur device R94XC0DT1WJ) :
`RenderBox was not laid out` / `'child.hasSize': is not true` / `Null check used on null`. Le KPI
**« Solde calculé »** de `_ActiveSessionCard` était un `_SessionKpi(large: true)` **autonome**, et
`_SessionKpi` renvoie un **`Expanded`**. Un `Expanded` (flex) placé directement dans la `Column` de la
carte — elle-même enfant d'un `ListView` (hauteur **non bornée**) — est invalide → échec de layout →
frame jamais peint → **ANR**. Bug **latent** : ne se déclenchait que sur la branche « session ouverte »
(`if (session != null && isOpen)`), donc invisible tant qu'aucune session n'était ouverte sur le compte.

**Correctif** (`cash_session_screen.dart`) : `_SessionKpi` prend un flag **`expand`** (défaut `true` pour
l'usage en `Row`) ; quand `false`, il renvoie un `SizedBox(width: double.infinity)` au lieu d'`Expanded`.
Le KPI autonome « Solde calculé » passe `expand: false`. **Règle** : ne jamais mettre un `Expanded`
directement dans une `Column` rendue par un `ListView`. Vérifié sur device : carte session ouverte rendue,
0 exception, plus d'ANR. `flutter analyze lib/features/finance` = **No issues found**.

### RH self-service — 2ᵉ vague : navigation, absents, motif de refus (20/06/2026)

Corrections suite à un audit complet du module RH self-service.

- **Navigation RH ouverte à tout le personnel** : `app_drawer.dart` — nouvelle section **« Mon espace →
  Présences & Congés »** (`_monEspaceSection`) ajoutée aux 5 rôles opérationnels (gestionnaire_stock,
  caissier, chauffeur, maintenancier, commercial ; admin/superviseur l'avaient déjà). `bottom_nav_bar.dart`
  — item **« RH »** ajouté à ces 5 rôles (admin/superviseur déjà présents → **pas de doublon**, 7 occ./7 rôles).
  Sinon les employés ne peuvent pas pointer / demander un congé.
- **Liste présences réservée aux managers** : `GET /presences/` = `RH_READ` (admin/superviseur) backend.
  `_PresencesTab` ne `watch` `presencesProvider` **que** si `canViewRecap` ; les autres rôles n'ont que la
  carte de pointage + un message (évite un 403).
- **Récap du jour (absents)** : `_RecapBanner` (admin/superviseur) consomme `GET /presences/recap/`
  (`presenceRecapProvider`) → présents / absents / effectif + liste dépliable. Chaîne Clean Arch :
  `PresenceRecap`(+`RecapAbsent`)/`PresenceRecapModel`, datasource `getPresenceRecap`, repo, provider,
  endpoint `presenceRecap`.
- **Motif de refus de congé** : `_showRefuseDialog` (saisie motif) → `refuserConge(id, motif:)` →
  `POST /conges/{id}/refuser/ {motif_traitement}`. Affichage « Motif du refus : … » sur les congés refusés
  (`CongeEntity.motifTraitement` + parsing `motif_traitement`).
- **FAB Présence masqué** pour les non-admins (plus de snackbar « pas les droits ») ; `_canCreatePresence`
  aligné sur **admin** (= `RH_WRITE`). **Fix faux-erreur** : un échec de `refresh()` après un pointage réussi
  n'affiche plus de message d'erreur (try/catch dans `pointer()`).
- `flutter analyze lib` = **No issues found**.

### Ouverture de session caisse par admin/superviseur — parité web (20/06/2026)

**Symptôme** : impossible d'ouvrir une session de caisse côté mobile sauf en tant que
caissier — l'admin/superviseur ne voyait aucun bouton « Ouvrir une session ».

**Cause** : dans `cash_session_screen.dart`, le bloc CTA de `_ActiveSessionCard` était gardé
`if (isCaissier)`, et `_OpenSessionDialog` ne savait qu'auto-résoudre la caisse depuis le
dépôt de l'utilisateur (un admin n'a pas de `depot_id`). Le web, lui, montre le bouton aux
non-caissiers en permanence + un **sélecteur de caisse** (`finance.html`/`finance.ts`).

**Correctif (parité web)** :
- `finance_provider.openSession({required num soldeOuverture, int? caisseId})` : si `caisseId`
  fourni (admin/superviseur) → ouverture directe sur cette caisse ; sinon (caissier) →
  auto-résolution depuis `effectiveUserProvider.depotId` (comportement existant inchangé).
- `cash_session_screen.dart` : bouton « Ouvrir une session » désormais affiché aussi aux
  **non-caissiers** (branche `else` du CTA). Nouveau widget `_CaissePicker` (consomme
  `caissesProvider`) dans `_OpenSessionDialog`, gaté `!isCaissier`.
  `_showOpenDialog`/`_OpenSessionDialog.show` prennent `required bool isCaissier`. Fermeture
  de session inchangée (reste caissier).
- **Choix de la caisse — contrainte backend** : `CaissePhysique` n'autorise **qu'une caisse
  ouverte par dépôt** (`UniqueConstraint(depot, condition=statut='ouverte')`), pas une seule
  par entreprise. Donc `_CaissePicker` ne propose que les caisses **actives ET ouvertes**
  (`isActive && isOuverte`) : s'il n'y en a **qu'une** (cas mono-dépôt) → elle est prise
  d'office et affichée en lecture seule (`_SelectedCaisseTile`) ; s'il y en a **plusieurs**
  (multi-dépôts) → menu déroulant. Aucune caisse ouverte → message d'erreur (rien à ouvrir).
- `flutter analyze lib/features/finance` = **No issues found**.

### RH self-service : pointage présence géolocalisé + demande de congé (20/06/2026)

`AttendanceScreen` passé en self-service (parité web). ⚠️ nécessite le backend RH déployé
(migrations `companies/0007`, `rh/0003`, `notifications/0002`).

- **Pointage présence géolocalisé** : carte `_PointageCard` (`ConsumerStatefulWidget`) en haut de l'onglet
  Présences. Bouton « Présent » → `Geolocator` (service activé + permission `requestPermission`) →
  `presencesProvider.notifier.pointer(lat, lon)` → `POST /presences/pointer/`. État piloté par
  `myPresenceProvider` (`GET /presences/aujourdhui/`) : si `dejaPointe`, la carte affiche « Présence
  enregistrée · pointé à HH:MM · à X m / hors site » (le bouton ne revient que le lendemain). Si pas de
  fiche employé liée → carte masquée. Badge **Sur site / Hors site** (`dansPerimetre`) dans `_PresenceTile`.
  Le sheet de saisie manuelle admin (`POST /presences/`) est conservé.
- **Demande de congé self-service** : `_AddCongeSheet` — champ « ID Employé » **retiré** (le backend déduit
  l'employé du compte), `create()` n'envoie plus `employe`, + bandeau « transmis à votre responsable ». FAB
  Congé déjà ouvert à tous. Validation `approuver`/`refuser` inchangée (admin/superviseur).
- **Chaîne Clean Arch** : `PresenceEntity`/`Model` + champs géo, `PresenceTodayStatus(Model)`, datasource
  (`pointerPresence`, `getPresenceAujourdhui`), repo + impl, provider (`myPresenceProvider`, `pointer()`),
  endpoints `presencePointer`/`presenceAujourdhui`.
- **Permissions localisation ajoutées** (manquaient — bloquaient aussi le GPS missions) :
  `AndroidManifest.xml` (`ACCESS_FINE/COARSE_LOCATION`) + `Info.plist` (`NSLocationWhenInUseUsageDescription`).
- `flutter analyze lib` = **No issues found**.

### Rapports & Analyses — parité avec le web (20/06/2026)

Le web avait une page **Rapports** (`/rapports`) absente du mobile. Ajout de la feature `reports/` complète
(Clean Arch) en miroir exact du front : entités (`ReportData` + `VentesAnalytics`/`StockAnalytics`/`FinanceAnalytics`,
chaque bloc nullable comme le `catchError(() => of(null))` du web), datasource consommant les **3 endpoints
analytics déjà définis** (`GET /analytics/ventes|stock|finance/?debut=YYYY-MM-DD&fin=YYYY-MM-DD`), repo, provider
(`AutoDisposeAsyncNotifier` + `reportPeriodProvider` StateProvider today/week/month/year), écran. Contenu identique
au web : filtre période, KPIs ventes (commandes, CA TTC, encaissé, alertes stock), bloc finance
(recettes/dépenses/solde net), **CA par dépôt** (barres), **top produits sortie**, **produits en alerte**, état vide.
Décimaux parsés en `num` robuste (DRF renvoie des strings). Route `AppRoutes.reports = '/reports'` + `GoRoute` +
entrée drawer « Rapports & Analyses » (icône bar_chart) pour **admin** et **superviseur** uniquement (le superadmin
reste SaaS-only ; les analytics sont des données internes d'entreprise). `flutter analyze lib` = **No issues found**.

> **Écart restant identifié** (web a / mobile n'a pas) : **Documents** (gestion documentaire générale `/api/documents/`).
> Le mobile n'a que `documents-vehicule` (logistique). Catégories, Unités, Fournisseurs, etc. existent déjà côté mobile.
> Non implémenté (hors périmètre de la demande « page rapport ») — à valider avec l'utilisateur avant build.

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
| **Finance — Config caisses** | `CaisseConfigScreen` (`/finance/configuration`) : admin lecture/écriture, autres rôles lecture seule. Hiérarchie visuelle Zone → Dépôt → Session avec flèches connectrices. `_humanize()` convertit jours en mois/semaines. Validation client `session < depot < zone` avant PATCH. Note : CaisseEntreprise permanente (jamais fermée). Endpoint `GET/PATCH /configuration-caisses/` |
| **RH — Création superviseur** | `employees_screen.dart` : sélecteur conditionnel zone/dépôt selon le rôle choisi. Si `superviseur` → dropdown "Zone de supervision *" (obligatoire), envoie `zone_id`. Sinon → dropdown "Dépôt" (optionnel), envoie `depot_id`. Watch `zonesProvider` dans `build()` |
| **Finance — Gating caisses** | `caisses_screen.dart` : FAB "Ouvrir" et bouton "Fermer" conditionnels sur `canManage` (admin uniquement). Paramètre `required bool canManage` sur `_CaissesList`. Les deux onglets (CaissesPhysiques + CaissesZone) passent `canManage: role == 'admin'` |
| **Users — Désactiver / Réactiver / Supprimer** (19/06) | `employees_screen.dart`, 3 actions admin distinctes : **Désactiver** (`deleteUser` → `DELETE /users/{id}/`, soft, `is_active=False`, réactivable, reste visible « Inactif ») · **Réactiver** (`updateUser {is_active:true}`) · **Supprimer** (`purgeUser` → `DELETE /users/{id}/supprimer/`). Côté backend, `supprimer` = purge physique si l'user n'a **aucun** historique, sinon **archivage tombstone** (`is_deleted=True` : retiré des listes mais ligne conservée → nom+email lisibles sur l'historique ; FK PROTECT respectées, caisses immuables préservées). Endpoint `userSupprimer(id)`. ⚠️ Nécessite migration backend `accounts/0009` + déploiement (le `back_fac` local divergeait du déployé). |
| **Produits — chargement KO + formulaire** (19/06) | (1) `product_model.fromJson` castait `prix_achat`/`prix_vente`/`tva_taux`/`seuil_*` en `num` → ce sont des `DecimalField` (strings DRF) → crash → « impossible de charger les produits » après création. Corrigé avec helpers `_num`/`_numN` (idem catégories). (2) Champ **TVA retiré** du formulaire produit (CDC §9 : TVA = global + par **catégorie**, pas par produit ; le produit hérite de sa catégorie). (3) Note ajoutée : quantité de stock & dates de péremption se saisissent **par dépôt / par lot à l'entrée de stock**, pas sur la fiche produit. ✅ **Résolu** : écran « Entrée de stock » créé (voir ligne suivante). |
| **Nouvelle vente — sélecteur dépôt (19/06)** | `new_sale_screen.dart` : la vente était **refusée** quand l'utilisateur n'avait pas de dépôt associé (cas admin, `depot_id: null`) → « aucun dépôt associé ». Ajout d'un **DropdownButtonFormField « Dépôt source * »** (charge `GET /depots/?page_size=100&is_active=true` dans `initState`, présélectionne le dépôt de l'utilisateur s'il en a un, ou l'unique dépôt sinon). `_valider()` utilise désormais `_depotId` sélectionné (message « Sélectionnez le dépôt source de la vente » si vide). CDC §3.5 : « commandes avec sélection du dépôt source ». `flutter analyze` fichier = 0 issue. |
| **Scanner QR mission — isolation entreprise (19/06)** | ⚠️ **Backend** `logistique/views.py` : `scanner_qr` filtrait `Mission.objects.get(qr_code=...)` sans `company` → un chauffeur pouvait théoriquement scanner le QR d'une mission d'une autre entreprise. Ajout `company=request.user.company` au lookup (règle universelle #8 isolation SaaS). À déployer. |
| **Décimal — sweep complet (19/06)** | Tous les `as num` restants sur des `DecimalField` (renvoyés en string par DRF) → parsing robuste : `client_model` (solde_credit), `sale_model` (montants), `new_sale_screen` (prix_vente ×2 → **fix « nouvelle vente ne charge pas clients/produits »**), `transaction_model` (montant), `cash_session_model` (soldes/écart/totaux), `mission_model` (LigneMission quantités). Plus aucun `as num` brut dans `lib/features`. |
| **Config caisse entreprise (19/06)** | Écran `CaisseEntrepriseConfigScreen` (`/finance/caisse-entreprise`, route `AppRoutes.caisseEntrepriseConfig`) : intitulé + devise, GET `/caisse-entreprise/me/`, PATCH `/caisse-entreprise/configurer/` (backend `get_or_create` → règle aussi les entreprises pré-existantes). Entrée Paramètres → Finance (admin). first-login guide vers Paramètres après connexion. |
| **Lot correctifs test (19/06)** | **Décimal** : `stock_model`, `movement_model` (+ `AjustementModel`) castaient `quantite`/`seuil` en `as num?` → DRF renvoie des strings → crash « impossible de charger » dès la 1ʳᵉ ligne. Corrigé (`_num`/`_numN` robustes). **Documents véhicule** : `DocumentsVehiculeScreen` n'avait aucun bouton → FAB + `_DocCreateSheet` (`POST /documents-vehicule/` : véhicule, type, date expiration, notes ; admin/superviseur/maintenancier). **Stock** : FAB « Entrée de stock » ajouté sur `StockScreen` (admin/gestionnaire_stock) → `/inventory/entree`. |
| **Lot corrections (audit 19/06)** | **#5** liste entreprises super-admin : datasource lit `companies` (et fallback `results`) — le backend renvoie `data:{count, companies}`, plus `results` (count=3 mais liste vide). **#7** Mobile Money : FAB « Associer un compte » (admin/`FINANCE_WRITE`) + `_AddCompteSheet` → `POST /comptes-mobile-money/` (opérateur, dépôt, numéro, titulaire). **#8** Inventaires : bandeau explicatif (comptage physique vs théorique → écart → ajustement). **#9** Missions : sélecteur **type de mission** (transfert/livraison/enlèvement) threadé datasource→repo→provider→form (`type_mission`, défaut transfert). `flutter analyze` projet = 0 issue. |
| **Véhicules / Flotte** (19/06) | Nouveau `VehiculesScreen` (`/logistics/vehicules`, `AppRoutes.vehicules`) : liste paginée + CRUD (immatriculation, type, marque, modèle, année, capacité, statut). Consomme `GET/POST/PATCH/DELETE /vehicules/`. Écriture gatée **admin + maintenancier** (`_canWrite`). Drawer : maintenancier « Flotte & Véhicules » repointé → cet écran (+ entrée « Missions » séparée) ; admin → entrée « Véhicules » ajoutée. **Raison** : la création de mission imposait un véhicule mais aucun écran ne permettait d'en créer (datasource avait seulement `getVehiculesSimple`). Modèle = flotte **entreprise** (Vehicule a seulement FK company, pas depot/zone). ⚠️ **Backend** : `LOG_WRITE_VEHICLE = [ADMIN, MAINTENANCIER]` (était `[ADMIN]`) dans `logistique/views.py` — à déployer. |
| **Entrée de stock (approvisionnement)** (19/06) | Nouveau `StockEntreeScreen` (`/inventory/entree`, `AppRoutes.inventoryEntree`) : dépôt + produit + quantité + référence ; si produit **périmable** → champs **n° de lot** + **date d'expiration** (date picker) obligatoires pour la FEFO. Consomme `POST /stocks/entree/` via `inventoryRepositoryProvider.stockEntree` (datasource/repo/interface étendus avec `numeroLot`/`dateExpiration` — additif, ne casse rien). Invalide `inventoryProvider` après succès. Entrées drawer « Entrée de stock » ajoutées (gestionnaire_stock + admin). Rôles backend : ADMIN/GESTIONNAIRE_STOCK. `flutter analyze` projet entier = 0 issue. |
| **Zones/Dépôts — erreurs masquées + carte dépôt** (19/06) | (1) `zones_provider._msg` et `depots_provider._msg` renvoyaient `e.toString()` (DioException brut) → la vraie cause d'un échec de création (ex. « Ce code est déjà utilisé par une autre zone dans votre entreprise », « Une zone avec ce nom existe déjà », « Cette zone n'appartient pas à votre entreprise ») était invisible. Corrigé : extraction de l'`AppException`/`ValidationException` depuis `DioException.error` (comme le login). (2) `depots_screen` : le formulaire dépôt utilisait des champs texte manuels pour lat/long → remplacés par le **sélecteur de carte** `MapPickerSheet` + `_PositionPickerTile` (identique aux zones). (3) **CAUSE RACINE du 400 création zone/dépôt** : backend `latitude`/`longitude` = `DecimalField(max_digits=9, decimal_places=6)` → max **6 décimales**. Le sélecteur de carte renvoie un double haute précision (≈15 décimales) → 400. Corrigé dans `zone_model.toJson` + `depot_model.toJson` : `latitude.toStringAsFixed(6)` (envoi en string à 6 décimales). |
| **Fix refresh token — déconnexion prématurée** (19/06) | Backend : access=60 min, refresh=7 j (`ROTATE_REFRESH_TOKENS`+`BLACKLIST_AFTER_ROTATION`). Bug : `build()` (auth_provider) et `isAuthenticatedProvider` (providers.dart) décidaient la session via `hasValidToken()` qui ne teste que l'**access** → l'app déconnectait dès 60 min même avec un refresh token valide 7 j (le refresh n'était jamais utilisé au démarrage à froid / garde-fou routeur). **Corrigé** : ajout `SecureStorageService.hasSession()` (access valide **OU** refresh valide, via `_isJwtValid` factorisé) ; `build()` + `isAuthenticatedProvider` l'utilisent. Access expiré + refresh valide → `GET /auth/me/` 401 → AuthInterceptor rafraîchit → session restaurée. L'interceptor lui-même (rotation, resauvegarde du nouveau refresh, retry via Dio neuf, garde-fou concurrence) était déjà correct. |
| **Fix login — erreurs invisibles** (19/06) | Identifiants invalides → backend renvoie **401** `{detail}` (et **403** compte désactivé/bloqué). Bug : `AuthInterceptor.onError` traitait **tout** 401 comme session expirée, y compris sur `/auth/login/` → tentait un refresh inutile **puis `onLogout()`** (invalide `isAuthenticatedProvider` → refresh routeur en plein vol) qui faisait disparaître le SnackBar. **Corrigé** : (1) `AuthInterceptor` ignore les endpoints du flux d'auth (`_authFlowPaths` : login/refresh/2fa-login-verify/2fa-resend/password-reset(+confirm)/first-login) ; (2) `ErrorInterceptor` propage le message backend pour 401/403 (`UnauthorizedException(message)` / `ForbiddenException(message)`) ; (3) `login_screen._errorMessage` lit `DioException.error` (AppException typée) au lieu de matcher la chaîne brute → message fiable (identifiants / compte bloqué / réseau). |
| **Paramètres (hub) + Journaux d'audit** (19/06) | Nouvelle page `SettingsScreen` (`/settings`, route `AppRoutes.settings`) accessible à **tous les rôles** mais sections filtrées par rôle (`_roleSections` interne) : carte profil → `/profile`, Configuration entreprise (Zones/Dépôts), Finance (Config caisses), Catalogue (Catégories/Unités), **Sécurité & traçabilité (admin/superadmin uniquement)**, Compte (profil/notifs), Déconnexion. Nouvelle feature `audit/` (entity+model+datasource+provider+screen) : `AuditLogsScreen` (`/settings/audit-logs`) à 2 onglets **Audit** (filtres action create/update/delete + modèle CustomUser/Zone/Depot) et **Connexions** (filtre réussies/échouées), consomme `GET /audit-logs/` + `/login-logs/` (champs alignés sur les serializers Django). **Blocage frontend des logs** = la section "Sécurité" n'apparaît que pour admin/superadmin (backend renvoie 403 aux autres). **Drawer allégé** : Zones, Dépôts, Config. caisses, Catégories, Unités, Notifications, Mon profil retirés des menus → remplacés par une entrée unique "Paramètres" (`_compteSection` commune). |

### Ouverture de session caisse — « pas associé à un dépôt » (20/06/2026)

**Symptôme** : un admin qui **simule** un caissier (lui bien rattaché à un dépôt) ne pouvait pas
ouvrir de session → « Aucun dépôt associé à votre compte ».

**Cause racine** : `finance_provider.openSession()` lisait le dépôt depuis **`authProvider`**
(l'utilisateur réellement connecté = l'admin, `depot_id=null`) au lieu de **`effectiveUserProvider`**
(le caissier simulé, qui porte bien `depot_id`). L'UI s'appuie déjà sur `effectiveRoleProvider`
→ incohérence. **Corrigé** : `openSession` lit `ref.read(effectiveUserProvider)?.depotId`
(`finance_provider.dart`, import `role_simulation_provider`).

**Garde-fou associé — dépôt obligatoire** (`employees_screen.dart`, formulaires création + édition) :
les rôles opérationnels rattachés à un dépôt (caissier, commercial, chauffeur, gestionnaire_stock,
maintenancier — `_depotRoles`/`_needsDepot`) ont désormais un **validator** sur le dropdown « Dépôt »
(option « Aucun dépôt » masquée pour ces rôles) et `depot_id` est **toujours** envoyé. Empêche de
créer/éditer un de ces comptes sans dépôt. ⚠️ Garde-fou **backend** symétrique
(`accounts/serializers.py` — `DEPOT_BOUND_ROLES`, à déployer). `flutter analyze` = 0 issue.

> Distinction rappelée : **caisse physique** (coffre du dépôt, créée par l'admin) ≠ **session de
> caisse** (« section » : ouverture de poste du caissier SUR cette caisse). On ouvre une *session*
> sur une *caisse physique* ; la session appartient au caissier rattaché au dépôt.

### Scan QR mission — lectures partielles + champ code_barre produit (20/06/2026)

(1) **Fix scan QR** (`qr_scan_screen.dart`) : le scanner déclenchait l'appel API dès qu'il captait
n'importe quel code (lecture partielle / autofocus instable) → valeur malformée → faux « QR invalide ou
mission introuvable ». Corrigé : `MobileScannerController(detectionSpeed: noDuplicates, detectionTimeoutMs: 250,
formats: [qrCode])` + **validation regex UUID** de `rawValue` avant tout appel réseau (les lectures
non-UUID sont ignorées silencieusement, on continue de scanner). Message d'erreur reformulé (la cause
résiduelle est métier : mission non « Planifiée » ou non assignée au chauffeur connecté — pas un défaut de scan).
(2) **Champ `code_barre` produit** : ajouté à `ProductEntity`/`ProductModel` (`code_barre`) + champ de saisie
optionnel dans `_CreateProductSheet` (`products_list_screen.dart`, envoie `code_barre` au POST). Permet au
`BarcodeScanScreen` (recherche `?search=`) de retrouver un produit par son EAN/UPC. ⚠️ nécessite la migration
backend `produits/0004` déployée.

### Afficher le QR mission sur mobile (20/06/2026)

Le mobile savait **scanner** un QR (`scanQr`) mais ne pouvait pas **afficher** celui d'une mission (l'URL `missionQr(id)` existait dans `api_endpoints.dart` mais n'était branchée nulle part, et aucun bouton n'existait). Ajout chaîne Clean Arch complète : `getMissionQr(id)` dans datasource (lit `image_base64` de `GET /missions/{id}/qr/`) → repo interface + impl → `missionQrProvider` (family). Dans `mission_detail_screen.dart` : bouton **« Afficher le QR de la mission »** (`_ShowQrButton`) + modale `_QrDialog` (`Image.memory(base64Decode(...))`, texte « Le chauffeur scanne ce code pour démarrer le chargement »). **Gating** : admin / superviseur / gestionnaire_stock uniquement (pas le chauffeur, qui scanne — il ne s'auto-scanne pas) **et** mission `planifiee` (seul état scannable côté backend). `flutter analyze lib/features/logistics` = 0 issue.

**MAJ (20/06)** : ajout d'un bouton **« Enregistrer »** dans `_QrDialog` (le web avait « Télécharger », le mobile n'avait que « Fermer »). Décode le base64 → écrit `QR-{numero}.png` dans le dossier temporaire → `OpenFilex.open()` (même pattern que `PdfService._saveAndOpen`) → ouvre le visionneur système d'où on imprime / partage / enregistre dans la galerie. Visible uniquement quand l'image QR est chargée (`hasQr`).

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

### Design mobile-natif (20/06/2026) — Audit débordements & cibles tactiles

> Lot « pages mal foutues » : tuiles avec débordement `RenderFlex`, boutons d'action trop petits (< 44px), textes sans ellipsis. Palette `AppColors` conservée.

| Fichier | Correction |
| ------- | ---------- |
| `ajustements_screen.dart` | **(page signalée)** Tuile refondue : la méta « Par … • date » passe sur **sa propre ligne** (`maxLines:1` + ellipsis, fin du débordement) ; boutons **Approuver/Refuser** sortis de la ligne méta → ligne dédiée, **pleine largeur (`Expanded`), hauteur 44px**, icône + couleur (`_ActionButton` réécrit : `icon`/`filled`, `Material`+`InkWell`). Approuver = vert plein, Refuser = contour rouge. |
| `zones_screen.dart` | **(page signalée)** Coordonnées GPS de la tuile enveloppées dans `Flexible` + `maxLines:1`/ellipsis (anti-débordement à côté du nombre de dépôts). |
| `mission_detail_screen.dart` | Lignes marchandises : nom produit `maxLines:1`+ellipsis, `SizedBox` avant la quantité. |
| `transfer_screen.dart` | Bouton supprimer ligne : `BoxConstraints(minWidth:40, minHeight:40)` (cible tactile). |
| `missions_screen.dart` | Hint « Chargement… » du dropdown en `Flexible`+ellipsis. |
| `cash_session_screen.dart` | Montants KPI (`_SessionKpi`, `_MiniKpi`) : ajout `maxLines:1` (l'ellipsis existante était inopérante sans). |
| `caisses_screen.dart` | Nom + sous-titre de caisse (`_SoldeCard`) : `maxLines:1`+ellipsis. |
| `new_sale_screen.dart` | Ligne d'article : nom produit en ellipsis ; steppers −/+ agrandis **28→36px** (radius 6→8, icône 16→18). |

**Faux positifs de l'audit écartés** (vérifiés, non modifiés) : `cash_session` (pas de boutons +/-, badge non cliquable), `caisses` (« Fermer » = `TextButton` déjà ≥ 48px), `inventaires_screen` (paragraphe d'aide multi-ligne dans `Expanded` → s'enroule, tronquer aurait masqué l'explication), `new_sale` (label de chip de paiement court et statique). `flutter analyze` sur les 8 fichiers = **No issues found**.

### Corrections (18/06/2026) — Session 3 (audit croisé CDC + YAML + backend + skill)

| Fichier | Correction |
| ------- | ---------- |
| `api_endpoints.dart` | URL `/mouvements-dette-fournisseur/` → `/mouvements-dette/` (nom réel backend) |
| `api_endpoints.dart` | Ajout `configurationCaisses = '/configuration-caisses/'` |
| `app_routes.dart` | Ajout `financeConfig = '/finance/configuration'` |
| `app_router.dart` | Route `GoRoute(path: 'configuration', builder: CaisseConfigScreen)` sous `/finance` |
| `app_drawer.dart` (admin) | Ajout "Config. caisses" → `AppRoutes.financeConfig` après "Gestion des caisses" |
| `app_drawer.dart` (superviseur) | Suppression "Commandes fournisseurs" (périmètre gestionnaire_stock, pas superviseur) |
| `sales_list_screen.dart` | `canAnnuler` + `canPayer` : suppression `superadmin` (ne doit pas toucher aux ventes d'une entreprise) |
| `role_simulation_provider.dart` | Fail-safe role : `'caissier'` → `'commercial'` (principe moindre privilège) |
| `logistics_sub_screens.dart` | `carburant canCreate` : `['chauffeur', 'maintenancier', 'admin']` (suppression gestionnaire_stock et superviseur) |
| `products_list_screen.dart` | Import `api_client.dart` inutilisé supprimé |
| `ajustements_screen.dart` | `value:` → `initialValue:` dans `DropdownButtonFormField` |
| `transfer_screen.dart` | `value:` → `initialValue:` dans `DropdownButtonFormField` |
| `missions_screen.dart` | `value:` → `initialValue:` dans `DropdownButtonFormField` |
| `commandes_fournisseurs_screen.dart` | Accolades manquantes dans `if (mounted) setState(...)` |
| `flutter analyze` | **0 warnings** après toutes corrections (exit code 0 confirmé) |

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
| `/finance/configuration` | Config durées de période caisses (admin R/W, autres lecture seule) | Oui |
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
