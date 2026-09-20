import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:family_budget_app/presentation/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class FamilyManagementScreen extends ConsumerStatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  ConsumerState<FamilyManagementScreen> createState() =>
      _FamilyManagementScreenState();
}

class _FamilyManagementScreenState
    extends ConsumerState<FamilyManagementScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _familyCode;

  @override
  void initState() {
    super.initState();
    _fetchFamilyCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _fetchFamilyCode() async {
    final authState = ref.read(authProvider);
    if (authState.familyId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('families')
          .doc(authState.familyId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _familyCode = doc.data()?['code'];
        });
      }
    }
  }

  void _createFamily() async {
    setState(() => _isLoading = true);
    try {
      final code = await ref.read(authProvider.notifier).createFamily();
      if (mounted) {
        setState(() => _familyCode = code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aile oluşturuldu! Kod: $code'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _joinFamily() async {
    if (_codeController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).joinFamily(_codeController.text.trim());
      _fetchFamilyCode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aileye başarıyla katıldınız!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _leaveFamily() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).leaveFamily();
      setState(() => _familyCode = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aileden ayrıldınız.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: Text('family_profile'.tr(ref))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (authState.familyId == null ? _buildNoFamily() : _buildHasFamily()),
    );
  }

  Widget _buildNoFamily() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.family_restroom, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Henüz bir aileye katılmadınız.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Yeni Aile Kur'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: _createFamily,
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          const Text(
            'Veya Davet Kodu İle Katıl',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Davet Kodu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _joinFamily,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: const Text('Katıl'),
          ),
        ],
      ),
    );
  }

  Widget _buildHasFamily() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'Aileniz',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  if (_familyCode != null)
                    Text(
                      'Davet Kodu: $_familyCode',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Davet Linkini Paylaş'),
                    onPressed: () {
                      if (_familyCode != null) {
                        SharePlus.instance.share(
                          ShareParams(
                            text:
                                'Seni Aile Bütçesi uygulamasına davet ediyorum! '
                                'Davet linkin: '
                                'familybudget://join?code=$_familyCode',
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _leaveFamily,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Aileden Ayrıl'),
          ),
        ],
      ),
    );
  }
}
