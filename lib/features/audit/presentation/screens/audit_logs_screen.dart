import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/audit/domain/entities/audit_log_entity.dart';
import 'package:djoulagest_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

/// Journaux d'audit + connexion. Réservé Admin / SuperAdmin (l'accès est filtré
/// en amont par la page Paramètres ; le backend renvoie 403 aux autres rôles).
class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Journaux',
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.gray500,
                indicatorColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.fontSm,
                ),
                tabs: [
                  Tab(text: 'Audit'),
                  Tab(text: 'Connexions'),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
            const Expanded(
              child: TabBarView(
                children: [
                  _AuditTab(),
                  _LoginTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Onglet Audit ─────────────────────────────────────────────────────────────

class _AuditTab extends ConsumerStatefulWidget {
  const _AuditTab();

  @override
  ConsumerState<_AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends ConsumerState<_AuditTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollCtrl = ScrollController();

  static const _actionFilters = [
    ('Toutes', null),
    ('Création', 'create'),
    ('Modification', 'update'),
    ('Suppression', 'delete'),
  ];
  static const _modelFilters = [
    ('Tous', null),
    ('Utilisateurs', 'CustomUser'),
    ('Zones', 'Zone'),
    ('Dépôts', 'Depot'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        ref.read(auditLogsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final asyncState = ref.watch(auditLogsProvider);
    final notifier = ref.read(auditLogsProvider.notifier);
    final current = asyncState.valueOrNull;

    return Column(
      children: [
        // Filtres action
        _FilterChipsRow<String?>(
          options: _actionFilters,
          selected: current?.action,
          onSelected: (v) => notifier.setFilters(action: v),
        ),
        // Filtres modèle
        _FilterChipsRow<String?>(
          options: _modelFilters,
          selected: current?.modelName,
          onSelected: (v) => notifier.setFilters(modelName: v),
        ),
        const SizedBox(height: AppSizes.xs),
        Expanded(
          child: asyncState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: notifier.refresh,
            ),
            data: (state) {
              if (state.logs.isEmpty) {
                return const _EmptyView(
                  icon: Icons.history_rounded,
                  message: 'Aucune action enregistrée',
                );
              }
              return RefreshIndicator(
                onRefresh: notifier.refresh,
                child: ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingPage, AppSizes.xs, AppSizes.paddingPage, AppSizes.xxl,
                  ),
                  itemCount: state.logs.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, i) {
                    if (i >= state.logs.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSizes.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _AuditTile(log: state.logs[i]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.log});
  final AuditLogEntity log;

  static const _modelLabels = {
    'CustomUser': 'Utilisateur',
    'Zone': 'Zone',
    'Depot': 'Dépôt',
  };

  ({Color color, IconData icon}) get _style {
    switch (log.action) {
      case 'create':
        return (color: AppColors.secondary, icon: Icons.add_circle_outline_rounded);
      case 'update':
        return (color: AppColors.info, icon: Icons.edit_outlined);
      case 'delete':
        return (color: AppColors.danger, icon: Icons.delete_outline_rounded);
      default:
        return (color: AppColors.gray500, icon: Icons.history_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final modelLabel = _modelLabels[log.modelName] ?? log.modelName;
    return _CardTile(
      onTap: () => _showDetail(context),
      leadingColor: s.color,
      leadingIcon: s.icon,
      title: '$modelLabel #${log.objectId}',
      subtitleLines: [
        log.author,
        AppFormatters.dateTime(log.timestamp),
      ],
      trailing: _Badge(label: log.actionDisplay, color: s.color),
    );
  }

  void _showDetail(BuildContext context) {
    final s = _style;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        icon: s.icon,
        color: s.color,
        title: '${log.actionDisplay} · ${_modelLabels[log.modelName] ?? log.modelName} #${log.objectId}',
        rows: [
          ('Auteur', log.author),
          ('Action', log.actionDisplay),
          ('Modèle', log.modelName),
          ('Objet', '#${log.objectId}'),
          if (log.ipAddress != null) ('Adresse IP', log.ipAddress!),
          ('Horodatage', AppFormatters.dateTime(log.timestamp)),
        ],
        jsonBefore: log.dataBefore,
        jsonAfter: log.dataAfter,
      ),
    );
  }
}

// ─── Onglet Connexions ────────────────────────────────────────────────────────

class _LoginTab extends ConsumerStatefulWidget {
  const _LoginTab();

  @override
  ConsumerState<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends ConsumerState<_LoginTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollCtrl = ScrollController();

  static const _filters = [
    ('Toutes', null),
    ('Réussies', true),
    ('Échouées', false),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        ref.read(loginLogsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final asyncState = ref.watch(loginLogsProvider);
    final notifier = ref.read(loginLogsProvider.notifier);
    final current = asyncState.valueOrNull;

    return Column(
      children: [
        _FilterChipsRow<bool?>(
          options: _filters,
          selected: current?.success,
          onSelected: notifier.setSuccessFilter,
        ),
        const SizedBox(height: AppSizes.xs),
        Expanded(
          child: asyncState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: notifier.refresh,
            ),
            data: (state) {
              if (state.logs.isEmpty) {
                return const _EmptyView(
                  icon: Icons.login_rounded,
                  message: 'Aucune connexion enregistrée',
                );
              }
              return RefreshIndicator(
                onRefresh: notifier.refresh,
                child: ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingPage, AppSizes.xs, AppSizes.paddingPage, AppSizes.xxl,
                  ),
                  itemCount: state.logs.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, i) {
                    if (i >= state.logs.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSizes.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _LoginTile(log: state.logs[i]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoginTile extends StatelessWidget {
  const _LoginTile({required this.log});
  final LoginLogEntity log;

  @override
  Widget build(BuildContext context) {
    final color = log.success ? AppColors.secondary : AppColors.danger;
    final icon = log.success ? Icons.check_circle_outline_rounded : Icons.block_rounded;
    return _CardTile(
      onTap: () => _showDetail(context),
      leadingColor: color,
      leadingIcon: icon,
      title: log.author,
      subtitleLines: [
        if (log.ipAddress != null) 'IP : ${log.ipAddress}',
        AppFormatters.dateTime(log.timestamp),
      ],
      trailing: _Badge(
        label: log.success ? 'Réussie' : 'Échouée',
        color: color,
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = log.success ? AppColors.secondary : AppColors.danger;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        icon: log.success ? Icons.check_circle_outline_rounded : Icons.block_rounded,
        color: color,
        title: log.success ? 'Connexion réussie' : 'Connexion échouée',
        rows: [
          ('Compte', log.author),
          ('Statut', log.success ? 'Réussie' : 'Échouée'),
          if (log.ipAddress != null) ('Adresse IP', log.ipAddress!),
          if (log.userAgent.isNotEmpty) ('Navigateur', log.userAgent),
          ('Horodatage', AppFormatters.dateTime(log.timestamp)),
        ],
      ),
    );
  }
}

// ─── Widgets partagés ─────────────────────────────────────────────────────────

class _FilterChipsRow<T> extends StatelessWidget {
  const _FilterChipsRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, T)> options;
  final T selected;
  final void Function(T value) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingPage,
          vertical: AppSizes.sm,
        ),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.xs),
        itemBuilder: (_, i) {
          final (label, value) = options[i];
          final active = value == selected;
          return ChoiceChip(
            label: Text(label),
            selected: active,
            onSelected: (_) => onSelected(value),
            showCheckmark: false,
            labelStyle: TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? AppColors.primary : AppColors.gray600,
            ),
            backgroundColor: AppColors.gray50,
            selectedColor: AppColors.primaryLightBg,
            side: BorderSide(
              color: active ? AppColors.primary.withValues(alpha: 0.4) : AppColors.gray200,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
          );
        },
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.leadingColor,
    required this.leadingIcon,
    required this.title,
    required this.subtitleLines,
    required this.trailing,
    this.onTap,
  });

  final Color leadingColor;
  final IconData leadingIcon;
  final String title;
  final List<String> subtitleLines;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: leadingColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(leadingIcon, color: leadingColor, size: AppSizes.iconMd),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                        fontSize: AppSizes.fontSm,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    ...subtitleLines.map(
                      (l) => Text(
                        l,
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: AppSizes.fontXs,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.icon,
    required this.color,
    required this.title,
    required this.rows,
    this.jsonBefore,
    this.jsonAfter,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<(String, String)> rows;
  final Map<String, dynamic>? jsonBefore;
  final Map<String, dynamic>? jsonAfter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Icon(icon, color: color, size: AppSizes.iconMd),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...rows.map((r) => _DetailRow(label: r.$1, value: r.$2)),
                      if (jsonBefore != null && jsonBefore!.isNotEmpty)
                        _JsonBlock(title: 'Données avant', data: jsonBefore!),
                      if (jsonAfter != null && jsonAfter!.isNotEmpty)
                        _JsonBlock(title: 'Données après', data: jsonAfter!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: AppSizes.fontXs,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonBlock extends StatelessWidget {
  const _JsonBlock({required this.title, required this.data});
  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.gray400,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${e.key} : ${e.value}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryLightBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
              fontSize: AppSizes.fontMd,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.gray300),
            const SizedBox(height: AppSizes.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
