import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:customer_nzubia_global/core/theme/custom_theme_extension.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/widgets/glass_container.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/features/profile/domain/entities/user_profile_entity.dart';
import 'package:customer_nzubia_global/features/auth/domain/entities/user_entity.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:customer_nzubia_global/core/widgets/offline_error_widget.dart';

class AgentFinanceScreen extends StatefulWidget {
  const AgentFinanceScreen({super.key});

  @override
  State<AgentFinanceScreen> createState() => _AgentFinanceScreenState();
}

class _AgentFinanceScreenState extends State<AgentFinanceScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _transactions = [];
  Map<String, dynamic> _earningsData = {
    'total': 0.0,
    'pending': 0.0,
    'available': 0.0,
    'paidOut': 0.0
  };
  Map<String, dynamic>? _stripeStatus;
  Map<String, dynamic>? _payoutStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStripeStatus();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchEarnings(),
      _checkStripeStatus(),
      _checkPayoutStatus(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _checkPayoutStatus() async {
    try {
      final response = await sl<DioClient>().dio.get('/users/payout/status');
      if (mounted) setState(() => _payoutStatus = response.data);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to check payout status: $e');
    }
  }

  Future<void> _checkStripeStatus() async {
    try {
      final status = await sl<AuthRepository>().checkStripeStatus();
      if (mounted) setState(() => _stripeStatus = status);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to check Stripe status: $e');
    }
  }

  Future<void> _connectStripe() async {
    try {
      final url = await sl<AuthRepository>().getStripeOnboardingLink();
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
    }
  }

  Future<void> _fetchEarnings() async {
    try {
      final response = await sl<DioClient>().dio.get('/transactions/agent/earnings');
      if (response.data is Map) {
         if (mounted) {
           setState(() {
             _earningsData = {
                'total': (response.data['total'] ?? 0.0).toDouble(),
                'pending': (response.data['pending'] ?? 0.0).toDouble(),
                'available': (response.data['available'] ?? 0.0).toDouble(),
                'paidOut': (response.data['paidOut'] ?? 0.0).toDouble(),
             };
             // Assuming transactions endpoint is separate or part of this?
             // Admin fetches simple earnings then transactions.
             // We'll keep existing transaction list if available or fetch separately.
           });
           // Fetch transactions separately if needed, for now assuming simpler flow.
           final transResponse = await sl<DioClient>().dio.get('/transactions/my-transactions');
           if (mounted) {
              setState(() {
                 _transactions = transResponse.data ?? [];
              });
           }
         }
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load earnings'; });
    }
  }

  Future<void> _requestPayout() async {
     double available = _earningsData['available'] ?? 0.0;
     if (available < 100) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum payout amount is \$100')));
        return;
     }

     try {
       await sl<DioClient>().dio.post('/transactions', data: {
          'type': 'PAYOUT_SENT',
          'amount': available,
          'currency': 'USD',
          'description': 'Agent payout request',
       });
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout requested successfully!')));
          _fetchEarnings();
       }
     } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to request payout')));
     }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.financeAndEarnings),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
// Button removed as per user request
           /* Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: Center(
               child: ElevatedButton(
                 onPressed: (_earningsData['available'] ?? 0) >= 100 ? _requestPayout : null,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: colors?.neonLime,
                   disabledBackgroundColor: Colors.grey[800],
                   foregroundColor: Colors.black,
                 ),
                 child: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.bold)),
               ),
             ),
           ) */
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
           ? OfflineErrorWidget(
               errorMessage: _error!,
               onRetry: _loadData,
             )
           : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // _buildBankAccountStatus(context), // Removed as requested
                  _buildEarningsSummary(context),
                  const SizedBox(height: 16),
                  TabBar(
                    labelColor: colors?.neonCyan ?? Colors.cyan,
                    unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    indicatorColor: colors?.neonCyan ?? Colors.cyan,
                    tabs: [
                      Tab(text: AppLocalizations.of(context)!.transactions),
                      Tab(text: AppLocalizations.of(context)!.zelleSettings),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                         _TransactionsView(transactions: _transactions),
                         _PayoutSettingsView(
                           stripeStatus: _stripeStatus,
                           payoutStatus: _payoutStatus,
                           onRefresh: _loadData,
                         ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEarningsSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final bool payoutEnabled = _stripeStatus?['payoutsEnabled'] ?? false;
    final bool chargesEnabled = _stripeStatus?['enabled'] ?? false;
    final bool isConnected = payoutEnabled && chargesEnabled;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
           // Total
           Text(AppLocalizations.of(context)!.totalEarned, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
           Text('\$${(_earningsData['total'] ?? 0).toStringAsFixed(2)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.textTheme.headlineMedium?.color)),
           
           const SizedBox(height: 16),
           
           // Payout Status
           if (isConnected)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: (colors?.neonLime ?? Colors.green).withOpacity(0.2),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: colors?.neonLime ?? Colors.green),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Icon(Icons.check_circle, size: 16, color: colors?.neonLime ?? Colors.green),
                   const SizedBox(width: 6),
                   Text(AppLocalizations.of(context)!.payoutsEnabled, style: TextStyle(color: colors?.neonLime ?? Colors.green, fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
             
           const SizedBox(height: 24),
           
           // Shortcut to Settings

             
           const SizedBox(height: 24),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: [
                _buildStat(context, AppLocalizations.of(context)!.pending, _earningsData['pending'], colors?.warning ?? Colors.orange),
                _buildStat(context, AppLocalizations.of(context)!.available, _earningsData['available'], colors?.neonLime ?? Colors.green),
                _buildStat(context, AppLocalizations.of(context)!.paidOut, _earningsData['paidOut'], Colors.blue),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, double amount, Color color) {
     final theme = Theme.of(context);
     return Column(
       children: [
         Text(label, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
         const SizedBox(height: 4),
         Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
       ],
     );
  }

  Widget _buildBankAccountStatus(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();
    
    final canReceivePayouts = _payoutStatus?['canReceivePayouts'] ?? false;
    final isLegacyConnect = _payoutStatus?['isLegacyConnect'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canReceivePayouts 
          ? (colors?.neonLime ?? Colors.green).withOpacity(0.1)
          : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canReceivePayouts 
            ? (colors?.neonLime ?? Colors.green)
            : Colors.orange,
        ),
      ),
      child: Row(
        children: [
          Icon(
            canReceivePayouts ? Icons.check_circle : Icons.warning_amber,
            color: canReceivePayouts 
              ? (colors?.neonLime ?? Colors.green)
              : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    canReceivePayouts 
                      ? AppLocalizations.of(context)!.bankAccountConnected
                      : AppLocalizations.of(context)!.connectBankAccount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  canReceivePayouts
                    ? (isLegacyConnect 
                        ? 'Using Stripe Connect (Legacy)' // This is fine for now, or use a key if I have one
                        : AppLocalizations.of(context)!.readyToReceivePayouts)
                    : AppLocalizations.of(context)!.linkBankToReceivePayouts,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          if (!canReceivePayouts)
            ElevatedButton(
              onPressed: () async {
                final result = await context.push('/bank-setup');
                if (result == true && mounted) {
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.linkBank),
            ),
        ],
      ),
    );
  }
}

class _PayoutSettingsView extends StatefulWidget {
  final Map<String, dynamic>? stripeStatus;
  final Map<String, dynamic>? payoutStatus;
  final VoidCallback onRefresh;

  const _PayoutSettingsView({
    this.stripeStatus,
    this.payoutStatus,
    required this.onRefresh,
  });

  @override
  State<_PayoutSettingsView> createState() => _PayoutSettingsViewState();
}

class _PayoutSettingsViewState extends State<_PayoutSettingsView> {
  late TextEditingController _zelleEmailController;
  late TextEditingController _zellePhoneController;
  String _selectedMethod = 'STRIPE';
  bool _isSaving = false;
  bool _isEditing = false;
  String? _zellePhoneIsoCode;
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  @override
  void initState() {
    super.initState();
    _zelleEmailController = TextEditingController();
    _zellePhoneController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await sl<AuthRepository>().getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _selectedMethod = user.preferredPayoutMethod ?? 'STRIPE';
        _zelleEmailController.text = user.zelleEmail ?? '';
        _zellePhoneController.text = user.zellePhone ?? ''; // This might contain full number
        // Extract ISO code if stored separately or handle during input? 
        // For simplicity, we assume user re-enters or we just show what we have.
      });
    }
  }

  @override
  void dispose() {
    _zelleEmailController.dispose();
    _zellePhoneController.dispose();
    super.dispose();
  }

  Future<void> _updateSettings() async {
    if (_selectedMethod == 'ZELLE') {
       if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isSaving = true);
    try {
      await sl<AuthRepository>().updateAgentProfile(
        preferredPayoutMethod: _selectedMethod,
        zelleEmail: _zelleEmailController.text.trim(),
        zellePhone: _zellePhoneController.text.trim(), // Consider formatting with country code
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.payoutInfoUpdated)),
        );
        widget.onRefresh();
        await _loadProfile();
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();
    final isStripeEnabled = widget.stripeStatus?['payoutsEnabled'] ?? false;

    // View Mode for Zelle
    if (!_isEditing && _selectedMethod == 'ZELLE') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReadOnlyView(context, theme, colors),
            const SizedBox(height: 24),
             SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit),
                label: Text(AppLocalizations.of(context)!.edit),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
     // Edit Mode (Or initial setup)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.preferredPayoutMethod,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.choosePayoutMethod,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // Method Selection
            Row(
              children: [
                Expanded(
                  child: _buildMethodCard(
                    AppLocalizations.of(context)!.stripeConnect,
                    'STRIPE',
                    Icons.account_balance,
                    isStripeEnabled ? Colors.green : Colors.grey,
                    isStripeEnabled ? AppLocalizations.of(context)!.payoutMethodActive : AppLocalizations.of(context)!.payoutMethodNotConnected,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMethodCard(
                    AppLocalizations.of(context)!.zelleTransfer,
                    'ZELLE',
                    Icons.mobile_friendly,
                    Colors.deepPurple,
                    AppLocalizations.of(context)!.manual,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_selectedMethod == 'STRIPE') ...[
               _buildStripeSection(theme, colors),
            ] else ...[
               _buildZelleSection(theme, colors),
            ],

            const SizedBox(height: 32),
            
            Row(
              children: [
                if (_isEditing) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                         setState(() {
                           _isEditing = false;
                           _loadProfile(); // Reset changes
                         });
                      },
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors?.neonLime ?? Colors.green,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(AppLocalizations.of(context)!.savePayoutSettings, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyView(BuildContext context, ThemeData theme, AppColorsExtension? colors) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.mobile_friendly, color: Colors.deepPurple, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.zelleTransfer, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: (colors?.neonLime ?? Colors.green).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text(AppLocalizations.of(context)!.active.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors?.neonLime ?? Colors.green)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(theme, AppLocalizations.of(context)!.zelleEmail, _zelleEmailController.text),
            const Divider(height: 24),
            _buildInfoRow(theme, AppLocalizations.of(context)!.zellePhoneNumber, _zellePhoneController.text),
          ],
        ),
      );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        Text(value.isNotEmpty ? value : '-', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMethodCard(String title, String value, IconData icon, Color color, String status) {
    final isSelected = _selectedMethod == value;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStripeSection(ThemeData theme, AppColorsExtension? colors) {
    final payoutsEnabled = widget.stripeStatus?['payoutsEnabled'] ?? false;
    
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: colors?.neonCyan),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.stripeConnectTitle, style: TextStyle(color: colors?.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            payoutsEnabled 
              ? 'Your Stripe account is fully connected and ready for automated payouts.'
              : 'Stripe enables automated payouts directly to your bank account. You must complete onboarding to activate this.',
            style: theme.textTheme.bodyMedium,
          ),
          if (!payoutsEnabled) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await context.push('/bank-setup');
                if (result == true) widget.onRefresh();
              },
              child: const Text('Setup Stripe Wallet'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZelleSection(ThemeData theme, AppColorsExtension? colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.manualTransferTitle, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Zelle payouts are processed manually by our finance team. Please ensure your contact details are correct.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.zelleSettings, style: theme.textTheme.titleSmall), 
        const SizedBox(height: 12),
        TextFormField(
          controller: _zelleEmailController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.zelleEmailLabel,
            hintText: 'e.g. your@email.com',
            prefixIcon: const Icon(Icons.email_outlined),
          ),
           validator: (value) {
            if (value == null || value.isEmpty) {
              // If phone is empty, email is required (or maybe both optional? usually one is needed for Zelle)
              // Let's require at least one contact method for Zelle. 
              // Simplifying: Require Email if Phone is empty
              if (_zellePhoneController.text.isEmpty) return 'Email or Phone is required';
              return null; 
            }
            if (value.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return AppLocalizations.of(context)!.invalidEmail;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // PHONE INPUT
        IntlPhoneField(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.zellePhoneLabel,
            border: const OutlineInputBorder(
              borderSide: BorderSide(),
            ),
          ),
          initialCountryCode: 'US',
          onChanged: (phone) {
            _zellePhoneController.text = phone.completeNumber;
            _zellePhoneIsoCode = phone.countryISOCode;
          },
          initialValue: _zellePhoneController.text, // May need parsing to separate code if complex
        ),
      ],
    );
  }
}

class _TransactionsView extends StatelessWidget {
  final List<dynamic> transactions;
  const _TransactionsView({required this.transactions});

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: theme.iconTheme.color?.withOpacity(0.24)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noTransactionsYet, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
      itemBuilder: (context, index) {
        final t = transactions[index];
        final List<String> urls = [];
        if (t['payout_proof_urls'] != null && t['payout_proof_urls'] is List) {
          urls.addAll((t['payout_proof_urls'] as List).map((e) => e.toString()));
        } else if (t['payout_proof_url'] != null) {
          urls.add(t['payout_proof_url'].toString());
        }

        final isPayout = t['type'] == 'PAYOUT_SENT';

        return GestureDetector(
          onTap: () => context.push('/agent/transaction-detail', extra: t),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPayout 
                              ? Colors.orange.withOpacity(0.1)
                              : (colors?.neonLime ?? Colors.green).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPayout ? Icons.arrow_upward : Icons.arrow_downward, 
                            color: isPayout ? Colors.orange : (colors?.neonLime ?? Colors.green), 
                            size: 20
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPayout 
                                ? 'Payout #${t['id'].toString().substring(0,8)}' 
                                : 'Payment #${t['id'].toString().substring(0,8)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)
                            ),
                            Text(DateFormat.yMMMd().format(DateTime.parse(t['created_at'])),
                              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${isPayout ? '+' : '+'}\$${t['amount']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: isPayout ? Colors.orange : (colors?.neonLime ?? Colors.green), 
                        fontSize: 16
                      ),
                    ),
                  ],
                ),
                if (urls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.payoutProofTitle ?? 'Proof of Payment:', 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: urls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        return GestureDetector(
                          onTap: () => _showImagePreview(context, urls[i]),
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(urls[i]),
                                fit: BoxFit.cover,
                              ),
                              border: Border.all(color: theme.dividerColor),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
