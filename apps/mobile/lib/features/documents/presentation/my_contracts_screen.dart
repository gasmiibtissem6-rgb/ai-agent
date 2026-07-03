import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'create_contract_screen.dart';

class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({super.key});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  final _dio = Dio();
  List<dynamic> _contracts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _dio.get('http://localhost:3001/api/contracts');
      setState(() => _contracts = (response.data['data'] as List<dynamic>?) ?? []);
    } catch (e) {
      setState(() => _error = 'Erreur de chargement : $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendContract(String contractId, String? defaultEmail) async {
    final controller = TextEditingController(text: defaultEmail ?? '');
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Envoyer le contrat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Email du destinataire'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;

    try {
      await _dio.post(
        'http://localhost:3001/api/contracts/$contractId/send',
        data: {'email': email},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contrat envoyé à $email')),
        );
      }
      _loadContracts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi : $e')),
        );
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'SIGNED': return Colors.green;
      case 'SENT': return Colors.blue;
      case 'WAITING_SIGNATURE': return Colors.orange;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Contrats'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadContracts),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _contracts.isEmpty
                  ? const Center(child: Text('Aucun contrat pour le moment'))
                  : RefreshIndicator(
                      onRefresh: _loadContracts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _contracts.length,
                        itemBuilder: (context, index) {
                          final c = _contracts[index];
                          final parties = (c['parties'] as List?) ?? [];
                          final prestataire = parties.firstWhere(
                            (p) => p['role'] == 'PRESTATAIRE',
                            orElse: () => null,
                          );
                          final defaultEmail = prestataire?['email'] as String?;
                          final status = c['status'] as String?;

                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateContractScreen(contractId: c['id']),
                                ),
                              );
                              _loadContracts();
                            },
                            child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c['title'] ?? 'Sans titre',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status ?? 'DRAFT',
                                        style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (parties.isNotEmpty)
                                  Text(
                                    parties.map((p) => p['fullName'] ?? '').where((s) => s != '').join(' • '),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _sendContract(c['id'], defaultEmail),
                                  icon: const Icon(Icons.send, size: 16),
                                  label: const Text('Envoyer'),
                                ),
                              ],
                            ),
                          ),
                          );
                        },
                      ),
                    ),
    );
  }
}

