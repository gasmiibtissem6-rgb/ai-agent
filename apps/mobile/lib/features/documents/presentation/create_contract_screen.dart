import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ContractPartyData {
  final TextEditingController fullName = TextEditingController();
  final TextEditingController functionRole = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController email = TextEditingController();
  final String role;

  ContractPartyData(this.role);

  void fillFrom(Map<String, dynamic> data) {
    fullName.text = data['fullName'] ?? '';
    functionRole.text = data['functionRole'] ?? '';
    address.text = data['address'] ?? '';
    email.text = data['email'] ?? '';
  }
}

class CreateContractScreen extends StatefulWidget {
  final String? contractId;
  final String? initialTitle;
  final String? initialContent;
  final String partyALabel;
  final String partyBLabel;

  const CreateContractScreen({
    super.key,
    this.contractId,
    this.initialTitle,
    this.initialContent,
    this.partyALabel = 'Client',
    this.partyBLabel = 'Prestataire',
  });

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  static const _baseUrl = 'http://localhost:3001/api/contracts';

  late final _titleController = TextEditingController(
    text: widget.initialTitle ?? 'Contrat de prestation de services',
  );
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  final _client = ContractPartyData('CLIENT');
  final _prestataire = ContractPartyData('PRESTATAIRE');

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSending = false;
  String? _createdContractId;
  String? _status;

  @override
  void initState() {
    super.initState();
    _createdContractId = widget.contractId;
    if (widget.contractId != null) {
      _loadContract(widget.contractId!);
    } else if (widget.initialTitle != null) {
      _autoCreateFromTemplate();
    }
  }

  Future<void> _loadContract(String id) async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final response = await dio.get('$_baseUrl/$id');
      final data = response.data['data'] ?? response.data;
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _contentController.text = data['content'] ?? '';
      _status = data['status'];
      final parties = (data['parties'] as List?) ?? [];
      for (final p in parties) {
        if (p['role'] == 'CLIENT') _client.fillFrom(p);
        if (p['role'] == 'PRESTATAIRE') _prestataire.fillFrom(p);
      }
    } catch (e) {
      _showSnack('Erreur de chargement : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _autoCreateFromTemplate() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final response = await dio.post(
        _baseUrl,
        data: {
          'title': widget.initialTitle,
          'content': widget.initialContent ?? '',
          'parties': [],
        },
      );
      final data = response.data['data'] ?? response.data;
      setState(() {
        _createdContractId = data['id'];
        _status = data['status'];
      });
    } catch (e) {
      _showSnack('Erreur lors de la création automatique : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContract() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Le titre est obligatoire');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = Dio();
      final payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'content': _contentController.text,
        'parties': [
          {
            'role': 'CLIENT',
            'fullName': _client.fullName.text.trim(),
            'functionRole': _client.functionRole.text.trim(),
            'address': _client.address.text.trim(),
            'email': _client.email.text.trim(),
          },
          {
            'role': 'PRESTATAIRE',
            'fullName': _prestataire.fullName.text.trim(),
            'functionRole': _prestataire.functionRole.text.trim(),
            'address': _prestataire.address.text.trim(),
            'email': _prestataire.email.text.trim(),
          },
        ],
      };

      if (_createdContractId == null) {
        final response = await dio.post(_baseUrl, data: payload);
        final data = response.data['data'] ?? response.data;
        setState(() => _createdContractId = data['id']);
      } else {
        await dio.put('$_baseUrl/$_createdContractId', data: payload);
      }
      _showSnack('Contrat enregistré !');
    } catch (e) {
      _showSnack('Erreur lors de l\'enregistrement : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sendContract() async {
    if (_createdContractId == null) {
      _showSnack('Enregistrez d\'abord le contrat avant de l\'envoyer');
      return;
    }
    if (_prestataire.email.text.trim().isEmpty) {
      _showSnack('Renseignez l\'email du destinataire');
      return;
    }

    setState(() => _isSending = true);

    try {
      final dio = Dio();
      await dio.post(
        '$_baseUrl/$_createdContractId/send',
        data: {'email': _prestataire.email.text.trim()},
      );
      setState(() => _status = 'SENT');
      _showSnack('Contrat envoyé par email !');
    } catch (e) {
      _showSnack('Erreur lors de l\'envoi : $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_createdContractId == null ? 'Créer un contrat' : 'Modifier le contrat'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_status != null) _buildStatusChip(_status!),
                if (_status != null) const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre du contrat', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Contenu du contrat', border: OutlineInputBorder(), alignLabelWithHint: true),
                  maxLines: 10,
                ),
                const SizedBox(height: 24),
                _buildPartySection('Première partie (${widget.partyALabel})', _client, Colors.blue),
                const SizedBox(height: 20),
                _buildPartySection('Deuxième partie (${widget.partyBLabel})', _prestataire, Colors.orange),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveContract,
                  child: _isSaving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_createdContractId == null ? 'Créer le contrat' : 'Enregistrer les modifications'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: (_createdContractId == null || _isSending) ? null : _sendContract,
                  child: _isSending
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Envoyer le contrat'),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = {
      'DRAFT': Colors.grey,
      'SENT': Colors.orange,
      'SIGNED': Colors.green,
      'CANCELLED': Colors.red,
    };
    final labels = {
      'DRAFT': 'Brouillon',
      'SENT': 'Envoyé',
      'SIGNED': 'Signé',
      'CANCELLED': 'Annulé',
    };
    final color = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(labels[status] ?? status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildPartySection(String title, ContractPartyData party, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 10),
          TextField(
            controller: party.fullName,
            decoration: const InputDecoration(labelText: 'Nom ou société', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: party.functionRole,
            decoration: const InputDecoration(labelText: 'Fonction / Rôle', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: party.address,
            decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: party.email,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}
