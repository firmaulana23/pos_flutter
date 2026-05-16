import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/promo.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Member Picker Modal
// ─────────────────────────────────────────────────────────────────────────────

class MemberPickerModal extends StatefulWidget {
  final void Function(Member) onSelected;

  const MemberPickerModal({super.key, required this.onSelected});

  @override
  State<MemberPickerModal> createState() => _MemberPickerModalState();
}

class _MemberPickerModalState extends State<MemberPickerModal> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  String? _errorMsg;
  List<Member> _members = [];
  List<Member> _filtered = [];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _applyFilter();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final members = await ApiService.getMembers();
      // Only show non-expired members
      final now = DateTime.now();
      final validMembers = members.where((m) => m.expiredDate.isAfter(now)).toList();

      setState(() {
        _members = validMembers;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Gagal memuat member: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filtered = List.from(_members);
    } else {
      _filtered = _members.where((m) {
        final nameMatch = m.fullName.toLowerCase().contains(_searchQuery);
        final phoneMatch = m.phoneNumber?.toLowerCase().contains(_searchQuery) ?? false;
        final codeMatch = m.memberCode.toLowerCase().contains(_searchQuery);
        return nameMatch || phoneMatch || codeMatch;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Member',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'Cari pelanggan terdaftar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.disabled,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _searchQuery.isNotEmpty
                      ? AppColors.secondary
                      : AppColors.inputBorder,
                  width: _searchQuery.isNotEmpty ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama, No. HP, atau No. Kartu...',
                  hintStyle: TextStyle(
                    color: AppColors.disabled,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _searchQuery.isNotEmpty
                        ? AppColors.secondary
                        : AppColors.disabled,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.secondary),
                        SizedBox(height: 12),
                        Text('Memuat member...'),
                      ],
                    ),
                  )
                : _errorMsg != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMsg!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchMembers,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: AppColors.disabled,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Tidak ada member terdaftar'
                              : 'Member tidak ditemukan',
                          style: TextStyle(
                            color: AppColors.disabled,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) =>
                        _buildMemberCard(_filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          widget.onSelected(member);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar/Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: AppColors.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            member.phoneNumber ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.credit_card_rounded,
                            size: 14,
                            color: AppColors.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            member.memberCode,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Diskon ${member.discount.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${member.points} Poin',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selection icon
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Promo Picker Modal
// ─────────────────────────────────────────────────────────────────────────────

class PromoPickerModal extends StatefulWidget {
  final void Function(Promo) onSelected;

  const PromoPickerModal({super.key, required this.onSelected});

  @override
  State<PromoPickerModal> createState() => _PromoPickerModalState();
}

class _PromoPickerModalState extends State<PromoPickerModal> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  String? _errorMsg;
  List<Promo> _promos = [];
  List<Promo> _filtered = [];

  @override
  void initState() {
    super.initState();
    _fetchPromos();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _applyFilter();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPromos() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final promos = await ApiService.getPromos();
      // Show only active promos that are within valid date range
      final now = DateTime.now();
      final available = promos.where((p) {
        if (!p.isActive) return false;
        if (p.startAt != null && now.isBefore(p.startAt!)) return false;
        if (p.endAt != null && now.isAfter(p.endAt!)) return false;
        return true;
      }).toList();

      setState(() {
        _promos = available;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Gagal memuat promo: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filtered = List.from(_promos);
    } else {
      _filtered = _promos.where((p) {
        return p.name.toLowerCase().contains(_searchQuery) ||
            p.code.toLowerCase().contains(_searchQuery) ||
            (p.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Promo',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'Promo aktif tersedia',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.disabled,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _searchQuery.isNotEmpty
                      ? AppColors.primary
                      : AppColors.inputBorder,
                  width: _searchQuery.isNotEmpty ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau kode promo...',
                  hintStyle: TextStyle(
                    color: AppColors.disabled,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _searchQuery.isNotEmpty
                        ? AppColors.primary
                        : AppColors.disabled,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Memuat promo...'),
                      ],
                    ),
                  )
                : _errorMsg != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMsg!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchPromos,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: AppColors.disabled,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Tidak ada promo aktif saat ini'
                              : 'Promo tidak ditemukan',
                          style: TextStyle(
                            color: AppColors.disabled,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) =>
                        _buildPromoCard(_filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(Promo promo) {
    final isPercentage = promo.type.toLowerCase() == 'percentage';
    final discountText = isPercentage
        ? '${promo.value.toStringAsFixed(promo.value % 1 == 0 ? 0 : 1)}% OFF'
        : '${AppFormatters.formatCurrency(promo.value)} OFF';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          widget.onSelected(promo);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.accent.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Discount badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer_rounded,
                        color: AppColors.onPrimary,
                        size: 18,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        discountText,
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Promo info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Code chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          promo.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: AppColors.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (promo.description != null &&
                          promo.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          promo.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurface.withValues(alpha: 0.6),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Validity row
                      Row(
                        children: [
                          if (promo.stackable) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Bisa Digabung',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (promo.endAt != null) ...[
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: AppColors.onSurface.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Berlaku s/d ${_formatDate(promo.endAt!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurface.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
