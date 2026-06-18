abstract class ApiEndpoints {
  static const String baseUrl = 'https://gestion.kingreys.fr/api';

  // Auth
  static const String login = '/auth/login/';
  static const String refreshToken = '/auth/refresh/';
  static const String logout = '/auth/logout/';
  static const String me = '/auth/me/';
  static const String changePassword = '/auth/me/change-password/';
  static const String passwordReset = '/auth/password-reset/';
  static const String passwordResetConfirm = '/auth/password-reset/confirm/';
  static const String firstLogin = '/auth/first-login/';

  // 2FA
  static const String twoFaSetup = '/auth/2fa/setup/';
  static const String twoFaSetupVerify = '/auth/2fa/setup-verify/';
  static const String twoFaDisable = '/auth/2fa/disable/';
  static const String twoFaLoginVerify = '/auth/2fa/login-verify/';
  static const String twoFaResend = '/auth/2fa/resend/';

  // Utilisateurs & Audit
  static const String users = '/users/';
  static String userDetail(int id) => '/users/$id/';
  static String userResetPassword(int id) => '/users/$id/reset-password/';
  static const String auditLogs = '/audit-logs/';
  static const String loginLogs = '/login-logs/';

  // Entreprises & Zones & Dépôts
  static const String companies = '/companies/';
  static String companyDetail(int id) => '/companies/$id/';
  static String companyToggle(int id) => '/companies/$id/toggle/';
  static const String zones = '/zones/';
  static String zoneDetail(int id) => '/zones/$id/';
  static const String depots = '/depots/';
  static String depotDetail(int id) => '/depots/$id/';
  static String depotDashboard(int id) => '/depots/$id/dashboard/';
  static const String superadminDashboard = '/superadmin/dashboard/';

  // Analytics
  static const String analyticsVentes = '/analytics/ventes/';
  static const String analyticsStock = '/analytics/stock/';
  static const String analyticsFinance = '/analytics/finance/';
  static const String analyticsTva = '/analytics/tva/';
  static const String analyticsPerformance = '/analytics/performance/';

  // Produits
  static const String categories = '/categories/';
  static String categoryDetail(int id) => '/categories/$id/';
  static const String unites = '/unites/';
  static String uniteDetail(int id) => '/unites/$id/';
  static const String fournisseurs = '/fournisseurs/';
  static String fournisseurDetail(int id) => '/fournisseurs/$id/';
  static String fournisseurEvaluations(int id) => '/fournisseurs/$id/evaluations/';
  static const String produits = '/produits/';
  static String produitDetail(int id) => '/produits/$id/';
  static String produitStock(int id) => '/produits/$id/stock/';
  static const String commandesFournisseurs = '/commandes-fournisseurs/';
  static String commandeFournisseurDetail(int id) => '/commandes-fournisseurs/$id/';
  static String commandeFournisseurRecevoir(int id) => '/commandes-fournisseurs/$id/recevoir/';
  static const String mouvementsDettesFournisseur = '/mouvements-dette/';
  static const String evaluationsFournisseurs = '/evaluations-fournisseurs/';

  // Stocks
  static const String stocks = '/stocks/';
  static const String stockEntree = '/stocks/entree/';
  static const String stockSortie = '/stocks/sortie/';
  static const String mouvementsStock = '/mouvements-stock/';
  static const String transferts = '/transferts/';
  static String transfertDetail(int id) => '/transferts/$id/';
  static String transfertExpedier(int id) => '/transferts/$id/expedier/';
  static String transfertReceptionner(int id) => '/transferts/$id/receptionner/';
  static String transfertAnnuler(int id) => '/transferts/$id/annuler/';
  static const String inventaires = '/inventaires/';
  static String inventaireDetail(int id) => '/inventaires/$id/';
  static String inventaireValider(int id) => '/inventaires/$id/valider/';
  static const String ajustements = '/ajustements-stock/';
  static String ajustementDetail(int id) => '/ajustements-stock/$id/';
  static String ajustementApprouver(int id) => '/ajustements-stock/$id/approuver/';
  static String ajustementRefuser(int id) => '/ajustements-stock/$id/refuser/';

  // Ventes
  static const String clients = '/clients/';
  static String clientDetail(int id) => '/clients/$id/';
  static const String clientsCreances = '/clients/creances/';
  static const String commandes = '/commandes/';
  static String commandeDetail(int id) => '/commandes/$id/';
  static String commandePaiement(int id) => '/commandes/$id/paiement/';
  static String commandeAnnuler(int id) => '/commandes/$id/annuler/';
  static String commandeFacture(int id) => '/commandes/$id/facture/';
  static String commandeBonLivraison(int id) => '/commandes/$id/bon-livraison/';
  static const String fideliteParametres = '/fidelite/parametres/';
  static const String devis = '/devis/';
  static String devisDetail(int id) => '/devis/$id/';
  static String devisConvertir(int id) => '/devis/$id/convertir/';
  static const String retours = '/retours/';
  static String retourDetail(int id) => '/retours/$id/';
  static const String historiquePoints = '/historique-points/';
  static const String promotions = '/promotions/';
  static String promotionDetail(int id) => '/promotions/$id/';

  // Finance
  static const String tauxChange = '/taux-change/';
  static String tauxChangeDetail(int id) => '/taux-change/$id/';
  static const String caisses = '/caisses/';
  static String caisseDetail(int id) => '/caisses/$id/';
  static String caisseFermer(int id) => '/caisses/$id/fermer/';
  static const String caissesZone = '/caisses-zone/';
  static String caisseZoneDetail(int id) => '/caisses-zone/$id/';
  static String caisseZoneFermer(int id) => '/caisses-zone/$id/fermer/';
  static const String caisseEntreprise = '/caisse-entreprise/';
  static const String caisseEntrepriseMe = '/caisse-entreprise/me/';
  static const String caissesConsolidation = '/caisses/consolidation/';
  static const String configurationCaisses = '/configuration-caisses/';
  static const String sessionsCaisse = '/sessions-caisse/';
  static String sessionCaisseDetail(int id) => '/sessions-caisse/$id/';
  static const String sessionCaisseOuvrir = '/sessions-caisse/ouvrir/';
  static String sessionCaisseFermer(int id) => '/sessions-caisse/$id/fermer/';
  static String sessionCaisseTransaction(int id) => '/sessions-caisse/$id/transaction/';
  static const String versementsCaisse = '/versements-caisse/';
  static const String comptesMobileMoney = '/comptes-mobile-money/';
  static String compteMobileMoneyDetail(int id) => '/comptes-mobile-money/$id/';
  static String compteMobileMoneyTransaction(int id) => '/comptes-mobile-money/$id/transaction/';
  static String compteMobileMoneyTransactions(int id) => '/comptes-mobile-money/$id/transactions/';
  static const String depenses = '/depenses/';
  static String depenseDetail(int id) => '/depenses/$id/';

  // Logistique
  static const String vehicules = '/vehicules/';
  static String vehiculeDetail(int id) => '/vehicules/$id/';
  static const String missions = '/missions/';
  static String missionDetail(int id) => '/missions/$id/';
  static String missionChargement(int id) => '/missions/$id/chargement/';
  static String missionTransit(int id) => '/missions/$id/transit/';
  static String missionArrivee(int id) => '/missions/$id/arrivee/';
  static String missionTerminer(int id) => '/missions/$id/terminer/';
  static String missionAnnuler(int id) => '/missions/$id/annuler/';
  static String missionPosition(int id) => '/missions/$id/position/';
  static String missionPositions(int id) => '/missions/$id/positions/';
  static String missionQr(int id) => '/missions/$id/qr/';
  static const String missionsScannerQr = '/missions/scanner-qr/';
  static String missionBonLivraison(int id) => '/missions/$id/bon-livraison/';
  static const String maintenances = '/maintenances/';
  static String maintenanceDetail(int id) => '/maintenances/$id/';
  static const String pannes = '/pannes/';
  static String panneDetail(int id) => '/pannes/$id/';
  static String panneResoudre(int id) => '/pannes/$id/resoudre/';
  static const String documentsVehicule = '/documents-vehicule/';
  static String documentVehiculeDetail(int id) => '/documents-vehicule/$id/';
  static const String carburant = '/carburant/';
  static String carburantDetail(int id) => '/carburant/$id/';

  // RH
  static const String employes = '/employes/';
  static String employeDetail(int id) => '/employes/$id/';
  static String employePresences(int id) => '/employes/$id/presences/';
  static String employeConges(int id) => '/employes/$id/conges/';
  static String employeDocuments(int id) => '/employes/$id/documents/';
  static String employeAffectations(int id) => '/employes/$id/affectations/';
  static const String presences = '/presences/';
  static String presenceDetail(int id) => '/presences/$id/';
  static const String conges = '/conges/';
  static String congeDetail(int id) => '/conges/$id/';
  static String congeApprouver(int id) => '/conges/$id/approuver/';
  static String congeRefuser(int id) => '/conges/$id/refuser/';
  static const String documents = '/documents/';
  static String documentDetail(int id) => '/documents/$id/';
  static const String objectifsVente = '/objectifs-vente/';
  static String objectifVenteDetail(int id) => '/objectifs-vente/$id/';

  // Notifications
  static const String notifications = '/notifications/';
  static String notificationLire(int id) => '/notifications/$id/lire/';
  static const String notificationsToutLire = '/notifications/tout-lire/';
}
