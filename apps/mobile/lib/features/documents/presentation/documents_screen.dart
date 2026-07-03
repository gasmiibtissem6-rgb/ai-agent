<<<<<<< HEAD
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
=======
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

>>>>>>> c6204d425370e1f5650e9db9e5fe71aaf6b88b80
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/file_saver.dart';
import '../../../shared/ideal_ui.dart';
import '../../../shared/platform_file_picker.dart';

class MediaItem {
  final String type; // 'image' or 'video'
  final String data; // base64
  final String? thumbnail; // base64 thumbnail for videos
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
  final Map<String, String> bodies; // 'fr', 'en', 'ar'
  const _ContractTemplate({required this.title, required this.subtitle, required this.icon, required this.color, required this.bodies});
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
      'fr': """## CONTRAT DE VENTE

## Parties
Vendeur : [Nom, Adresse]
Acheteur : [Nom, Adresse]

## Objet de la vente
[Description du bien vendu]

## Prix
Montant : [Montant] DT
Modalites de paiement : [Details]

## Livraison / Transfert
Date : [Date]
Lieu : [Lieu]

## Clauses particulieres
- [Clause 1]
- [Clause 2]

---
Fait a [Ville], le [Date]""",
      'en': """## SALES CONTRACT

## Parties
Seller: [Name, Address]
Buyer: [Name, Address]

## Object of Sale
[Description of the goods sold]

## Price
Amount: [Amount] TND
Payment terms: [Details]

## Delivery / Transfer
Date: [Date]
Location: [Location]

## Special Clauses
- [Clause 1]
- [Clause 2]

---
Done at [City], on [Date]""",
      'ar': """## عقد بيع

## الأطراف
البائع: [الاسم، العنوان]
المشتري: [الاسم، العنوان]

## موضوع البيع
[وصف السلعة المباعة]

## الثمن
المبلغ: [المبلغ] د.ت
شروط الدفع: [التفاصيل]

## التسليم / النقل
التاريخ: [التاريخ]
المكان: [المكان]

## بنود خاصة
- [بند 1]
- [بند 2]

---
حرر في [المدينة]، بتاريخ [التاريخ]""",
    },
  ),
  _ContractTemplate(
    title: "Accord de Confidentialite (NDA)",
    subtitle: "Protection d'informations sensibles",
    icon: Icons.lock,
    color: Colors.blueGrey,
    bodies: {
      'fr': """## ACCORD DE CONFIDENTIALITE (NDA)

## Parties
Partie divulgatrice : [Nom, Adresse]
Partie receveuse : [Nom, Adresse]

## Objet
Protection des informations confidentielles echangees dans le cadre de [contexte : projet, negociation...]

## Obligations
- Ne pas divulguer les informations a des tiers
- Utiliser les informations uniquement dans le cadre prevu
- Restituer ou detruire les documents a la fin de l'accord

## Duree
Duree de confidentialite : [Duree, ex: 3 ans apres la fin de l'accord]

## Clauses particulieres
- [Clause 1]
- [Clause 2]

---
Fait a [Ville], le [Date]""",
      'en': """## NON-DISCLOSURE AGREEMENT (NDA)

## Parties
Disclosing Party: [Name, Address]
Receiving Party: [Name, Address]

## Purpose
Protection of confidential information exchanged in the context of [context: project, negotiation...]

## Obligations
- Not to disclose the information to third parties
- Use the information only for the intended purpose
- Return or destroy documents at the end of the agreement

## Duration
Confidentiality period: [Duration, e.g. 3 years after termination]

## Special Clauses
- [Clause 1]
- [Clause 2]

---
Done at [City], on [Date]""",
      'ar': """## اتفاقية عدم إفشاء المعلومات (NDA)

## الأطراف
الطرف المفصح: [الاسم، العنوان]
الطرف المتلقي: [الاسم، العنوان]

## الموضوع
حماية المعلومات السرية المتبادلة في إطار [السياق: مشروع، مفاوضات...]

## الالتزامات
- عدم إفشاء المعلومات لأطراف ثالثة
- استخدام المعلومات فقط للغرض المحدد
- إعادة أو إتلاف الوثائق عند انتهاء الاتفاقية

## المدة
مدة السرية: [المدة، مثلا 3 سنوات بعد انتهاء الاتفاقية]

## بنود خاصة
- [بند 1]
- [بند 2]

---
حرر في [المدينة]، بتاريخ [التاريخ]""",
    },
  ),
  _ContractTemplate(
    title: "Contrat de Partenariat",
    subtitle: "Collaboration entre deux entites",
    icon: Icons.groups,
    color: Colors.deepPurple,
    bodies: {
      'fr': """## CONTRAT DE PARTENARIAT

## Parties
Partenaire 1 : [Nom, Adresse]
Partenaire 2 : [Nom, Adresse]

## Objet du partenariat
[Description : objectifs communs, projet, apports respectifs]

## Repartition
Apports de chaque partie : [Details]
Repartition des benefices/couts : [Pourcentages ou modalites]

## Duree
Date de debut : [Date]
Duree : [Duree ou date de fin]

## Clauses particulieres
- [Clause 1]
- [Clause 2]

---
Fait a [Ville], le [Date]""",
      'en': """## PARTNERSHIP AGREEMENT

## Parties
Partner 1: [Name, Address]
Partner 2: [Name, Address]

## Purpose of Partnership
[Description: common goals, project, respective contributions]

## Distribution
Contributions of each party: [Details]
Profit/cost sharing: [Percentages or terms]

## Duration
Start date: [Date]
Duration: [Duration or end date]

## Special Clauses
- [Clause 1]
- [Clause 2]

---
Done at [City], on [Date]""",
      'ar': """## عقد شراكة

## الأطراف
الشريك 1: [الاسم، العنوان]
الشريك 2: [الاسم، العنوان]

## موضوع الشراكة
[الوصف: الأهداف المشتركة، المشروع، مساهمة كل طرف]

## التوزيع
مساهمة كل طرف: [التفاصيل]
توزيع الأرباح/التكاليف: [النسب أو الشروط]

## المدة
تاريخ البداية: [التاريخ]
المدة: [المدة أو تاريخ الانتهاء]

## بنود خاصة
- [بند 1]
- [بند 2]

---
حرر في [المدينة]، بتاريخ [التاريخ]""",
    },
  ),
  _ContractTemplate(
    title: "Freelance IT / Developpement",
    subtitle: "Mission technique, livrables, code",
    icon: Icons.code,
    color: Colors.cyan,
    bodies: {
      'fr': """## CONTRAT DE PRESTATION IT (FREELANCE)

## Parties
Freelance/Developpeur : [Nom, Adresse]
Client : [Nom, Adresse]

## Objet de la mission
[Description technique : application, site web, module...]

## Livrables
- [Livrable 1]
- [Livrable 2]
Delai de livraison : [Date]

## Tarif
Montant : [Montant] DT
Modalites : [Forfait / TJM / a l'avancement]

## Propriete intellectuelle
[Le code livre devient la propriete du client apres paiement integral]

## Clauses particulieres
- [Clause 1]
- [Clause 2]

---
Fait a [Ville], le [Date]""",
      'en': """## IT / DEVELOPMENT FREELANCE CONTRACT

## Parties
Freelancer/Developer: [Name, Address]
Client: [Name, Address]

## Scope of Work
[Technical description: application, website, module...]

## Deliverables
- [Deliverable 1]
- [Deliverable 2]
Delivery deadline: [Date]

## Fees
Amount: [Amount] TND
Terms: [Fixed price / daily rate / milestone-based]

## Intellectual Property
[Delivered code becomes client's property upon full payment]

## Special Clauses
- [Clause 1]
- [Clause 2]

---
Done at [City], on [Date]""",
      'ar': """## عقد عمل حر في المعلوماتية (فريلانس)

## الأطراف
المستقل/المطور: [الاسم، العنوان]
العميل: [الاسم، العنوان]

## موضوع المهمة
[الوصف التقني: تطبيق، موقع ويب، وحدة برمجية...]

## المخرجات
- [مخرج 1]
- [مخرج 2]
أجل التسليم: [التاريخ]

## الأجرة
المبلغ: [المبلغ] د.ت
الشروط: [سعر ثابت / يومي / حسب التقدم]

## الملكية الفكرية
[يصبح الكود المسلم ملكا للعميل بعد الدفع الكامل]

## بنود خاصة
- [بند 1]
- [بند 2]

---
حرر في [المدينة]، بتاريخ [التاريخ]""",
    },
  ),
_ContractTemplate(title: "Contrat de Mandat", subtitle: "Representation, procuration", icon: Icons.gavel, color: Colors.blueGrey,
    bodies: {'fr': "## CONTRAT DE MANDAT\n## Parties\nMandant : [Nom]\nMandataire : [Nom]\n## Objet\n[Description]\n## Duree\n[Duree]\n---\nFait a [Ville], le [Date]",
      'en': "## AGENCY AGREEMENT\n## Parties\nPrincipal: [Name]\nAgent: [Name]\n## Subject\n[Description]\n## Duration\n[Duration]\n---\nDone at [City], on [Date]",
      'ar': "## عقد وكالة\n## الأطراف\nالموكل: [الاسم]\nالوكيل: [الاسم]\n## الموضوع\n[الوصف]\n## المدة\n[المدة]\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Stage", subtitle: "Stagiaire, entreprise", icon: Icons.school, color: Colors.teal,
    bodies: {'fr': "## CONTRAT DE STAGE\n## Parties\nEntreprise : [Nom]\nStagiaire : [Nom]\n## Duree\n[Duree]\n## Indemnite\n[Montant] DT/mois\n---\nFait a [Ville], le [Date]",
      'en': "## INTERNSHIP AGREEMENT\n## Parties\nCompany: [Name]\nIntern: [Name]\n## Duration\n[Duration]\n## Allowance\n[Amount]/month\n---\nDone at [City], on [Date]",
      'ar': "## عقد تربص\n## الأطراف\nالشركة: [الاسم]\nالمتربص: [الاسم]\n## المدة\n[المدة]\n## المنحة\n[المبلغ] د.ت/شهر\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Maintenance", subtitle: "Support technique, SLA", icon: Icons.build_circle, color: Colors.indigoAccent,
    bodies: {'fr': "## CONTRAT DE MAINTENANCE\n## Parties\nPrestataire : [Nom]\nClient : [Nom]\n## Services\n[Description]\n## Duree\n[Duree]\n## Tarif\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## MAINTENANCE AGREEMENT\n## Parties\nProvider: [Name]\nClient: [Name]\n## Services\n[Description]\n## Duration\n[Duration]\n## Fee\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد صيانة\n## الأطراف\nالمزود: [الاسم]\nالعميل: [الاسم]\n## الخدمات\n[الوصف]\n## المدة\n[المدة]\n## التعرفة\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat d'Assurance", subtitle: "Police, couverture, prime", icon: Icons.shield, color: Colors.lightBlue,
    bodies: {'fr': "## CONTRAT D'ASSURANCE\n## Parties\nAssureur : [Nom]\nAssure : [Nom]\n## Couverture\n[Description]\n## Prime\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## INSURANCE POLICY\n## Parties\nInsurer: [Name]\nInsured: [Name]\n## Coverage\n[Description]\n## Premium\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد تأمين\n## الأطراف\nالمؤمن: [الاسم]\nالمؤمن له: [الاسم]\n## التغطية\n[الوصف]\n## القسط\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Transport", subtitle: "Livraison, logistique", icon: Icons.local_shipping_outlined, color: Colors.orangeAccent,
    bodies: {'fr': "## CONTRAT DE TRANSPORT\n## Parties\nTransporteur : [Nom]\nExpediteur : [Nom]\n## Marchandise\n[Description]\n## Tarif\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## TRANSPORT AGREEMENT\n## Parties\nCarrier: [Name]\nShipper: [Name]\n## Goods\n[Description]\n## Fee\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد نقل\n## الأطراف\nالناقل: [الاسم]\nالمرسل: [الاسم]\n## البضاعة\n[الوصف]\n## الأجرة\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Partenariat Commercial", subtitle: "Alliance strategique", icon: Icons.handshake, color: Colors.purpleAccent,
    bodies: {'fr': "## PARTENARIAT COMMERCIAL\n## Parties\nPartie A : [Nom]\nPartie B : [Nom]\n## Objet\n[Description]\n## Duree\n[Duree]\n---\nFait a [Ville], le [Date]",
      'en': "## BUSINESS PARTNERSHIP\n## Parties\nParty A: [Name]\nParty B: [Name]\n## Subject\n[Description]\n## Duration\n[Duration]\n---\nDone at [City], on [Date]",
      'ar': "## شراكة تجارية\n## الأطراف\nالطرف أ: [الاسم]\nالطرف ب: [الاسم]\n## الموضوع\n[الوصف]\n## المدة\n[المدة]\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Reservation", subtitle: "Hebergement, evenement", icon: Icons.event, color: Colors.deepPurpleAccent,
    bodies: {'fr': "## CONTRAT DE RESERVATION\n## Parties\nPrestataire : [Nom]\nClient : [Nom]\n## Objet\n[Description]\n## Montant\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## BOOKING AGREEMENT\n## Parties\nProvider: [Name]\nClient: [Name]\n## Subject\n[Description]\n## Amount\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد حجز\n## الأطراف\nالمزود: [الاسم]\nالعميل: [الاسم]\n## الموضوع\n[الوصف]\n## المبلغ\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Gestion Immobiliere", subtitle: "Gerance, syndic", icon: Icons.apartment, color: Colors.brown,
    bodies: {'fr': "## GESTION IMMOBILIERE\n## Parties\nProprietaire : [Nom]\nGestionnaire : [Nom]\n## Biens\n[Description]\n## Honoraires\n[Pourcentage] %\n---\nFait a [Ville], le [Date]",
      'en': "## PROPERTY MANAGEMENT\n## Parties\nOwner: [Name]\nManager: [Name]\n## Property\n[Description]\n## Fees\n[Percentage] %\n---\nDone at [City], on [Date]",
      'ar': "## إدارة عقارية\n## الأطراف\nالمالك: [الاسم]\nالمدير: [الاسم]\n## الممتلكات\n[الوصف]\n## الأتعاب\n[النسبة] %\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Licence Logiciel", subtitle: "Utilisation, SaaS", icon: Icons.laptop_mac, color: Colors.cyanAccent,
    bodies: {'fr': "## LICENCE LOGICIEL\n## Parties\nEditeur : [Nom]\nUtilisateur : [Nom]\n## Objet\n[Description]\n## Tarif\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## SOFTWARE LICENSE\n## Parties\nLicensor: [Name]\nLicensee: [Name]\n## Subject\n[Description]\n## Fee\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## ترخيص برمجيات\n## الأطراف\nالمرخص: [الاسم]\nالمرخص له: [الاسم]\n## الموضوع\n[الوصف]\n## التعرفة\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Publicite", subtitle: "Campagne, sponsoring", icon: Icons.campaign, color: Colors.redAccent,
    bodies: {'fr': "## CONTRAT DE PUBLICITE\n## Parties\nAnnonceur : [Nom]\nDiffuseur : [Nom]\n## Objet\n[Description]\n## Budget\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## ADVERTISING AGREEMENT\n## Parties\nAdvertiser: [Name]\nPublisher: [Name]\n## Subject\n[Description]\n## Budget\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد إعلان\n## الأطراف\nالمعلن: [الاسم]\nالناشر: [الاسم]\n## الموضوع\n[الوصف]\n## الميزانية\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat d'Investissement", subtitle: "Levee de fonds, actionnariat", icon: Icons.trending_up, color: Colors.green,
    bodies: {'fr': "## CONTRAT D'INVESTISSEMENT\n## Parties\nInvestisseur : [Nom]\nSociete : [Nom]\n## Montant\n[Montant] DT\n## Parts\n[Pourcentage] %\n---\nFait a [Ville], le [Date]",
      'en': "## INVESTMENT AGREEMENT\n## Parties\nInvestor: [Name]\nCompany: [Name]\n## Amount\n[Amount]\n## Equity\n[Percentage] %\n---\nDone at [City], on [Date]",
      'ar': "## عقد استثمار\n## الأطراف\nالمستثمر: [الاسم]\nالشركة: [الاسم]\n## المبلغ\n[المبلغ] د.ت\n## الحصة\n[النسبة] %\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Garde d'Enfants", subtitle: "Nounou, babysitting", icon: Icons.child_care, color: Colors.pinkAccent,
    bodies: {'fr': "## CONTRAT DE GARDE\n## Parties\nParents : [Nom]\nGarde : [Nom]\n## Horaires\n[Description]\n## Remuneration\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## CHILDCARE AGREEMENT\n## Parties\nParents: [Name]\nCaregiver: [Name]\n## Hours\n[Description]\n## Pay\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد حضانة\n## الأطراف\nالوالدان: [الاسم]\nالحاضنة: [الاسم]\n## المواعيد\n[الوصف]\n## الأجر\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Coaching", subtitle: "Formation, accompagnement", icon: Icons.psychology, color: Colors.amberAccent,
    bodies: {'fr': "## CONTRAT DE COACHING\n## Parties\nCoach : [Nom]\nClient : [Nom]\n## Objectifs\n[Description]\n## Tarif\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## COACHING AGREEMENT\n## Parties\nCoach: [Name]\nClient: [Name]\n## Goals\n[Description]\n## Fee\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد تدريب\n## الأطراف\nالمدرب: [الاسم]\nالعميل: [الاسم]\n## الأهداف\n[الوصف]\n## الأجر\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Co-fondation", subtitle: "Associes, startup", icon: Icons.rocket_launch, color: Colors.deepOrangeAccent,
    bodies: {'fr': "## PACTE D'ASSOCIES\n## Parties\nAssocie 1 : [Nom]\nAssocie 2 : [Nom]\n## Repartition\n[Pourcentages]\n## Duree\n[Duree]\n---\nFait a [Ville], le [Date]",
      'en': "## FOUNDERS AGREEMENT\n## Parties\nFounder 1: [Name]\nFounder 2: [Name]\n## Equity Split\n[Percentages]\n## Duration\n[Duration]\n---\nDone at [City], on [Date]",
      'ar': "## اتفاقية شركاء\n## الأطراف\nالشريك 1: [الاسم]\nالشريك 2: [الاسم]\n## التوزيع\n[النسب]\n## المدة\n[المدة]\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Vente de Vehicule", subtitle: "Voiture, moto", icon: Icons.directions_car, color: Colors.blueGrey,
    bodies: {'fr': "## VENTE DE VEHICULE\n## Parties\nVendeur : [Nom]\nAcheteur : [Nom]\n## Vehicule\n[Marque, modele, immatriculation]\n## Prix\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## VEHICLE SALE\n## Parties\nSeller: [Name]\nBuyer: [Name]\n## Vehicle\n[Make, model, plate]\n## Price\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## بيع سيارة\n## الأطراف\nالبائع: [الاسم]\nالمشتري: [الاسم]\n## المركبة\n[الماركة، الموديل، رقم اللوحة]\n## الثمن\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Cloture de Compte", subtitle: "Solde de tout compte", icon: Icons.account_balance, color: Colors.grey,
    bodies: {'fr': "## SOLDE DE TOUT COMPTE\n## Parties\nEmployeur : [Nom]\nSalarie : [Nom]\n## Montant\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## FINAL SETTLEMENT\n## Parties\nEmployer: [Name]\nEmployee: [Name]\n## Amount\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## تسوية نهائية\n## الأطراف\nصاحب العمل: [الاسم]\nالأجير: [الاسم]\n## المبلغ\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Mandat", subtitle: "Representation, procuration", icon: Icons.gavel, color: Colors.blueGrey,
    bodies: {'fr': "## CONTRAT DE MANDAT\n## Parties\nMandant : [Nom]\nMandataire : [Nom]\n## Objet\n[Description]\n## Duree\n[Duree]\n---\nFait a [Ville], le [Date]",
      'en': "## AGENCY AGREEMENT\n## Parties\nPrincipal: [Name]\nAgent: [Name]\n## Subject\n[Description]\n## Duration\n[Duration]\n---\nDone at [City], on [Date]",
      'ar': "## عقد وكالة\n## الأطراف\nالموكل: [الاسم]\nالوكيل: [الاسم]\n## الموضوع\n[الوصف]\n## المدة\n[المدة]\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Stage", subtitle: "Stagiaire, entreprise", icon: Icons.school, color: Colors.teal,
    bodies: {'fr': "## CONTRAT DE STAGE\n## Parties\nEntreprise : [Nom]\nStagiaire : [Nom]\n## Duree\n[Duree]\n## Indemnite\n[Montant] DT/mois\n---\nFait a [Ville], le [Date]",
      'en': "## INTERNSHIP AGREEMENT\n## Parties\nCompany: [Name]\nIntern: [Name]\n## Duration\n[Duration]\n## Allowance\n[Amount]/month\n---\nDone at [City], on [Date]",
      'ar': "## عقد تربص\n## الأطراف\nالشركة: [الاسم]\nالمتربص: [الاسم]\n## المدة\n[المدة]\n## المنحة\n[المبلغ] د.ت/شهر\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Maintenance", subtitle: "Support technique, SLA", icon: Icons.build_circle, color: Colors.indigoAccent,
    bodies: {'fr': "## CONTRAT DE MAINTENANCE\n## Parties\nPrestataire : [Nom]\nClient : [Nom]\n## Services\n[Description]\n## Duree\n[Duree]\n## Tarif\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## MAINTENANCE AGREEMENT\n## Parties\nProvider: [Name]\nClient: [Name]\n## Services\n[Description]\n## Duration\n[Duration]\n## Fee\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد صيانة\n## الأطراف\nالمزود: [الاسم]\nالعميل: [الاسم]\n## الخدمات\n[الوصف]\n## المدة\n[المدة]\n## التعرفة\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat d'Assurance", subtitle: "Police, couverture, prime", icon: Icons.shield, color: Colors.lightBlue,
    bodies: {'fr': "## CONTRAT D'ASSURANCE\n## Parties\nAssureur : [Nom]\nAssure : [Nom]\n## Couverture\n[Description]\n## Prime\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## INSURANCE POLICY\n## Parties\nInsurer: [Name]\nInsured: [Name]\n## Coverage\n[Description]\n## Premium\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد تأمين\n## الأطراف\nالمؤمن: [الاسم]\nالمؤمن له: [الاسم]\n## التغطية\n[الوصف]\n## القسط\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Transport", subtitle: "Livraison, logistique", icon: Icons.local_shipping_outlined, color: Colors.orangeAccent,
    bodies: {'fr': "## CONTRAT DE TRANSPORT\n## Parties\nTransporteur : [Nom]\nExpediteur : [Nom]\n## Marchandise\n[Description]\n## Tarif\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## TRANSPORT AGREEMENT\n## Parties\nCarrier: [Name]\nShipper: [Name]\n## Goods\n[Description]\n## Fee\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد نقل\n## الأطراف\nالناقل: [الاسم]\nالمرسل: [الاسم]\n## البضاعة\n[الوصف]\n## الأجرة\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Partenariat Commercial", subtitle: "Alliance strategique", icon: Icons.handshake, color: Colors.purpleAccent,
    bodies: {'fr': "## PARTENARIAT COMMERCIAL\n## Parties\nPartie A : [Nom]\nPartie B : [Nom]\n## Objet\n[Description]\n## Duree\n[Duree]\n---\nFait a [Ville], le [Date]",
      'en': "## BUSINESS PARTNERSHIP\n## Parties\nParty A: [Name]\nParty B: [Name]\n## Subject\n[Description]\n## Duration\n[Duration]\n---\nDone at [City], on [Date]",
      'ar': "## شراكة تجارية\n## الأطراف\nالطرف أ: [الاسم]\nالطرف ب: [الاسم]\n## الموضوع\n[الوصف]\n## المدة\n[المدة]\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Reservation", subtitle: "Hebergement, evenement", icon: Icons.event, color: Colors.deepPurpleAccent,
    bodies: {'fr': "## CONTRAT DE RESERVATION\n## Parties\nPrestataire : [Nom]\nClient : [Nom]\n## Objet\n[Description]\n## Montant\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## BOOKING AGREEMENT\n## Parties\nProvider: [Name]\nClient: [Name]\n## Subject\n[Description]\n## Amount\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد حجز\n## الأطراف\nالمزود: [الاسم]\nالعميل: [الاسم]\n## الموضوع\n[الوصف]\n## المبلغ\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Gestion Immobiliere", subtitle: "Gerance, syndic", icon: Icons.apartment, color: Colors.brown,
    bodies: {'fr': "## GESTION IMMOBILIERE\n## Parties\nProprietaire : [Nom]\nGestionnaire : [Nom]\n## Biens\n[Description]\n## Honoraires\n[Pourcentage] %\n---\nFait a [Ville], le [Date]",
      'en': "## PROPERTY MANAGEMENT\n## Parties\nOwner: [Name]\nManager: [Name]\n## Property\n[Description]\n## Fees\n[Percentage] %\n---\nDone at [City], on [Date]",
      'ar': "## إدارة عقارية\n## الأطراف\nالمالك: [الاسم]\nالمدير: [الاسم]\n## الممتلكات\n[الوصف]\n## الأتعاب\n[النسبة] %\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Licence Logiciel", subtitle: "Utilisation, SaaS", icon: Icons.laptop_mac, color: Colors.cyanAccent,
    bodies: {'fr': "## LICENCE LOGICIEL\n## Parties\nEditeur : [Nom]\nUtilisateur : [Nom]\n## Objet\n[Description]\n## Tarif\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## SOFTWARE LICENSE\n## Parties\nLicensor: [Name]\nLicensee: [Name]\n## Subject\n[Description]\n## Fee\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## ترخيص برمجيات\n## الأطراف\nالمرخص: [الاسم]\nالمرخص له: [الاسم]\n## الموضوع\n[الوصف]\n## التعرفة\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Publicite", subtitle: "Campagne, sponsoring", icon: Icons.campaign, color: Colors.redAccent,
    bodies: {'fr': "## CONTRAT DE PUBLICITE\n## Parties\nAnnonceur : [Nom]\nDiffuseur : [Nom]\n## Objet\n[Description]\n## Budget\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## ADVERTISING AGREEMENT\n## Parties\nAdvertiser: [Name]\nPublisher: [Name]\n## Subject\n[Description]\n## Budget\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد إعلان\n## الأطراف\nالمعلن: [الاسم]\nالناشر: [الاسم]\n## الموضوع\n[الوصف]\n## الميزانية\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat d'Investissement", subtitle: "Levee de fonds, actionnariat", icon: Icons.trending_up, color: Colors.green,
    bodies: {'fr': "## CONTRAT D'INVESTISSEMENT\n## Parties\nInvestisseur : [Nom]\nSociete : [Nom]\n## Montant\n[Montant] DT\n## Parts\n[Pourcentage] %\n---\nFait a [Ville], le [Date]",
      'en': "## INVESTMENT AGREEMENT\n## Parties\nInvestor: [Name]\nCompany: [Name]\n## Amount\n[Amount]\n## Equity\n[Percentage] %\n---\nDone at [City], on [Date]",
      'ar': "## عقد استثمار\n## الأطراف\nالمستثمر: [الاسم]\nالشركة: [الاسم]\n## المبلغ\n[المبلغ] د.ت\n## الحصة\n[النسبة] %\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Garde d'Enfants", subtitle: "Nounou, babysitting", icon: Icons.child_care, color: Colors.pinkAccent,
    bodies: {'fr': "## CONTRAT DE GARDE\n## Parties\nParents : [Nom]\nGarde : [Nom]\n## Horaires\n[Description]\n## Remuneration\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## CHILDCARE AGREEMENT\n## Parties\nParents: [Name]\nCaregiver: [Name]\n## Hours\n[Description]\n## Pay\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد حضانة\n## الأطراف\nالوالدان: [الاسم]\nالحاضنة: [الاسم]\n## المواعيد\n[الوصف]\n## الأجر\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Coaching", subtitle: "Formation, accompagnement", icon: Icons.psychology, color: Colors.amberAccent,
    bodies: {'fr': "## CONTRAT DE COACHING\n## Parties\nCoach : [Nom]\nClient : [Nom]\n## Objectifs\n[Description]\n## Tarif\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## COACHING AGREEMENT\n## Parties\nCoach: [Name]\nClient: [Name]\n## Goals\n[Description]\n## Fee\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## عقد تدريب\n## الأطراف\nالمدرب: [الاسم]\nالعميل: [الاسم]\n## الأهداف\n[الوصف]\n## الأجر\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Co-fondation", subtitle: "Associes, startup", icon: Icons.rocket_launch, color: Colors.deepOrangeAccent,
    bodies: {'fr': "## PACTE D'ASSOCIES\n## Parties\nAssocie 1 : [Nom]\nAssocie 2 : [Nom]\n## Repartition\n[Pourcentages]\n## Duree\n[Duree]\n---\nFait a [Ville], le [Date]",
      'en': "## FOUNDERS AGREEMENT\n## Parties\nFounder 1: [Name]\nFounder 2: [Name]\n## Equity Split\n[Percentages]\n## Duration\n[Duration]\n---\nDone at [City], on [Date]",
      'ar': "## اتفاقية شركاء\n## الأطراف\nالشريك 1: [الاسم]\nالشريك 2: [الاسم]\n## التوزيع\n[النسب]\n## المدة\n[المدة]\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Vente de Vehicule", subtitle: "Voiture, moto", icon: Icons.directions_car, color: Colors.blueGrey,
    bodies: {'fr': "## VENTE DE VEHICULE\n## Parties\nVendeur : [Nom]\nAcheteur : [Nom]\n## Vehicule\n[Marque, modele, immatriculation]\n## Prix\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## VEHICLE SALE\n## Parties\nSeller: [Name]\nBuyer: [Name]\n## Vehicle\n[Make, model, plate]\n## Price\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## بيع سيارة\n## الأطراف\nالبائع: [الاسم]\nالمشتري: [الاسم]\n## المركبة\n[الماركة، الموديل، رقم اللوحة]\n## الثمن\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
  _ContractTemplate(title: "Contrat de Cloture de Compte", subtitle: "Solde de tout compte", icon: Icons.account_balance, color: Colors.grey,
    bodies: {'fr': "## SOLDE DE TOUT COMPTE\n## Parties\nEmployeur : [Nom]\nSalarie : [Nom]\n## Montant\n[Montant] DT\n---\nFait a [Ville], le [Date]",
      'en': "## FINAL SETTLEMENT\n## Parties\nEmployer: [Name]\nEmployee: [Name]\n## Amount\n[Amount]\n---\nDone at [City], on [Date]",
      'ar': "## تسوية نهائية\n## الأطراف\nصاحب العمل: [الاسم]\nالأجير: [الاسم]\n## المبلغ\n[المبلغ] د.ت\n---\nحرر في [المدينة]، بتاريخ [التاريخ]"}),
];

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isScanning = false;
  String _scannedText = '';
  final _editController = TextEditingController();
  bool _showSignature = false;
  String? _signatureImageBase64;
  final List<MediaItem> _mediaItems = [];
  String? _currentContractId;

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _pickFile({bool imageOnly = false}) {
<<<<<<< HEAD
    final input = html.FileUploadInputElement();
    input.accept = imageOnly ? 'image/*' : 'image/*,application/pdf';
    input.click();
    input.onChange.listen((e) async {
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      await reader.onLoad.first;
      final base64 = reader.result as String;
      await _processScannedImage(base64);
    });
  }

  Future<void> _processScannedImage(String base64) async {
=======
    _handlePickFile(imageOnly: imageOnly);
  }

  Future<void> _handlePickFile({bool imageOnly = false}) async {
    final file = await pickSingleFile(
      allowedExtensions: imageOnly
          ? ['png', 'jpg', 'jpeg', 'webp']
          : ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
    );
    if (file == null) return;

>>>>>>> c6204d425370e1f5650e9db9e5fe71aaf6b88b80
    setState(() => _isScanning = true);
    try {
      final dio = Dio();
      final response = await dio.post(
<<<<<<< HEAD
        'http://localhost:3001/api/chat/scan-contract',
        data: {'image': base64, 'lang': 'fra+eng+ara'},
=======
        '${ApiConfig.baseUrl}/chat/scan-contract',
        data: {'image': file.dataUrl, 'lang': 'fra+eng+ara'},
>>>>>>> c6204d425370e1f5650e9db9e5fe71aaf6b88b80
      );
      final raw = response.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      final text = (data['text'] ?? '') as String;
      if (text.isNotEmpty) {
<<<<<<< HEAD
        setState(() { _scannedText = text; _editController.text = text; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document scanné !'), backgroundColor: Colors.green));
        await _createContractRecord('Document scanné', text);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun texte détecté'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de scan'), backgroundColor: Colors.red));
    }
    setState(() => _isScanning = false);
  }

  Future<void> _openCameraCapture() async {
    html.MediaStream? stream;
    try {
      stream = await html.window.navigator.mediaDevices!.getUserMedia({'video': true, 'audio': false});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caméra indisponible, choisissez un fichier'), backgroundColor: Colors.orange));
      }
      _pickFile(imageOnly: true);
      return;
    }

    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
    video.srcObject = stream;

    final viewId = 'camera-view-\${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) => video);

    if (!mounted) {
      stream.getTracks().forEach((t) => t.stop());
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 480,
            height: 420,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: HtmlElementView(viewType: viewId),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Annuler'),
                        onPressed: () {
                          stream?.getTracks().forEach((t) => t.stop());
                          Navigator.pop(dialogContext);
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera),
                        label: const Text('Capturer'),
                        onPressed: () async {
                          final w = video.videoWidth != 0 ? video.videoWidth : 640;
                          final h = video.videoHeight != 0 ? video.videoHeight : 480;
                          final canvas = html.CanvasElement(width: w, height: h);
                          canvas.context2D.drawImage(video, 0, 0);
                          final dataUrl = canvas.toDataUrl('image/jpeg', 0.9);
                          stream?.getTracks().forEach((t) => t.stop());
                          Navigator.pop(dialogContext);
                          await _processScannedImage(dataUrl);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
=======
        setState(() {
          _scannedText = text;
          _editController.text = text;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document scanné !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun texte détecté'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de scan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isScanning = false);
>>>>>>> c6204d425370e1f5650e9db9e5fe71aaf6b88b80
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
      final fileName = file.name.toLowerCase();
      final isVideo =
          fileName.endsWith('.mp4') ||
          fileName.endsWith('.mov') ||
          fileName.endsWith('.avi') ||
          fileName.endsWith('.mkv');
      setState(() {
        _mediaItems.add(
          MediaItem(
            type: isVideo ? 'video' : 'image',
            data: file.dataUrl,
            thumbnail: null,
            caption: file.name.split('.').first,
            date: DateTime.now().toLocal().toString().split(' ')[0],
          ),
        );
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${files.length} fichier(s) ajouté(s)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _createContractRecord(String title, String content) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'http://localhost:3001/api/contracts',
        data: {'title': title, 'content': content, 'parties': []},
      );
      final data = response.data['data'] ?? response.data;
      setState(() => _currentContractId = data['id']);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de création du contrat'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveContractRecord() async {
    try {
      final dio = Dio();
      if (_currentContractId == null) {
        await _createContractRecord(
          _editController.text.split('\n').first.replaceAll('#', '').trim().isEmpty
              ? 'Contrat'
              : _editController.text.split('\n').first.replaceAll('#', '').trim(),
          _editController.text,
        );
      } else {
        await dio.put(
          'http://localhost:3001/api/contracts/$_currentContractId',
          data: {'content': _editController.text},
        );
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contrat enregistré !'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur d'enregistrement"), backgroundColor: Colors.red));
    }
  }

  void _showSignatureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SignatureDialog(
        onSigned: (sig) {
          setState(() {
            _showSignature = true;
            _signatureImageBase64 = sig.isNotEmpty ? sig : null;
            if (!_editController.text.contains('signé électroniquement')) {
              _editController.text +=
                  '\n\n--- Document signé électroniquement le '
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ---';
            }
          });
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signature apposée !'),
                backgroundColor: Colors.green,
              ),
            );
        },
      ),
    );
  }

  void _downloadPdf() async {
    try {
      final dio = Dio();
      final mediaPayload = _mediaItems
          .map(
            (m) => {
              'type': m.type,
              'data': m.type == 'image' ? m.data : (m.thumbnail ?? m.data),
              'thumbnail': m.thumbnail,
              'caption': m.caption,
              'date': m.date,
            },
          )
          .toList();
      final response = await dio.post(
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
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur export PDF'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IdealAppScaffold(
      activeRoute: 'documents',
      body: IdealGradientBackground(
        child: _scannedText.isEmpty
            ? _buildImportScreen(cs)
            : _buildEditScreen(cs),
      ),
    );
  }

  Widget _buildImportScreen(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
<<<<<<< HEAD
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.document_scanner, size: 80, color: cs.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text('Scanner & Importer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text('Scannez ou importez un contrat pour le modifier, ajouter des photos/vidéos et le signer',
            textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
          const SizedBox(height: 40),
          if (_isScanning)
            const CircularProgressIndicator()
          else ...[
                        _buildCard(cs, Icons.camera_alt, 'Take a photo', 'Camera or image file', Colors.blue, () => _openCameraCapture()),
                        _buildCard(cs, Icons.upload_file, 'Import a file', 'PDF or image from your device', Colors.green, () => _pickFile()),
            _buildCard(cs, Icons.edit_document, 'New Contract', 'Choose a template or start from scratch', Colors.purple, _showTemplatePicker),
            
=======
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner,
              size: 80,
              color: cs.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Scanner & Importer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scannez ou importez un contrat pour le modifier, ajouter des photos/vidéos et le signer',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 40),
            if (_isScanning)
              const CircularProgressIndicator()
            else ...[
              _buildCard(
                cs,
                Icons.camera_alt,
                'Prendre une photo',
                'Appareil photo ou fichier image',
                Colors.blue,
                () => _pickFile(imageOnly: true),
              ),
              const SizedBox(height: 16),
              _buildCard(
                cs,
                Icons.upload_file,
                'Importer un fichier',
                'PDF ou image depuis votre appareil',
                Colors.green,
                () => _pickFile(),
              ),
              const SizedBox(height: 16),
              _buildCard(
                cs,
                Icons.edit_document,
                'Nouveau contrat vide',
                'Rédiger depuis zéro',
                Colors.purple,
                () {
                  setState(() {
                    _scannedText = ' ';
                    _editController.text = '';
                  });
                },
              ),
            ],
>>>>>>> c6204d425370e1f5650e9db9e5fe71aaf6b88b80
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  String _templateLang = 'fr';

  void _showTemplatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
          builder: (ctx, scrollCtrl) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Choisir un modèle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                _langChip('fr', 'FR', setModalState),
                const SizedBox(width: 8),
                _langChip('en', 'EN', setModalState),
                const SizedBox(width: 8),
                _langChip('ar', 'AR', setModalState),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    ...kContractTemplates.map((t) => _templateTile(t)),
                    _templateTile(null),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _langChip(String code, String label, void Function(void Function()) setModalState) {
    final selected = _templateLang == code;
    return GestureDetector(
      onTap: () => setModalState(() => _templateLang = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.purple : Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
(String, String) _partyLabelsFor(String? title) {
    final t = (title ?? '').toLowerCase();
    if (t.contains('location') || t.contains('bail')) return ('Bailleur', 'Locataire');
    if (t.contains('vente')) return ('Vendeur', 'Acheteur');
    if (t.contains('travail')) return ('Employeur', 'Salarié');
    if (t.contains('prêt') || t.contains('pret')) return ('Prêteur', 'Emprunteur');
    if (t.contains('franchise')) return ('Franchiseur', 'Franchisé');
    if (t.contains('distribution')) return ('Fournisseur', 'Distributeur');
    if (t.contains('sous-traitance')) return ('Donneur d\'ordre', 'Sous-traitant');
    if (t.contains('cession')) return ('Cédant', 'Cessionnaire');
    if (t.contains('confidentialite') || t.contains('nda')) return ('Partie divulgatrice', 'Partie destinataire');
    if (t.contains('partenariat')) return ('Partenaire 1', 'Partenaire 2');
    if (t.contains('architecte')) return ('Client', 'Architecte');
    if (t.contains('consultant')) return ('Client', 'Consultant');
    return ('Client', 'Prestataire');
  }
  
   Widget _templateTile(_ContractTemplate? t) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        final body = t?.body(_templateLang) ?? '';
        setState(() {
          _scannedText = ' ';
          _editController.text = body;
        });
        await _createContractRecord(t?.title ?? 'Nouveau contrat', body);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (t?.color ?? Colors.grey).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (t?.color ?? Colors.grey).withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(t?.icon ?? Icons.note_add, color: t?.color ?? Colors.grey, size: 26),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t?.title ?? 'Page vide', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(t?.subtitle ?? 'Rédiger depuis zéro', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ])),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildCard(ColorScheme c, IconData icon, String title, String sub, Color color, VoidCallback onTap) {
=======
  Widget _buildCard(
    ColorScheme c,
    IconData icon,
    String title,
    String sub,
    Color color,
    VoidCallback onTap,
  ) {
>>>>>>> c6204d425370e1f5650e9db9e5fe71aaf6b88b80
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
                      color: c.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      color: c.onSurface.withOpacity(0.6),
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

  Widget _buildEditScreen(ColorScheme cs) {
<<<<<<< HEAD
    return Column(children: [
      // Barre d'outils
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: cs.surface,
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() { _scannedText = ''; _mediaItems.clear(); _showSignature = false; _signatureImageBase64 = null; _currentContractId = null; })),
          const Text('Contrat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.save, color: Colors.blue), tooltip: 'Enregistrer', onPressed: _saveContractRecord),
          IconButton(icon: const Icon(Icons.add_photo_alternate, color: Colors.teal), tooltip: 'Ajouter photo/vidéo', onPressed: _addMedia),
          IconButton(icon: Icon(Icons.draw, color: _showSignature ? Colors.green : Colors.purple), tooltip: 'Signer', onPressed: _showSignatureDialog),
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red), tooltip: 'Exporter PDF', onPressed: _downloadPdf),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Zone texte
            TextField(
              controller: _editController, maxLines: null,
              style: TextStyle(color: cs.onSurface, fontSize: 13),
              decoration: InputDecoration(
                filled: true, fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Contenu du contrat...'),
            ),

            // Galerie médias
            if (_mediaItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(children: [
                const Icon(Icons.photo_library, size: 18, color: Colors.teal),
                const SizedBox(width: 6),
                Text('Pièces jointes (${_mediaItems.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
                const Spacer(),
                TextButton.icon(onPressed: _addMedia, icon: const Icon(Icons.add, size: 16), label: const Text('Ajouter')),
              ]),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3),
                itemCount: _mediaItems.length,
                itemBuilder: (ctx, i) => _buildMediaCard(cs, i),
=======
    return Column(
      children: [
        // Barre d'outils
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: cs.surface,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _scannedText = '';
                  _mediaItems.clear();
                  _showSignature = false;
                  _signatureImageBase64 = null;
                }),
>>>>>>> c6204d425370e1f5650e9db9e5fe71aaf6b88b80
              ),
              const Text(
                'Contrat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_photo_alternate, color: Colors.teal),
                tooltip: 'Ajouter photo/vidéo',
                onPressed: _addMedia,
              ),
              IconButton(
                icon: Icon(
                  Icons.draw,
                  color: _showSignature ? Colors.green : Colors.purple,
                ),
                tooltip: 'Signer',
                onPressed: _showSignatureDialog,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                tooltip: 'Exporter PDF',
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
                // Zone texte
                TextField(
                  controller: _editController,
                  maxLines: null,
                  style: TextStyle(color: cs.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    hintText: 'Contenu du contrat...',
                  ),
                ),

                // Galerie médias
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
                        'Pièces jointes (${_mediaItems.length})',
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
                        label: const Text('Ajouter'),
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
                    itemBuilder: (ctx, i) => _buildMediaCard(cs, i),
                  ),
                ],

                // Badge signature
                if (_showSignature) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Document signé électroniquement',
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

  Widget _buildMediaCard(ColorScheme cs, int index) {
    final item = _mediaItems[index];
    final previewData = item.thumbnail ?? item.data;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
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
                          color: cs.surfaceContainerHigh,
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
                    onTap: () => setState(() => _mediaItems.removeAt(index)),
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
                  child: TextField(
                    controller: TextEditingController(text: item.caption),
                    onChanged: (v) => item.caption = v,
                    style: const TextStyle(fontSize: 11),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Légende...',
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

// ─── Dialogue de signature ─────────────────────────────────────────────────
class _SignatureDialog extends StatefulWidget {
  final Function(String) onSigned;
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
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _cameraStarted = false;
  bool _cameraError = false;
  final String _viewType = 'camera-view-${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _onTerminer() async {
    setState(() => _isProcessing = true);
    String signature = '';
    if (_tab == 0) {
      signature = await _captureDrawing();
    } else {
      signature = _cameraImageBase64 ?? '';
    }
    setState(() => _isProcessing = false);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSigned(signature);
  }

  Future<String> _captureDrawing() async {
    try {
      final boundary =
          _signatureBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        return '';
      }
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return '';
      }
      final bytes = byteData.buffer.asUint8List();
      return 'data:image/png;base64,${base64Encode(bytes)}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _startCamera() async {
    try {
      final stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'video': true, 'audio': false});
      final video = html.VideoElement()
        ..autoplay = true
        ..srcObject = stream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int id) => video);
      setState(() {
        _mediaStream = stream;
        _videoElement = video;
        _cameraStarted = true;
        _cameraError = false;
      });
    } catch (_) {
      setState(() => _cameraError = true);
    }
  }

  void _stopCamera() {
    _mediaStream?.getTracks().forEach((t) => t.stop());
    _mediaStream = null;
    _videoElement = null;
    _cameraStarted = false;
  }

  void _capturePhoto() {
    if (_videoElement == null) return;
    final video = _videoElement!;
    final canvas = html.CanvasElement(width: video.videoWidth, height: video.videoHeight);
    canvas.context2D.drawImage(video, 0, 0);
    final dataUrl = canvas.toDataUrl('image/png');
    _stopCamera();
    setState(() { _cameraImageBase64 = dataUrl; _hasSignature = true; });
  }

  void _importFile() {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.style.display = 'none';
    html.document.body!.append(input);
    input.click();
    input.onChange.listen((e) async {
      final file = input.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoad.first;
        setState(() { _cameraImageBase64 = reader.result as String; _hasSignature = true; });
      }
      input.remove();
    });
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
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
            const Text(
              'Signature',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [_tabBtn('✍️ Dessiner', 0), _tabBtn('📷 Caméra', 1)],
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
                      onPanUpdate: (d) => setState(() {
                        _points.add(d.localPosition);
                        _hasSignature = true;
                      }),
                      onPanEnd: (_) => setState(() => _points.add(null)),
                      child: CustomPaint(
                        painter: _SigPainter(_points),
                        child: _points.isEmpty
                            ? Center(
                                child: Text(
                                  'Dessinez votre signature',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
<<<<<<< HEAD
              ),
            )
          else if (_cameraImageBase64 == null && _cameraStarted)
            Stack(children: [
              Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black),
                child: ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: HtmlElementView(viewType: _viewType)),
              ),
              Positioned(bottom: 8, left: 0, right: 0,
                child: Center(child: ElevatedButton.icon(
                  onPressed: _capturePhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Prendre la photo'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ))),
            ])
          else if (_cameraImageBase64 == null && !_cameraStarted)
            Container(
              height: 180, width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.4))),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.camera_alt, size: 40, color: Colors.blue),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _startCamera,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Ouvrir la caméra', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _importFile, child: const Text('ou importer une photo')),
                if (_cameraError)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text("Camera indisponible, utilisez l'import de fichier",
                      style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
              ])),
            )
          else if (_cameraImageBase64 != null)
            Stack(children: [
              Container(height: 180, width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                child: ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: Image.network(_cameraImageBase64!, fit: BoxFit.contain))),
              Positioned(top: 4, right: 4,
                child: GestureDetector(
                  onTap: () => setState(() { _cameraImageBase64 = null; _hasSignature = false; }),
                  child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(4), child: const Icon(Icons.refresh, size: 16, color: Colors.white)))),
            ]),
          const SizedBox(height: 12),
          Row(children: [
            TextButton(onPressed: () => setState(() { _points = []; _hasSignature = false; _cameraImageBase64 = null; _stopCamera(); }),
              child: const Text('Effacer', style: TextStyle(color: Colors.red))),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: (_hasSignature && !_isProcessing) ? _onTerminer : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: _isProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Terminer', style: TextStyle(color: Colors.white)),
=======
              )
            else if (!_useCameraCapture && _cameraImageBase64 == null)
              GestureDetector(
                onTap: () async {
                  final file = await pickSingleFile(
                    allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
                  );
                  if (file == null) return;
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
                    border: Border.all(color: Colors.blue.withOpacity(0.4)),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file, size: 40, color: Colors.blue),
                        SizedBox(height: 8),
                        Text(
                          'Importer une photo de votre signature',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '(signez sur papier blanc, prenez une photo)',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_cameraImageBase64 != null)
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                      onTap: () => setState(() {
                        _cameraImageBase64 = null;
                        _hasSignature = false;
                      }),
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
                  onPressed: () => setState(() {
                    _points = [];
                    _hasSignature = false;
                    _cameraImageBase64 = null;
                  }),
                  child: const Text(
                    'Effacer',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_hasSignature && !_isProcessing)
                      ? _onTerminer
                      : null,
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
                      : const Text(
                          'Terminer',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
>>>>>>> c6204d425370e1f5650e9db9e5fe71aaf6b88b80
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final sel = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SigPainter extends CustomPainter {
  final List<Offset?> points;
  _SigPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null)
        canvas.drawLine(points[i]!, points[i + 1]!, p);
    }
  }

  @override
  bool shouldRepaint(_SigPainter old) => true;
}
