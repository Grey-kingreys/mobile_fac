abstract class AppRoutes {
  // Onboarding (premier lancement)
  static const String onboarding = '/onboarding';

  // Auth (non protégées)
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String firstLogin = '/first-login';
  static const String twoFactor = '/two-factor';
  static const String twoFactorSetup = '/profile/2fa-setup';

  // App (protégées)
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String reports = '/reports';

  // Paramètres (hub — tous rôles, sections filtrées)
  static const String settings = '/settings';
  static const String auditLogs = '/settings/audit-logs';

  // Administration (superadmin & admin)
  static const String admin = '/admin';

  // Configuration (admin & superviseur)
  static const String zones = '/zones';
  static const String depots = '/depots';

  // Stocks
  static const String inventory = '/inventory';
  static const String inventoryEntree = '/inventory/entree';
  static const String inventoryMovements = '/inventory/movements';
  static const String inventoryBarcode = '/inventory/scan';
  static const String inventoryTransfer = '/inventory/transfer';
  static const String inventoryAjustements = '/inventory/ajustements';
  static const String inventoryInventaires = '/inventory/inventaires';

  // Ventes
  static const String sales = '/sales';
  static const String newSale = '/sales/new';
  static const String clients = '/sales/clients';
  static const String devis = '/sales/devis';

  // Finance
  static const String finance = '/finance';
  static const String financeTransactions = '/finance/transactions';
  static const String financeVersement = '/finance/versement';
  static const String financeDepenses = '/finance/depenses';
  static const String financeMobileMoney = '/finance/mobile-money';
  static const String financeCaisses = '/finance/caisses';
  static const String financeConfig = '/finance/configuration';
  static const String caisseEntrepriseConfig = '/finance/caisse-entreprise';

  // Logistique
  static const String logistics = '/logistics';
  static const String vehicules = '/logistics/vehicules';
  static const String missionDetail = '/logistics/:id';
  static const String qrScan = '/logistics/qr-scan';
  static const String signature = '/logistics/signature';
  static const String maintenances = '/logistics/maintenances';
  static const String pannes = '/logistics/pannes';
  static const String carburant = '/logistics/carburant';
  static const String documentsVehicule = '/logistics/documents-vehicule';

  // RH
  static const String hr = '/hr';
  // Route top-level (pas sous /hr) pour ne PAS instancier EmployeesScreen (=/users/)
  // quand un rôle opérationnel ouvre le pointage/congés.
  static const String attendance = '/attendance';

  // Fournisseurs
  static const String suppliers = '/suppliers';
  static const String supplierDetail = '/suppliers/:id';
  static const String commandesFournisseurs = '/suppliers/commandes';

  // Produits
  static const String products = '/products';
  static const String productDetail = '/products/:id';
  static const String categories = '/products/categories';
  static const String unites = '/products/unites';

  // Helpers
  static String missionDetailPath(int id) => '/logistics/$id';
  static String signaturePath(int id) => '/logistics/signature/$id';
  static String productDetailPath(int id) => '/products/$id';
  static String supplierDetailPath(int id) => '/suppliers/$id';
}
