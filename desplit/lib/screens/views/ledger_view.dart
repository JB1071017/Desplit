import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';

class LedgerView extends StatefulWidget {
  const LedgerView({super.key});

  @override
  State<LedgerView> createState() => _LedgerViewState();
}

class _LedgerViewState extends State<LedgerView> {
  // Navigation tabs: 'Overview', 'Payment', 'Transaction', 'Cards', 'Reports'
  String _activeSubTab = 'Overview';
  String _activityTimeframe = 'Week';
  String _categoryTimeframe = 'Month';
  int? _hoveredCardIndex;
  int? _hoveredRowIndex;
  int _selectedNodeIndex = 1;

  final List<String> _subTabs = [
    'Overview',
    'Payment',
    'Transaction',
    'Cards',
    'Reports',
  ];

  // ---------------------------------------------------------------------------
  // PAYMENT TAB STATE
  // ---------------------------------------------------------------------------
  String _paymentRecipientType = 'NODE'; // 'NODE' or 'WALLET'
  String _selectedPaymentNode = 'Node-US (Virginia Mesh) • 0x71a4...84c1';
  final TextEditingController _walletAddressController = TextEditingController();
  final TextEditingController _paymentAmountController = TextEditingController(text: '12500');
  final TextEditingController _paymentMemoController = TextEditingController(text: 'FedAvg Round 4 gradient compute reward');
  String _paymentSpeed = 'Fast'; // 'Standard', 'Fast', 'Instant'
  bool _isProcessingPayment = false;

  final List<String> _availableNodes = [
    'Node-US (Virginia Mesh) • 0x71a4...84c1',
    'Node-SG (Singapore Shard) • 0x82c1...91a7',
    'Node-DE (Frankfurt Shard) • 0x39f5...28b2',
    'Node-JP (Tokyo Validator) • 0x14d8...55e0',
    'Node-IN (Bengaluru Shard) • 0x67e2...33f4',
    'Node-UK (London Data) • 0x58b9...77a3',
  ];

  final List<Map<String, dynamic>> _scheduledPayments = [
    {
      'title': 'Weekly Compute Worker Payroll',
      'amount': '120,000 SPLIT',
      'cadence': 'Every Friday • 18:00 UTC',
      'active': true,
      'recipients': '8 Active Nodes',
    },
    {
      'title': 'Daily Validator Staking Compounder',
      'amount': '25,000 SPLIT',
      'cadence': 'Daily at 00:00 UTC',
      'active': true,
      'recipients': 'Staking Vault',
    },
    {
      'title': 'Cluster Bandwidth Ingress Escrow',
      'amount': '15,000 SPLIT',
      'cadence': 'Monthly • 1st of month',
      'active': false,
      'recipients': 'WireGuard Gateway',
    },
  ];

  final List<Map<String, dynamic>> _pendingInvoices = [
    {
      'id': 'INV-8821',
      'node': 'Node-SG (Singapore)',
      'amount': '14,200 SPLIT',
      'for': '72h GPU Compute Slice (Shard 2)',
      'status': 'PENDING',
    },
    {
      'id': 'INV-8824',
      'node': 'Node-DE (Frankfurt)',
      'amount': '8,500 SPLIT',
      'for': 'Validator Shard 4 Aggregation Buffer',
      'status': 'PENDING',
    },
  ];

  // ---------------------------------------------------------------------------
  // TRANSACTION TAB STATE
  // ---------------------------------------------------------------------------
  String _txSearchQuery = '';
  String _txStatusFilter = 'ALL'; // 'ALL', 'CONFIRMED', 'PENDING', 'FAILED'
  String _txTypeFilter = 'ALL'; // 'ALL', 'REWARD', 'STAKING', 'TRANSFER', 'FEE'
  String? _expandedTxHash;

  late List<Map<String, dynamic>> _transactions;

  // ---------------------------------------------------------------------------
  // CARDS TAB STATE
  // ---------------------------------------------------------------------------
  int _selectedCardIndex = 0;
  bool _isCardFrozen = false;
  bool _showCardDetails = false;
  double _cardSpendingLimit = 25000.0;
  bool _autoDebitFromYield = true;

  final List<Map<String, dynamic>> _cardsData = [
    {
      'title': 'TITANIUM BLACK VAULT',
      'number': '4712 8901 2345 8421',
      'exp': '08/29',
      'cvv': '842',
      'holder': 'JESWIN (OPERATOR)',
      'limit': '\$50,000 / mo',
      'spent': '\$18,420.50',
      'gradient': [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)],
      'chipColor': Color(0xFFE2E8F0),
    },
    {
      'title': 'GPU CLOUD COMPUTE CARD',
      'number': '4112 5521 9081 3319',
      'exp': '11/28',
      'cvv': '194',
      'holder': 'DESPLIT CLOUD RUNNER',
      'limit': '\$20,000 / mo',
      'spent': '\$4,020.50',
      'gradient': [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF042F2E)],
      'chipColor': Color(0xFF00F5A0),
    },
    {
      'title': 'VALIDATOR STAKING CARD',
      'number': '5219 7712 4021 6612',
      'exp': '03/30',
      'cvv': '551',
      'holder': 'CONSENSUS TREASURY',
      'limit': '\$100,000 / mo',
      'spent': '\$62,100.00',
      'gradient': [Color(0xFF701A75), Color(0xFF4A044E), Color(0xFF18181B)],
      'chipColor': Color(0xFFA855F7),
    },
  ];

  // ---------------------------------------------------------------------------
  // REPORTS TAB STATE
  // ---------------------------------------------------------------------------
  String _reportTimeframe = 'Q3 2026'; // 'Last 30 Days', 'Q3 2026', 'FY26 YTD', 'Lifetime'

  @override
  void initState() {
    super.initState();
    _initTransactions();
  }

  @override
  void dispose() {
    _walletAddressController.dispose();
    _paymentAmountController.dispose();
    _paymentMemoController.dispose();
    super.dispose();
  }

  void _initTransactions() {
    _transactions = [
      {
        'hash': '0x4e2a89c1f0b9381d4a72e91b5c829031',
        'block': '#18,942,104',
        'type': 'REWARD',
        'typeLabel': 'Compute Reward',
        'from': 'Swarm Treasury',
        'to': 'Local Host (0x71a4...84c1)',
        'amount': '+4,250.00 SPLIT',
        'amountVal': 4250.0,
        'isPositive': true,
        'fee': '0.0012 SPLIT',
        'time': '2 mins ago',
        'status': 'CONFIRMED',
        'gasUsed': '21,000 / 21,000 (100%)',
        'nonce': '1482',
      },
      {
        'hash': '0x991f4b27cc01948ae1837492cda19482',
        'block': '#18,942,098',
        'type': 'STAKING',
        'typeLabel': 'Consensus Staking',
        'from': 'Local Host',
        'to': 'Trimmed-Mean Vault',
        'amount': '-15,000.00 SPLIT',
        'amountVal': -15000.0,
        'isPositive': false,
        'fee': '0.0035 SPLIT',
        'time': '18 mins ago',
        'status': 'CONFIRMED',
        'gasUsed': '64,280 / 80,000 (80%)',
        'nonce': '1481',
      },
      {
        'hash': '0x33b8a1c900e28174fca819234dd7291a',
        'block': '#18,942,082',
        'type': 'TRANSFER',
        'typeLabel': 'Worker Payout',
        'from': 'Swarm Treasury',
        'to': 'Node-SG (Singapore)',
        'amount': '-14,200.00 SPLIT',
        'amountVal': -14200.0,
        'isPositive': false,
        'fee': '0.0021 SPLIT',
        'time': '1 hour ago',
        'status': 'CONFIRMED',
        'gasUsed': '45,100 / 50,000 (90%)',
        'nonce': '1480',
      },
      {
        'hash': '0x77c28194ff002194a8274109ca882194',
        'block': '#18,942,060',
        'type': 'REWARD',
        'typeLabel': 'Compute Reward',
        'from': 'Swarm Treasury',
        'to': 'Node-DE (Frankfurt)',
        'amount': '+8,500.00 SPLIT',
        'amountVal': 8500.0,
        'isPositive': true,
        'fee': '0.0012 SPLIT',
        'time': '3 hours ago',
        'status': 'CONFIRMED',
        'gasUsed': '21,000 / 21,000 (100%)',
        'nonce': '1479',
      },
      {
        'hash': '0x119a44c800b21849ce88129410ca8492',
        'block': '#18,942,042',
        'type': 'FEE',
        'typeLabel': 'Protocol Burn',
        'from': 'Local Host',
        'to': '0x0000...0000 (Burn)',
        'amount': '-42.18 SPLIT',
        'amountVal': -42.18,
        'isPositive': false,
        'fee': '0.0004 SPLIT',
        'time': '5 hours ago',
        'status': 'CONFIRMED',
        'gasUsed': '21,000 / 21,000 (100%)',
        'nonce': '1478',
      },
      {
        'hash': '0x882410ca99ff1824a772b109cc881144',
        'block': '#18,941,990',
        'type': 'TRANSFER',
        'typeLabel': 'P2P Escrow Seed',
        'from': 'External (0x442...99a)',
        'to': 'Local Host',
        'amount': '+50,000.00 SPLIT',
        'amountVal': 50000.0,
        'isPositive': true,
        'fee': '0.0028 SPLIT',
        'time': '12 hours ago',
        'status': 'CONFIRMED',
        'gasUsed': '35,000 / 40,000 (87%)',
        'nonce': '1477',
      },
      {
        'hash': '0x5511aa99cc8824190ffb82144ca77192',
        'block': '#18,941,950',
        'type': 'STAKING',
        'typeLabel': 'Yield Auto-Compound',
        'from': 'Trimmed-Mean Vault',
        'to': 'Local Host',
        'amount': '+1,842.50 SPLIT',
        'amountVal': 1842.50,
        'isPositive': true,
        'fee': '0.0010 SPLIT',
        'time': '1 day ago',
        'status': 'CONFIRMED',
        'gasUsed': '21,000 / 21,000 (100%)',
        'nonce': '1476',
      },
      {
        'hash': '0x6644bb22dd99118800ff773355aa8811',
        'block': 'Pending',
        'type': 'TRANSFER',
        'typeLabel': 'Node Sync Bounty',
        'from': 'Local Host',
        'to': 'Node-JP (Tokyo)',
        'amount': '-3,200.00 SPLIT',
        'amountVal': -3200.0,
        'isPositive': false,
        'fee': '0.0018 SPLIT',
        'time': 'Just now',
        'status': 'PENDING',
        'gasUsed': 'Estimating...',
        'nonce': '1483',
      },
    ];
  }

  void _executePayment() {
    final amountText = _paymentAmountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid transfer amount.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final recipient = _paymentRecipientType == 'NODE'
        ? _selectedPaymentNode
        : (_walletAddressController.text.trim().isNotEmpty ? _walletAddressController.text.trim() : '0x71a4...84c1');

    setState(() => _isProcessingPayment = true);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final newHash = '0x${math.Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}${math.Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}4e2a89c';

      setState(() {
        _isProcessingPayment = false;
        _transactions.insert(0, {
          'hash': newHash,
          'block': '#18,942,108',
          'type': 'TRANSFER',
          'typeLabel': 'Compute Transfer',
          'from': 'Local Host (0x71a4...84c1)',
          'to': recipient,
          'amount': '-${amount.toStringAsFixed(2)} SPLIT',
          'amountVal': -amount,
          'isPositive': false,
          'fee': _paymentSpeed == 'Instant' ? '0.0036 SPLIT' : '0.0018 SPLIT',
          'time': 'Just now',
          'status': 'CONFIRMED',
          'gasUsed': '21,000 / 21,000 (100%)',
          'nonce': '${1484 + _transactions.length}',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Payment of ${amount.toStringAsFixed(2)} SPLIT sent to $recipient!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.brandAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isProf = themeMode == AppThemeMode.professional;
        final isDark = themeMode == AppThemeMode.dark;
        final isLight = themeMode == AppThemeMode.light;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Sub-Header Navigation
              _buildTopSubHeader(isProf, isDark, isLight),

              const SizedBox(height: 16),

              // 2. Active Tab Content
              if (_activeSubTab == 'Overview')
                _buildOverviewTab(isProf, isDark, isLight)
              else if (_activeSubTab == 'Payment')
                _buildPaymentTab(isProf, isDark, isLight)
              else if (_activeSubTab == 'Transaction')
                _buildTransactionTab(isProf, isDark, isLight)
              else if (_activeSubTab == 'Cards')
                _buildCardsTab(isProf, isDark, isLight)
              else if (_activeSubTab == 'Reports')
                _buildReportsTab(isProf, isDark, isLight),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. TOP SUB-HEADER (DeSplit-style title, navigation pills, search & profile)
  // ===========================================================================
  Widget _buildTopSubHeader(bool isProf, bool isDark, bool isLight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Logo & Title
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 17,
                          color: AppColors.brandAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Token & Reward Ledger',
                          style: TextStyle(
                            color: isLight ? AppColors.textPrimary : Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Swarm compute rewards, validator staking, and P2P token distributions',
                          style: TextStyle(
                            color: isLight ? AppColors.textSecondary : const Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Middle Navigation Pills (Wide screen)
                if (!isCompact)
                  _buildNavPillsBar(isLight),

                // Right: Actions (Search, Notifications, Operator Avatar)
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ledger search index updated • 1,428 blocks indexed'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search_rounded, size: 18),
                      color: isLight ? AppColors.textSecondary : const Color(0xFF94A3B8),
                      splashRadius: 18,
                      tooltip: 'Search Ledger',
                    ),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_none_rounded, size: 18),
                          color: isLight ? AppColors.textSecondary : const Color(0xFF94A3B8),
                          splashRadius: 18,
                          tooltip: 'Notifications',
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Operator Avatar
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.brandAccent, AppColors.accentHover],
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: const Center(
                        child: Text(
                          'JB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // On Compact screens, render navigation pills below the title row
            if (isCompact) ...[
              const SizedBox(height: 12),
              _buildNavPillsBar(isLight),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNavPillsBar(bool isLight) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _subTabs.map((tab) {
          final isSelected = _activeSubTab == tab;
          return InkWell(
            onTap: () => setState(() => _activeSubTab = tab),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandAccent.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.brandAccent
                      : (isLight ? AppColors.textSecondary : const Color(0xFF94A3B8)),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: OVERVIEW TAB CONTENT
  // ===========================================================================
  Widget _buildOverviewTab(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Hero Balance Banner
        _buildHeroBalanceBanner(isProf, isDark, isLight),

        const SizedBox(height: 18),

        // 2. 4 Sleek Horizontal Metric Cards with Sparklines
        _buildFourMetricCards(isProf, isDark, isLight),

        const SizedBox(height: 18),

        // 3. Split Layout: Recent Activity Table (Left) + Top Categories & Quick Stake (Right)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 980;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 62,
                    child: _buildRecentActivityCard(isProf, isDark, isLight),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 38,
                    child: Column(
                      children: [
                        _buildTopCategoryCard(isProf, isDark, isLight),
                        const SizedBox(height: 16),
                        _buildQuickTransferCard(isProf, isDark, isLight),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildRecentActivityCard(isProf, isDark, isLight),
                  const SizedBox(height: 16),
                  _buildTopCategoryCard(isProf, isDark, isLight),
                  const SizedBox(height: 16),
                  _buildQuickTransferCard(isProf, isDark, isLight),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: PAYMENT MANAGEMENT TAB
  // ===========================================================================
  Widget _buildPaymentTab(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top 3 Stat Cards for Payments
        Row(
          children: [
            Expanded(
              child: _buildPaymentMetricCard(
                label: 'AVAILABLE FOR DISBURSEMENT',
                value: '23,800,217 SPLIT',
                subtext: '≈ \$47,600.43 USD liquid vault',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: const Color(0xFF00F5A0),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMetricCard(
                label: 'PENDING INVOICES',
                value: '2 Invoices (22,700 SPLIT)',
                subtext: 'Awaiting operator signature',
                icon: Icons.receipt_long_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMetricCard(
                label: 'DAILY DISBURSEMENT LIMIT',
                value: '\$100,000 USD',
                subtext: '\$81,580 USD (81.5% Available)',
                icon: Icons.verified_user_rounded,
                accentColor: const Color(0xFF38BDF8),
                isDark: isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Split Layout: Payment Form (Left) & Scheduled Payroll / Invoices (Right)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 920;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 55,
                    child: _buildPaymentExecutionCard(isDark, isLight),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 45,
                    child: Column(
                      children: [
                        _buildPendingInvoicesCard(isDark, isLight),
                        const SizedBox(height: 16),
                        _buildScheduledPayrollCard(isDark, isLight),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildPaymentExecutionCard(isDark, isLight),
                  const SizedBox(height: 16),
                  _buildPendingInvoicesCard(isDark, isLight),
                  const SizedBox(height: 16),
                  _buildScheduledPayrollCard(isDark, isLight),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMetricCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
              Icon(icon, size: 14, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentExecutionCard(bool isDark, bool isLight) {
    final double amount = double.tryParse(_paymentAmountController.text) ?? 0.0;
    final double usdVal = amount * 0.0020;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.send_rounded, size: 16, color: Color(0xFF00F5A0)),
              SizedBox(width: 8),
              Text(
                'DISBURSE SWARM TOKENS / INCENTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recipient Type Selector (Pills)
          Row(
            children: [
              _buildTypeSelectorPill('SWARM WORKER NODE', 'NODE', _paymentRecipientType, (v) => setState(() => _paymentRecipientType = v)),
              const SizedBox(width: 8),
              _buildTypeSelectorPill('CUSTOM WALLET (0x...)', 'WALLET', _paymentRecipientType, (v) => setState(() => _paymentRecipientType = v)),
            ],
          ),

          const SizedBox(height: 14),

          // Recipient Input
          if (_paymentRecipientType == 'NODE') ...[
            const Text('SELECT DESTINATION WORKER', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D111A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2D3748)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPaymentNode,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF161E2E),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                  items: _availableNodes.map((n) {
                    return DropdownMenuItem(value: n, child: Text(n));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPaymentNode = val);
                  },
                ),
              ),
            ),
          ] else ...[
            const Text('RECIPIENT WALLET / CONTRACT ADDRESS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _walletAddressController,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'Enter 0x... EVM or Solana recipient address',
                hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF0D111A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2D3748))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2D3748))),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Amount in SPLIT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AMOUNT TO DISBURSE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600)),
              Text(
                '≈ \$${usdVal.toStringAsFixed(2)} USD',
                style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _paymentAmountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
            decoration: InputDecoration(
              suffixText: 'SPLIT',
              suffixStyle: const TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.w800),
              filled: true,
              fillColor: const Color(0xFF0D111A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2D3748))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2D3748))),
            ),
          ),

          const SizedBox(height: 8),

          // Quick Percent chips
          Row(
            children: [
              _buildQuickPercentChip('1,000', () => setState(() => _paymentAmountController.text = '1000')),
              const SizedBox(width: 6),
              _buildQuickPercentChip('5,000', () => setState(() => _paymentAmountController.text = '5000')),
              const SizedBox(width: 6),
              _buildQuickPercentChip('25,000', () => setState(() => _paymentAmountController.text = '25000')),
              const SizedBox(width: 6),
              _buildQuickPercentChip('100,000', () => setState(() => _paymentAmountController.text = '100000')),
            ],
          ),

          const SizedBox(height: 14),

          // Speed & Priority
          const Text('TRANSACTION SPEED / GAS PRIORITY', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildSpeedChip('Standard', '12 gwei • ~15s', _paymentSpeed == 'Standard', () => setState(() => _paymentSpeed = 'Standard')),
              const SizedBox(width: 8),
              _buildSpeedChip('Fast', '24 gwei • ~5s', _paymentSpeed == 'Fast', () => setState(() => _paymentSpeed = 'Fast')),
              const SizedBox(width: 8),
              _buildSpeedChip('Instant', '36 gwei • <1s ZK', _paymentSpeed == 'Instant', () => setState(() => _paymentSpeed = 'Instant')),
            ],
          ),

          const SizedBox(height: 14),

          // Memo
          const Text('MEMO / AUDIT REFERENCE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _paymentMemoController,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            decoration: InputDecoration(
              hintText: 'e.g. FedAvg gradient reward for round 4',
              hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 11),
              filled: true,
              fillColor: const Color(0xFF0D111A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2D3748))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2D3748))),
            ),
          ),

          const SizedBox(height: 18),

          // Execute Button
          InkWell(
            onTap: _isProcessingPayment ? null : _executePayment,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F5A0), Color(0xFF00D287)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F5A0).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: _isProcessingPayment
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 15, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'SIGN & EXECUTE DISBURSEMENT',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelectorPill(String title, String val, String current, Function(String) onSelect) {
    final isSelected = val == current;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(val),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E2638) : const Color(0xFF0D111A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? const Color(0xFF00F5A0) : const Color(0xFF2D3748)),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00F5A0) : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPercentChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF161E2E),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF2D3748)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9.5, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  Widget _buildSpeedChip(String title, String sub, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E2638) : const Color(0xFF0D111A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF2D3748)),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 8.5, fontFamily: 'monospace'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingInvoicesCard(bool isDark, bool isLight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Text(
                    'PENDING COMPUTE INVOICES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_pendingInvoices.length} PENDING',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_pendingInvoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('All compute invoices have been cleared.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ),
            )
          else
            ...List.generate(_pendingInvoices.length, (idx) {
              final inv = _pendingInvoices[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D111A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E2638)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(inv['id'], style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                              const SizedBox(width: 8),
                              Text(inv['node'], style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(inv['for'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(inv['amount'], style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() => _pendingInvoices.removeAt(idx));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invoice ${inv['id']} approved & dispatched.'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                            ),
                            child: const Text('APPROVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            setState(() => _pendingInvoices.removeAt(idx));
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildScheduledPayrollCard(bool isDark, bool isLight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Text(
                'SCHEDULED RECURRING PAYROLL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._scheduledPayments.map((p) {
            final bool isActive = p['active'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D111A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E2638)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['title'], style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${p['amount']} • ${p['cadence']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  Switch(
                    value: isActive,
                    activeThumbColor: const Color(0xFF00F5A0),
                    activeTrackColor: const Color(0xFF00F5A0).withValues(alpha: 0.3),
                    onChanged: (val) {
                      setState(() => p['active'] = val);
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: TRANSACTION EXPLORER TAB CONTENT
  // ===========================================================================
  Widget _buildTransactionTab(bool isProf, bool isDark, bool isLight) {
    final filteredTxs = _transactions.where((tx) {
      if (_txStatusFilter != 'ALL' && tx['status'] != _txStatusFilter) {
        return false;
      }
      if (_txTypeFilter != 'ALL' && tx['type'] != _txTypeFilter) {
        return false;
      }
      if (_txSearchQuery.isNotEmpty) {
        final q = _txSearchQuery.toLowerCase();
        final matchHash = (tx['hash'] as String).toLowerCase().contains(q);
        final matchFrom = (tx['from'] as String).toLowerCase().contains(q);
        final matchTo = (tx['to'] as String).toLowerCase().contains(q);
        final matchType = (tx['typeLabel'] as String).toLowerCase().contains(q);
        if (!matchHash && !matchFrom && !matchTo && !matchType) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 Key Stats
        Row(
          children: [
            Expanded(child: _buildTxMetricCard('TOTAL TRANSACTIONS', '${_transactions.length}', Icons.swap_horiz_rounded, const Color(0xFF38BDF8))),
            const SizedBox(width: 10),
            Expanded(child: _buildTxMetricCard('TOTAL INFLOW', '+842,500 SPLIT', Icons.arrow_downward_rounded, const Color(0xFF00F5A0))),
            const SizedBox(width: 10),
            Expanded(child: _buildTxMetricCard('TOTAL OUTFLOW', '-312,200 SPLIT', Icons.arrow_upward_rounded, const Color(0xFFEF4444))),
            const SizedBox(width: 10),
            Expanded(child: _buildTxMetricCard('AVERAGE NETWORK GAS', '0.0018 SPLIT (\$0.003)', Icons.local_gas_station_rounded, const Color(0xFFA855F7))),
          ],
        ),

        const SizedBox(height: 16),

        // Filter & Search Toolbar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              // Search Field
              Container(
                width: 320,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D111A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF1E2638)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Icon(Icons.search_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _txSearchQuery = v),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          hintText: 'Search by Tx Hash, Block, or Node...',
                          hintStyle: TextStyle(color: Color(0xFF475569), fontSize: 10.5),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Chips
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTxFilterChip('ALL', _txStatusFilter == 'ALL', () => setState(() => _txStatusFilter = 'ALL')),
                  const SizedBox(width: 6),
                  _buildTxFilterChip('CONFIRMED', _txStatusFilter == 'CONFIRMED', () => setState(() => _txStatusFilter = 'CONFIRMED')),
                  const SizedBox(width: 6),
                  _buildTxFilterChip('PENDING', _txStatusFilter == 'PENDING', () => setState(() => _txStatusFilter = 'PENDING')),
                ],
              ),

              // Type Filter Dropdown
              PopupMenuButton<String>(
                initialValue: _txTypeFilter,
                onSelected: (v) => setState(() => _txTypeFilter = v),
                color: const Color(0xFF161E2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFF2D3748))),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'ALL', child: Text('All Types', style: TextStyle(color: Colors.white, fontSize: 11))),
                  const PopupMenuItem(value: 'REWARD', child: Text('Compute Rewards', style: TextStyle(color: Colors.white, fontSize: 11))),
                  const PopupMenuItem(value: 'STAKING', child: Text('Consensus Staking', style: TextStyle(color: Colors.white, fontSize: 11))),
                  const PopupMenuItem(value: 'TRANSFER', child: Text('Worker Transfers', style: TextStyle(color: Colors.white, fontSize: 11))),
                  const PopupMenuItem(value: 'FEE', child: Text('Protocol Burns', style: TextStyle(color: Colors.white, fontSize: 11))),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D111A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2D3748)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TYPE: $_txTypeFilter',
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, size: 14, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),

              // Export CSV Button
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transactions exported to /exports/ledger_history.csv'), backgroundColor: Color(0xFF00F5A0)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D111A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2D3748)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 12, color: Color(0xFF00F5A0)),
                      SizedBox(width: 5),
                      Text('EXPORT CSV', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Transactions Table
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E17),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E2638)),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D121F),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(9), topRight: Radius.circular(9)),
                  border: Border(bottom: BorderSide(color: Color(0xFF1E2638))),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 24, child: Text('#', style: TextStyle(color: Color(0xFF475569), fontSize: 9.5, fontFamily: 'monospace', fontWeight: FontWeight.w700))),
                    Expanded(flex: 3, child: Text('TX HASH', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
                    Expanded(flex: 2, child: Text('BLOCK', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
                    Expanded(flex: 2, child: Text('TYPE', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
                    Expanded(flex: 3, child: Text('FROM ➔ TO', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
                    Expanded(flex: 2, child: Text('AMOUNT', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
                    Expanded(flex: 2, child: Text('TIME', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
                  ],
                ),
              ),

              if (filteredTxs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text('No transactions found matching your filters.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ),
                )
              else
                ...List.generate(filteredTxs.length, (idx) {
                  final tx = filteredTxs[idx];
                  final isExpanded = _expandedTxHash == tx['hash'];

                  Color typeColor = const Color(0xFF38BDF8);
                  if (tx['type'] == 'STAKING') typeColor = const Color(0xFF00F5A0);
                  if (tx['type'] == 'TRANSFER') typeColor = const Color(0xFFA855F7);
                  if (tx['type'] == 'FEE') typeColor = const Color(0xFFF59E0B);

                  final isPositive = tx['isPositive'] as bool;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _expandedTxHash = isExpanded ? null : tx['hash'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: isExpanded ? const Color(0xFF131929) : Colors.transparent,
                        border: const Border(bottom: BorderSide(color: Color(0xFF141A29))),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Icon(
                                  tx['status'] == 'CONFIRMED' ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
                                  size: 13,
                                  color: tx['status'] == 'CONFIRMED' ? const Color(0xFF00F5A0) : const Color(0xFFF59E0B),
                                ),
                              ),
                              // Hash with Copy
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Text(
                                      '${(tx['hash'] as String).substring(0, 10)}...${(tx['hash'] as String).substring((tx['hash'] as String).length - 4)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _copyToClipboard(tx['hash'], 'Transaction Hash'),
                                      child: const Icon(Icons.copy_rounded, size: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              // Block
                              Expanded(
                                flex: 2,
                                child: Text(tx['block'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontFamily: 'monospace')),
                              ),
                              // Type Badge
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      tx['typeLabel'],
                                      style: TextStyle(color: typeColor, fontSize: 9.5, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                                    ),
                                  ),
                                ),
                              ),
                              // From -> To
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '${tx['from']} ➔ ${tx['to']}',
                                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Amount
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx['amount'],
                                  style: TextStyle(
                                    color: isPositive ? const Color(0xFF00F5A0) : const Color(0xFFF43F5E),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              // Time
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx['time'],
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),

                          // Expanded Tx Detail
                          if (isExpanded) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B0E17),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF1E2638)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Gas Used: ${tx['gasUsed']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontFamily: 'monospace')),
                                  Text('Fee: ${tx['fee']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontFamily: 'monospace')),
                                  Text('Nonce: ${tx['nonce']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontFamily: 'monospace')),
                                  TextButton(
                                    onPressed: () => _copyToClipboard('https://etherscan.io/tx/${tx['hash']}', 'Explorer URL'),
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                    child: const Text('View on Explorer ↗', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 10.5, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTxMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              Icon(icon, size: 13, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildTxFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2638) : const Color(0xFF0D111A),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: isSelected ? const Color(0xFF00F5A0) : const Color(0xFF2D3748)),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? const Color(0xFF00F5A0) : const Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 4: COMPUTE & CORPORATE CARDS TAB CONTENT
  // ===========================================================================
  Widget _buildCardsTab(bool isProf, bool isDark, bool isLight) {
    final currentCard = _cardsData[_selectedCardIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two-Column Layout: The Interactive 3D Card + Card Controls
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 50,
                    child: _buildCardVisualization(currentCard, isDark),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 50,
                    child: _buildCardControlsPanel(currentCard, isDark),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildCardVisualization(currentCard, isDark),
                  const SizedBox(height: 18),
                  _buildCardControlsPanel(currentCard, isDark),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 20),

        // Linked Cloud Services & GPU Subscriptions
        _buildLinkedCloudSubscriptions(isDark),
      ],
    );
  }

  Widget _buildCardVisualization(Map<String, dynamic> card, bool isDark) {
    final List<Color> gradientColors = card['gradient'];
    final String cardNumber = _showCardDetails ? card['number'] : '•••• •••• •••• ${card['number'].substring(card['number'].length - 4)}';
    final String cvv = _showCardDetails ? card['cvv'] : '•••';

    return Column(
      children: [
        // Card Selector Pills
        Row(
          children: List.generate(_cardsData.length, (idx) {
            final isSelected = _selectedCardIndex == idx;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: idx < _cardsData.length - 1 ? 8.0 : 0),
                child: InkWell(
                  onTap: () => setState(() => _selectedCardIndex = idx),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E2638) : const Color(0xFF0D111A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSelected ? const Color(0xFF00F5A0) : const Color(0xFF2D3748)),
                    ),
                    child: Center(
                      child: Text(
                        'CARD 0${idx + 1}',
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF00F5A0) : const Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 14),

        // The Physical/Virtual Credit Card Canvas
        AspectRatio(
          aspectRatio: 1.58, // Standard credit card aspect ratio (85.6mm x 53.98mm)
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Card Inner Design
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top row: Brand & NFC icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'deSplit',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                card['title'],
                                style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.wifi_rounded, size: 20, color: Colors.white70),
                      ],
                    ),

                    // Middle: Chip Icon
                    Container(
                      width: 36,
                      height: 28,
                      decoration: BoxDecoration(
                        color: card['chipColor'],
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                        ],
                      ),
                    ),

                    // Number
                    Text(
                      cardNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        fontFamily: 'monospace',
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),

                    // Bottom Row: Holder, Exp, CVV
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CARDHOLDER', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 0.8)),
                            Text(card['holder'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 0.8)),
                                Text(card['exp'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CVV', style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 0.8)),
                                Text(cvv, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Freeze Glass Overlay
                if (_isCardFrozen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 36, color: Color(0xFF38BDF8)),
                            SizedBox(height: 8),
                            Text(
                              'CARD TEMPORARILY FROZEN',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'All compute charges & outbound payments blocked',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardControlsPanel(Map<String, dynamic> card, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SECURITY & LIMIT CONTROLS',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, fontFamily: 'monospace'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5A0).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('ACTIVE CORPORATE CARD', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 9, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Control 1: Freeze Card Toggle
          _buildCardToggleRow(
            title: 'Freeze Card',
            subtitle: 'Temporarily pause all online charges and cloud billing',
            icon: Icons.ac_unit_rounded,
            value: _isCardFrozen,
            onChanged: (val) {
              setState(() => _isCardFrozen = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isCardFrozen ? 'Card has been frozen.' : 'Card has been unfrozen and activated.'),
                  backgroundColor: _isCardFrozen ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),

          const Divider(height: 20, color: Color(0xFF1E2638)),

          // Control 2: Show / Hide Card Details
          _buildCardToggleRow(
            title: 'Reveal Card Number & CVV',
            subtitle: 'Show unmasked 16-digit card number on display',
            icon: Icons.visibility_rounded,
            value: _showCardDetails,
            onChanged: (val) => setState(() => _showCardDetails = val),
          ),

          const Divider(height: 20, color: Color(0xFF1E2638)),

          // Control 3: Auto-Recharge from Staking Yield
          _buildCardToggleRow(
            title: 'Auto-Recharge from Yield',
            subtitle: 'Automatically settle cloud charges from staking rewards',
            icon: Icons.auto_mode_rounded,
            value: _autoDebitFromYield,
            onChanged: (val) => setState(() => _autoDebitFromYield = val),
          ),

          const Divider(height: 20, color: Color(0xFF1E2638)),

          // Control 4: Spending Limit Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MONTHLY DISBURSEMENT LIMIT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600)),
              Text(
                '\$${_cardSpendingLimit.toStringAsFixed(0)} USD',
                style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
              ),
            ],
          ),
          Slider(
            value: _cardSpendingLimit,
            min: 5000.0,
            max: 100000.0,
            divisions: 19,
            activeColor: const Color(0xFF00F5A0),
            inactiveColor: const Color(0xFF1E2638),
            onChanged: (v) => setState(() => _cardSpendingLimit = v),
          ),

          // Total spent status
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D111A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E2638)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Billing Cycle Spent:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                Text(card['spent'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardToggleRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D111A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF00F5A0)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF00F5A0),
          activeTrackColor: const Color(0xFF00F5A0).withValues(alpha: 0.3),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLinkedCloudSubscriptions(bool isDark) {
    final subscriptions = [
      {'service': 'Lambda Labs Cloud GPU', 'rate': '\$2,480.00 / mo', 'status': 'ACTIVE', 'cluster': '8x NVIDIA H100'},
      {'service': 'RunPod Serverless AI', 'rate': '\$890.50 / mo', 'status': 'ACTIVE', 'cluster': 'RTX 4090 Shard'},
      {'service': 'Hugging Face Enterprise', 'rate': '\$200.00 / mo', 'status': 'ACTIVE', 'cluster': 'Model Hub Sync'},
      {'service': 'Vast.ai Compute Instances', 'rate': '\$450.00 / mo', 'status': 'ACTIVE', 'cluster': 'Secondary Mesh'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_done_rounded, size: 16, color: Color(0xFF38BDF8)),
                  SizedBox(width: 8),
                  Text(
                    'LINKED CLOUD GPU SUBSCRIPTIONS & AUTOPAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Text(
                'Auto-Debited from Card 01',
                style: TextStyle(color: Color(0xFF00F5A0), fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: subscriptions.map((s) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D111A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['service']!, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(s['cluster']!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                      const SizedBox(height: 8),
                      Text(s['rate']!, style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 5: REPORTS & AUDIT TAB CONTENT
  // ===========================================================================
  Widget _buildReportsTab(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar: Timeframe Selector & Export Action
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_rounded, size: 16, color: Color(0xFF00F5A0)),
                  const SizedBox(width: 8),
                  const Text(
                    'FINANCIAL AUDIT & TOKENOMICS STATEMENTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Timeframe pills
                  ...['Last 30 Days', 'Q3 2026', 'FY26 YTD', 'Lifetime'].map((t) {
                    final isSelected = _reportTimeframe == t;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkWell(
                        onTap: () => setState(() => _reportTimeframe = t),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1E2638) : const Color(0xFF0D111A),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isSelected ? const Color(0xFF00F5A0) : const Color(0xFF2D3748)),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00F5A0) : const Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4 Financial KPI Cards
        Row(
          children: [
            Expanded(
              child: _buildReportKpiCard('GROSS COMPUTE REVENUE', '\$68,240.00 USD', '+24.2% YoY growth', const Color(0xFF00F5A0), Icons.trending_up_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildReportKpiCard('OPERATIONAL COSTS', '\$14,810.00 USD', '-8.4% efficiency gain', const Color(0xFF38BDF8), Icons.hardware_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildReportKpiCard('NET STAKING PROFIT', '\$53,430.00 USD', '78.3% Net Margin', const Color(0xFFA855F7), Icons.monetization_on_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildReportKpiCard('TOKEN BURN RATE', '124,500 SPLIT', '0.52% of total supply', const Color(0xFFF59E0B), Icons.local_fire_department_rounded),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Visual Inflow vs Outflow Chart (Custom Painted Bar Chart)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'HISTORICAL CASH FLOW & TOKENOMICS ACCUMULATION (6 MONTHS)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00F5A0), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Inflow / Rewards', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace')),
                      const SizedBox(width: 12),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF43F5E), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Outflow / Hardware', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ReportBarChartPainter(),
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('MAY 2026', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontFamily: 'monospace')),
                  Text('JUN 2026', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontFamily: 'monospace')),
                  Text('JUL 2026', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontFamily: 'monospace')),
                  Text('AUG 2026', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontFamily: 'monospace')),
                  Text('SEP 2026', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontFamily: 'monospace')),
                  Text('OCT 2026 (CURRENT)', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 9.5, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Audit Statements & Ready Downloads
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_rounded, size: 16, color: Color(0xFF00F5A0)),
                  SizedBox(width: 8),
                  Text(
                    'DOWNLOADABLE COMPLIANCE & CRYPTOGRAPHIC PROOF STATEMENTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildDownloadableReportTile(
                      title: 'Q3 2026 Comprehensive Swarm Audit',
                      fileFormat: 'PDF FORMAT',
                      fileSize: '3.4 MB',
                      icon: Icons.picture_as_pdf_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDownloadableReportTile(
                      title: 'FY2026 Cryptographic Ledger Statement',
                      fileFormat: 'CSV FORMAT',
                      fileSize: '1.2 MB',
                      icon: Icons.table_chart_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDownloadableReportTile(
                      title: 'Byzantine Fault Verification & Slashing Audit',
                      fileFormat: 'JSON PROOF',
                      fileSize: '840 KB',
                      icon: Icons.code_rounded,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportKpiCard(String label, String value, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDownloadableReportTile({
    required String title,
    required String fileFormat,
    required String fileSize,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D111A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('$fileFormat • $fileSize', style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontFamily: 'monospace')),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading $title...'),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF00F5A0)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. COHESIVE HERO BANNER (Matches DeSplit design system & color theme)
  // ===========================================================================
  Widget _buildHeroBalanceBanner(bool isProf, bool isDark, bool isLight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.brandAccent.withValues(alpha: 0.32),
          width: 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandAccent.withValues(alpha: isLight ? 0.10 : 0.18),
            AppColors.cardSurface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandAccent.withValues(alpha: isLight ? 0.08 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.brandAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Contributed GPU Cluster Tokens',
                      style: TextStyle(
                        color: AppColors.brandAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: AppColors.brandAccent,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 11, color: isLight ? AppColors.textSecondary : const Color(0xFFCBD5E1)),
                        const SizedBox(width: 5),
                        Text(
                          '20 Sep - 20 Oct, 2026',
                          style: TextStyle(
                            color: isLight ? AppColors.textPrimary : Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: isLight ? AppColors.textSecondary : const Color(0xFFCBD5E1)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Exporting Token Ledger to CSV...'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppColors.brandAccent,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded, size: 13, color: isLight ? AppColors.textSecondary : const Color(0xFFCBD5E1)),
                          const SizedBox(width: 5),
                          Text(
                            'Export',
                            style: TextStyle(
                              color: isLight ? AppColors.textPrimary : Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '23,800,217',
                style: TextStyle(
                  color: isLight ? AppColors.textPrimary : Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'SPLIT',
                style: TextStyle(
                  color: AppColors.brandAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 11, color: Color(0xFF10B981)),
                    SizedBox(width: 3),
                    Text(
                      '+14.8% APY',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            '≈ \$47,600.43 USD Equivalent Value (1 SPLIT = \$0.0020 USD)',
            style: TextStyle(
              color: isLight ? AppColors.textSecondary : const Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. FOUR METRIC SUMMARY CARDS WITH SPARKLINES
  // ===========================================================================
  Widget _buildFourMetricCards(bool isProf, bool isDark, bool isLight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 840;

        final cards = [
          _buildMetricSummaryTile(
            index: 0,
            title: 'Compute Earnings',
            value: '\$18,420.50',
            badgeText: '+18.4%',
            isBadgePositive: true,
            sparklineColor: const Color(0xFF10B981),
            sparklinePoints: const [0.2, 0.35, 0.3, 0.5, 0.45, 0.7, 0.65, 0.9],
            isProf: isProf,
            isDark: isDark,
            isLight: isLight,
          ),
          _buildMetricSummaryTile(
            index: 1,
            title: 'Validator Staked',
            value: '14,200,000',
            badgeText: '68% Total',
            isBadgePositive: true,
            sparklineColor: AppColors.brandAccent,
            sparklinePoints: const [0.4, 0.42, 0.5, 0.55, 0.6, 0.68, 0.72, 0.78],
            isProf: isProf,
            isDark: isDark,
            isLight: isLight,
          ),
          _buildMetricSummaryTile(
            index: 2,
            title: 'Gas & Network Fees',
            value: '42.18 SPLIT',
            badgeText: '-12.5%',
            isBadgePositive: true,
            sparklineColor: const Color(0xFF38BDF8),
            sparklinePoints: const [0.8, 0.7, 0.65, 0.5, 0.45, 0.38, 0.3, 0.22],
            isProf: isProf,
            isDark: isDark,
            isLight: isLight,
          ),
          _buildMetricSummaryTile(
            index: 3,
            title: 'Slashing Penalties',
            value: '0.00 SPLIT',
            badgeText: '100% Clean',
            isBadgePositive: true,
            sparklineColor: const Color(0xFFF59E0B),
            sparklinePoints: const [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
            isProf: isProf,
            isDark: isDark,
            isLight: isLight,
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _buildMetricSummaryTile({
    required int index,
    required String title,
    required String value,
    required String badgeText,
    required bool isBadgePositive,
    required Color sparklineColor,
    required List<double> sparklinePoints,
    required bool isProf,
    required bool isDark,
    required bool isLight,
  }) {
    final isHovered = _hoveredCardIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCardIndex = index),
      onExit: (_) => setState(() => _hoveredCardIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHovered
                ? AppColors.brandAccent.withValues(alpha: 0.6)
                : AppColors.borderSubtle.withValues(alpha: 0.7),
            width: 1.0,
          ),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: AppColors.brandAccent.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isLight ? AppColors.textSecondary : const Color(0xFF94A3B8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isBadgePositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: isBadgePositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: isLight ? AppColors.textPrimary : Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(
                  width: 58,
                  height: 24,
                  child: CustomPaint(
                    painter: _MiniSparklinePainter(
                      points: sparklinePoints,
                      color: sparklineColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. RECENT ACTIVITY TABLE
  // ===========================================================================
  Widget _buildRecentActivityCard(bool isProf, bool isDark, bool isLight) {
    final activities = [
      {
        'title': 'FedAvg Model Update Bounty (Round #4)',
        'type': 'COMPUTE REWARD',
        'date': 'Today, 2:45 PM',
        'amount': '+1,420 SPLIT',
        'status': 'Complete',
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Trimmed-Mean Consensus Stake Deposit',
        'type': 'STAKING POOL',
        'date': 'Yesterday, 8:12 PM',
        'amount': '-10,000 SPLIT',
        'status': 'Active',
        'icon': Icons.lock_outline_rounded,
        'color': AppColors.brandAccent,
      },
      {
        'title': 'Validator P2P Gradient Verification Fee',
        'type': 'NETWORK GAS',
        'date': '22 Oct, 11:30 AM',
        'amount': '-1.25 SPLIT',
        'status': 'Complete',
        'icon': Icons.local_gas_station_rounded,
        'color': const Color(0xFF38BDF8),
      },
      {
        'title': 'Node-SG Compute Epoch Finalization Reward',
        'type': 'COMPUTE REWARD',
        'date': '20 Oct, 6:15 PM',
        'amount': '+850 SPLIT',
        'status': 'Complete',
        'icon': Icons.hub_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Token Delegation to Top Node-US Host',
        'type': 'DELEGATION',
        'date': '19 Oct, 10:00 AM',
        'amount': '-5,000 SPLIT',
        'status': 'Active',
        'icon': Icons.person_add_alt_1_rounded,
        'color': const Color(0xFFA855F7),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.7),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Ledger Activity',
                style: TextStyle(
                  color: isLight ? AppColors.textPrimary : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: ['Day', 'Week', 'Month'].map((time) {
                  final isSelected = _activityTimeframe == time;
                  return InkWell(
                    onTap: () => setState(() => _activityTimeframe = time),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandAccent.withValues(alpha: 0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.brandAccent
                              : (isLight ? AppColors.textSecondary : const Color(0xFF94A3B8)),
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...List.generate(activities.length, (index) {
            final act = activities[index];
            final isHovered = _hoveredRowIndex == index;

            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredRowIndex = index),
              onExit: (_) => setState(() => _hoveredRowIndex = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isHovered
                      ? AppColors.cardSurfaceLight.withValues(alpha: 0.6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (act['color'] as Color).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(act['icon'] as IconData, size: 16, color: act['color'] as Color),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act['title'] as String,
                            style: TextStyle(
                              color: isLight ? AppColors.textPrimary : Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${act['type']} • ${act['date']}',
                            style: TextStyle(
                              color: isLight ? AppColors.textSecondary : const Color(0xFF94A3B8),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          act['amount'] as String,
                          style: TextStyle(
                            color: (act['amount'] as String).startsWith('+')
                                ? const Color(0xFF10B981)
                                : (isLight ? AppColors.textPrimary : Colors.white),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            act['status'] as String,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. TOP CATEGORY DONUT CARD
  // ===========================================================================
  Widget _buildTopCategoryCard(bool isProf, bool isDark, bool isLight) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.7),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reward Allocation',
                style: TextStyle(
                  color: isLight ? AppColors.textPrimary : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: ['Week', 'Month'].map((time) {
                  final isSelected = _categoryTimeframe == time;
                  return InkWell(
                    onTap: () => setState(() => _categoryTimeframe = time),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandAccent.withValues(alpha: 0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.brandAccent
                              : (isLight ? AppColors.textSecondary : const Color(0xFF94A3B8)),
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    slices: const [0.52, 0.28, 0.15, 0.05],
                    colors: [
                      AppColors.brandAccent,
                      const Color(0xFF10B981),
                      const Color(0xFF38BDF8),
                      const Color(0xFFF59E0B),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '100%',
                      style: TextStyle(
                        color: isLight ? AppColors.textPrimary : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendRow('Compute Slicing', '52%', AppColors.brandAccent, isLight),
                    const SizedBox(height: 6),
                    _buildLegendRow('Validator Staking', '28%', const Color(0xFF10B981), isLight),
                    const SizedBox(height: 6),
                    _buildLegendRow('P2P Bandwidth', '15%', const Color(0xFF38BDF8), isLight),
                    const SizedBox(height: 6),
                    _buildLegendRow('Governance', '5%', const Color(0xFFF59E0B), isLight),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String title, String percent, Color color, bool isLight) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isLight ? AppColors.textSecondary : const Color(0xFF94A3B8),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          percent,
          style: TextStyle(
            color: isLight ? AppColors.textPrimary : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. QUICK TRANSFER / STAKE CARD
  // ===========================================================================
  Widget _buildQuickTransferCard(bool isProf, bool isDark, bool isLight) {
    final nodes = [
      {'name': 'Node-US', 'icon': Icons.hub_rounded, 'color': const Color(0xFF38BDF8)},
      {'name': 'Local Host', 'icon': Icons.computer_rounded, 'color': const Color(0xFF00F5A0)},
      {'name': 'Node-SG', 'icon': Icons.cloud_done_rounded, 'color': const Color(0xFF10B981)},
      {'name': 'Node-DE', 'icon': Icons.sync_rounded, 'color': const Color(0xFFA855F7)},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.7),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Stake & Delegate',
                style: TextStyle(
                  color: isLight ? AppColors.textPrimary : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.more_horiz_rounded, size: 16, color: isLight ? AppColors.textSecondary : const Color(0xFF94A3B8)),
            ],
          ),

          const SizedBox(height: 14),

          // Node Avatars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(nodes.length, (index) {
              final n = nodes[index];
              final isSelected = _selectedNodeIndex == index;

              return InkWell(
                onTap: () => setState(() => _selectedNodeIndex = index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandAccent.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandAccent.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (n['color'] as Color).withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(n['icon'] as IconData, size: 16, color: n['color'] as Color),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n['name'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.brandAccent
                              : (isLight ? AppColors.textSecondary : const Color(0xFFCBD5E1)),
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Amount Input + Transfer Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardSurfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount to Stake',
                        style: TextStyle(
                          color: isLight ? AppColors.textSecondary : const Color(0xFF94A3B8),
                          fontSize: 9.5,
                        ),
                      ),
                      Text(
                        '5,000 SPLIT',
                        style: TextStyle(
                          color: isLight ? AppColors.textPrimary : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully delegated 5,000 SPLIT to ${nodes[_selectedNodeIndex]['name']}!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.brandAccent, AppColors.accentHover],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandAccent.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Stake',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Custom Donut Chart Painter
// -----------------------------------------------------------------------------
class _DonutChartPainter extends CustomPainter {
  final List<double> slices;
  final List<Color> colors;

  _DonutChartPainter({required this.slices, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 12.0;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      final sweepAngle = slices[i] * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + 0.04,
        sweepAngle - 0.08,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Custom Mini Sparkline Painter
// -----------------------------------------------------------------------------
class _MiniSparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _MiniSparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final path = Path();
    final double stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Custom Report Cashflow Bar Chart Painter
// -----------------------------------------------------------------------------
class _ReportBarChartPainter extends CustomPainter {
  // Monthly pairs: [Inflow, Outflow] normalized 0.0 - 1.0
  static const List<List<double>> _monthlyData = [
    [0.45, 0.22],
    [0.55, 0.26],
    [0.68, 0.30],
    [0.74, 0.28],
    [0.85, 0.32],
    [0.95, 0.35],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final int count = _monthlyData.length;
    final double groupWidth = w / count;
    final double barWidth = groupWidth * 0.28;

    final gridPaint = Paint()
      ..color = const Color(0xFF1E2638)
      ..strokeWidth = 0.8;

    // Gridlines
    for (double yFrac in [0.25, 0.5, 0.75]) {
      final y = h * yFrac;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final inflowPaint = Paint()..color = const Color(0xFF00F5A0);
    final outflowPaint = Paint()..color = const Color(0xFFF43F5E);

    for (int i = 0; i < count; i++) {
      final data = _monthlyData[i];
      final inflowH = data[0] * h * 0.9;
      final outflowH = data[1] * h * 0.9;

      final groupCenterX = i * groupWidth + (groupWidth / 2);
      final inX = groupCenterX - barWidth - 2;
      final outX = groupCenterX + 2;

      // Inflow Bar
      final inRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(inX, h - inflowH, barWidth, inflowH),
        const Radius.circular(3),
      );
      canvas.drawRRect(inRect, inflowPaint);

      // Outflow Bar
      final outRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(outX, h - outflowH, barWidth, outflowH),
        const Radius.circular(3),
      );
      canvas.drawRRect(outRect, outflowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
