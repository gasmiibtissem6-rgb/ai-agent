import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'locale_provider.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _values = {
    'fr': {
      'myContracts_title': 'Mes Contrats',
      'myContracts_subtitle': 'Consultez, complétez et envoyez vos contrats',
      'myContracts_search': 'Rechercher un contrat...',
      'myContracts_filter_all': 'Tous',
      'myContracts_filter_draft': 'Brouillon',
      'myContracts_filter_sent': 'Envoyé',
      'myContracts_filter_signed': 'Signé',
      'myContracts_no_description': 'Aucune description',
      'myContracts_empty': 'Aucun contrat pour le moment',
      'myContracts_load_error': 'Impossible de charger les contrats',
      'myContracts_retry': 'Réessayer',
      'myContracts_send': 'Envoyer',
      'myContracts_send_dialog_title': 'Envoyer le contrat',
      'myContracts_send_dialog_email_label': 'Email du destinataire',
      'myContracts_send_dialog_cancel': 'Annuler',
      'myContracts_send_dialog_confirm': 'Envoyer',
      'myContracts_sent_snackbar': 'Contrat envoyé à',
      'myContracts_sent_error': "Erreur lors de l'envoi",
      'settings_language_label': 'Langue',
      'settings_language_fr': 'Français',
      'settings_language_en': 'Anglais',
      'myContracts_no_contract_found': 'Aucun contrat trouvé',
      'myContracts_no_title': 'Sans titre',
      'myContracts_status_draft': 'Brouillon',
      'myContracts_status_sent': 'Envoyé',
      'myContracts_status_signed': 'Signé',
      'myContracts_status_cancelled': 'Annulé',
    },
    'en': {
      'myContracts_title': 'My Contracts',
      'myContracts_subtitle': 'View, complete, and send your contracts',
      'myContracts_search': 'Search a contract...',
      'myContracts_filter_all': 'All',
      'myContracts_filter_draft': 'Draft',
      'myContracts_filter_sent': 'Sent',
      'myContracts_filter_signed': 'Signed',
      'myContracts_no_description': 'No description',
      'myContracts_empty': 'No contracts yet',
      'myContracts_load_error': 'Unable to load contracts',
      'myContracts_retry': 'Retry',
      'myContracts_send': 'Send',
      'myContracts_send_dialog_title': 'Send contract',
      'myContracts_send_dialog_email_label': 'Recipient email',
      'myContracts_send_dialog_cancel': 'Cancel',
      'myContracts_send_dialog_confirm': 'Send',
      'myContracts_sent_snackbar': 'Contract sent to',
      'myContracts_sent_error': 'Error while sending',
      'settings_language_label': 'Language',
      'settings_language_fr': 'French',
      'settings_language_en': 'English',
      'myContracts_no_contract_found': 'No contract found',
      'myContracts_no_title': 'No title',
      'myContracts_status_draft': 'Draft',
      'myContracts_status_sent': 'Sent',
      'myContracts_status_signed': 'Signed',
      'myContracts_status_cancelled': 'Cancelled',
    },
  };

  static String get(String languageCode, String key) {
    return _values[languageCode]?[key] ?? _values['fr']?[key] ?? key;
  }
}

extension AppStringsX on WidgetRef {
  String t(String key) {
    final locale = watch(localeProvider);
    return AppStrings.get(locale.languageCode, key);
  }
}
