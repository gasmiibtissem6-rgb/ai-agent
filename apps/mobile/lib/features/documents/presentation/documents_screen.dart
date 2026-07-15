import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/config/api_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/file_saver.dart';
import '../../../shared/ideal_ui.dart';
import '../../../shared/platform_file_picker.dart';

class MediaItem {
  final String type;
  final String data;
  final String? thumbnail;
  String caption;
  String date;

  MediaItem({
    required this.type,
    required this.data,
    this.thumbnail,
    this.caption = '',
    required this.date,
  });
}

class _ContractTemplate {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Map<String, String> bodies;

  const _ContractTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bodies,
  });

  String body(String lang) => bodies[lang] ?? bodies['fr']!;
}

const List<_ContractTemplate> kContractTemplates = [
  _ContractTemplate(
    title: "Contrat Architecte - Client",
    subtitle: "Maitrise d'oeuvre, suivi de chantier",
    icon: Icons.architecture,
    color: Colors.indigo,
    bodies: {
      'fr': """## CONTRAT DE MAITRISE D'OEUVRE

## Parties
Architecte : [Nom, Cabinet, Adresse]
Client : [Nom, Adresse]

## Objet de la mission
[Description : conception, suivi de chantier, permis de construire...]

## Honoraires
Montant : [Montant] DT
Modalites de paiement : [Acompte, tranches...]

## Duree
Date de debut : [Date]
Date de fin prevue : [Date]

## Clauses particulieres
- [Clause 1]
- [Clause 2]

---
Fait a [Ville], le [Date]""",
      'en': """## ARCHITECTURAL SERVICES CONTRACT

## Parties
Architect: [Name, Firm, Address]
Client: [Name, Address]

## Scope of Services
[Description: design, construction supervision, permits...]

## Fees
Amount: [Amount] TND
Payment terms: [Deposit, installments...]

## Duration
Start date: [Date]
Expected end date: [Date]

## Special Clauses
- [Clause 1]
- [Clause 2]

---
Done at [City], on [Date]""",
      'ar': """## عقد إدارة أعمال البناء

## الأطراف
المهندس المعماري: [الاسم، المكتب، العنوان]
العميل: [الاسم، العنوان]

## موضوع المهمة
[الوصف: التصميم، متابعة الورشة، رخصة البناء...]

## الأتعاب
المبلغ: [المبلغ] د.ت
شروط الدفع: [عربون، دفعات...]

## المدة
تاريخ البداية: [التاريخ]
تاريخ الانتهاء المتوقع: [التاريخ]

## بنود خاصة
- [بند 1]
- [بند 2]

---
حرر في [المدينة]، بتاريخ [التاريخ]""",
    },
  ),
  _ContractTemplate(
    title: "Contrat de Location",
    subtitle: "Bail immobilier, loyer, charges",
    icon: Icons.home_work,
    color: Colors.teal,
    bodies: {
      'fr': """## CONTRAT DE LOCATION

## Parties
Bailleur : [Nom, Adresse]
Locataire : [Nom, Adresse]

## Bien loue
Adresse : [Adresse du bien]
Description : [Type, surface, pieces]

## Conditions financieres
Loyer mensuel : [Montant] DT
Charges : [Montant] DT
Depot de garantie : [Montant] DT

## Duree
Date d'entree : [Date]
Duree du bail : [Duree]

## Clauses particulieres
- [Clause 1]
- [Clause 2]

---
Fait a [Ville], le [Date]""",
      'en': """## LEASE AGREEMENT

## Parties
Landlord: [Name, Address]
Tenant: [Name, Address]

## Leased Property
Address: [Property address]
Description: [Type, surface, rooms]

## Financial Terms
Monthly rent: [Amount] TND
Charges: [Amount] TND
Security deposit: [Amount] TND

## Duration
Move-in date: [Date]
Lease term: [Duration]

## Special Clauses
- [Clause 1]
- [Clause 2]

---
Done at [City], on [Date]""",
      'ar': """## عقد إيجار

## الأطراف
المؤجر: [الاسم، العنوان]
المستأجر: [الاسم، العنوان]

## العقار المؤجر
العنوان: [عنوان العقار]
الوصف: [النوع، المساحة، الغرف]

## الشروط المالية
الإيجار الشهري: [المبلغ] د.ت
المصاريف: [المبلغ] د.ت
مبلغ التأمين: [المبلغ] د.ت

## المدة
تاريخ الدخول: [التاريخ]
مدة الإيجار: [المدة]

## بنود خاصة
- [بند 1]
- [بند 2]

---
حرر في [المدينة]، بتاريخ [التاريخ]""",
    },
  ),
  _ContractTemplate(
    title: "Contrat de Prestation de Service",
    subtitle: "Freelance, consulting, missions",
    icon: Icons.handshake,
    color: Colors.orange,
    bodies: {
      'fr': """## CONTRAT DE PRESTATION DE SERVICE

## Parties
Prestataire : [Nom, Adresse]
Client : [Nom, Adresse]

## Objet
[Description de la mission]

## Tarif
Montant total : [Montant] DT
Modalites de paiement : [Details]

## Duree
Date de debut : [Date]
Date de fin : [Date]

## Clauses particulieres
- [Clause 1]
- [Clause 2]

---
Fait a [Ville], le [Date]""",
      'en': """## SERVICE AGREEMENT

## Parties
Service Provider: [Name, Address]
Client: [Name, Address]

## Purpose
[Description of the assignment]

## Fees
Total amount: [Amount] TND
Payment terms: [Details]

## Duration
Start date: [Date]
End date: [Date]

## Special Clauses
- [Clause 1]
- [Clause 2]

---
Done at [City], on [Date]""",
      'ar': """## عقد تقديم خدمات

## الأطراف
مقدم الخدمة: [الاسم، العنوان]
العميل: [الاسم، العنوان]

## الموضوع
[وصف المهمة]

## الأجرة
المبلغ الإجمالي: [المبلغ] د.ت
شروط الدفع: [التفاصيل]

## المدة
تاريخ البداية: [التاريخ]
تاريخ الانتهاء: [التاريخ]

## بنود خاصة
- [بند 1]
- [بند 2]

---
حرر في [المدينة]، بتاريخ [التاريخ]""",
    },
  ),
  _ContractTemplate(
    title: "Contrat de Vente",
    subtitle: "Vente de bien ou de marchandise",
    icon: Icons.sell,
    color: Colors.pink,
    bodies: {
      'fr':
          "## CONTRAT DE VENTE\n\n## Parties\nVendeur : [Nom, Adresse]\nAcheteur : [Nom, Adresse]\n\n## Objet de la vente\n[Description du bien vendu]\n\n## Prix\nMontant : [Montant] DT\nModalites de paiement : [Details]\n\n## Livraison / Transfert\nDate : [Date]\nLieu : [Lieu]\n\n## Clauses particulieres\n- [Clause 1]\n- [Clause 2]\n\n---\nFait a [Ville], le [Date]",
      'en':
          "## SALES CONTRACT\n\n## Parties\nSeller: [Name, Address]\nBuyer: [Name, Address]\n\n## Object of Sale\n[Description of the goods sold]\n\n## Price\nAmount: [Amount] TND\nPayment terms: [Details]\n\n## Delivery / Transfer\nDate: [Date]\nLocation: [Location]\n\n## Special Clauses\n- [Clause 1]\n- [Clause 2]\n\n---\nDone at [City], on [Date]",
      'ar':
          "## عقد بيع\n\n## الأطراف\nالبائع: [الاسم، العنوان]\nالمشتري: [الاسم، العنوان]\n\n## موضوع البيع\n[وصف السلعة المباعة]\n\n## الثمن\nالمبلغ: [المبلغ] د.ت\nشروط الدفع: [التفاصيل]\n\n## التسليم / النقل\nالتاريخ: [التاريخ]\nالمكان: [المكان]\n\n## بنود خاصة\n- [بند 1]\n- [بند 2]\n\n---\nحرر في [المدينة]، بتاريخ [التاريخ]",
    },
  ),
  _ContractTemplate(
    title: "Accord de Confidentialite (NDA)",
    subtitle: "Protection d'informations sensibles",
    icon: Icons.lock,
    color: Colors.blueGrey,
    bodies: {
      'fr':
          "## ACCORD DE CONFIDENTIALITE (NDA)\n\n## Parties\nPartie divulgatrice : [Nom, Adresse]\nPartie receveuse : [Nom, Adresse]\n\n## Objet\nProtection des informations confidentielles echangees dans le cadre de [contexte]\n\n## Obligations\n- Ne pas divulguer les informations a des tiers\n- Utiliser les informations uniquement dans le cadre prevu\n- Restituer ou detruire les documents a la fin de l'accord\n\n## Duree\nDuree de confidentialite : [Duree]\n\n---\nFait a [Ville], le [Date]",
      'en':
          "## NON-DISCLOSURE AGREEMENT (NDA)\n\n## Parties\nDisclosing Party: [Name, Address]\nReceiving Party: [Name, Address]\n\n## Purpose\nProtection of confidential information exchanged in the context of [context]\n\n## Obligations\n- Not to disclose the information to third parties\n- Use the information only for the intended purpose\n- Return or destroy documents at the end of the agreement\n\n## Duration\nConfidentiality period: [Duration]\n\n---\nDone at [City], on [Date]",
      'ar':
          "## اتفاقية عدم إفشاء المعلومات\n\n## الأطراف\nالطرف المفصح: [الاسم، العنوان]\nالطرف المتلقي: [الاسم، العنوان]\n\n## الموضوع\nحماية المعلومات السرية المتبادلة في إطار [السياق]\n\n## الالتزامات\n- عدم إفشاء المعلومات لأطراف ثالثة\n- استخدام المعلومات فقط للغرض المحدد\n- إعادة أو إتلاف الوثائق عند انتهاء الاتفاقية\n\n## المدة\nمدة السرية: [المدة]\n\n---\nحرر في [المدينة]، بتاريخ [التاريخ]",
    },
  ),
  _ContractTemplate(
    title: "Contrat de Partenariat",
    subtitle: "Collaboration entre deux entites",
    icon: Icons.groups,
    color: Colors.deepPurple,
    bodies: {
      'fr':
          "## CONTRAT DE PARTENARIAT\n## Parties\nPartenaire 1 : [Nom]\nPartenaire 2 : [Nom]\n## Objet\n[Description]\n## Duree\n[Duree]\n---\nFait a [Ville], le [Date]",
      'en':
          "## PARTNERSHIP AGREEMENT\n## Parties\nPartner 1: [Name]\nPartner 2: [Name]\n## Purpose\n[Description]\n## Duration\n[Duration]\n---\nDone at [City], on [Date]",
      'ar':
          "## عقد شراكة\n## الأطراف\nالشريك 1: [الاسم]\nالشريك 2: [الاسم]\n## الموضوع\n[الوصف]\n## المدة\n[المدة]\n---\nحرر في [المدينة]، بتاريخ [التاريخ]",
    },
  ),
  _ContractTemplate(
    title: "Freelance IT / Developpement",
    subtitle: "Mission technique, livrables, code",
    icon: Icons.code,
    color: Colors.cyan,
    bodies: {
      'fr':
          "## CONTRAT DE PRESTATION IT\n## Parties\nFreelance : [Nom]\nClient : [Nom]\n## Mission\n[Description]\n## Livrables\n- [Livrable 1]\n- [Livrable 2]\n## Tarif\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en':
          "## IT FREELANCE CONTRACT\n## Parties\nFreelancer: [Name]\nClient: [Name]\n## Scope\n[Description]\n## Deliverables\n- [Deliverable 1]\n- [Deliverable 2]\n## Fee\n[Amount]\n---\nDone at [City], on [Date]",
      'ar':
          "## عقد عمل حر في المعلوماتية\n## الأطراف\nالمستقل: [الاسم]\nالعميل: [الاسم]\n## المهمة\n[الوصف]\n## المخرجات\n- [مخرج 1]\n- [مخرج 2]\n## الأجرة\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]",
    },
  ),
  _ContractTemplate(
    title: "Contrat de Mandat",
    subtitle: "Representation, procuration",
    icon: Icons.gavel,
    color: Colors.blueGrey,
    bodies: {
      'fr':
          "## CONTRAT DE MANDAT\n## Parties\nMandant : [Nom]\nMandataire : [Nom]\n## Objet\n[Description]\n## Duree\n[Duree]\n---\nFait a [Ville], le [Date]",
      'en':
          "## AGENCY AGREEMENT\n## Parties\nPrincipal: [Name]\nAgent: [Name]\n## Subject\n[Description]\n## Duration\n[Duration]\n---\nDone at [City], on [Date]",
      'ar':
          "## عقد وكالة\n## الأطراف\nالموكل: [الاسم]\nالوكيل: [الاسم]\n## الموضوع\n[الوصف]\n## المدة\n[المدة]\n---\nحرر في [المدينة]، بتاريخ [التاريخ]",
    },
  ),
  _ContractTemplate(
    title: "Contrat de Stage",
    subtitle: "Stagiaire, entreprise",
    icon: Icons.school,
    color: Colors.teal,
    bodies: {
      'fr':
          "## CONTRAT DE STAGE\n## Parties\nEntreprise : [Nom]\nStagiaire : [Nom]\n## Duree\n[Duree]\n## Indemnite\n[Montant] DT/mois\n---\nFait a [Ville], le [Date]",
      'en':
          "## INTERNSHIP AGREEMENT\n## Parties\nCompany: [Name]\nIntern: [Name]\n## Duration\n[Duration]\n## Allowance\n[Amount]/month\n---\nDone at [City], on [Date]",
      'ar':
          "## عقد تربص\n## الأطراف\nالشركة: [الاسم]\nالمتربص: [الاسم]\n## المدة\n[المدة]\n## المنحة\n[المبلغ] د.ت/شهر\n---\nحرر في [المدينة]، بتاريخ [التاريخ]",
    },
  ),
  _ContractTemplate(
    title: "Contrat de Maintenance",
    subtitle: "Support technique, SLA",
    icon: Icons.build_circle,
    color: Colors.indigoAccent,
    bodies: {
      'fr':
          "## CONTRAT DE MAINTENANCE\n## Parties\nPrestataire : [Nom]\nClient : [Nom]\n## Services\n[Description]\n## Duree\n[Duree]\n## Tarif\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en':
          "## MAINTENANCE AGREEMENT\n## Parties\nProvider: [Name]\nClient: [Name]\n## Services\n[Description]\n## Duration\n[Duration]\n## Fee\n[Amount]\n---\nDone at [City], on [Date]",
      'ar':
          "## عقد صيانة\n## الأطراف\nالمزود: [الاسم]\nالعميل: [الاسم]\n## الخدمات\n[الوصف]\n## المدة\n[المدة]\n## التعرفة\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]",
    },
  ),
];

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isScanning = false;
  String _scannedText = '';
  final TextEditingController _editController = TextEditingController();
  bool _showSignature = false;
  String? _signatureImageBase64;
  final List<MediaItem> _mediaItems = [];
  String? _currentContractId;
  String _templateLang = 'fr';

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _pickFile({bool imageOnly = false}) {
    _handlePickFile(imageOnly: imageOnly);
  }

  Future<void> _handlePickFile({bool imageOnly = false}) async {
    final file = await pickSingleFile(
      allowedExtensions: imageOnly
          ? ['png', 'jpg', 'jpeg', 'webp']
          : ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
    );

    if (file == null) return;

    setState(() => _isScanning = true);

    try {
      final response = await Dio().post(
        '${ApiConfig.baseUrl}/chat/scan-contract',
        data: {'image': file.dataUrl, 'lang': 'fra+eng+ara'},
      );

      final raw = response.data;
      final dynamic data = raw is Map ? (raw['data'] ?? raw) : raw;
      final text = data is Map ? (data['text'] ?? '').toString() : '';

      if (!mounted) return;

      if (text.isNotEmpty) {
        setState(() {
          _scannedText = text;
          _editController.text = text;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tr('doc.scanned')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tr('doc.noText')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tr('doc.scanError')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _addMedia({bool videoOnly = false}) {
    _handleAddMedia(videoOnly: videoOnly);
  }

  Future<void> _handleAddMedia({bool videoOnly = false}) async {
    final files = await pickMultipleFiles(
      allowedExtensions: videoOnly
          ? ['mp4', 'mov', 'avi', 'mkv']
          : ['png', 'jpg', 'jpeg', 'webp', 'mp4', 'mov', 'avi', 'mkv'],
    );

    if (files.isEmpty) return;

    for (final file in files) {
      final name = file.name.toLowerCase();
      final isVideo =
          name.endsWith('.mp4') ||
          name.endsWith('.mov') ||
          name.endsWith('.avi') ||
          name.endsWith('.mkv');

      _mediaItems.add(
        MediaItem(
          type: isVideo ? 'video' : 'image',
          data: file.dataUrl,
          caption: file.name.split('.').first,
          date: DateTime.now().toLocal().toString().split(' ')[0],
        ),
      );
    }

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.trp('doc.filesAdded', {'count': '${files.length}'}),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _createContractRecord(String title, String content) async {
    try {
      final response = await Dio().post(
        '${ApiConfig.baseUrl}/contracts',
        data: {'title': title, 'content': content, 'parties': <dynamic>[]},
      );

      final raw = response.data;
      final dynamic data = raw is Map ? (raw['data'] ?? raw) : raw;

      if (mounted && data is Map) {
        setState(() {
          _currentContractId = data['id']?.toString();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de création du contrat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveContractRecord() async {
    try {
      final content = _editController.text.trim();
      if (content.isEmpty) return;

      if (_currentContractId == null) {
        final firstLine = content.split('\n').first.replaceAll('#', '').trim();
        await _createContractRecord(
          firstLine.isEmpty ? 'Contrat' : firstLine,
          content,
        );
      } else {
        await Dio().put(
          '${ApiConfig.baseUrl}/contracts/$_currentContractId',
          data: {'content': content},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrat enregistré !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur d'enregistrement"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSignatureDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SignatureDialog(
        onSigned: (signature) {
          setState(() {
            _showSignature = true;
            _signatureImageBase64 = signature.isNotEmpty ? signature : null;

            if (!_editController.text.contains('signé électroniquement')) {
              _editController.text +=
                  '\n\n--- Document signé électroniquement le '
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ---';
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.tr('doc.signatureApplied')),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _downloadPdf() async {
    try {
      final mediaPayload = _mediaItems
          .map(
            (item) => {
              'type': item.type,
              'data': item.type == 'image'
                  ? item.data
                  : (item.thumbnail ?? item.data),
              'thumbnail': item.thumbnail,
              'caption': item.caption,
              'date': item.date,
            },
          )
          .toList();

      final response = await Dio().post(
        '${ApiConfig.baseUrl}/chat/generate-pdf',
        data: {
          'content': _editController.text,
          'title': 'Contrat',
          if (_signatureImageBase64 != null)
            'signatureImage': _signatureImageBase64,
          if (_mediaItems.isNotEmpty) 'mediaItems': mediaPayload,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data is Uint8List
          ? response.data as Uint8List
          : Uint8List.fromList(List<int>.from(response.data as List));

      await savePdfBytes(bytes, 'contrat.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tr('doc.pdfError')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTemplatePicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (sheetContext, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choisir un modèle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _langChip('fr', 'FR', setModalState),
                          const SizedBox(width: 8),
                          _langChip('en', 'EN', setModalState),
                          const SizedBox(width: 8),
                          _langChip('ar', 'AR', setModalState),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            ...kContractTemplates.map(_templateTile),
                            _templateTile(null),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _langChip(String code, String label, StateSetter setModalState) {
    final selected = _templateLang == code;

    return GestureDetector(
      onTap: () {
        setModalState(() {
          _templateLang = code;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.purple : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _templateTile(_ContractTemplate? template) {
    final color = template?.color ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);

        final body = template?.body(_templateLang) ?? '';

        setState(() {
          _scannedText = ' ';
          _editController.text = body;
          _currentContractId = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(template?.icon ?? Icons.note_add, color: color, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template?.title ?? 'Page vide',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    template?.subtitle ?? 'Rédiger depuis zéro',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IdealAppScaffold(
      activeRoute: 'documents',
      body: IdealGradientBackground(
        child: _scannedText.isEmpty
            ? _buildImportScreen(colorScheme)
            : _buildEditScreen(colorScheme),
      ),
    );
  }

  Widget _buildImportScreen(ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.tr('doc.importTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.tr('doc.importSubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),
            if (_isScanning)
              const CircularProgressIndicator()
            else ...[
              _buildCard(
                colorScheme,
                Icons.camera_alt,
                context.l10n.tr('doc.takePhoto'),
                context.l10n.tr('doc.takePhotoSub'),
                Colors.blue,
                () => _pickFile(imageOnly: true),
              ),
              const SizedBox(height: 16),
              _buildCard(
                colorScheme,
                Icons.upload_file,
                context.l10n.tr('doc.importFile'),
                context.l10n.tr('doc.importFileSub'),
                Colors.green,
                _pickFile,
              ),
              const SizedBox(height: 16),
              _buildCard(
                colorScheme,
                Icons.edit_document,
                context.l10n.tr('doc.newContract'),
                context.l10n.tr('doc.newContractSub'),
                Colors.purple,
                _showTemplatePicker,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    ColorScheme colorScheme,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEditScreen(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: colorScheme.surface,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _scannedText = '';
                    _editController.clear();
                    _mediaItems.clear();
                    _showSignature = false;
                    _signatureImageBase64 = null;
                    _currentContractId = null;
                  });
                },
              ),
              Text(
                context.l10n.tr('doc.contract'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.save, color: Colors.blue),
                tooltip: 'Enregistrer',
                onPressed: _saveContractRecord,
              ),
              IconButton(
                icon: const Icon(Icons.add_photo_alternate, color: Colors.teal),
                tooltip: context.l10n.tr('doc.addMedia'),
                onPressed: _addMedia,
              ),
              IconButton(
                icon: Icon(
                  Icons.draw,
                  color: _showSignature ? Colors.green : Colors.purple,
                ),
                tooltip: context.l10n.tr('doc.sign'),
                onPressed: _showSignatureDialog,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                tooltip: context.l10n.tr('doc.exportPdf'),
                onPressed: _downloadPdf,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _editController,
                  maxLines: null,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    hintText: context.l10n.tr('doc.contentHint'),
                  ),
                ),
                if (_mediaItems.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_library,
                        size: 18,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.trp('doc.attachments', {
                          'count': '${_mediaItems.length}',
                        }),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.teal,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addMedia,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(context.l10n.tr('doc.add')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.3,
                        ),
                    itemCount: _mediaItems.length,
                    itemBuilder: (context, index) {
                      return _buildMediaCard(colorScheme, index);
                    },
                  ),
                ],
                if (_showSignature) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.tr('doc.signedBadge'),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_signatureImageBase64 != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              _signatureImageBase64!,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(ColorScheme colorScheme, int index) {
    final item = _mediaItems[index];
    final previewData = item.thumbnail ?? item.data;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: item.type == 'image'
                      ? Image.network(previewData, fit: BoxFit.cover)
                      : Container(
                          color: colorScheme.surfaceContainerHigh,
                          child: const Center(
                            child: Icon(
                              Icons.videocam,
                              size: 36,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                ),
                if (item.type == 'video')
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _mediaItems.removeAt(index);
                      });
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.caption,
                    onChanged: (value) {
                      item.caption = value;
                    },
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: context.l10n.tr('doc.caption'),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.date,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureDialog extends StatefulWidget {
  final ValueChanged<String> onSigned;

  const _SignatureDialog({required this.onSigned});

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final GlobalKey _signatureBoundaryKey = GlobalKey();
  int _tab = 0;
  List<Offset?> _points = [];
  bool _hasSignature = false;
  bool _isProcessing = false;
  String? _cameraImageBase64;

  Future<void> _onFinish() async {
    setState(() => _isProcessing = true);

    final signature = _tab == 0
        ? await _captureDrawing()
        : (_cameraImageBase64 ?? '');

    if (!mounted) return;

    setState(() => _isProcessing = false);
    Navigator.pop(context);
    widget.onSigned(signature);
  }

  Future<String> _captureDrawing() async {
    try {
      final boundary =
          _signatureBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) return '';

      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return '';

      final bytes = byteData.buffer.asUint8List();
      return 'data:image/png;base64,${base64Encode(bytes)}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.tr('doc.signature'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _tabButton(context.l10n.tr('doc.draw'), 0),
                  _tabButton(context.l10n.tr('doc.camera'), 1),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_tab == 0)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: RepaintBoundary(
                  key: _signatureBoundaryKey,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        setState(() {
                          _points.add(details.localPosition);
                          _hasSignature = true;
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _points.add(null);
                        });
                      },
                      child: CustomPaint(
                        painter: _SignaturePainter(_points),
                        child: _points.isEmpty
                            ? Center(
                                child: Text(
                                  context.l10n.tr('doc.drawHint'),
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              )
            else if (_cameraImageBase64 == null)
              GestureDetector(
                onTap: () async {
                  final file = await pickSingleFile(
                    allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
                  );

                  if (file == null || !mounted) return;

                  setState(() {
                    _cameraImageBase64 = file.dataUrl;
                    _hasSignature = true;
                  });
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.upload_file,
                          size: 40,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.tr('doc.importSig'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.tr('doc.importSigSub'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _cameraImageBase64!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _cameraImageBase64 = null;
                          _hasSignature = false;
                        });
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _points = [];
                      _hasSignature = false;
                      _cameraImageBase64 = null;
                    });
                  },
                  child: Text(
                    context.l10n.tr('doc.clear'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.tr('common.cancel')),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _hasSignature && !_isProcessing ? _onFinish : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.l10n.tr('doc.finish'),
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];

      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return true;
  }
}
