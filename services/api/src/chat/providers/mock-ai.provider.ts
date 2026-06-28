import { Injectable } from '@nestjs/common';
import { AiProvider, AiChatRequest, AiChatResponse } from './ai-provider.interface';

@Injectable()
export class MockAiProvider implements AiProvider {
  async chat(request: AiChatRequest): Promise<AiChatResponse> {
    const msg = request.message.toLowerCase().trim();
    const history = request.history ?? [];
    const lastAiMessage = history.filter(h => h.role === 'assistant').pop()?.content ?? '';

    let reply = '';

    // Etape 1 : demande de contrat
    if ((msg.includes('contrat') || msg.includes('prestation') || msg.includes('location') || msg.includes('vente') || msg.includes('emploi')) && history.length <= 1) {
      reply = `Parfait, je vais vous aider à rédiger un contrat professionnel.\n\n**Question 1/5 — Identification des parties**\n\nQui est le **Prestataire** ?\n- Nom / Raison sociale :\n- Forme juridique :\n- Adresse :\n- Matricule fiscal :`;

    // Etape 2 : on attend les parties
    } else if (lastAiMessage.includes('Question 1/5')) {
      reply = `Merci. **Question 2/5 — Objet de la prestation**\n\nQuelle est la nature exacte du service ?\n- Le service (ex: développement web, conseil, formation...)\n- Les livrables attendus\n- Les spécifications techniques`;

    // Etape 3 : on attend l'objet
    } else if (lastAiMessage.includes('Question 2/5')) {
      reply = `**Question 3/5 — Durée et dates**\n\n- Date de début :\n- Date de fin :\n- Renouvellement possible ?`;

    // Etape 4 : on attend la durée
    } else if (lastAiMessage.includes('Question 3/5')) {
      reply = `**Question 4/5 — Rémunération**\n\n- Montant total :\n- TVA applicable ?\n- Modalités de paiement :`;

    // Etape 5 : on attend le montant
    } else if (lastAiMessage.includes('Question 4/5')) {
      reply = `**Question 5/5 — Clauses particulières**\n\nY a-t-il des clauses spécifiques ?\n- Confidentialité ?\n- Propriété intellectuelle ?\n- Pénalités de retard ?\n\nOu tapez **"clauses standards"** pour continuer.`;

    // Choix de version
    } else if (lastAiMessage.includes('Question 5/5') || msg.includes('standard') || msg.includes('clause')) {
      reply = `Toutes les informations sont réunies. Choisissez votre version :\n\n**Option A** — Version simple et concise\n**Option B** — Version standard équilibrée ✅ recommandée\n**Option C** — Version complète et détaillée`;

    // Génération du contrat
    } else if (lastAiMessage.includes('Option A') || lastAiMessage.includes('Option B') || msg.includes('option a') || msg.includes('option b') || msg.includes('option c')) {
      const allContent = history.map(h => h.content).join(' ') + ' ' + request.message;
      const prestataire = allContent.match(/prestataire[^.]*?:(.*?)(?:client|\.)/i)?.[1]?.trim() ?? 'Ahmed Ben Salah, auto-entrepreneur, 15 rue de Carthage Tunis, MF 123456A';
      const client = allContent.match(/client[^.]*?:(.*?)(?:service|\.)/i)?.[1]?.trim() ?? 'Société Delta SARL, capital 50 000 DT, avenue Mohamed V Tunis, MF 789012B, représentée par Sami Trabelsi';

      reply = `# CONTRAT DE PRESTATION DE SERVICES\n\n**Entre les soussignés :**\n\n**Le Prestataire :** ${prestataire}\n\n**Le Client :** ${client}\n\nCi-après désignés collectivement « les Parties ».\n\n---\n\n## ARTICLE 1 — OBJET\n\nLe Prestataire s'engage à réaliser pour le compte du Client le service convenu entre les parties.\n\n## ARTICLE 2 — DURÉE\n\nLe présent contrat prend effet à la date de signature et se termine à la date convenue.\n\n## ARTICLE 3 — OBLIGATIONS DU PRESTATAIRE\n\n- Réaliser la mission avec diligence\n- Livrer les livrables dans les délais\n- Respecter la confidentialité\n\n## ARTICLE 4 — RÉMUNÉRATION\n\nLe montant et les modalités de paiement sont ceux convenus entre les parties.\n\n## ARTICLE 5 — CONFIDENTIALITÉ\n\nChaque partie s'engage à garder confidentielles toutes les informations échangées.\n\n## ARTICLE 6 — PROPRIÉTÉ INTELLECTUELLE\n\nÀ complet paiement, le Client devient propriétaire des livrables produits.\n\n## ARTICLE 7 — RÉSILIATION\n\nEn cas de manquement grave, résiliation après mise en demeure de 15 jours.\n\n## ARTICLE 8 — LOI APPLICABLE\n\nDroit tunisien. Juridiction compétente : tribunaux de Tunis.\n\n---\n\nFait à Tunis, le ____________________\n\n**Le Prestataire** | **Le Client**\n\n_Signature :_ _________________ | _Signature :_ _________________\n\n---\n⚠️ *Ce contrat est un modèle généré automatiquement. Une relecture par un professionnel du droit est recommandée avant signature.*`;

    // Réponse FAQ par défaut
    } else {
      reply = `Bonjour ! Je suis l'assistant juridique IDEAL.\n\nJe peux vous aider à :\n- 📄 **Rédiger un contrat** (prestation, vente, location, emploi...)\n- ❓ **Répondre à vos questions** sur l'application\n\nComment puis-je vous aider ?`;
    }

    return { reply, provider: 'mock' };
  }
}
