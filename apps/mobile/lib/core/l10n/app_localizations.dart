import 'package:flutter/widgets.dart';

/// Lightweight, hand-written localization layer (no codegen).
///
/// Strings live in the [_en] / [_fr] maps below, keyed by dotted identifiers
/// (e.g. `settings.title`). Screens read them through `context.l10n.tr('key')`
/// or the typed helpers on [AppLocalizations].
///
/// Adding a language = add a `<code>: {...}` map and list its [Locale] in
/// [supportedLocales]. Adding a string = add the same key to every map.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Locales the app ships translations for.
  static const supportedLocales = <Locale>[Locale('en'), Locale('fr')];

  /// The dropdown labels (English name of each language, shown untranslated on
  /// purpose so users always recognise their own language).
  static const languageLabels = <String, String>{
    'en': 'English',
    'fr': 'French',
  };

  Map<String, String> get _values =>
      locale.languageCode == 'fr' ? _fr : _en;

  /// Translates [key]; falls back to English, then to the raw key so a missing
  /// translation is visible (and never crashes).
  String tr(String key) => _values[key] ?? _en[key] ?? key;

  /// Translates [key] and substitutes `{name}`-style placeholders.
  String trp(String key, Map<String, String> params) {
    var value = tr(key);
    params.forEach((name, replacement) {
      value = value.replaceAll('{$name}', replacement);
    });
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// `context.l10n.tr('key')` sugar.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// -----------------------------------------------------------------------------
// English (template) — the source of truth. Every key here MUST exist in [_fr].
// -----------------------------------------------------------------------------
const Map<String, String> _en = {
  // Common / shared
  'common.cancel': 'Cancel',
  'common.save': 'Save',
  'common.change': 'Change',
  'common.retry': 'Retry',
  'common.close': 'Close',
  'common.comingSoon': 'This feature is still being built.',
  'common.error': 'Something went wrong. Please try again.',
  'common.refresh': 'Refresh',

  // Deal party discussion (chat)
  'dealChat.title': 'Discussion — {title}',
  'dealChat.loadError': 'Could not load the discussion.\n{error}',
  'dealChat.empty': 'No messages yet. Start the discussion.',
  'dealChat.hint': 'Message the other party…',

  // Deal share
  'share.title': 'Deal created 🎉',
  'share.subtitle': 'Share it and pick who you want to deal with.',
  'share.labelTitle': 'Title',
  'share.labelReference': 'Reference',
  'share.qrCaption': 'Scan to open this deal',
  'share.invitationLink': 'Invitation link',
  'share.copyLink': 'Copy link',
  'share.linkCopied': 'Link copied to clipboard.',
  'share.addParty': 'Add the other party',
  'share.addPartyHelp':
      'Enter their username or email. They will get a notification to accept the deal.',
  'share.partyHint': 'username or email@example.com',
  'share.inviteAnother': 'Invite another',
  'share.inviteParty': 'Invite party',
  'share.goToDeal': 'Go to deal',
  'share.partyInvited': 'The other party has been invited.',
  'share.couldNotAddParty': 'Could not add that party.',
  'share.linkError': 'Could not generate the link.\n{error}',

  // Bottom / side navigation (IdealAppScaffold)
  'nav.home': 'Home',
  'nav.deals': 'Deals',
  'nav.documents': 'Documents',
  'nav.assistant': 'Assistant',
  'nav.settings': 'Settings',
  'nav.notifications': 'Notifications',

  // Deals list
  'deals.title': 'Deals',
  'deals.subtitle': 'Manage and track all your deals',
  'deals.tabDeals': 'Deals',
  'deals.tabTemplates': 'Templates',
  'deals.search': 'Search deals...',
  'deals.filterAll': 'All',
  'deals.filterDraft': 'Draft',
  'deals.filterBridged': 'Bridged',
  'deals.filterApproved': 'Approved',
  'deals.filterCancelled': 'Cancelled',
  'deals.emptyTitle': 'No deals yet',
  'deals.emptySubtitle': 'Create your first deal to start negotiating.',
  'deals.emptyAction': 'Create deal',
  'deals.noneFound': 'No deals found',
  'deals.createButton': 'Create Deal',
  'deals.errorPrefix': 'Error: {message}',

  // Deal status labels (NEGOTIATION reads as "Bridged")
  'dealStatus.draft': 'Draft',
  'dealStatus.negotiation': 'Bridged',
  'dealStatus.pendingApproval': 'Pending approval',
  'dealStatus.approved': 'Approved',
  'dealStatus.locked': 'Locked',
  'dealStatus.changesRequested': 'Changes requested',
  'dealStatus.rejected': 'Rejected',
  'dealStatus.cancelled': 'Cancelled',
  'dealStatus.archived': 'Archived',

  // Deal content types
  'dealType.document': 'Document',
  'dealType.video': 'Video',
  'dealType.scanned': 'Scanned document',
  'dealType.documentDesc': 'A written agreement drafted in the app.',
  'dealType.videoDesc': 'A recorded video agreement or walkthrough.',
  'dealType.scannedDesc': 'A photo or scan, read with OCR.',

  // Home
  'home.signOut': 'Sign out',
  'home.profile': 'Profile',
  'home.there': 'there',
  'home.welcome': 'Welcome back, {name}',
  'home.welcomeSub': "Here's what's happening with your deals today.",
  'home.recentDeals': 'Recent Deals',
  'home.viewAll': 'View All',
  'home.emptyRecent':
      'Create your first deal to start tracking agreements.',
  'home.scanProfileTitle': 'Scan a profile',
  'home.notIdealQr': 'That QR code is not an IDEAL profile.',
  'home.profileNotFound': 'Profile not found',
  'home.profilePrivate': 'This profile is private or does not exist.',
  'home.verifiedAccount': 'Verified account',
  'home.notVerifiedYet': 'Not verified yet',
  'home.kycVerified': 'Verified (KYC)',
  'home.notVerified': 'Not verified',
  'home.publicProfile': 'Public profile',
  'home.privateProfile': 'Private profile',
  'home.publicSub': 'Others can find you by scanning your QR.',
  'home.privateSub': 'Only you can see this profile.',
  'home.qrCaption': 'Your profile QR — let others scan it',
  'home.scanAnother': 'Scan another profile',
  'home.statSuccessful': 'Successful Deals',
  'home.statBridged': 'Bridged Deals',
  'home.statActive': 'Active Deals',
  'home.createDeal': 'Create Deal',
  'home.createDealSub': 'Start a new agreement',
  'home.viewDeals': 'View Deals',
  'home.viewDealsSub': 'Track active work',
  'home.miniIdentity': 'Identity',
  'home.miniApprovals': 'Approvals',

  // Settings
  'settings.title': 'Settings',
  'settings.subtitle': 'Manage your preferences and account security',
  'settings.general': 'General Settings',
  'settings.language': 'Language',
  'settings.notifications': 'Notifications',
  'settings.pushNotifications': 'Push Notifications',
  'settings.pushNotificationsSub': 'Receive notifications for deal updates',
  'settings.emailUpdates': 'Email Updates',
  'settings.emailUpdatesSub': 'Receive email notifications',
  'settings.security': 'Security',
  'settings.twoFactor': 'Two-Factor Authentication',
  'settings.twoFactorSub': 'Add an extra layer of security',
  'settings.changePassword': 'Change Password',
  'settings.changePasswordSub': 'Update your password',
  'settings.account': 'Account Management',
  'settings.editProfile': 'Edit Profile',
  'settings.editProfileSub': 'Change your display name and avatar',
  'settings.activeSessions': 'Active Sessions',
  'settings.activeSessionsSub': 'View signed-in devices',
  'settings.privacy': 'Privacy',
  'settings.publicProfile': 'Public Profile',
  'settings.publicProfileSub': 'Make your profile visible to others',
  'settings.dangerZone': 'Danger Zone',
  'settings.logout': 'Log Out',
  'settings.deleteAccount': 'Delete Account',

  // Shared auth
  'common.or': 'or',
  'auth.email': 'Email Address',
  'auth.emailHint': 'you@example.com',
  'auth.password': 'Password',
  'auth.tooManyAttempts': 'Too many attempts. Try again later.',
  'auth.backToSignIn': 'Back to sign in',

  // Login
  'login.title': 'Welcome back',
  'login.subtitle': 'Sign in to continue managing trusted deals.',
  'login.passwordHint': 'Your password',
  'login.rememberMe': 'Remember me',
  'login.forgot': 'Forgot password?',
  'login.signIn': 'Sign In',
  'login.google': 'Continue with Google',
  'login.noAccount': "Don't have an account? ",
  'login.signUpLink': 'Sign Up',

  // Register
  'register.title': 'Create Account',
  'register.subtitle': 'Join IDEAL and start trusted agreements.',
  'register.acceptTerms': 'Please accept the Terms of Service to continue.',
  'register.fullName': 'Full Name',
  'register.fullNameHint': 'John Doe',
  'register.passwordHint': 'At least 8 characters',
  'register.confirmPassword': 'Confirm Password',
  'register.confirmHint': 'Repeat your password',
  'register.accountType': 'Account Type',
  'register.individual': 'Individual',
  'register.company': 'Company',
  'register.agree': 'I agree to the Terms of Service and Privacy Policy',
  'register.create': 'Create Account',
  'register.google': 'Sign up with Google',
  'register.haveAccount': 'Already have an account? ',
  'register.signInLink': 'Sign In',
  'register.signInAction': 'Sign in',

  // Forgot password
  'forgot.checkEmail': 'Check your email',
  'forgot.sentTo': 'We sent a password reset link to',
  'forgot.title': 'Reset password',
  'forgot.subtitle': 'Enter your email and we will send you a reset link.',
  'forgot.send': 'Send reset link',

  // Reset password
  'reset.title': 'New password',
  'reset.subtitle': 'Choose a strong password for your account.',
  'reset.newPassword': 'New Password',
  'reset.newPasswordHint': 'At least 8 characters',
  'reset.confirmNew': 'Confirm New Password',
  'reset.confirmNewHint': 'Re-enter your password',
  'reset.strengthHint':
      'Use a mix of letters, numbers, and symbols for a strong password.',
  'reset.update': 'Update password',

  // OTP (verification flow — currently disabled but still routed)
  'otp.enterComplete': 'Please enter the complete 6-digit code.',
  'otp.newCodeSent': 'A new verification code has been sent.',
  'otp.title': 'Verify Email',
  'otp.sentCode': "We've sent a code to your email",
  'otp.enter6': 'Enter the 6-digit code sent to your email address',
  'otp.didntReceive': "Didn't receive the code? ",
  'otp.resend': 'Resend',
  'otp.resendIn': 'Resend ({seconds}s)',
  'otp.expire': 'This code will expire in 10 minutes',

  // Splash / onboarding
  'splash.tagline': 'Secure Deal Management',
  'splash.getStarted': 'Get Started',
  'splash.feat1Title': 'Secure Contract Management',
  'splash.feat1Desc':
      'Encrypt, verify, and co-sign legal agreements with complete assurance.',
  'splash.feat2Title': 'Real-Time Collaboration',
  'splash.feat2Desc':
      'Instantly sync updates and co-author terms with partners on the fly.',
  'splash.feat3Title': 'Built-in Negotiation Tools',
  'splash.feat3Desc':
      'Easily track document revisions, audits, and final consensus.',

  // Form validation
  'validation.emailRequired': 'Email is required.',
  'validation.emailInvalid': 'Enter a valid email address.',
  'validation.passwordRequired': 'Password is required.',
  'validation.passwordShort': 'Password must be at least 8 characters.',
  'validation.fullNameRequired': 'Full name is required.',
  'validation.fullNameShort': 'Enter your full name.',
  'validation.otpRequired': 'Verification code is required.',
  'validation.otpLength': 'Enter the 6-digit code.',
  'validation.otpDigits': 'Code must be 6 digits.',
  'validation.fieldRequired': '{field} is required.',
  'validation.confirmPassword': 'Please confirm your password.',
  'validation.passwordsNoMatch': 'Passwords do not match.',

  'common.errorPrefix': 'Error: {message}',

  // KYC — status screen
  'kyc.verifyIdentity': 'Verify your identity',
  'kyc.verifyDesc':
      'To participate in deals and build trust with other parties, verify your identity with a government-issued ID.',
  'kyc.infoSecure': 'Your documents are stored securely and privately',
  'kyc.infoTime': 'Verification usually takes 1-2 business days',
  'kyc.infoAuthorized':
      'Only authorized reviewers can access your documents',
  'kyc.start': 'Start Verification',
  'kyc.rejectionReason': 'Rejection reason',
  'kyc.resubmit': 'Resubmit Documents',
  'kyc.submissionDetails': 'Submission details',
  'kyc.documentType': 'Document type',
  'kyc.submittedOn': 'Submitted on',
  'kyc.reviewedOn': 'Reviewed on',
  // KYC — upload screen
  'kyc.uploadTitle': 'Upload Documents',
  'kyc.uploadSubtitle': 'Submit identity files for secure review.',
  'kyc.selectType': 'Select document type',
  'kyc.uploadDocs': 'Upload documents',
  'kyc.frontLabel': 'Front of document',
  'kyc.frontSub': 'Clear photo of the front side',
  'kyc.backLabel': 'Back of document',
  'kyc.backSub': 'Clear photo of the back side',
  'kyc.selfieLabel': 'Selfie with document',
  'kyc.selfieSub': 'Hold your document next to your face',
  'kyc.securityNotice': 'Security notice',
  'kyc.securityText':
      'Your documents are encrypted and stored in a private secure bucket. Only authorized reviewers can access them.',
  'kyc.uploading': 'Uploading... {percent}%',
  'kyc.submit': 'Submit for verification',
  'kyc.needFront': 'Please upload the front of your document.',
  'kyc.needSelfie': 'Please upload a selfie with your document.',
  'kyc.submitted': 'KYC submitted! We will review it shortly.',
  'kyc.uploadFailed': 'Upload failed.',
  // KYC status labels + messages
  'kycStatus.notSubmitted': 'Not submitted',
  'kycStatus.pending': 'Under review',
  'kycStatus.approved': 'Verified',
  'kycStatus.rejected': 'Rejected',
  'kycMsg.pending':
      'Your documents are being reviewed. This usually takes 1-2 business days.',
  'kycMsg.approved':
      'Your identity has been verified. You can now participate in deals.',
  'kycMsg.rejected':
      'Your verification was rejected. Please review the reason and resubmit.',
  'kycDoc.nationalId': 'National ID',
  'kycDoc.passport': 'Passport',
  'kycDoc.driverLicense': 'Driver License',

  // Notifications
  'notif.unread': 'You have {count} unread notifications',
  'notif.markAll': 'Mark all as read',
  'notif.unreadLabel': 'UNREAD',
  'notif.earlierLabel': 'EARLIER',
  'notif.empty': 'No notifications yet',
  'notif.loadError': 'Could not load notifications.\n{error}',
  'time.justNow': 'Just now',
  'time.minAgo': '{n} min ago',
  'time.hourAgo': '{n} h ago',
  'time.dayAgo': '{n} d ago',

  // Edit profile
  'profile.title': 'Edit Profile',
  'profile.subtitle': 'Update how you appear across IDEAL.',
  'profile.displayName': 'Display Name *',
  'profile.displayNameHint': 'e.g., Imen Ben Ouaghrem',
  'profile.username': 'Username',
  'profile.usernameHint': 'e.g., imen_bo',
  'profile.usernameHelper': 'Others can find you by this handle or your QR.',
  'profile.avatarUrl': 'Avatar URL',
  'profile.avatarHint': 'https://example.com/avatar.png',
  'profile.email': 'Email',
  'profile.emailHelper':
      'Your email is your sign-in identity and cannot be changed here.',
  'profile.identityVerification': 'Identity verification',
  'profile.updated': 'Profile updated.',
  'profile.saveChanges': 'Save changes',
  'validation.usernameLength': 'Username must be 3-30 characters.',
  'validation.usernameChars': 'Only letters, digits and underscores are allowed.',
  'validation.urlFull': 'Enter a full URL, including https://',
  'validation.urlScheme': 'Only http and https URLs are allowed.',
  'kycProfile.approved': 'Approved',
  'kycProfile.submitted': 'Submitted',
  'kycProfile.underReview': 'Under review',
  'kycProfile.rejected': 'Rejected',
  'kycProfile.resubmission': 'Resubmission required',
  'kycProfile.revoked': 'Revoked',
  'kycProfile.notStarted': 'Not started',

  // QR scanner
  'qr.torch': 'Toggle torch',
  'qr.hint': 'Point the camera at a profile or deal QR code.',

  // Documents
  'doc.scanned': 'Document scanned!',
  'doc.noText': 'No text detected',
  'doc.scanError': 'Scan error',
  'doc.filesAdded': '{count} file(s) added',
  'doc.signatureApplied': 'Signature applied!',
  'doc.pdfError': 'PDF export error',
  'doc.importTitle': 'Scan & Import',
  'doc.importSubtitle':
      'Scan or import a contract to edit it, add photos/videos and sign it',
  'doc.takePhoto': 'Take a photo',
  'doc.takePhotoSub': 'Camera or image file',
  'doc.importFile': 'Import a file',
  'doc.importFileSub': 'PDF or image from your device',
  'doc.newContract': 'New blank contract',
  'doc.newContractSub': 'Write from scratch',
  'doc.contract': 'Contract',
  'doc.addMedia': 'Add photo/video',
  'doc.sign': 'Sign',
  'doc.exportPdf': 'Export PDF',
  'doc.contentHint': 'Contract content...',
  'doc.attachments': 'Attachments ({count})',
  'doc.add': 'Add',
  'doc.signedBadge': 'Document signed electronically',
  'doc.caption': 'Caption...',
  'doc.signature': 'Signature',
  'doc.draw': '✍️ Draw',
  'doc.camera': '📷 Camera',
  'doc.drawHint': 'Draw your signature',
  'doc.importSig': 'Import a photo of your signature',
  'doc.importSigSub': '(sign on white paper, take a photo)',
  'doc.clear': 'Clear',
  'doc.finish': 'Finish',

  // AI assistant chat (UI only)
  'chatai.voiceError': 'Voice error: {msg}',
  'chatai.voiceUnavailable': 'Voice input not available on this browser/device.',
  'chatai.voiceLang': 'Voice language: {lang}',
  'chatai.downloadPdf': 'Download PDF',
  'chatai.clear': 'Clear conversation',
  'chatai.pdfFailed': 'Failed to generate PDF',
  'chatai.title': 'AI Assistant',
  'chatai.subtitle':
      'Ask me about contracts or app features\nin English, French or Arabic',
  'chatai.thinking': 'Thinking...',
  'chatai.listening': 'Listening...',
  'chatai.inputHint': 'Ask a question or describe a contract...',
  'chatai.micTooltip':
      'Tap to speak ({lang}) — long-press to change language',
  'scanBtn.tooltip': 'Scan a document',
  'common.delete': 'Delete',

  // Templates
  'tpl.loadError': 'Could not load templates.',
  'tpl.countOne': '{count} template',
  'tpl.countMany': '{count} templates',
  'tpl.new': 'New template',
  'tpl.deleteTitle': 'Delete template',
  'tpl.deleteConfirm': '"{name}" will be removed from this device.',
  'tpl.use': 'Use template',
  'tpl.edit': 'Edit template',
  'tpl.delete': 'Delete template',
  'tpl.sectionOne': '{count} section',
  'tpl.sectionMany': '{count} sections',
  'tpl.emptyTitle': 'No templates yet',
  'tpl.emptySubtitle':
      'Build a reusable structure once, then spin up new deals from it in a single tap.',
  'tpl.emptyAction': 'Create template',
  'common.saveChanges': 'Save changes',

  // Template form
  'tplForm.editTitle': 'Edit Template',
  'tplForm.newTitle': 'New Template',
  'tplForm.subtitle': 'Reusable structure you can apply to any new deal.',
  'tplForm.nameLabel': 'Template Name *',
  'tplForm.nameHint': 'e.g., Standard Partnership Agreement',
  'tplForm.descLabel': 'Description *',
  'tplForm.descHint': 'What kind of deal is this template for?',
  'tplForm.categoryLabel': 'Category *',
  'tplForm.sections': 'Sections',
  'tplForm.sectionsHelp': 'Each section becomes a titled block in the deal body.',
  'tplForm.addSection': 'Add section',
  'tplForm.createBtn': 'Create Template',
  'tplForm.updated': 'Template updated.',
  'tplForm.saved': 'Template saved and ready to use.',
  'tplForm.docFailed': 'Template saved, but the document failed: {error}',
  'tplForm.sectionTitleHint': 'Section title, e.g., Payment Terms',
  'tplForm.removeSection': 'Remove section',
  'tplForm.sectionBodyHint': 'What this section should say...',
  'field.templateName': 'Template name',
  'field.description': 'Description',
  'field.sectionTitle': 'Section title',
  'field.sectionContent': 'Section content',
  'field.title': 'Title',

  // Create deal
  'cd.title': 'Create New Deal',
  'cd.subtitle': 'Set up a new agreement with participants',
  'cd.contentType': 'Content Type *',
  'cd.dealTitle': 'Deal Title *',
  'cd.dealTitleHint': 'e.g., Partnership Agreement with ABC Corp',
  'cd.descLabel': 'Description *',
  'cd.descHint': 'Provide details about this deal...',
  'cd.category': 'Category *',
  'cd.creationDate': 'Creation Date',
  'cd.selectDate': 'Select date',
  'cd.participants': 'Participants',
  'cd.participantsHelp': 'Optional. Leave blank to invite people later.',
  'cd.addParticipant': 'Add Participant',
  'cd.additionalSections': 'Additional Sections',
  'cd.sectionsHelp': 'Add as many titled blocks as the agreement needs.',
  'cd.addSection': 'Add section',
  'cd.createBtn': 'Create Deal',
  'cd.noTextDetected': 'No text was detected in that image.',
  'cd.attachFirst': 'Attach a {type} first.',
  'cd.docFailed': 'Deal created, but the document failed: {error}',
  'cd.createFailed': 'Failed to create deal.',
  'cd.noAttached': 'No {type} attached',
  'cd.removeAttachment': 'Remove attachment',
  'cd.attach': 'Attach',
  'cd.replace': 'Replace',
  'cd.ocrReading': 'Reading the document with OCR…',
  'cd.extractedText': 'Extracted text',
  'cd.pdfNotice':
      'A PDF document with everything you entered is generated once the deal is created.',
  'cd.templateBanner': 'Prefilled from template "{name}"',
  'cd.participantHint': 'participant@example.com',
  'cd.removeParticipant': 'Remove participant',
  'cd.noSectionsAdd': 'Add a section',
  'cd.noSectionsSub': 'Payment terms, deliverables, exit clauses…',

  // Deal create start (mode chooser)
  'dcs.title': 'New Deal',
  'dcs.subtitle': 'Start a new agreement',
  'dcs.kycRequired': 'Identity verification required',
  'dcs.kycBody':
      'You must complete your KYC before you can create a deal. Verify your identity, then come back to start a new deal.',
  'dcs.completeKyc': 'Complete KYC',
  'dcs.reference': 'Reference',
  'dcs.referenceValue': 'Generated automatically on creation',
  'dcs.owner': 'Owner',
  'dcs.ownerYou': 'You',
  'dcs.howBuild': 'How do you want to build it?',
  'dcs.manual': 'Manual editing',
  'dcs.manualSub': 'Fill in the form with sections you can add yourself.',
  'dcs.ai': 'AI assistant',
  'dcs.aiSub': 'Let the assistant draft the deal for you (coming soon).',

  // AI assistant screen + panel (placeholder, no AI logic)
  'aia.title': 'AI assistant',
  'aia.subtitle': 'Draft your deal with help (placeholder)',
  'aia.panelTitle': 'Draft a deal with AI',
  'aia.panelDesc':
      'The assistant will interview you and generate a first draft of the deal, including suggested sections and clauses. This is a placeholder — nothing is generated yet.',
  'aia.bullet1': 'Describe the deal in plain language.',
  'aia.bullet2': 'Get a structured draft with sections.',
  'aia.bullet3': 'Review and edit before creating.',
  'aia.switchManual': 'Switch to manual editing',
  'aiPanel.comingSoon': 'Coming soon',
  'aiPanel.placeholder': 'AI assistant will plug in here. No AI is running yet.',

  // Deal detail
  'dd.lockedOfficial': 'Locked official version',
  'dd.tabOverview': 'Overview',
  'dd.tabVersions': 'Versions',
  'dd.tabDocument': 'Document',
  'dd.workflow': 'Workflow',
  'dd.readAiTitle': 'Read this deal with AI',
  'dd.readAiDesc':
      'The assistant will summarise the deal and flag clauses you should pay attention to before deciding. This is a placeholder — no AI is running yet.',
  'dd.readAiBullet1': 'Plain-language summary of each section.',
  'dd.readAiBullet2': 'Highlights of risky or unusual clauses.',
  'dd.readAiBullet3': 'Suggested questions to raise in the discussion.',
  'dd.dealDocument': 'Deal document',
  'dd.noDocContent': 'No document content.',
  'dd.requestChanges': 'Request changes',
  'dd.whatChange': 'What should change? (optional)',
  'dd.send': 'Send',
  'dd.proposeTitle': 'Propose a new version',
  'dd.whatChanged': 'What changed (summary)',
  'dd.updatedDoc': 'Updated document',
  'dd.createVersion': 'Create version',
  'dd.versionCreated': 'New version created.',
  'dd.invitedBody':
      'You have been invited to this deal. Read it, then accept or refuse.',
  'dd.readAi': 'Read with AI',
  'dd.readManually': 'Read manually',
  'dd.accept': 'Accept',
  'dd.refuse': 'Refuse',
  'dd.acceptedBody':
      'You accepted this deal. Discuss changes in the chat; the creator turns the outcome into new versions.',
  'dd.openDiscussion': 'Open discussion',
  'dd.approveVersion': 'Approve version',
  'dd.refusedBody': 'You refused this deal.',
  'dd.waitingAccept':
      'Waiting for the other party to accept. Share the deal link/QR or add them by username/email.',
  'dd.shareAddParty': 'Share / add party',
  'dd.partyAcceptedBody':
      'A party has accepted. Discuss changes, submit a version for approval, or propose a new version.',
  'dd.submitVersion': 'Submit V{n} for approval',
  'dd.proposeNewVersion': 'Propose new version',
  'dd.noActions': 'No actions available for you on this deal right now.',
  'dd.pendingNote': 'Submitted — waiting for the other party to approve.',
  'dd.infoStatus': 'Status',
  'dd.infoCreated': 'Created',
  'dd.infoType': 'Type',
  'dd.infoLock': 'Lock',
  'dd.final': 'Final',
  'dd.open': 'Open',
  'dd.description': 'Description',
  'dd.noDescription': 'No description provided.',
  'dd.stepDraftSub': 'Terms remain editable while the deal is a draft.',
  'dd.stepBridgedSub': 'The deal is in flight between the parties.',
  'dd.stepApprovedSub': 'All parties agree on the current version.',
  'dd.versionsError': 'Error loading versions: {error}',
  'dd.noVersions': 'No versions yet.',
  'dd.documentError': 'Error loading document: {error}',
  'dd.noGeneratedDoc': 'This deal has no generated document.',
  'dd.generating': 'Generating…',
  'dd.downloadPdf': 'Download PDF',
  'dd.noContent': 'No content.',
};

// -----------------------------------------------------------------------------
// French
// -----------------------------------------------------------------------------
const Map<String, String> _fr = {
  // Common / shared
  'common.cancel': 'Annuler',
  'common.save': 'Enregistrer',
  'common.change': 'Modifier',
  'common.retry': 'Réessayer',
  'common.close': 'Fermer',
  'common.comingSoon': 'Cette fonctionnalité est encore en cours de développement.',
  'common.error': 'Une erreur est survenue. Veuillez réessayer.',
  'common.refresh': 'Actualiser',

  // Deal party discussion (chat)
  'dealChat.title': 'Discussion — {title}',
  'dealChat.loadError': "Impossible de charger la discussion.\n{error}",
  'dealChat.empty': 'Aucun message pour le moment. Démarrez la discussion.',
  'dealChat.hint': "Écrire à l'autre partie…",

  // Deal share
  'share.title': 'Deal créé 🎉',
  'share.subtitle': 'Partagez-le et choisissez avec qui traiter.',
  'share.labelTitle': 'Titre',
  'share.labelReference': 'Référence',
  'share.qrCaption': 'Scannez pour ouvrir ce deal',
  'share.invitationLink': "Lien d'invitation",
  'share.copyLink': 'Copier le lien',
  'share.linkCopied': 'Lien copié dans le presse-papiers.',
  'share.addParty': "Ajouter l'autre partie",
  'share.addPartyHelp':
      "Saisissez son nom d'utilisateur ou son e-mail. Elle recevra une notification pour accepter le deal.",
  'share.partyHint': "nom d'utilisateur ou email@example.com",
  'share.inviteAnother': 'Inviter une autre',
  'share.inviteParty': 'Inviter la partie',
  'share.goToDeal': 'Aller au deal',
  'share.partyInvited': "L'autre partie a été invitée.",
  'share.couldNotAddParty': "Impossible d'ajouter cette partie.",
  'share.linkError': 'Impossible de générer le lien.\n{error}',

  // Bottom / side navigation (IdealAppScaffold)
  'nav.home': 'Accueil',
  'nav.deals': 'Deals',
  'nav.documents': 'Documents',
  'nav.assistant': 'Assistant',
  'nav.settings': 'Réglages',
  'nav.notifications': 'Notifications',

  // Deals list
  'deals.title': 'Deals',
  'deals.subtitle': 'Gérez et suivez tous vos deals',
  'deals.tabDeals': 'Deals',
  'deals.tabTemplates': 'Modèles',
  'deals.search': 'Rechercher des deals...',
  'deals.filterAll': 'Tous',
  'deals.filterDraft': 'Brouillon',
  'deals.filterBridged': 'Rapprochés',
  'deals.filterApproved': 'Approuvés',
  'deals.filterCancelled': 'Annulés',
  'deals.emptyTitle': 'Aucun deal pour le moment',
  'deals.emptySubtitle': 'Créez votre premier deal pour commencer à négocier.',
  'deals.emptyAction': 'Créer un deal',
  'deals.noneFound': 'Aucun deal trouvé',
  'deals.createButton': 'Créer un deal',
  'deals.errorPrefix': 'Erreur : {message}',

  // Deal status labels (NEGOTIATION reads as "Bridged" / « Rapproché »)
  'dealStatus.draft': 'Brouillon',
  'dealStatus.negotiation': 'Rapproché',
  'dealStatus.pendingApproval': "En attente d'approbation",
  'dealStatus.approved': 'Approuvé',
  'dealStatus.locked': 'Verrouillé',
  'dealStatus.changesRequested': 'Modifications demandées',
  'dealStatus.rejected': 'Rejeté',
  'dealStatus.cancelled': 'Annulé',
  'dealStatus.archived': 'Archivé',

  // Deal content types
  'dealType.document': 'Document',
  'dealType.video': 'Vidéo',
  'dealType.scanned': 'Document scanné',
  'dealType.documentDesc': "Un accord écrit rédigé dans l'application.",
  'dealType.videoDesc': 'Un accord vidéo enregistré ou une démonstration.',
  'dealType.scannedDesc': 'Une photo ou un scan, lu par OCR.',

  // Home
  'home.signOut': 'Se déconnecter',
  'home.profile': 'Profil',
  'home.there': 'à vous',
  'home.welcome': 'Bon retour, {name}',
  'home.welcomeSub': "Voici l'actualité de vos deals aujourd'hui.",
  'home.recentDeals': 'Deals récents',
  'home.viewAll': 'Tout voir',
  'home.emptyRecent':
      'Créez votre premier deal pour commencer à suivre vos accords.',
  'home.scanProfileTitle': 'Scanner un profil',
  'home.notIdealQr': "Ce QR code n'est pas un profil IDEAL.",
  'home.profileNotFound': 'Profil introuvable',
  'home.profilePrivate': "Ce profil est privé ou n'existe pas.",
  'home.verifiedAccount': 'Compte vérifié',
  'home.notVerifiedYet': 'Pas encore vérifié',
  'home.kycVerified': 'Vérifié (KYC)',
  'home.notVerified': 'Non vérifié',
  'home.publicProfile': 'Profil public',
  'home.privateProfile': 'Profil privé',
  'home.publicSub': 'Les autres peuvent vous trouver en scannant votre QR.',
  'home.privateSub': 'Vous seul pouvez voir ce profil.',
  'home.qrCaption': 'Votre QR de profil — laissez les autres le scanner',
  'home.scanAnother': 'Scanner un autre profil',
  'home.statSuccessful': 'Deals réussis',
  'home.statBridged': 'Deals rapprochés',
  'home.statActive': 'Deals actifs',
  'home.createDeal': 'Créer un deal',
  'home.createDealSub': 'Démarrer un nouvel accord',
  'home.viewDeals': 'Voir les deals',
  'home.viewDealsSub': 'Suivre les travaux en cours',
  'home.miniIdentity': 'Identité',
  'home.miniApprovals': 'Approbations',

  // Settings
  'settings.title': 'Réglages',
  'settings.subtitle': 'Gérez vos préférences et la sécurité de votre compte',
  'settings.general': 'Paramètres généraux',
  'settings.language': 'Langue',
  'settings.notifications': 'Notifications',
  'settings.pushNotifications': 'Notifications push',
  'settings.pushNotificationsSub': 'Recevoir des notifications sur les deals',
  'settings.emailUpdates': 'Mises à jour par e-mail',
  'settings.emailUpdatesSub': 'Recevoir des notifications par e-mail',
  'settings.security': 'Sécurité',
  'settings.twoFactor': 'Authentification à deux facteurs',
  'settings.twoFactorSub': 'Ajouter une couche de sécurité supplémentaire',
  'settings.changePassword': 'Changer le mot de passe',
  'settings.changePasswordSub': 'Mettre à jour votre mot de passe',
  'settings.account': 'Gestion du compte',
  'settings.editProfile': 'Modifier le profil',
  'settings.editProfileSub': 'Changer votre nom affiché et votre avatar',
  'settings.activeSessions': 'Sessions actives',
  'settings.activeSessionsSub': 'Voir les appareils connectés',
  'settings.privacy': 'Confidentialité',
  'settings.publicProfile': 'Profil public',
  'settings.publicProfileSub': 'Rendre votre profil visible par les autres',
  'settings.dangerZone': 'Zone de danger',
  'settings.logout': 'Se déconnecter',
  'settings.deleteAccount': 'Supprimer le compte',

  // Shared auth
  'common.or': 'ou',
  'auth.email': 'Adresse e-mail',
  'auth.emailHint': 'vous@example.com',
  'auth.password': 'Mot de passe',
  'auth.tooManyAttempts': 'Trop de tentatives. Réessayez plus tard.',
  'auth.backToSignIn': 'Retour à la connexion',

  // Login
  'login.title': 'Bon retour',
  'login.subtitle': 'Connectez-vous pour continuer à gérer vos deals.',
  'login.passwordHint': 'Votre mot de passe',
  'login.rememberMe': 'Se souvenir de moi',
  'login.forgot': 'Mot de passe oublié ?',
  'login.signIn': 'Se connecter',
  'login.google': 'Continuer avec Google',
  'login.noAccount': "Pas encore de compte ? ",
  'login.signUpLink': "S'inscrire",

  // Register
  'register.title': 'Créer un compte',
  'register.subtitle': 'Rejoignez IDEAL et lancez des accords de confiance.',
  'register.acceptTerms':
      "Veuillez accepter les conditions d'utilisation pour continuer.",
  'register.fullName': 'Nom complet',
  'register.fullNameHint': 'Jean Dupont',
  'register.passwordHint': 'Au moins 8 caractères',
  'register.confirmPassword': 'Confirmer le mot de passe',
  'register.confirmHint': 'Répétez votre mot de passe',
  'register.accountType': 'Type de compte',
  'register.individual': 'Particulier',
  'register.company': 'Entreprise',
  'register.agree':
      "J'accepte les conditions d'utilisation et la politique de confidentialité",
  'register.create': 'Créer le compte',
  'register.google': "S'inscrire avec Google",
  'register.haveAccount': 'Vous avez déjà un compte ? ',
  'register.signInLink': 'Se connecter',
  'register.signInAction': 'Se connecter',

  // Forgot password
  'forgot.checkEmail': 'Vérifiez vos e-mails',
  'forgot.sentTo': 'Nous avons envoyé un lien de réinitialisation à',
  'forgot.title': 'Réinitialiser le mot de passe',
  'forgot.subtitle':
      'Saisissez votre e-mail et nous vous enverrons un lien de réinitialisation.',
  'forgot.send': 'Envoyer le lien',

  // Reset password
  'reset.title': 'Nouveau mot de passe',
  'reset.subtitle': 'Choisissez un mot de passe fort pour votre compte.',
  'reset.newPassword': 'Nouveau mot de passe',
  'reset.newPasswordHint': 'Au moins 8 caractères',
  'reset.confirmNew': 'Confirmer le nouveau mot de passe',
  'reset.confirmNewHint': 'Ressaisissez votre mot de passe',
  'reset.strengthHint':
      'Mélangez lettres, chiffres et symboles pour un mot de passe fort.',
  'reset.update': 'Mettre à jour le mot de passe',

  // OTP (verification flow — currently disabled but still routed)
  'otp.enterComplete': 'Veuillez saisir le code complet à 6 chiffres.',
  'otp.newCodeSent': 'Un nouveau code de vérification a été envoyé.',
  'otp.title': "Vérifier l'e-mail",
  'otp.sentCode': 'Nous avons envoyé un code à votre e-mail',
  'otp.enter6': 'Saisissez le code à 6 chiffres envoyé à votre adresse e-mail',
  'otp.didntReceive': "Vous n'avez pas reçu le code ? ",
  'otp.resend': 'Renvoyer',
  'otp.resendIn': 'Renvoyer ({seconds}s)',
  'otp.expire': 'Ce code expirera dans 10 minutes',

  // Splash / onboarding
  'splash.tagline': 'Gestion sécurisée des deals',
  'splash.getStarted': 'Commencer',
  'splash.feat1Title': 'Gestion sécurisée des contrats',
  'splash.feat1Desc':
      'Chiffrez, vérifiez et cosignez vos accords juridiques en toute confiance.',
  'splash.feat2Title': 'Collaboration en temps réel',
  'splash.feat2Desc':
      'Synchronisez les mises à jour et corédigez les termes avec vos partenaires en direct.',
  'splash.feat3Title': 'Outils de négociation intégrés',
  'splash.feat3Desc':
      'Suivez facilement les révisions, les audits et le consensus final.',

  // Form validation
  'validation.emailRequired': "L'e-mail est requis.",
  'validation.emailInvalid': 'Saisissez une adresse e-mail valide.',
  'validation.passwordRequired': 'Le mot de passe est requis.',
  'validation.passwordShort': 'Le mot de passe doit contenir au moins 8 caractères.',
  'validation.fullNameRequired': 'Le nom complet est requis.',
  'validation.fullNameShort': 'Saisissez votre nom complet.',
  'validation.otpRequired': 'Le code de vérification est requis.',
  'validation.otpLength': 'Saisissez le code à 6 chiffres.',
  'validation.otpDigits': 'Le code doit comporter 6 chiffres.',
  'validation.fieldRequired': '{field} est requis.',
  'validation.confirmPassword': 'Veuillez confirmer votre mot de passe.',
  'validation.passwordsNoMatch': 'Les mots de passe ne correspondent pas.',

  'common.errorPrefix': 'Erreur : {message}',

  // KYC — status screen
  'kyc.verifyIdentity': 'Vérifiez votre identité',
  'kyc.verifyDesc':
      "Pour participer à des deals et instaurer la confiance avec les autres parties, vérifiez votre identité avec une pièce d'identité officielle.",
  'kyc.infoSecure': 'Vos documents sont stockés de façon sécurisée et privée',
  'kyc.infoTime': 'La vérification prend généralement 1 à 2 jours ouvrés',
  'kyc.infoAuthorized':
      'Seuls les vérificateurs autorisés peuvent accéder à vos documents',
  'kyc.start': 'Démarrer la vérification',
  'kyc.rejectionReason': 'Motif de rejet',
  'kyc.resubmit': 'Renvoyer les documents',
  'kyc.submissionDetails': 'Détails de la soumission',
  'kyc.documentType': 'Type de document',
  'kyc.submittedOn': 'Soumis le',
  'kyc.reviewedOn': 'Vérifié le',
  // KYC — upload screen
  'kyc.uploadTitle': 'Téléverser les documents',
  'kyc.uploadSubtitle': "Soumettez vos pièces d'identité pour vérification sécurisée.",
  'kyc.selectType': 'Sélectionnez le type de document',
  'kyc.uploadDocs': 'Téléverser les documents',
  'kyc.frontLabel': 'Recto du document',
  'kyc.frontSub': 'Photo nette du recto',
  'kyc.backLabel': 'Verso du document',
  'kyc.backSub': 'Photo nette du verso',
  'kyc.selfieLabel': 'Selfie avec le document',
  'kyc.selfieSub': 'Tenez votre document près de votre visage',
  'kyc.securityNotice': 'Avis de sécurité',
  'kyc.securityText':
      'Vos documents sont chiffrés et stockés dans un espace privé sécurisé. Seuls les vérificateurs autorisés peuvent y accéder.',
  'kyc.uploading': 'Téléversement… {percent}%',
  'kyc.submit': 'Soumettre pour vérification',
  'kyc.needFront': 'Veuillez téléverser le recto de votre document.',
  'kyc.needSelfie': 'Veuillez téléverser un selfie avec votre document.',
  'kyc.submitted': 'KYC soumis ! Nous le vérifierons sous peu.',
  'kyc.uploadFailed': 'Échec du téléversement.',
  // KYC status labels + messages
  'kycStatus.notSubmitted': 'Non soumis',
  'kycStatus.pending': 'En cours de vérification',
  'kycStatus.approved': 'Vérifié',
  'kycStatus.rejected': 'Rejeté',
  'kycMsg.pending':
      'Vos documents sont en cours de vérification. Cela prend généralement 1 à 2 jours ouvrés.',
  'kycMsg.approved':
      'Votre identité a été vérifiée. Vous pouvez désormais participer à des deals.',
  'kycMsg.rejected':
      'Votre vérification a été rejetée. Consultez le motif et renvoyez vos documents.',
  'kycDoc.nationalId': "Carte d'identité",
  'kycDoc.passport': 'Passeport',
  'kycDoc.driverLicense': 'Permis de conduire',

  // Notifications
  'notif.unread': 'Vous avez {count} notifications non lues',
  'notif.markAll': 'Tout marquer comme lu',
  'notif.unreadLabel': 'NON LUES',
  'notif.earlierLabel': 'PLUS TÔT',
  'notif.empty': 'Aucune notification pour le moment',
  'notif.loadError': 'Impossible de charger les notifications.\n{error}',
  'time.justNow': "À l'instant",
  'time.minAgo': 'il y a {n} min',
  'time.hourAgo': 'il y a {n} h',
  'time.dayAgo': 'il y a {n} j',

  // Edit profile
  'profile.title': 'Modifier le profil',
  'profile.subtitle': 'Mettez à jour votre apparence dans IDEAL.',
  'profile.displayName': 'Nom affiché *',
  'profile.displayNameHint': 'ex. : Imen Ben Ouaghrem',
  'profile.username': "Nom d'utilisateur",
  'profile.usernameHint': 'ex. : imen_bo',
  'profile.usernameHelper':
      'Les autres peuvent vous trouver via ce pseudo ou votre QR.',
  'profile.avatarUrl': "URL de l'avatar",
  'profile.avatarHint': 'https://example.com/avatar.png',
  'profile.email': 'E-mail',
  'profile.emailHelper':
      "Votre e-mail est votre identifiant de connexion et ne peut pas être modifié ici.",
  'profile.identityVerification': "Vérification d'identité",
  'profile.updated': 'Profil mis à jour.',
  'profile.saveChanges': 'Enregistrer',
  'validation.usernameLength': "Le nom d'utilisateur doit comporter 3 à 30 caractères.",
  'validation.usernameChars':
      'Seuls les lettres, chiffres et underscores sont autorisés.',
  'validation.urlFull': "Saisissez une URL complète, avec https://",
  'validation.urlScheme': 'Seules les URL http et https sont autorisées.',
  'kycProfile.approved': 'Approuvé',
  'kycProfile.submitted': 'Soumis',
  'kycProfile.underReview': 'En cours de vérification',
  'kycProfile.rejected': 'Rejeté',
  'kycProfile.resubmission': 'Nouvelle soumission requise',
  'kycProfile.revoked': 'Révoqué',
  'kycProfile.notStarted': 'Non commencé',

  // QR scanner
  'qr.torch': 'Activer/désactiver la lampe',
  'qr.hint': 'Pointez la caméra vers un QR de profil ou de deal.',

  // Documents
  'doc.scanned': 'Document scanné !',
  'doc.noText': 'Aucun texte détecté',
  'doc.scanError': 'Erreur de scan',
  'doc.filesAdded': '{count} fichier(s) ajouté(s)',
  'doc.signatureApplied': 'Signature apposée !',
  'doc.pdfError': 'Erreur export PDF',
  'doc.importTitle': 'Scanner & Importer',
  'doc.importSubtitle':
      'Scannez ou importez un contrat pour le modifier, ajouter des photos/vidéos et le signer',
  'doc.takePhoto': 'Prendre une photo',
  'doc.takePhotoSub': 'Appareil photo ou fichier image',
  'doc.importFile': 'Importer un fichier',
  'doc.importFileSub': 'PDF ou image depuis votre appareil',
  'doc.newContract': 'Nouveau contrat vide',
  'doc.newContractSub': 'Rédiger depuis zéro',
  'doc.contract': 'Contrat',
  'doc.addMedia': 'Ajouter photo/vidéo',
  'doc.sign': 'Signer',
  'doc.exportPdf': 'Exporter PDF',
  'doc.contentHint': 'Contenu du contrat...',
  'doc.attachments': 'Pièces jointes ({count})',
  'doc.add': 'Ajouter',
  'doc.signedBadge': 'Document signé électroniquement',
  'doc.caption': 'Légende...',
  'doc.signature': 'Signature',
  'doc.draw': '✍️ Dessiner',
  'doc.camera': '📷 Caméra',
  'doc.drawHint': 'Dessinez votre signature',
  'doc.importSig': 'Importer une photo de votre signature',
  'doc.importSigSub': '(signez sur papier blanc, prenez une photo)',
  'doc.clear': 'Effacer',
  'doc.finish': 'Terminer',

  // AI assistant chat (UI only)
  'chatai.voiceError': 'Erreur vocale : {msg}',
  'chatai.voiceUnavailable':
      'La saisie vocale n\'est pas disponible sur ce navigateur/appareil.',
  'chatai.voiceLang': 'Langue vocale : {lang}',
  'chatai.downloadPdf': 'Télécharger le PDF',
  'chatai.clear': 'Effacer la conversation',
  'chatai.pdfFailed': 'Échec de la génération du PDF',
  'chatai.title': 'Assistant IA',
  'chatai.subtitle':
      "Posez-moi des questions sur les contrats ou l'application\nen anglais, français ou arabe",
  'chatai.thinking': 'Réflexion…',
  'chatai.listening': 'Écoute…',
  'chatai.inputHint': 'Posez une question ou décrivez un contrat…',
  'chatai.micTooltip':
      'Appuyez pour parler ({lang}) — appui long pour changer de langue',
  'scanBtn.tooltip': 'Scanner un document',
  'common.delete': 'Supprimer',

  // Templates
  'tpl.loadError': 'Impossible de charger les modèles.',
  'tpl.countOne': '{count} modèle',
  'tpl.countMany': '{count} modèles',
  'tpl.new': 'Nouveau modèle',
  'tpl.deleteTitle': 'Supprimer le modèle',
  'tpl.deleteConfirm': '« {name} » sera supprimé de cet appareil.',
  'tpl.use': 'Utiliser le modèle',
  'tpl.edit': 'Modifier le modèle',
  'tpl.delete': 'Supprimer le modèle',
  'tpl.sectionOne': '{count} section',
  'tpl.sectionMany': '{count} sections',
  'tpl.emptyTitle': 'Aucun modèle pour le moment',
  'tpl.emptySubtitle':
      "Créez une structure réutilisable une fois, puis lancez de nouveaux deals en un seul tap.",
  'tpl.emptyAction': 'Créer un modèle',
  'common.saveChanges': 'Enregistrer',

  // Template form
  'tplForm.editTitle': 'Modifier le modèle',
  'tplForm.newTitle': 'Nouveau modèle',
  'tplForm.subtitle': 'Structure réutilisable applicable à tout nouveau deal.',
  'tplForm.nameLabel': 'Nom du modèle *',
  'tplForm.nameHint': 'ex. : Accord de partenariat standard',
  'tplForm.descLabel': 'Description *',
  'tplForm.descHint': 'Pour quel type de deal ce modèle est-il prévu ?',
  'tplForm.categoryLabel': 'Catégorie *',
  'tplForm.sections': 'Sections',
  'tplForm.sectionsHelp':
      'Chaque section devient un bloc titré dans le corps du deal.',
  'tplForm.addSection': 'Ajouter une section',
  'tplForm.createBtn': 'Créer le modèle',
  'tplForm.updated': 'Modèle mis à jour.',
  'tplForm.saved': 'Modèle enregistré et prêt à l\'emploi.',
  'tplForm.docFailed': "Modèle enregistré, mais le document a échoué : {error}",
  'tplForm.sectionTitleHint': 'Titre de section, ex. : Conditions de paiement',
  'tplForm.removeSection': 'Supprimer la section',
  'tplForm.sectionBodyHint': 'Ce que cette section doit contenir…',
  'field.templateName': 'Le nom du modèle',
  'field.description': 'La description',
  'field.sectionTitle': 'Le titre de section',
  'field.sectionContent': 'Le contenu de section',
  'field.title': 'Le titre',

  // Create deal
  'cd.title': 'Créer un nouveau deal',
  'cd.subtitle': 'Configurez un nouvel accord avec des participants',
  'cd.contentType': 'Type de contenu *',
  'cd.dealTitle': 'Titre du deal *',
  'cd.dealTitleHint': 'ex. : Accord de partenariat avec ABC Corp',
  'cd.descLabel': 'Description *',
  'cd.descHint': 'Donnez des détails sur ce deal…',
  'cd.category': 'Catégorie *',
  'cd.creationDate': 'Date de création',
  'cd.selectDate': 'Choisir une date',
  'cd.participants': 'Participants',
  'cd.participantsHelp':
      'Facultatif. Laissez vide pour inviter des personnes plus tard.',
  'cd.addParticipant': 'Ajouter un participant',
  'cd.additionalSections': 'Sections supplémentaires',
  'cd.sectionsHelp': "Ajoutez autant de blocs titrés que l'accord le nécessite.",
  'cd.addSection': 'Ajouter une section',
  'cd.createBtn': 'Créer le deal',
  'cd.noTextDetected': 'Aucun texte détecté dans cette image.',
  'cd.attachFirst': 'Joignez d\'abord un(e) {type}.',
  'cd.docFailed': 'Deal créé, mais le document a échoué : {error}',
  'cd.createFailed': 'Échec de la création du deal.',
  'cd.noAttached': 'Aucun(e) {type} joint(e)',
  'cd.removeAttachment': 'Retirer la pièce jointe',
  'cd.attach': 'Joindre',
  'cd.replace': 'Remplacer',
  'cd.ocrReading': 'Lecture du document par OCR…',
  'cd.extractedText': 'Texte extrait',
  'cd.pdfNotice':
      'Un document PDF reprenant tout ce que vous avez saisi est généré une fois le deal créé.',
  'cd.templateBanner': 'Prérempli à partir du modèle « {name} »',
  'cd.participantHint': 'participant@example.com',
  'cd.removeParticipant': 'Retirer le participant',
  'cd.noSectionsAdd': 'Ajouter une section',
  'cd.noSectionsSub': 'Conditions de paiement, livrables, clauses de sortie…',

  // Deal create start (mode chooser)
  'dcs.title': 'Nouveau deal',
  'dcs.subtitle': 'Démarrer un nouvel accord',
  'dcs.kycRequired': "Vérification d'identité requise",
  'dcs.kycBody':
      "Vous devez compléter votre KYC avant de pouvoir créer un deal. Vérifiez votre identité, puis revenez pour démarrer un nouveau deal.",
  'dcs.completeKyc': 'Compléter le KYC',
  'dcs.reference': 'Référence',
  'dcs.referenceValue': 'Générée automatiquement à la création',
  'dcs.owner': 'Propriétaire',
  'dcs.ownerYou': 'Vous',
  'dcs.howBuild': 'Comment voulez-vous le créer ?',
  'dcs.manual': 'Édition manuelle',
  'dcs.manualSub': 'Remplissez le formulaire avec des sections que vous ajoutez vous-même.',
  'dcs.ai': 'Assistant IA',
  'dcs.aiSub': "Laissez l'assistant rédiger le deal pour vous (bientôt disponible).",

  // AI assistant screen + panel (placeholder, no AI logic)
  'aia.title': 'Assistant IA',
  'aia.subtitle': 'Rédigez votre deal avec de l\'aide (aperçu)',
  'aia.panelTitle': 'Rédiger un deal avec l\'IA',
  'aia.panelDesc':
      "L'assistant vous posera des questions et générera un premier brouillon du deal, avec des sections et clauses suggérées. Ceci est un aperçu — rien n'est généré pour l'instant.",
  'aia.bullet1': 'Décrivez le deal en langage courant.',
  'aia.bullet2': 'Obtenez un brouillon structuré en sections.',
  'aia.bullet3': 'Relisez et modifiez avant de créer.',
  'aia.switchManual': 'Passer à l\'édition manuelle',
  'aiPanel.comingSoon': 'Bientôt disponible',
  'aiPanel.placeholder':
      "L'assistant IA s'intégrera ici. Aucune IA n'est active pour l'instant.",

  // Deal detail
  'dd.lockedOfficial': 'Version officielle verrouillée',
  'dd.tabOverview': 'Aperçu',
  'dd.tabVersions': 'Versions',
  'dd.tabDocument': 'Document',
  'dd.workflow': 'Flux de travail',
  'dd.readAiTitle': 'Lire ce deal avec l\'IA',
  'dd.readAiDesc':
      "L'assistant résumera le deal et signalera les clauses auxquelles prêter attention avant de décider. Ceci est un aperçu — aucune IA n'est active pour l'instant.",
  'dd.readAiBullet1': 'Résumé en langage clair de chaque section.',
  'dd.readAiBullet2': 'Mise en évidence des clauses risquées ou inhabituelles.',
  'dd.readAiBullet3': 'Questions suggérées à soulever dans la discussion.',
  'dd.dealDocument': 'Document du deal',
  'dd.noDocContent': 'Aucun contenu de document.',
  'dd.requestChanges': 'Demander des modifications',
  'dd.whatChange': 'Que faut-il changer ? (facultatif)',
  'dd.send': 'Envoyer',
  'dd.proposeTitle': 'Proposer une nouvelle version',
  'dd.whatChanged': 'Ce qui a changé (résumé)',
  'dd.updatedDoc': 'Document mis à jour',
  'dd.createVersion': 'Créer la version',
  'dd.versionCreated': 'Nouvelle version créée.',
  'dd.invitedBody':
      'Vous avez été invité à ce deal. Lisez-le, puis acceptez ou refusez.',
  'dd.readAi': 'Lire avec l\'IA',
  'dd.readManually': 'Lire manuellement',
  'dd.accept': 'Accepter',
  'dd.refuse': 'Refuser',
  'dd.acceptedBody':
      "Vous avez accepté ce deal. Discutez des changements dans le chat ; le créateur transforme le résultat en nouvelles versions.",
  'dd.openDiscussion': 'Ouvrir la discussion',
  'dd.approveVersion': 'Approuver la version',
  'dd.refusedBody': 'Vous avez refusé ce deal.',
  'dd.waitingAccept':
      "En attente de l'acceptation de l'autre partie. Partagez le lien/QR du deal ou ajoutez-la par nom d'utilisateur/e-mail.",
  'dd.shareAddParty': 'Partager / ajouter une partie',
  'dd.partyAcceptedBody':
      'Une partie a accepté. Discutez des changements, soumettez une version pour approbation, ou proposez une nouvelle version.',
  'dd.submitVersion': 'Soumettre la V{n} pour approbation',
  'dd.proposeNewVersion': 'Proposer une nouvelle version',
  'dd.noActions': "Aucune action disponible pour vous sur ce deal actuellement.",
  'dd.pendingNote': "Soumise — en attente de l'approbation de l'autre partie.",
  'dd.infoStatus': 'Statut',
  'dd.infoCreated': 'Créé',
  'dd.infoType': 'Type',
  'dd.infoLock': 'Verrou',
  'dd.final': 'Finale',
  'dd.open': 'Ouverte',
  'dd.description': 'Description',
  'dd.noDescription': 'Aucune description fournie.',
  'dd.stepDraftSub': 'Les termes restent modifiables tant que le deal est un brouillon.',
  'dd.stepBridgedSub': 'Le deal est en cours entre les parties.',
  'dd.stepApprovedSub': "Toutes les parties s'accordent sur la version actuelle.",
  'dd.versionsError': 'Erreur de chargement des versions : {error}',
  'dd.noVersions': 'Aucune version pour le moment.',
  'dd.documentError': 'Erreur de chargement du document : {error}',
  'dd.noGeneratedDoc': "Ce deal n'a aucun document généré.",
  'dd.generating': 'Génération…',
  'dd.downloadPdf': 'Télécharger le PDF',
  'dd.noContent': 'Aucun contenu.',
};
