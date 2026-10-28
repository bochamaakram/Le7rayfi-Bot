# le7raifiBot Mini V1 — PWA Le7rayfi

Démonstrateur de robot de table bilingue (FR/AR) construit autour d'un smartphone
Android NFC existant. Cette application est une **Progressive Web App** autonome :
réponses locales, voix expérimentale, lecture/écriture NFC, QR de secours,
import/export JSON et fonctionnement hors ligne.

> **Statut : démonstrateur non certifié.** Toutes les fiches et tous les profils
> sont marqués **DONNÉES FICTIVES — DÉMONSTRATION**. Aucune disponibilité, qualification
> ou partenariat réel n'est affirmé. Ne jamais publier de données personnelles ou de
> secrets dans ce dossier public.

---

## 1. Contenu du dossier

| Fichier | Fonction |
|---|---|
| `index.html` | Écran principal : visage animé, questions, fiche artisan, NFC, QR |
| `style.css` | Design adaptatif, mode sombre, interface FR/AR et RTL |
| `app.js` | Recherche locale, voix, NFC, QR, import/export/synchronisation |
| `knowledge.json` | Base de connaissances locale complète (85 fiches détaillées FR + AR + Darija) |
| `sw.js` | Service worker et cache hors ligne |
| `manifest.webmanifest` | Installation sur l'écran d'accueil Android |
| `assets/` | Icônes PWA, favicon, QR site et QR fiche démo |
| `README.md` | Ce document |

Aucune bibliothèque externe, aucun CDN, aucune clé API n'est utilisée.

---

## 2. Démarrage local

```bash
cd le7raifiBot_Mini_V1
python3 -m http.server 8080
```

Ouvrir <http://localhost:8080>. Le service worker et l'installation PWA fonctionnent
sur `localhost`. **Web NFC ne fonctionne que sur Chrome Android en HTTPS** (ou sur
localhost dans de rares configurations), avec NFC activé et téléphone déverrouillé.

Pour tester sans serveur : ouvrir `index.html` directement fonctionne pour l'interface,
mais ni le service worker, ni le mode hors ligne, ni la synchronisation ne seront
disponibles correctement.

---

## 3. Déploiement sur Plesk

1. Créer le sous-domaine de démonstration (exemple : `bot.le7rayfi.com`).
2. Vérifier l'enregistrement DNS `A`/`CNAME` et attendre la propagation.
3. Activer **HTTPS** avec un certificat TLS valide (obligatoire pour PWA et Web NFC).
4. Téléverser **le contenu** de ce dossier dans le répertoire public du sous-domaine,
   en conservant `index.html` à la racine et le dossier `assets/`.
5. Ne pas écraser le site principal Le7rayfi. Sauvegarder la version précédente.
6. Ouvrir l'URL en HTTPS sur ordinateur puis sur Chrome Android.
7. Vérifier l'affichage des icônes, du manifest, du JSON et des deux QR.
8. Si Plesk ne sert pas correctement le manifest, ajouter le type MIME
   `application/manifest+json` pour `.webmanifest`.

**Ne jamais publier** : mots de passe, jetons, exports clients, données personnelles,
fichiers de sauvegarde non destinés au public.

---

## 4. Installation PWA sur Android

1. Connecter le téléphone au Wi-Fi et ouvrir l'URL HTTPS dans Chrome.
2. Laisser la page et `knowledge.json` se charger complètement.
3. Menu Chrome → **Installer l'application** (ou « Ajouter à l'écran d'accueil »).
4. Lancer le7raifiBot depuis son icône.
5. Tester le **mode Avion** : fermer puis rouvrir l'application et poser une question
   déjà connue. Les réponses locales doivent rester disponibles.
6. Pour la démonstration : verrouiller l'orientation portrait, régler la luminosité,
   désactiver les notifications personnelles, utiliser un profil Android dédié,
   et prévoir un chargeur/câble de secours.

> Une mise à jour du cache peut nécessiter une réinstallation ou un rechargement.
> Voir la section 9.

---

## 5. NFC et QR

### Écrire une carte

1. Activer NFC sur Android, déverrouiller le téléphone.
2. Ouvrir le7raifiBot **en HTTPS dans Chrome** et garder la page au premier plan.
3. Appuyer sur **Écrire NFC**, accepter la permission du navigateur.
4. Approcher une carte NTAG213 vierge de l'antenne NFC du téléphone.
5. L'URL écrite est construite à partir de l'adresse réelle ouverte :
   `https://votre-domaine/?artisan=ART-DEMO-01`.

### Lire une carte

1. Appuyer sur **Lire NFC**, puis approcher la carte.
2. La fiche fictive correspondante s'affiche.
3. Si Web NFC n'est pas disponible : utiliser **QR** → onglet **Fiche démo** →
   **Afficher la fiche démo (simulation)**.

### Limites de sécurité

- Une carte NTAG213 classique peut être copiée : elle **ouvre une fiche**, elle ne
  certifie pas un artisan et n'autorise aucune administration.
- La carte ne contient qu'une URL ou un identifiant, jamais un dossier complet, un
  mot de passe, un jeton ou des données bancaires.
- Web NFC est expérimental et dépend de Chrome Android + HTTPS + matériel compatible.
- Le QR fourni (`assets/qr-le7rayfi.png`) pointe vers <https://www.le7rayfi.com/>.
  Le QR de démonstration (`assets/qr-demo.png`) pointe vers l'exemple
  `https://bot.le7rayfi.com/?artisan=ART-DEMO-01` : **remplacez-le après déploiement**
  si votre domaine diffère.

Régénérer un QR avec Python (le paquet `qrcode` est optionnel, hors application) :

```python
import qrcode
qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M,
                   box_size=12, border=3)
qr.add_data("https://VOTRE-DOMAINE/?artisan=ART-DEMO-01")
qr.make_image(fill_color="#0b1b20", back_color="#f7ecd7").resize((512, 512)).save(
    "assets/qr-demo.png")
```

---

## 6. Base de connaissances

Structure attendue :

```json
{
  "version": "1.1",
  "updated": "2026-10-23",
  "items": [
    {
      "id": "heritage-sud",
      "keywords": ["artisanat", "patrimoine", "metiers du Sud"],
      "fr": "Le7rayfi valorise les savoir-faire des artisans.",
      "ar": "إجابة عربية تم التحقق منها من الفريق."
    }
  ]
}
```

Règles contrôlées par l'application :

- 200 fiches maximum ;
- 35 mots-clés maximum par fiche (les doublons sont retirés) ;
- 180 000 octets maximum pour un fichier importé ou synchronisé ;
- `id`, `keywords`, `fr` et `ar` obligatoires ; texte non vide ;
- JSON valide, encodage UTF-8.

La recherche compare les mots-clés normalisés (accents, diacritiques arabes, article
défini et suffixes simples). Une question inconnue affiche un message prudent :
**aucune adresse, disponibilité ou qualification n'est inventée**.

### Modifier / importer / exporter

1. Éditer `knowledge.json` avec un éditeur UTF-8 et conserver un JSON valide.
2. Dans **Options** : **Importer JSON** charge un fichier local, **Exporter JSON**
   télécharge une sauvegarde.
3. La base importée/synchronisée est stockée dans `localStorage` et reste prioritaire
   après redémarrage. **Revenir à la base fournie** supprime cette copie locale.
4. Pour une synchronisation : saisir une URL **HTTPS** publique dans **Options**, puis
   **Synchroniser**. Le fichier doit être accessible en CORS.
5. Tester toutes les questions dans les deux langues après chaque mise à jour.

Le prototype ne se connecte pas à la base MySQL Le7rayfi et n'ouvre aucun espace
authentifié. La synchronisation ne récupère qu'un fichier JSON public statique.

---

## 7. Voix et langues

- Lecture vocale : synthèse vocale d'Android (`speechSynthesis`), selon les voix
  installées. Arabe et français sont séparés.
- Micro : reconnaissance vocale du navigateur (`SpeechRecognition`), expérimentale.
  Elle peut nécessiter Internet et n'est pas garantie hors ligne.
- Hassania : **non garantie en V1** ; prévue en V1.1 avec des locuteurs natifs et des
  textes validés.
- Solution fiable devant le jury : questions suggérées à l'écran, réponse tactile,
  QR et NFC. Le texte reste toujours disponible.

---

## 8. Scénario de démonstration (3 minutes)

| Temps | Action | Ce que le jury constate |
|---|---|---|
| 0:00–0:20 | Présenter le7raifiBot et les artisans du Sud | Identité locale et problème ciblé |
| 0:20–0:55 | Poser une question en français | Réponse locale claire |
| 0:55–1:25 | Passer en arabe, question sur l'artisanat | Bilinguisme et RTL |
| 1:25–1:55 | Lire `ART-DEMO-01` (NFC) ou scanner le QR | Lien objet physique / numérique |
| 1:55–2:25 | Activer le mode Avion et reposer une question | Persistance locale vérifiée |
| 2:25–3:00 | Montrer la feuille de route et les partenaires visés | Passage du prototype au pilote |

Plan de secours : captures d'écran, QR imprimé, carte NFC programmée + carte vierge,
copie locale du dossier, chargeur et câble de réserve.

---

## 9. Mise à jour et cache

Après modification des fichiers :

1. Incrémenter `CACHE_VERSION` dans `sw.js` (ex. `le7raifiBot-v1.1.1`).
2. Redéployer les fichiers.
3. Rouvrir l'application en ligne, attendre le message de mise à jour, recharger.
4. Tester à nouveau le mode Avion et les questions locales.

Si l'ancienne version persiste : fermer l'application, vider le cache du site dans
Chrome, ou réinstaller la PWA. Conserver toujours la version précédente pour revenir
en arrière.

---

## 10. Fiche de recette rapide

| Test | Critère | OK / KO |
|---|---|---|
| Visage animé | Animation visible, sans artefact | ☐ |
| Interface FR | Textes lisibles en français | ☐ |
| Interface AR | Direction RTL, textes corrects | ☐ |
| Recherche connue | Bonne réponse locale | ☐ |
| Recherche inconnue | Message prudent, sans invention | ☐ |
| Mode hors ligne | Question connue après mode Avion | ☐ |
| NFC | Lecture/écriture si appareil compatible | ☐ |
| QR | Ouverture du lien voulu | ☐ |
| Synchronisation | Import d'un JSON HTTPS valide | ☐ |
| Sauvegarde | Export JSON téléchargé | ☐ |
| Fixation | Téléphone stable et extractible | ☐ |
| Sécurité | Pas de surchauffe après test prolongé | ☐ |

Noter à chaque correction : date, fichier ou composant modifié, version, résultat du
test et responsable.

---

## 11. Dépannage

| Problème | Cause probable | Action |
|---|---|---|
| PWA ne s'installe pas | HTTP, manifest mal servi, erreur SW | Vérifier HTTPS, fichiers, Chrome, recharger |
| Mode Avion inopérant | Cache absent ou ancien | Ouvrir en ligne, attendre, retester |
| NFC ne répond pas | NFC désactivé, page non HTTPS, permission | Activer NFC, déverrouiller, Chrome HTTPS |
| Tag lu mais fiche absente | Mauvais NDEF ou identifiant | Réécrire avec `ART-DEMO-01` |
| Lecture NFC difficile | Coque épaisse, antenne mal placée | Repérer l'antenne, rapprocher la carte |
| QR ne correspond pas | QR général du site | Utiliser le QR démo ou en générer un |
| Voix absente | Voix/API indisponible | Utiliser le texte, installer une voix |
| Mise à jour invisible | Base importée prioritaire ou cache | Importer la nouvelle base, changer la version du cache |
| Robot bascule | Base légère, tête haute | Renforcer la base, abaisser le centre de gravité |
| Téléphone chauffe | Ventilation insuffisante, batterie | Arrêter, refroidir, revoir le boîtier et la charge |

---

## 12. Sécurité et limites

- Ne pas modifier la batterie du téléphone, ne pas souder de fils, ne pas charger un
  appareil endommagé.
- Ne pas bloquer la ventilation ; contrôler la température après 20 puis 60 minutes.
- Aucun bord coupant ni câble tendu accessible au public ; protéger de l'humidité.
- Ne pas laisser l'appareil en charge 24 h/24 sans surveillance adaptée.
- Le code HTML/JS, le JSON et les cartes NFC sont publics et copiables :
  **aucun secret ne doit y figurer**.
- Les réponses restent des contenus de démonstration à valider avec des artisans,
  associations et référents locaux avant tout usage public.

---

*Le7rayfi — le7raifiBot Mini V1 — Guide du 23 octobre 2026.*
