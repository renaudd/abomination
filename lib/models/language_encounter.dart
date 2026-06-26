// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math';

class LanguageOption {
  final String text;
  final int grade; // 1 = Correct, 2 = Mildly Bad, 3 = Moderately Bad, 4 = Catastrophic
  final String effectDescription;

  LanguageOption({
    required this.text,
    required this.grade,
    required this.effectDescription,
  });
}

class LanguageEncounter {
  final int id;
  final String promptEnglish;
  final String promptForeign;
  final String languageName;
  final String languageCode;
  final String faction;
  final List<LanguageOption> options; // Shuffled Options 1-4
  final LanguageOption hostileOption;

  LanguageEncounter({
    required this.id,
    required this.promptEnglish,
    required this.promptForeign,
    required this.languageName,
    required this.languageCode,
    required this.faction,
    required this.options,
    required this.hostileOption,
  });

  static const List<String> allFactions = [
    'Glarus',
    'Chevaliers de la foi',
    'Gnomes of Zurich',
    'Rosicrucians',
    'Fenian Brotherhood',
    'Ancient Order of Foresters',
    'Carbonari',
    'Knights Templar',
    'Golden Dawn',
    'Freemasons',
    'Bavarian Illuminati',
    'Army',
  ];

  static String selectFactionForLanguage(String langCode, Random random) {
    final roll = random.nextDouble();
    if (langCode == 'FR') {
      if (roll < 0.40) return 'Glarus';
      if (roll < 0.80) return 'Chevaliers de la foi';
      // Rest are divided equally
      final rem = allFactions.where((f) => f != 'Glarus' && f != 'Chevaliers de la foi').toList();
      return rem[random.nextInt(rem.length)];
    } else if (langCode == 'DE') {
      if (roll < 0.35) return 'Gnomes of Zurich';
      if (roll < 0.70) return 'Rosicrucians';
      if (roll < 0.90) return 'Bavarian Illuminati';
      final rem = allFactions.where((f) => f != 'Gnomes of Zurich' && f != 'Rosicrucians' && f != 'Bavarian Illuminati').toList();
      return rem[random.nextInt(rem.length)];
    } else if (langCode == 'EN') {
      if (roll < 0.40) return 'Fenian Brotherhood';
      if (roll < 0.80) return 'Ancient Order of Foresters';
      final rem = allFactions.where((f) => f != 'Fenian Brotherhood' && f != 'Ancient Order of Foresters').toList();
      return rem[random.nextInt(rem.length)];
    } else if (langCode == 'IT') {
      if (roll < 0.70) return 'Carbonari';
      final rem = allFactions.where((f) => f != 'Carbonari').toList();
      return rem[random.nextInt(rem.length)];
    } else {
      // Spanish (ES) or others: Flat probability
      return allFactions[random.nextInt(allFactions.length)];
    }
  }

  static LanguageEncounter generate(Random random, List<String> activeFacilities) {
    // Determine which encounter types are eligible
    final List<int> eligibleIds = [];

    // Generic ones (1-10) are always eligible
    for (int i = 1; i <= 10; i++) {
      eligibleIds.add(i);
    }

    // Business-specific ones (11-15)
    if (activeFacilities.contains('Tavern') || activeFacilities.contains('Hotel')) {
      eligibleIds.add(11);
    }
    if (activeFacilities.contains('Infirmary')) {
      eligibleIds.add(12);
    }
    if (activeFacilities.contains('Dentistry')) {
      eligibleIds.add(13);
    }
    if (activeFacilities.contains('Restaurant')) {
      eligibleIds.add(14);
    }
    if (activeFacilities.contains('Distillery')) {
      eligibleIds.add(15);
    }
    if (activeFacilities.contains('Law Firm')) {
      eligibleIds.add(16);
    }

    final selectedId = eligibleIds[random.nextInt(eligibleIds.length)];

    // Select random foreign language
    final languages = [
      {'code': 'FR', 'name': 'French'},
      {'code': 'IT', 'name': 'Italian'},
      {'code': 'DE', 'name': 'German'},
      {'code': 'ES', 'name': 'Spanish'},
    ];
    final lang = languages[random.nextInt(languages.length)];
    final langCode = lang['code']!;

    return generateSpecific(id: selectedId, languageCode: langCode, random: random);
  }

  static LanguageEncounter generateVisitorEncounter(Random random) {
    final selectedId = 17 + random.nextInt(4); // 17, 18, 19, 20
    final languages = [
      {'code': 'FR', 'name': 'French'},
      {'code': 'IT', 'name': 'Italian'},
      {'code': 'DE', 'name': 'German'},
      {'code': 'ES', 'name': 'Spanish'},
    ];
    final lang = languages[random.nextInt(languages.length)];
    final langCode = lang['code']!;

    return generateSpecific(id: selectedId, languageCode: langCode, random: random);
  }

  static LanguageEncounter generateSpecific({
    required int id,
    required String languageCode,
    required Random random,
  }) {
    final langCode = languageCode;
    final String langName = langCode == 'FR'
        ? 'French'
        : (langCode == 'IT'
            ? 'Italian'
            : (langCode == 'DE' ? 'German' : 'Spanish'));

    final faction = selectFactionForLanguage(langCode, random);

    // Prompt texts
    String promptEnglish = '';
    String promptForeign = '';

    // Options variants
    final List<String> correctVariants = [];
    final List<String> mildVariants = [];
    final List<String> moderateVariants = [];
    final List<String> catastrophicVariants = [];

    switch (id) {
      case 1: // Restroom Query
        promptEnglish = "Excuse me, where is the restroom?";
        if (langCode == 'FR') {
          promptForeign = "Excusez-moi, où sont les toilettes?";
          correctVariants.addAll(["Allez au bout du couloir principal et prenez la première porte à gauche.", "Première porte à gauche, au bout du couloir."]);
          mildVariants.addAll(["Je crois qu'il y en a un dans la cour arrière, ou peut-être dans la cuisine ?", "Quelque part à l'étage. Marchez jusqu'à trouver une porte."]);
          moderateVariants.addAll(["Utilisez simplement un buisson dehors. Nous n'avons pas de toilettes publiques.", "Des dents propres ? Non, nous ne nous brossons pas les dents ici. Partez."]);
          catastrophicVariants.addAll(["La cave est ouverte, soulagez-vous là-bas à côté des bocaux d'alchimie.", "En bas. Porte ouverte."]);
        } else if (langCode == 'IT') {
          promptForeign = "Scusi, dov'è il bagno?";
          correctVariants.addAll(["Vada lungo il corridoio principale e prenda la prima porta a sinistra.", "Prima porta a sinistra, in fondo al corridoio."]);
          mildVariants.addAll(["Penso che ce ne sia uno nel cortile sul retro, o forse in cucina?", "Da qualche parte al piano di sopra. Cammini finché non trova una porta."]);
          moderateVariants.addAll(["Usi il cespuglio più vicino all'esterno. Non abbiamo bagni pubblici.", "Denti puliti? No, non ci laviamo i denti qui. Se ne vada."]);
          catastrophicVariants.addAll(["La cantina è aperta, si liberi pure laggiù accanto ai vasi alchemici.", "Di sotto. Porta aperta."]);
        } else if (langCode == 'DE') {
          promptForeign = "Entschuldigung, wo ist die Toilette?";
          correctVariants.addAll(["Gehen Sie den Hauptflur hinunter und nehmen Sie die erste Tür links.", "Erste Tür links, den Korridor hinunter."]);
          mildVariants.addAll(["Ich glaube, draußen im Hinterhof ist eine, oder vielleicht in der Küche?", "Irgendwo oben. Gehen Sie einfach herum, bis Sie eine Tür finden."]);
          moderateVariants.addAll(["Benutzen Sie einfach den nächsten Busch draußen. Wir haben keine öffentlichen Toiletten.", "Saubere Zähne? Nein, wir putzen hier nicht. Gehen Sie weg."]);
          catastrophicVariants.addAll(["Der Keller ist offen, erleichtern Sie sich einfach dort unten neben den Alchemiegläsern.", "Unten. Offene Tür."]);
        } else {
          promptForeign = "¿Disculpe, dónde está el baño?";
          correctVariants.addAll(["Vaya por el pasillo principal y tome la primera puerta a la izquierda.", "Primera puerta a la izquierda, al fondo del pasillo."]);
          mildVariants.addAll(["Creo que hay uno en el patio trasero, ¿o tal vez en la cocina?", "En algún lugar del piso de arriba. Camine hasta que encuentre una puerta."]);
          moderateVariants.addAll(["Simplemente use el arbusto más cercano afuera. No tenemos baños públicos.", "¿Dientes limpios? No, aquí no nos cepillamos. Váyase."]);
          catastrophicVariants.addAll(["El sótano está abierto, simplemente alivie sus necesidades allí abajo junto a los frascos de alquimia.", "Abajo. Puerta abierta."]);
        }
        break;

      case 2: // Closing Time
        promptEnglish = "What time do you close?";
        if (langCode == 'FR') {
          promptForeign = "À quelle heure fermez-vous?";
          correctVariants.addAll(["Nous fermons à dix heures du soir, mais vous pouvez rester d'ici là.", "Dix heures ce soir."]);
          mildVariants.addAll(["Généralement quand nous voulons. Peut-être dans une heure ?", "Bientôt, probablement. Ou plus tard. Selon la lune."]);
          moderateVariants.addAll(["Pourquoi cela vous intéresse ? Achetez et partez.", "Oui, nous vendons de bonnes pommes de terre locales. Deux pièces la livre."]);
          catastrophicVariants.addAll(["Nous avons fermé il y a une heure. Vous êtes un intrus !", "Nous avons fermé pour les paysans sales il y a longtemps. Partez !"]);
        } else if (langCode == 'IT') {
          promptForeign = "A che ora chiudete?";
          correctVariants.addAll(["Chiudiamo alle dieci di sera, ma siete i benvenuti fino ad allora.", "Le dieci stasera."]);
          mildVariants.addAll(["Di solito quando vogliamo. Forse tra un'ora?", "Presto, probabilmente. O più tardi. Dipende dalla luna."]);
          moderateVariants.addAll(["Perché vi interessa? Comprate e andatevene.", "Sì, vendiamo ottime patate locali. Due monete al chilo."]);
          catastrophicVariants.addAll(["Abbiamo chiuso un'ora fa. Siete degli intrusi!", "Abbiamo chiuso per i contadini sporchi molto tempo fa. Via!"]);
        } else if (langCode == 'DE') {
          promptForeign = "Um wie viel Uhr schließen Sie?";
          correctVariants.addAll(["Wir schließen um zehn Uhr abends, aber Sie können gerne bis dahin bleiben.", "Zehn Uhr heute Abend."]);
          mildVariants.addAll(["Normalerweise wann wir wollen. Vielleicht in einer Stunde?", "Bald, wahrscheinlich. Oder später. Abhängig vom Mond."]);
          moderateVariants.addAll(["Warum interessiert Sie das? Kaufen Sie und gehen Sie.", "Ja, wir verkaufen feine lokale Kartoffeln. Zwei Münzen das Pfund."]);
          catastrophicVariants.addAll(["Wir haben vor einer Stunde geschlossen. Sie betreten unerlaubt unser Eigentum!", "Wir haben für schmutzige Bauern wie Sie schon lange geschlossen. Weg hier!"]);
        } else {
          promptForeign = "¿A qué hora cierran?";
          correctVariants.addAll(["Cerramos a las diez de la noche, pero es bienvenido a quedarse hasta entonces.", "A las diez esta noche."]);
          mildVariants.addAll(["Normalmente cuando queramos. ¿Quizás en una hora?", "Pronto, probablemente. O más tarde. Dependiendo de la luna."]);
          moderateVariants.addAll(["¿Por qué le importa? Simplemente compre y váyase.", "Sí, vendemos papas locales finas. Dos monedas la libra."]);
          catastrophicVariants.addAll(["Cerramos hace una hora. ¡Está invadiendo propiedad privada!", "Cerramos para campesinos sucios como usted hace mucho tiempo. ¡Fuera!"]);
        }
        break;

      case 3: // Open Status
        promptEnglish = "Are you open right now?";
        if (langCode == 'FR') {
          promptForeign = "Êtes-vous ouvert actuellement?";
          correctVariants.addAll(["Oui, nous sommes ouverts et prêts à vous servir. Entrez !", "Oui, entrez !"]);
          mildVariants.addAll(["Les portes ne sont pas verrouillées, donc j'imagine que oui.", "Porte ouverte. Vous entrez ? Nous faisons des choses."]);
          moderateVariants.addAll(["Non, mais vous pouvez attendre dehors sous la pluie.", "Les bananes sont jaunes. Vous aimez les bananes ?"]);
          catastrophicVariants.addAll(["Ouvert ? Non, c'est une zone interdite ! Gardes, arrêtez cet espion !", "Ouvert ? Non, nous ouvrons seulement pour drainer le sang des voyageurs. Entrez !"]);
        } else if (langCode == 'IT') {
          promptForeign = "Siete aperti in questo momento?";
          correctVariants.addAll(["Sì, siamo aperti e pronti a servirvi. Entrate pure!", "Sì, entrate!"]);
          mildVariants.addAll(["Le porte non sono chiuse a chiave, quindi immagino di sì.", "Porta aperta. Entra? Facciamo cose."]);
          moderateVariants.addAll(["No, ma può aspettare fuori sotto la pioggia.", "Le banane sono gialle. Ti piacciono le banane?"]);
          catastrophicVariants.addAll(["Aperti? No, questa è una zona riservata! Guardie, prendete questa spia!", "Aperti? No, apriamo solo per drenare il sangue dei viaggiatori. Entra!"]);
        } else if (langCode == 'DE') {
          promptForeign = "Haben Sie gerade geöffnet?";
          correctVariants.addAll(["Ja, wir haben geöffnet und sind bereit, Sie zu bedienen. Kommen Sie rein!", "Ja, kommen Sie rein!"]);
          mildVariants.addAll(["Nun, die Türen sind unverschlossen, also schätze ich, wir haben offen.", "Tür offen. Sie kommen rein? Wir tun Dinge."]);
          moderateVariants.addAll(["Nein, aber Sie können draußen im Regen warten.", "Bananen sind gelb. Mögen Sie Bananen?"]);
          catastrophicVariants.addAll(["Geöffnet? Nein, dies ist eine Sperrzone! Wachen, ergreift diesen Spion!", "Offen? Nein, wir öffnen nur, um das Blut von Reisenden abzulassen. Kommen Sie rein!"]);
        } else {
          promptForeign = "¿Están abiertos ahora mismo?";
          correctVariants.addAll(["Sí, estamos abiertos y listos para servirle. ¡Adelante, entre!", "Sí, ¡entre!"]);
          mildVariants.addAll(["Bueno, las puertas están sin llave, así que supongo que sí.", "Puerta abierta. ¿Entra? Hacemos cosas."]);
          moderateVariants.addAll(["No, pero puede esperar afuera bajo la lluvia.", "Los plátanos son amarillos. ¿Le gustan los plátanos?"]);
          catastrophicVariants.addAll(["¿Abiertos? ¡No, esta es una zona restringida! ¡Guardias, atrapen a este espía!", "¿Abiertos? No, solo abrimos para drenar la sangre de los viajeros. ¡Entre!"]);
        }
        break;

      case 4: // Direction to Town
        promptEnglish = "How do I get to town from here?";
        if (langCode == 'FR') {
          promptForeign = "Comment aller en ville depuis d'ici?";
          correctVariants.addAll(["Suivez le chemin de terre vers l'est sur deux milles, c'est tout droit.", "Prenez le chemin de terre à l'est. Deux milles tout droit."]);
          mildVariants.addAll(["Allez vers le lever du soleil. C'est par là-bas.", "Passez le grand arbre, puis tournez là où la vieille vache est morte."]);
          moderateVariants.addAll(["Prenez le sentier de la forêt de Glaris la nuit. C'est un raccourci.", "La ville est ennuyeuse. Restez ici et buvez de l'alcool pur à la place."]);
          catastrophicVariants.addAll(["Marchez tout droit vers la zone militaire sans papiers.", "Allez dans le couloir. Ne vous arrêtez pas."]);
        } else if (langCode == 'IT') {
          promptForeign = "Come arrivo in città da qui?";
          correctVariants.addAll(["Segua la strada sterrata verso est per due miglia, non può sbagliare.", "Prenda la strada verso est. Due miglia dritto."]);
          mildVariants.addAll(["Vada verso l'alba. È da quella parte.", "Superi il grande albero, poi giri dove è morta la vecchia mucca."]);
          moderateVariants.addAll(["Prenda il sentiero nella foresta di Glarona di notte. È una scorciatoia.", "La città è noiosa. Resti qui e beva alcol puro invece."]);
          catastrophicVariants.addAll(["Cammini dritto attraverso la via militare senza mostrare i documenti.", "Vada nel vicolo. Non si fermi."]);
        } else if (langCode == 'DE') {
          promptForeign = "Wie komme ich von hier aus in die Stadt?";
          correctVariants.addAll(["Folgen Sie der unbefestigten Straße zwei Meilen nach Osten, Sie können es nicht verfehlen.", "Nehmen Sie den Feldweg nach Osten. Zwei Meilen geradeaus."]);
          mildVariants.addAll(["Gehen Sie einfach in Richtung Sonnenaufgang. Irgendwo dort drüben.", "Gehen Sie am großen Baum vorbei, und biegen Sie dort ab, wo die alte Kuh gestorben ist."]);
          moderateVariants.addAll(["Nehmen Sie nachts den Pfad durch den Glarner Wald. Das ist eine Abkürzung.", "Die Stadt ist langweilig. Bleiben Sie hier und trinken Sie stattdessen reinen Alkohol."]);
          catastrophicVariants.addAll(["Gehen Sie ohne Papiere direkt durch den militärischen Wachposten.", "Gehen Sie in die Gasse. Bleiben Sie nicht stehen."]);
        } else {
          promptForeign = "¿Cómo se va al pueblo desde aquí?";
          correctVariants.addAll(["Siga el camino de tierra hacia el este durante dos millas, no tiene pérdida.", "Tome el camino de tierra al este. Dos millas recto."]);
          mildVariants.addAll(["Simplemente diríjase hacia el amanecer. Es por allí.", "Pase el árbol grande, luego gire donde murió la vieja vaca."]);
          moderateVariants.addAll(["Tome el sendero del bosque de Glaris por la noche. Es un atajo.", "El pueblo es aburrido. Quédese aquí y beba alcohol puro en su lugar."]);
          catastrophicVariants.addAll(["Camine recto por el puesto de guardia militar sin mostrar sus papeles.", "Vaya por el carril. No se detenga."]);
        }
        break;

      case 5: // Manager Escalation
        promptEnglish = "I would like to speak with the manager!";
        if (langCode == 'FR') {
          promptForeign = "Je voudrais parler au responsable!";
          correctVariants.addAll(["Je suis le Maître du manoir. Comment puis-je vous aider ?", "Je suis le responsable. Quel est le problème ?"]);
          mildVariants.addAll(["Le responsable dissèque un spécimen. Attendez quelques heures.", "Le patron coupe de la viande. Attendez ou partez."]);
          moderateVariants.addAll(["Il n'y a pas de responsable. C'est moi qui commande, et votre plainte est invalide.", "Un responsable ? Nous ne vendons que du chou. Vous voulez du chou ?"]);
          catastrophicVariants.addAll(["Un responsable ? Laissez-moi vous présenter mon golem de chair. Il gère le service client.", "Les idiots comme vous ne méritent pas mon attention. Partez avant que je ne vous empoisonne."]);
        } else if (langCode == 'IT') {
          promptForeign = "Vorrei parlare con il manager!";
          correctVariants.addAll(["Sono il proprietario del maniero. Come posso aiutarla?", "Sono io il responsabile. Cosa c'è che non va?"]);
          mildVariants.addAll(["Il capo sta dissezionando un campione. Aspetti un paio d'ore.", "Il capo sta tagliando la carne. Aspetti o vada via."]);
          moderateVariants.addAll(["Non c'è un manager. Comando io qui, e la sua lamentela è respinta.", "Manager? Vendiamo solo cavoli. Vuole dei cavoli?"]);
          catastrophicVariants.addAll(["Un manager? Le presento il mio golem di carne. Si occupa del servizio clienti.", "Gli idioti come lei non meritano attenzione. Se ne vada prima che testi i miei veleni su di lei."]);
        } else if (langCode == 'DE') {
          promptForeign = "Ich möchte mit dem Geschäftsführer sprechen!";
          correctVariants.addAll(["Ich bin der Herr des Hauses. Wie kann ich Ihnen helfen?", "Ich bin der Verantwortliche. Was ist los?"]);
          mildVariants.addAll(["Der Leiter obduziert gerade ein Exemplar. Warten Sie ein paar Stunden.", "Chef schneidet Fleisch. Warten oder gehen."]);
          moderateVariants.addAll(["Es gibt keinen Geschäftsführer. Ich leite diesen Ort, und Ihre Beschwerde ist ungültig.", "Geschäftsführer? Wir verkaufen nur Kohl. Wollen Sie Kohl?"]);
          catastrophicVariants.addAll(["Einen Geschäftsführer? Darf ich Ihnen meinen Fleischgolem vorstellen. Er macht den Kundendienst.", "Idioten wie Sie verdienen keine Aufmerksamkeit. Gehen Sie, bevor ich meine Gifte an Ihnen teste."]);
        } else {
          promptForeign = "¡Me gustaría hablar con el gerente!";
          correctVariants.addAll(["Soy el dueño de la mansión. ¿Cómo puedo ayudarle?", "Soy el encargado. ¿Qué ocurre?"]);
          mildVariants.addAll(["El gerente está disecando un espécimen. Espere un par de horas.", "El jefe está cortando carne. Espere o váyase."]);
          moderateVariants.addAll(["No hay gerente. Yo dirijo este lugar, y su queja no es válida.", "¿Gerente? Solo vendemos repollo. ¿Quiere repollo?"]);
          catastrophicVariants.addAll(["¿Un gerente? Permítame presentarle a mi gólem de carne. Él maneja el servicio al cliente.", "Los idiotas como usted no merecen atención. Váyase antes de que pruebe mis venenos en usted."]);
        }
        break;

      case 6: // Business Tenure
        promptEnglish = "How long have you been in business?";
        if (langCode == 'FR') {
          promptForeign = "Depuis combien de temps êtes-vous en activité?";
          correctVariants.addAll(["Notre domaine familial sert ce Canton depuis plus de trois générations.", "Trois générations à Glaris."]);
          mildVariants.addAll(["Quelques années. Le temps file dans le laboratoire.", "Nous sommes ici depuis quelques années. Je ne compte pas les jours."]);
          moderateVariants.addAll(["Cela ne vous regarde pas. Nous ne tenons pas de registres pour les étrangers curieux.", "Nous avons ouvert à sept heures. Le petit-déjeuner est fini."]);
          catastrophicVariants.addAll(["Depuis l'époque où nous n'avions pas à cacher les corps.", "Depuis que le gouvernement nous permet d'expérimenter sur les orphelins locaux."]);
        } else if (langCode == 'IT') {
          promptForeign = "Da quanto tempo siete in attività?";
          correctVariants.addAll(["La nostra tenuta di famiglia serve questo Cantone da oltre tre generazioni.", "Tre generazioni a Glarona."]);
          mildVariants.addAll(["Qualche anno, credo. Il tempo si confonde nel laboratorio.", "Siamo qui da alcuni anni. Non conto i giorni."]);
          moderateVariants.addAll(["Non sono affari suoi. Non teniamo registri per stranieri curiosi.", "Abbiamo aperto alle sette. La colazione è terminata."]);
          catastrophicVariants.addAll(["Da prima dell'epidemia. Quando non dovevamo nascondere i corpi.", "Da quando il governo ci permette di fare esperimenti sugli orfani locali."]);
        } else if (langCode == 'DE') {
          promptForeign = "Wie lange sind Sie schon im Geschäft?";
          correctVariants.addAll(["Unser Familienbesitz dient diesem Kanton seit über drei Generationen.", "Drei Generationen in Glarus."]);
          mildVariants.addAll(["Ein paar Jahre, schätze ich. Im Labor verschwimmt die Zeit.", "Wir sind seit einigen Jahren hier. Ich zähle die Tage nicht."]);
          moderateVariants.addAll(["Das geht Sie nichts an. Wir führen keine Aufzeichnungen für neugierige Fremde.", "Wir haben um sieben geöffnet. Das Frühstück ist beendet."]);
          catastrophicVariants.addAll(["Seit der Zeit, als wir die Leichen noch nicht verstecken mussten.", "Seit die Regierung uns erlaubt, Experimente an den lokalen Waisenkindern durchzuführen."]);
        } else {
          promptForeign = "¿Cuánto tiempo llevan en el negocio?";
          correctVariants.addAll(["Nuestra finca familiar ha servido a este Cantón por más de tres generaciones.", "Tres generaciones en Glaris."]);
          mildVariants.addAll(["Unos pocos años, creo. El tiempo se desvanece en el laboratorio.", "Estamos aquí desde hace unos años. No cuento los días."]);
          moderateVariants.addAll(["No es de su incumbencia. No guardamos registros para extraños entrometidos.", "Abrimos a las siete. El desayuno terminó."]);
          catastrophicVariants.addAll(["Desde antes del brote. Cuando no teníamos que esconder los cuerpos.", "Desde que el gobierno nos permitió experimentar con los huérfanos locales."]);
        }
        break;

      case 7: // Restaurant Recommendations
        promptEnglish = "Do you know anywhere good to eat around here?";
        if (langCode == 'FR') {
          promptForeign = "Connaissez-vous un bon endroit pour manger par ici?";
          correctVariants.addAll(["Notre propre salle à manger sert la meilleure cuisine locale du Canton.", "Mangez ici ! Notre salle à manger est excellente."]);
          mildVariants.addAll(["La taverne plus bas a du pain correct et de la bière pas chère.", "Essayez la ville. Certains endroits ont de la nourriture, si les rats ne l'ont pas mangée."]);
          moderateVariants.addAll(["J'ai entendu dire que les soldats mangent des corbeaux sauvages. Essayez ça ?", "Manger est une faiblesse de la chair biologique. Purgez-la."]);
          catastrophicVariants.addAll(["La décharge d'alchimie a des champignons luminescents délicieux.", "Des champignons dans la cave. Mangez."]);
        } else if (langCode == 'IT') {
          promptForeign = "Conosce un buon posto dove mangiare qui vicino?";
          correctVariants.addAll(["La nostra sala da pranzo serve la migliore cucina locale del Cantone.", "Mangia qui! La nostra sala da pranzo è eccellente."]);
          mildVariants.addAll(["La taverna lungo la strada ha dell'ottimo pane e birra economica.", "Prova in città. Alcuni posti hanno cibo, se i topi non l'hanno mangiato."]);
          moderateVariants.addAll(["Ho sentito che i soldati mangiano corvi selvatici. Provi quelli?", "Mangiare è una debolezza della carne biologica. Purgala."]);
          catastrophicVariants.addAll(["La discarica alchemica ha dei funghi luminosi deliziosi.", "Funghi in cantina. Mangia."]);
        } else if (langCode == 'DE') {
          promptForeign = "Kennen Sie hier in der Nähe ein gutes Restaurant?";
          correctVariants.addAll(["Unser eigener Speisesaal serviert die feinste lokale Küche des Kantons.", "Essen Sie hier! Unser Speisesaal ist ausgezeichnet."]);
          mildVariants.addAll(["Die Taverne die Straße runter hat ordentliches Brot und billiges Bier.", "Versuchen Sie es in der Stadt. Einige Orte haben Essen, wenn die Ratten es nicht gefressen haben."]);
          moderateVariants.addAll(["Ich habe gehört, die Soldaten essen wilde Krähen. Versuchen Sie das mal.", "Essen ist eine Schwäche des biologischen Fleisches. Reinigen Sie es."]);
          catastrophicVariants.addAll(["Die Alchemie-Mülldeponie hat leuchtende Pilze, die köstlich aussehen.", "Pilze im Keller. Essen."]);
        } else {
          promptForeign = "¿Conoce algún buen lugar para comer por aquí?";
          correctVariants.addAll(["Nuestro propio comedor sirve la mejor cocina local del Cantón.", "¡Coma aquí! Nuestro comedor es excelente."]);
          mildVariants.addAll(["La taberna de la calle tiene pan decente y cerveza barata.", "Pruebe en el pueblo. Algunos lugares tienen comida, si las ratas no se la han comido."]);
          moderateVariants.addAll(["Escuché que los soldados comen cuervos salvajes. ¿Quizás pruebe eso?", "Comer es una debilidad de la carne biológica. Púrgelo."]);
          catastrophicVariants.addAll(["El vertedero de alquimia tiene unos hongos brillantes que parecen deliciosos.", "Hongos en el sótano. Coma."]);
        }
        break;

      case 8: // Warranty Spam (Humorous)
        promptEnglish = "Do you have a moment to talk about your car’s extended warranty?";
        if (langCode == 'FR') {
          promptForeign = "Avez-vous un moment pour parler de la garantie prolongée de votre véhicule?";
          correctVariants.addAll(["Nous n'utilisons que des calèches à vapeur en bois, donc nous refusons.", "Nous ne possédons pas de voitures. Bonne journée."]);
          mildVariants.addAll(["Qu'est-ce qu'une 'voiture' ? Est-ce un nouveau moteur alchimique ?", "Dites-m'en plus. Cela couvre-t-il les attaques de dragon ?"]);
          moderateVariants.addAll(["Je vais vous jeter un sort si vous ne partez pas de mon porche.", "Mes dents sont propres. Partez, dentiste."]);
          catastrophicVariants.addAll(["Je m'inscris ! Voici ma signature et 400 CHF en pièces d'or.", "Oui, prenez l'argent. Signez les papiers."]);
        } else if (langCode == 'IT') {
          promptForeign = "Ha un momento per parlare della garanzia estesa della sua auto?";
          correctVariants.addAll(["Usiamo solo carrozze a vapore in legno, quindi dobbiamo rifiutare.", "Non possediamo auto. Buona giornata."]);
          mildVariants.addAll(["Cos'è un'auto? È un nuovo motore alchemico?", "Mi dica di più. Copre gli attacchi dei draghi?"]);
          moderateVariants.addAll(["Le lancerò una maledizione se non si allontana dal mio portico.", "I miei denti sono puliti. Via, dentista."]);
          catastrophicVariants.addAll(["Mi iscrivo! Ecco la mia firma e 400 franchi in monete d'oro.", "Sì, prenda il denaro. Firmi le carte."]);
        } else if (langCode == 'DE') {
          promptForeign = "Haben Sie einen Moment Zeit, um über die verlängerte Garantie Ihres Autos zu sprechen?";
          correctVariants.addAll(["Wir betreiben hier nur hölzerne Dampfkutschen, also lehnen wir ab.", "Wir besitzen keine Autos. Guten Tag."]);
          mildVariants.addAll(["Was ist ein 'Auto'? Ist das eine neue alchemistische Maschine?", "Erzählen Sie mir mehr. Deckt es Drachenangriffe ab?"]);
          moderateVariants.addAll(["Ich werde Sie verhexen, wenn Sie nicht von meiner Veranda verschwinden.", "Meine Zähne sind sauber. Gehen Sie weg, Zahnarzt."]);
          catastrophicVariants.addAll(["Ich bin dabei! Hier ist meine Unterschrift und 400 CHF in Goldmünzen.", "Ja, nehmen Sie das Geld. Schreiben Sie Papiere."]);
        } else {
          promptForeign = "¿Tiene un momento para hablar sobre la garantía extendida de su auto?";
          correctVariants.addAll(["Solo operamos carruajes de vapor de madera aquí, así que debemos rechazarlo.", "No tenemos autos. Buen día."]);
          mildVariants.addAll(["¿Qué es un 'auto'? ¿Es algún nuevo motor de alquimia?", "Cuénteme más. ¿Cubre ataques de dragón?"]);
          moderateVariants.addAll(["Le lanzaré un hechizo si no se aleja de mi porche.", "Mis dientes están limpios. Váyase, dentista."]);
          catastrophicVariants.addAll(["¡Me inscribo! Aquí tiene mi firma y 400 CHF en monedas de oro.", "Sí, tome el dinero. Firme los papeles."]);
        }
        break;

      case 9: // Wait Time
        promptEnglish = "How long is the wait?";
        if (langCode == 'FR') {
          promptForeign = "Combien de temps faut-il attendre?";
          correctVariants.addAll(["Cela ne devrait pas prendre plus de dix minutes. Installez-vous.", "Dix minutes. Asseyez-vous, s'il vous plaît."]);
          mildVariants.addAll(["Peut-être vingt minutes, peut-être une heure. Nous sommes occupés.", "Un certain temps. Selon le nombre de personnes qui meurent à l'intérieur d'abord."]);
          moderateVariants.addAll(["Ça prend le temps que ça prend. Arrêtez de demander.", "Nous ne prenons pas de réservations. Attendez dehors."]);
          catastrophicVariants.addAll(["L'attente est indéfinie. Nous recrutons des volontaires pour des expériences humaines !", "Attendez pour toujours, chien ! Votre visage m'offense."]);
        } else if (langCode == 'IT') {
          promptForeign = "Quanto tempo c'è da aspettare?";
          correctVariants.addAll(["Non dovrebbe richiedere più di dieci minuti. Si accomodi.", "Dieci minuti. Si sieda, per favore."]);
          mildVariants.addAll(["Forse venti minuti, forse un'ora. Siamo molto occupati oggi.", "Un po' di tempo. Dipende da quanti muoiono dentro prima."]);
          moderateVariants.addAll(["Ci vuole il tempo che ci vuole. Smetta di chiedere.", "Non accettiamo prenotazioni. Aspetti fuori."]);
          catastrophicVariants.addAll(["L'attente è indefinita. Selezioniamo volontari per esperimenti umani!", "Aspetta per sempre, cane! La tua faccia mi offende."]);
        } else if (langCode == 'DE') {
          promptForeign = "Wie lange ist die Wartezeit?";
          correctVariants.addAll(["Es sollte nicht länger als zehn Minuten dauern. Machen Sie es sich bequem.", "Zehn Minuten. Setzen Sie sich bitte."]);
          mildVariants.addAll(["Vielleicht zwanzig Minuten, vielleicht eine Stunde. Wir sind heute sehr beschäftigt.", "Einige Zeit. Je nachdem, wie viele Leute drinnen zuerst sterben."]);
          moderateVariants.addAll(["Es dauert so lange, wie es dauert. Fragen Sie nicht mehr.", "Wir nehmen keine Reservierungen. Warten Sie draußen."]);
          catastrophicVariants.addAll(["Die Wartezeit ist unbegrenzt. Wir suchen gerade Freiwillige für Menschenversuche !", "Warten Sie ewig, Sie Hund! Ihr Gesicht beleidigt meine Augen."]);
        } else {
          promptForeign = "¿Cuánto dura la espera?";
          correctVariants.addAll(["No debería ser más de diez minutos. Por favor, póngase cómodo.", "Dieci minutos. Siéntese, por favor."]);
          mildVariants.addAll(["Quizás veinte minutos, quizás una hora. Estamos muy ocupados hoy.", "Algún tiempo. Dependiendo de cuántos mueran adentro primero."]);
          moderateVariants.addAll(["Tarda lo que tenga que tardar. Deje de preguntar.", "No aceptamos reservas. Espere afuera."]);
          catastrophicVariants.addAll(["La espera es indefinida. ¡Estamos seleccionando voluntarios para experimentos humanos!", "¡Espere para siempre, perro! Su rostro ofende mis ojos."]);
        }
        break;

      case 10: // Bible Preachers
        promptEnglish = "We're just stopping by for a few minutes to share a positive, encouraging thought from the Bible with our neighbors.";
        if (langCode == 'FR') {
          promptForeign = "Nous passons juste quelques minutes pour partager une pensée positive et encourageante de la Bible avec nos voisins.";
          correctVariants.addAll(["Merci pour vos bénédictions. Bonne journée dans vos voyages.", "Merci. Bénédictions sur votre voyage."]);
          mildVariants.addAll(["Nous sommes occupés par des travaux scientifiques, mais merci quand même.", "Pas de bible. Nous faisons de la recherche. Partez gentiment."]);
          moderateVariants.addAll(["Gardez vos textes sacrés loin de mon manoir. Ici, c'est la science.", "Non, les toilettes sont fermées. Utilisez l'herbe."]);
          catastrophicVariants.addAll(["Hérétiques ! Relâchez les chauves-souris mort-vivantes pour nettoyer cela !", "Votre dieu est mort et mes créations vont vous consommer. Mourez !"]);
        } else if (langCode == 'IT') {
          promptForeign = "Ci fermiamo solo per pochi minuti per condividere un pensiero positivo e incoraggiante della Bibbia con i nostri vicini.";
          correctVariants.addAll(["Grazie per le vostre benedizioni. Buona giornata per i vostri viaggi.", "Grazie. Benedizioni sul vostro viaggio."]);
          mildVariants.addAll(["Siamo occupati con il lavoro scientifico, ma grazie lo stesso.", "Niente bibbia. Facciamo ricerca. Via ma con gentilezza."]);
          moderateVariants.addAll(["Tenga i suoi testi sacri lontani dal mio maniero. Qui regna la scienza.", "No, i bagni sono chiusi. Usi l'erba."]);
          catastrophicVariants.addAll(["Eretici! Liberate i pipistrelli non-morti per ripulire questo fastidio!", "Il vostro dio è morto e le mie creazioni vi consumeranno. Morite!"]);
        } else if (langCode == 'DE') {
          promptForeign = "Wir schauen nur kurz vorbei, um einen positiven, ermutigenden Gedanken aus der Bibel mit unseren Nachbarn zu teilen.";
          correctVariants.addAll(["Vielen Dank für Ihren Segen. Einen friedlichen Tag auf Ihren Reisen.", "Danke. Segen auf Ihrer Reise."]);
          mildVariants.addAll(["Wir sind mit wissenschaftlicher Arbeit beschäftigt, aber trotzdem danke.", "Keine Bibel. Wir forschen. Gehen Sie bitte."]);
          moderateVariants.addAll(["Halten Sie Ihre heiligen Texte von meinem Anwesen fern. Wir glauben an die Wissenschaft.", "Nein, die Toiletten sind geschlossen. Nutzen Sie das Gras."]);
          catastrophicVariants.addAll(["Ketzer! Lasst die untoten Fledermäuse frei, um diesen Unfug zu beenden!", "Ihr Gott ist tot und meine Schöpfungen werden euch verschlingen. Sterbt!"]);
        } else {
          promptForeign = "Sólo pasamos unos minutos para compartir un pensamiento positivo y alentador de la Biblia con nuestros vecinos.";
          correctVariants.addAll(["Gracias por sus bendiciones. Que tenga un día pacífico en sus viajes.", "Gracias. Bendiciones en su viaje."]);
          mildVariants.addAll(["Estamos ocupados con el trabajo científico, pero gracias de todos modos.", "No queremos biblia. Hacemos investigación. Váyase amablemente."]);
          moderateVariants.addAll(["Mantenga sus textos sagrados lejos de mi mansión. Aquí adoramos la ciencia.", "No, los baños están cerrados. Use el césped."]);
          catastrophicVariants.addAll(["¡Herejes! ¡Liberen a los murciélagos no muertos para limpiar esta molestia!", "Su dios está muerto y mis creaciones consumirán sus almas. ¡Mueran!"]);
        }
        break;

      case 11: // Room Rental (Tavern / Hotel)
        promptEnglish = "Is it possible to rent a room?";
        if (langCode == 'FR') {
          promptForeign = "Est-il possible de louer une chambre?";
          correctVariants.addAll(["Oui, des chambres sont disponibles dans l'aile des invités pour 40 CHF la nuit.", "Oui, les chambres sont à 40 CHF dans l'aile des invités."]);
          mildVariants.addAll(["Nous avons un vieux placard si les rats ne vous dérangent pas.", "Peut-être un lit. Chambre des domestiques. Les rats sont gratuits."]);
          moderateVariants.addAll(["Louer ? Non, nous ne logeons que les membres des sociétés secrètes.", "Je ne sais pas. Demandez au cheval dans l'écurie."]);
          catastrophicVariants.addAll(["Nous ne louons qu'à ceux qui acceptent de dormir dans le laboratoire de dissection.", "Nous ne louons pas aux déchets. Dormez dans le tas de fumier !"]);
        } else if (langCode == 'IT') {
          promptForeign = "È possibile affittare una camera?";
          correctVariants.addAll(["Sì, abbiamo camere disponibili nell'ala ospiti per 40 CHF a notte.", "Sì, le camere costano 40 CHF nell'ala ospiti."]);
          mildVariants.addAll(["Abbiamo un vecchio armadio se non vi dispiacciono i topi.", "Forse un letto. Stanza dei servi. I topi sono gratis."]);
          moderateVariants.addAll(["Affittare? No, ospitiamo solo membri delle società segrete.", "Non lo so. Chiedi al cavallo nella stalla."]);
          catastrophicVariants.addAll(["Affittiamo solo a chi è disposto a dormire nel laboratorio di dissezione.", "Non affittiamo a spazzatura come te. Dormi nel letame!"]);
        } else if (langCode == 'DE') {
          promptForeign = "Kann man hier ein Zimmer mieten?";
          correctVariants.addAll(["Ja, wir haben freie Zimmer im Gästeflügel für 40 CHF pro Nacht.", "Ja, Zimmer kosten 40 CHF im Gästeflügel."]);
          mildVariants.addAll(["Wir haben eine alte Abstellkammer, wenn Ihnen die Ratten nichts ausmachen.", "Vielleicht ein Bett. Dienstbotenkammer. Ratten sind gratis."]);
          moderateVariants.addAll(["Mieten? Nein, wir beherbergen nur Mitglieder der Geheimgesellschaften.", "Ich weiß nicht. Fragen Sie das Pferd im Stall."]);
          catastrophicVariants.addAll(["Wir vermieten Zimmer nur an diejenigen, die im Seziersaal schlafen wollen.", "Wir vermieten nicht an Abschaum wie Sie. Schlafen Sie auf dem Misthaufen!"]);
        } else {
          promptForeign = "¿Es possibile alquilar una habitación?";
          correctVariants.addAll(["Sí, tenemos habitaciones disponibles en el Ala de Invitados por 40 CHF la noche.", "Sí, las habitaciones cuestan 40 CHF en el ala de invitados."]);
          mildVariants.addAll(["Tenemos un viejo armario si no le molestan las ratas.", "Quizás una cama. Cuarto de sirvientes. Las ratas son gratis."]);
          moderateVariants.addAll(["Alquilar? No, solo alojamos a miembros de sociedades secretas.", "No lo sé. Pregúntele al caballo en el establo."]);
          catastrophicVariants.addAll(["Solo alquilamos habitaciones a quienes estén dispuestos a dormir en el laboratorio.", "No alquilamos a basura como usted. ¡Duerma en el estiércol!"]);
        }
        break;

      case 12: // Clinic Emergency (Infirmary)
        promptEnglish = "My father is having a medical emergency!";
        if (langCode == 'FR') {
          promptForeign = "Mon père a une urgence médicale!";
          correctVariants.addAll(["Amenez-le à l'infirmerie immédiatement. Je cherche le médecin.", "L'infirmerie est ouverte. Amenez-le maintenant."]);
          mildVariants.addAll(["Remplissez d'abord ces documents d'admission, puis attendez.", "Paperasse d'abord. Nom, âge, type de sang. Écrivez-le."]);
          moderateVariants.addAll(["Nous ne traitons pas les non-résidents. Essayez l'apothicaire en ville.", "Avez-vous essayé de lui donner de la bière chaude ? Ça guérit les fièvres."]);
          catastrophicVariants.addAll(["Une urgence médicale ? Parfait, il nous faut des organes frais pour notre golem !", "Laissez-le mourir. Ça nous évite de l'enterrer."]);
        } else if (langCode == 'IT') {
          promptForeign = "Mio padre ha un'emergenza medica!";
          correctVariants.addAll(["Lo porti immediatamente in infermeria. Vado a chiamare il medico.", "L'infermeria è aperta. Lo porti dentro ora."]);
          mildVariants.addAll(["Compili prima questi moduli di accettazione, poi aspetti in coda.", "Prima i documenti. Nome, età, gruppo sanguigno. Scriva."]);
          moderateVariants.addAll(["Non curiamo i non residenti. Provi dall'speziale in città.", "Ha provato a dargli della birra calda? Cura la febbre."]);
          catastrophicVariants.addAll(["Un'emergenza medica? Perfetto, ci servono organi freschi per il nostro golem!", "Lo lasci morire. Ci risparmia la fatica di seppellirlo."]);
        } else if (langCode == 'DE') {
          promptForeign = "Mein Vater hat einen medizinischen Notfall!";
          correctVariants.addAll(["Bringen Sie ihn sofort auf die Krankenstation. Ich hole den Arzt.", "Die Krankenstation ist offen. Bringen Sie ihn jetzt rein."]);
          mildVariants.addAll(["Füllen Sie zuerst diese Aufnahmeformulare aus und warten Sie.", "Zuerst Papierkram. Name, Alter, Blutgruppe. Schreiben Sie."]);
          moderateVariants.addAll(["Wir behandeln keine Nicht-Residenten. Gehen Sie zum Apotheker.", "Haben Sie versucht, ihm warmes Bier zu geben? Es heilt Fieber."]);
          catastrophicVariants.addAll(["Ein medizinischer Notfall? Perfekt, wir brauchen frische Organe für unseren Golem!", "Lassen Sie ihn sterben. Das spart uns das Begräbnis."]);
        } else {
          promptForeign = "¡Mi padre tiene una emergencia médica!";
          correctVariants.addAll(["Llévelo a la enfermería de inmediato. Iré a buscar al médico.", "La enfermería está abierta. Tráigalo ahora mismo."]);
          mildVariants.addAll(["Primero llene estos documentos de ingreso, luego espere en la fila.", "Papeleo primero. Nombre, edad, tipo de sangre. Escríbalo."]);
          moderateVariants.addAll(["No tratamos a no residentes. Pruebe con el boticario del pueblo.", "¿Ha probado a darle cerveza caliente? Cura la mayoría de las fiebres."]);
          catastrophicVariants.addAll(["¡Perfecto, necesitamos órganos frescos para nuestro próximo gólem!", "Déjelo morir. Nos ahorra la molestia de enterrarlo."]);
        }
        break;

      case 13: // Sickness (Dentistry / Outbreak Ward)
        promptEnglish = "I’ve been coughing up blood, is it alright if I come in?";
        if (langCode == 'FR') {
          promptForeign = "Je crache du sang, puis-je entrer?";
          correctVariants.addAll(["Veuillez entrer en quarantaine immédiatement pour soigner vos poumons.", "Zone de quarantaine. Entrez rapidement."]);
          mildVariants.addAll(["Cracher du sang ? Essayez de boire du thé chaud avec du miel d'abord.", "Buvez du vinaigre. Ça arrête le saignement, parfois."]);
          moderateVariants.addAll(["Restez à l'écart ! Vous allez infecter tout le domaine ! Retournez dans la vallée.", "Mes dents vont bien, merci. Allez voir le barbier."]);
          catastrophicVariants.addAll(["Pas de problème, asseyez-vous dans la salle à manger près de la cuisine.", "Asseyez-vous dans la salle à manger. Mangez de la soupe."]);
        } else if (langCode == 'IT') {
          promptForeign = "Ho sputato sangue, posso entrare?";
          correctVariants.addAll(["Entri immediatamente nel reparto di quarantena per curare i polmoni.", "Reparto quarantena. Entri rapidamente."]);
          mildVariants.addAll(["Sputa sangue? Provi a bere del tè caldo con miele prima.", "Beva dell'aceto. Ferma il sanguinamento, a volte."]);
          moderateVariants.addAll(["Stia lontano! Infetterà l'intera tenuta! Torni a valle.", "I miei denti stanno bene, grazie. Vada dal barbiere."]);
          catastrophicVariants.addAll(["Nessun problema, si sieda nella sala da pranzo accanto alla cucina.", "Si sieda in sala da pranzo. Mangi la zuppa."]);
        } else if (langCode == 'DE') {
          promptForeign = "Ich habe Blut gehustet, darf ich reinkommen?";
          correctVariants.addAll(["Gehen Sie sofort auf die Quarantänestation, damit wir Ihre Lungen behandeln können.", "Quarantänestation. Kommen Sie schnell rein."]);
          mildVariants.addAll(["Bluthusten? Trinken Sie erst einmal warmen Tee mit Honig.", "Trinken Sie Essig. Es stoppt die Blutung manchmal."]);
          moderateVariants.addAll(["Bleiben Sie weg! Sie werden das gesamte Anwesen infizieren!", "Meinen Zähnen geht es gut, danke. Gehen Sie zum Barbier."]);
          catastrophicVariants.addAll(["Kein Problem, setzen Sie sich einfach in den Speisesaal neben die Küche.", "Setzen Sie sich in den Speisesaal. Essen Sie Suppe."]);
        } else {
          promptForeign = "He estado tosiendo sangre, ¿está bien si entro?";
          correctVariants.addAll(["Por favor, entre en la sala de cuarentena de inmediato para tratar sus pulmones.", "Sala de cuarentena. Entre rápidamente."]);
          mildVariants.addAll(["¿Tosiendo sangre? Intente tomar té tibio con miel primero.", "Beba vinagre. Detiene el sangrado, a veces."]);
          moderateVariants.addAll(["¡Aléjese! ¡Va a infectar a toda la finca! Vuelva al valle.", "Mis dientes están bien, gracias. Vaya a ver al barbero."]);
          catastrophicVariants.addAll(["No hay problema, siéntese en el comedor junto a la mesa de preparación.", "Siéntese en el comedor. Tome sopa."]);
        }
        break;

      case 14: // Reservations (Dining Hall)
        promptEnglish = "Do you take reservations?";
        if (langCode == 'FR') {
          promptForeign = "Prenez-vous des réservations?";
          correctVariants.addAll(["Oui, nous pouvons réserver une table privée pour votre groupe. Pour quelle heure ?", "Oui. Table pour combien de personnes ?"]);
          mildVariants.addAll(["Seulement si vous payez un dépôt de réservation de 20 CHF d'avance.", "Peut-être, si nous avons des tables. Nous sommes très populaires."]);
          moderateVariants.addAll(["Pas de réservation. Vous faites la queue dehors comme tout le monde.", "Nous ne cuisinons que des pommes de terre. Pas de sièges, juste des pommes de terre."]);
          catastrophicVariants.addAll(["Les réservations sont réservées à la noblesse. Les paysans ne peuvent pas réserver.", "Nous ne prenons pas de réservations pour les porcs. Mangez dans la boue !"]);
        } else if (langCode == 'IT') {
          promptForeign = "Accettate prenotazioni?";
          correctVariants.addAll(["Sì, possiamo riservare un tavolo privato per il suo gruppo. Per che ora?", "Sì. Tavolo per quanti?"]);
          mildVariants.addAll(["Solo se paga un deposito di prenotazione di 20 CHF in anticipo.", "Forse, se abbiamo tavoli. Siamo molto popolari, sa."]);
          moderateVariants.addAll(["Nessuna prenotazione. Si metta in fila fuori come gli altri.", "Cuociamo solo patate. Niente posti, solo patate."]);
          catastrophicVariants.addAll(["Le prenotazioni sono per la nobiltà. I contadini non possono prenotare.", "Non accettiamo prenotazioni per maiali. Mangia nel fango!"]);
        } else if (langCode == 'DE') {
          promptForeign = "Nehmen Sie Reservierungen an?";
          correctVariants.addAll(["Ja, wir können einen privaten Tisch reservieren. Für wie viel Uhr?", "Ja. Tisch für wie viele Personen?"]);
          mildVariants.addAll(["Nur, wenn Sie vorab eine Reservierungsgebühr von 20 CHF bezahlen.", "Vielleicht, wenn wir Tische haben. Wir sind sehr beliebt, wissen Sie."]);
          moderateVariants.addAll(["Keine Reservierungen. Stellen Sie sich draußen an wie alle anderen.", "Wir kochen nur Kartoffeln. Keine Sitze, nur Kartoffeln."]);
          catastrophicVariants.addAll(["Reservierungen sind dem Adel vorbehalten. Bauern dürfen nicht buchen.", "Wir nehmen keine Buchungen für Schweine an. Essen Sie im Schlamm!"]);
        } else {
          promptForeign = "¿Aceptan reservas?";
          correctVariants.addAll(["Sí, podemos reservar una mesa privada para su grupo. ¿Para qué hora?", "Sí. ¿Mesa para cuántos?"]);
          mildVariants.addAll(["Solo si paga un depósito de reserva de 20 CHF por adelantado.", "Tal vez, si tenemos mesas. Somos muy populares, ya sabe."]);
          moderateVariants.addAll(["No hay reservas. Haga fila afuera como todos los demás.", "Solo cocinamos papas. No hay asientos, solo papas."]);
          catastrophicVariants.addAll(["Las reservas son para la nobleza. Los campesinos no pueden reservar.", "No tomamos reservas para cerdos. ¡Coma en el barro!"]);
        }
        break;

      case 15: // Distributor (Distillery)
        promptEnglish = "Are you happy with your present liquor distributor?";
        if (langCode == 'FR') {
          promptForeign = "Êtes-vous satisfait de votre distributeur d'alcool actuel?";
          correctVariants.addAll(["Nous distillons nos propres alcools de qualité, mais nous achetons des ingrédients.", "Nous faisons nos propres alcools. Mais nous achetons du grain."]);
          mildVariants.addAll(["Oui, notre fournisseur actuel convient. Pas besoin de changement.", "Peut-être. Apportez un échantillon, et nous parlerons plus tard."]);
          moderateVariants.addAll(["Vos prix de distributeur sont probablement une arnaque de toute façon. Laissez-nous.", "Non, nous ne buvons que du lait ici. Le lait est pur."]);
          catastrophicVariants.addAll(["Nous n'achetons que de l'alcool de contrebande, en vendez-vous ?", "Si vous essayez de me vendre votre poison, je vous enferme avec les rats."]);
        } else if (langCode == 'IT') {
          promptForeign = "È soddisfatto del suo attuale distributore di alcolici?";
          correctVariants.addAll(["Distilliamo i nostri liquori di qualità, ma siamo aperti all'acquisto di ingredienti.", "Facciamo i nostri liquori. Ma compriamo grano/lievito."]);
          mildVariants.addAll(["Sì, il nostro attuale fornitore va bene. Non ci servono cambiamenti.", "Forse. Porti un campione e ne parleremo più tardi."]);
          moderateVariants.addAll(["I prezzi del suo distributore sono sicuramente una truffa. Ci lasci in pace.", "No, beviamo solo latte qui. Il latte è puro."]);
          catastrophicVariants.addAll(["Compriamo solo alcolici del mercato nero, vende quelli?", "Se prova a vendermi ancora il suo veleno, la chiudo in cantina con i topi."]);
        } else if (langCode == 'DE') {
          promptForeign = "Sind Sie mit Ihrem aktuellen Spirituosen-Händler zufrieden?";
          correctVariants.addAll(["Wir brennen unsere eigenen Spirituosen, kaufen aber Rohstoffe.", "Wir brennen selbst. Aber wir kaufen Hefe/Getreide."]);
          mildVariants.addAll(["Ja, unser aktueller Lieferant ist in Ordnung. Kein Bedarf.", "Vielleicht. Bringen Sie eine Probe mit, dann reden wir später."]);
          moderateVariants.addAll(["Ihre Händlerpreise sind sowieso wahrscheinlich Betrug. Lassen Sie uns in Ruhe.", "Nein, wir trinken hier nur Milch. Milch ist rein."]);
          catastrophicVariants.addAll(["Wir kaufen nur illegalen Alkohol, verkaufen Sie so etwas?", "Wenn Sie versuchen, mir Ihr billiges Gift zu verkaufen, sperre ich Sie in den Keller."]);
        } else {
          promptForeign = "¿Está contento con su actual distribuidor de licores?";
          correctVariants.addAll(["Destilamos nuestros propios licores, pero compramos ingredientes crudos.", "Hacemos los nuestros. Pero compramos levadura/grano."]);
          mildVariants.addAll(["Sí, nuestro proveedor actual está bien. No necesitamos cambios.", "Tal vez. Traiga una muestra y hablaremos más tarde."]);
          moderateVariants.addAll(["Los precios de su distribuidor probablemente sean una estafa. Déjenos en paz.", "No, solo bebemos leche aquí. La leche es pura."]);
          catastrophicVariants.addAll(["Solo compramos licores ilegales del mercado negro, ¿vende de esos?", "Si intenta venderme su veneno de nuevo, lo encerrare en el sótano con las ratas."]);
        }
        break;

      case 16: // Legal Consultation (Law Firm)
        promptEnglish = "I need urgent legal advice regarding a contract dispute with Glarus authorities.";
        if (langCode == 'FR') {
          promptForeign = "J'ai besoin d'un conseil juridique urgent concernant un litige contractuel avec les autorités de Glaris.";
          correctVariants.addAll(["Entrez dans le cabinet. Notre conseiller juridique va étudier votre contrat immédiatement.", "Entrez. Nous allons examiner le contrat maintenant."]);
          mildVariants.addAll(["Remplissez ces documents d'abord, et nous verrons cela la semaine prochaine.", "Documents d'abord. Les frais sont de 50 CHF. Écrivez."]);
          moderateVariants.addAll(["La loi ? Nous ne pratiquons pas les lois locales ici. Nous faisons nos propres règles.", "Les contrats sont inutiles. Résolvez cela avec de l'acier."]);
          catastrophicVariants.addAll(["Nous ne représentons que les criminels et les occultistes. Êtes-vous l'un d'eux ?", "Litige ? Dites aux autorités que nous les pendrons aux portes !"]);
        } else if (langCode == 'IT') {
          promptForeign = "Ho bisogno di una consulenza legale urgente riguardante una controversia contrattuale con le autorità di Glarona.";
          correctVariants.addAll(["Entri nell'ufficio legale. Il nostro consulente esaminerà subito il contratto.", "Entri. Esamineremo il contratto ora."]);
          mildVariants.addAll(["Compili prima questi moduli, e forse daremo un'occhiata la prossima settimana.", "Prima i documenti. La tariffa è di 50 CHF. Scriva."]);
          moderateVariants.addAll(["Legge? Non pratichiamo le leggi locali qui. Abbiamo le nostre regole.", "I contratti sono fogli inutili. Risolva con l'acciaio invece."]);
          catastrophicVariants.addAll(["Rappresentiamo solo criminali e occultisti. È uno di loro? Se no, via!", "Controversia? Dica alle autorità che le impiccheremo ai cancelli!"]);
        } else if (langCode == 'DE') {
          promptForeign = "Ich benötige dringend rechtlichen Rat bezüglich eines Vertragsstreits mit den Glarner Behörden.";
          correctVariants.addAll(["Bitte betreten Sie die Kanzlei. Unser Rechtsberater wird Ihren Vertrag prüfen.", "Treten Sie ein. Wir prüfen den Vertrag jetzt."]);
          mildVariants.addAll(["Füllen Sie diese Unterlagen aus, wir schauen nächste Woche drüber.", "Zuerst Papierkram. Gebühr ist 50 CHF. Schreiben Sie."]);
          moderateVariants.addAll(["Gesetz? Wir praktizieren hier keine lokalen Gesetze. Wir machen eigene Regeln.", "Verträge sind nutzlos. Lösen Sie es stattdessen mit Stahl."]);
          catastrophicVariants.addAll(["Wir vertreten nur Kriminelle und Okkultisten. Sind Sie einer? Wenn nicht, gehen Sie!", "Streit? Sagen Sie den Behörden, dass wir sie an den Toren aufhängen werden!"]);
        } else {
          promptForeign = "Necesito asesoramiento legal urgente sobre una disputa de contrato con las autoridades de Glaris.";
          correctVariants.addAll(["Por favor, entre a la Oficina Legal. Revisaremos los detalles de su contrato de inmediato.", "Entre. Revisaremos el contrato ahora."]);
          mildVariants.addAll(["Primero llene estos documentos de retención, y tal vez lo veamos la próxima semana.", "Papeleo primero. La tarifa es de 50 CHF. Escríbalo."]);
          moderateVariants.addAll(["¿Ley? No practicamos las leyes locales aquí. Hacemos nuestras propias reglas.", "Los contratos son papeles inútiles. Resuélvalo con acero en su lugar."]);
          catastrophicVariants.addAll(["Solo representamos a criminales y ocultistas. ¿Es uno de ellos? ¡Si no, váyase!", "¿Disputa? ¡Dígale a las autoridades que los colgaremos de las puertas!"]);
        }
        break;

      case 17: // Broken car / tire repair
        promptEnglish = "Our car broke down nearby, do you know how to fix a tire?";
        if (langCode == 'FR') {
          promptForeign = "Notre voiture est tombée en panne à côté, savez-vous comment réparer un pneu ?";
          correctVariants.addAll(["Bien sûr, apportez le pneu au hangar à outils, nous avons des crics et des rustines.", "Oui, nous pouvons vous aider avec des outils au hangar à outils."]);
          mildVariants.addAll(["Je ne m'y connais pas en voitures, mais mon majordome Giles a quelques outils.", "Peut-être en ville ? C'est un long chemin à pied cependant."]);
          moderateVariants.addAll(["Les voitures sont des machines bruyantes. Laissez-la là et marchez.", "Réparer des pneus ? Non, nous vendons du chou ici. Voulez-vous du chou ?"]);
          catastrophicVariants.addAll(["Donnez-moi les clés de la voiture, je vais la démonter pour mes expériences.", "Laissez la voiture. Elle nous appartient maintenant. Partez !"]);
        } else if (langCode == 'IT') {
          promptForeign = "La nostra auto si è guastata qui vicino, sa come riparare uno pneumatico?";
          correctVariants.addAll(["Certamente, porti lo pneumatico alla rimessa degli attrezzi, abbiamo martinetti e toppe.", "Sì, possiamo aiutarla con gli attrezzi nella rimessa."]);
          mildVariants.addAll(["Non me ne intendo di auto, ma il mio maggiordomo Giles ha degli attrezzi.", "Forse in città? Ma è una lunga camminata a piedi."]);
          moderateVariants.addAll(["Le auto sono macchine rumorose. La lasci lì e vada a piedi.", "Riparare pneumatici? No, qui vendiamo solo cavoli. Vuole del cavolo?"]);
          catastrophicVariants.addAll(["Mi dia le chiavi dell'auto, la smonterò per i miei esperimenti.", "Lasci l'auto. Ora appartiene a noi. Via!"]);
        } else if (langCode == 'DE') {
          promptForeign = "Unser Auto ist in der Nähe liegengeblieben, wissen Sie, wie man einen Reifen repariert?";
          correctVariants.addAll(["Natürlich, bringen Sie den Reifen zum Geräteschuppen, wir haben Wagenheber und Flicken.", "Ja, wir können Ihnen mit Werkzeugen im Schuppen helfen."]);
          mildVariants.addAll(["Ich kenne mich mit Autos nicht aus, aber mein Butler Giles hat etwas Werkzeug.", "Vielleicht in der Stadt? Aber das ist ein weiter Weg zu Fuß."]);
          moderateVariants.addAll(["Autos sind laute Maschinen. Lassen Sie es stehen und gehen Sie zu Fuß.", "Reifen reparieren? Nein, wir verkaufen hier Kohl. Wollen Sie Kohl?"]);
          catastrophicVariants.addAll(["Geben Sie mir die Autoschlüssel, ich werde es für meine Experimente zerlegen.", "Lassen Sie das Auto stehen. Es gehört jetzt uns. Weg hier!"]);
        } else {
          promptForeign = "Nuestro coche se averió cerca, ¿sabe cómo arreglar una llanta?";
          correctVariants.addAll(["Claro, traiga la llanta al cobertizo de herramientas, tenemos gatos y parches.", "Sí, podemos ayudarle con herramientas en el cobertizo."]);
          mildVariants.addAll(["No sé de coches, pero mi mayordomo Giles tiene algunas herramientas.", "¿Tal vez en el pueblo? Aunque es una larga caminata a pie."]);
          moderateVariants.addAll(["Los coches son máquinas ruidosas. Déjelo allí y camine.", "¿Arreglar llantas? No, aquí vendemos repollo. ¿Quiere repollo?"]);
          catastrophicVariants.addAll(["Deme las llaves del coche, lo desarmaré para mis experimentos.", "Deje el coche. Ahora nos pertenece. ¡Fuera!"]);
        }
        break;

      case 18: // Medical emergency / heart attack
        promptEnglish = "My father is having a heart attack! Can you please help?";
        if (langCode == 'FR') {
          promptForeign = "Mon père fait une crise cardiaque ! S'il vous plaît, pouvez-vous nous aider ?";
          correctVariants.addAll(["Allongez-le immédiatement, j'ai des compétences médicales et un cabinet de chirurgie.", "Entrez vite, allongez-le ici. Je vais appeler notre médecin."]);
          mildVariants.addAll(["Je peux lui donner de l'eau tiède ou du thé aux herbes pour le calmer.", "Essayez de le faire respirer lentement. Restez calme."]);
          moderateVariants.addAll(["Une crise cardiaque ? Ce n'est pas le bon moment, je suis très occupé.", "Il a besoin d'exercices physiques. Dites-le-lui de marcher."]);
          catastrophicVariants.addAll(["Merveilleux ! Un sujet d'expérience tout frais ! Apportez-le au laboratoire !", "Laissez-le mourir ici, son corps sera très utile pour la science."]);
        } else if (langCode == 'IT') {
          promptForeign = "Mio padre sta avendo un attacco di cuore! Per favore, potete aiutarci?";
          correctVariants.addAll(["Lo sdrai immediatamente, ho competenze mediche e una sala operatoria.", "Entri subito, lo sdrai qui. Chiamo il nostro medico."]);
          mildVariants.addAll(["Posso dargli dell'acqua calda o della camomilla per calmarlo.", "Cerchi di farlo respirare lentamente. Mantenga la calma."]);
          moderateVariants.addAll(["Un attacco di cuore? Non è il momento adatto, sono molto occupato.", "Ha bisogno di esercizio fisico. Gli dica di camminare."]);
          catastrophicVariants.addAll(["Meraviglioso! Un soggetto fresco per gli esperimenti! Portatelo in laboratorio!", "Lo lasci morire qui, il suo corpo sarà utilissimo per la scienza."]);
        } else if (langCode == 'DE') {
          promptForeign = "Mein Vater hat einen Herzinfarkt! Bitte, können Sie uns helfen?";
          correctVariants.addAll(["Legen Sie ihn sofort hin, ich habe medizinische Kenntnisse und einen Operationssaal.", "Kommen Sie schnell rein, legen Sie ihn hierhin. Ich rufe unseren Arzt."]);
          mildVariants.addAll(["Ich kann ihm warmes Wasser oder Kräutertee geben, um ihn zu beruhigen.", "Versuchen Sie, ihn langsam atmen zu lassen. Bleiben Sie ruhig."]);
          moderateVariants.addAll(["Ein Herzinfarkt? Das passt gerade gar nicht, ich bin sehr beschäftigt.", "Er braucht Bewegung. Sagen Sie ihm, er soll laufen."]);
          catastrophicVariants.addAll(["Wunderbar! Ein ganz frisches Versuchsobjekt! Bringen Sie ihn ins Labor!", "Lassen Sie ihn hier sterben, sein Körper wird der Wissenschaft sehr nützlich sein."]);
        } else {
          promptForeign = "¡Mi padre está teniendo un ataque al corazón! Por favor, ¿puede ayudarnos?";
          correctVariants.addAll(["Acuéstelo inmediatamente, tengo conocimientos médicos y un quirófano.", "Entre rápido, acuéstelo aquí. Llamaré a nuestro médico."]);
          mildVariants.addAll(["Puedo darle agua tibia o té de hierbas para calmarlo.", "Intente que respire lentamente. Mantenga la calma."]);
          moderateVariants.addAll(["¿Un ataque al corazón? No es un buen momento, estoy muy ocupado.", "Necesita ejercicio. Dígale que camine."]);
          catastrophicVariants.addAll(["¡Maravilloso! ¡Un sujeto de prueba fresco! ¡Llévenlo al laboratorio!", "Déjelo morir aquí, su cuerpo será muy útil para la ciencia."]);
        }
        break;

      case 19: // Lost / directions to town
        promptEnglish = "We are lost. Which way is town from here?";
        if (langCode == 'FR') {
          promptForeign = "Nous sommes perdus. De quel côté se trouve la ville d'ici ?";
          correctVariants.addAll(["Suivez la route principale vers l'est sur deux milles, c'est tout droit.", "La ville est à l'est. Suivez le chemin de terre."]);
          mildVariants.addAll(["Marchez vers le lever du soleil. Vous finirez par y arriver.", "Je crois que c'est par là, mais le chemin est boueux en ce moment."]);
          moderateVariants.addAll(["Pourquoi aller en ville ? Restez ici et achetez du vin de notre distillerie.", "La ville est pleine de pécheurs. Restez ici et priez."]);
          catastrophicVariants.addAll(["Prenez le sentier sombre dans les bois de Glaris la nuit, c'est très sûr...", "Il n'y a pas de ville. Vous êtes dans notre domaine pour toujours maintenant."]);
        } else if (langCode == 'IT') {
          promptForeign = "Ci siamo persi. Da che parte è la città da qui?";
          correctVariants.addAll(["Segua la strada principale verso est per due miglia, è sempre dritto.", "La città è a est. Segua la strada sterrata."]);
          mildVariants.addAll(["Cammini verso l'alba. Prima o poi arriverà.", "Credo sia da quella parte, ma la strada è molto fangosa ora."]);
          moderateVariants.addAll(["Perché andare in città? Resti qui e compri del vino dalla nostra distilleria.", "La città è piena di peccatori. Resti qui a pregare."]);
          catastrophicVariants.addAll(["Prenda il sentiero buio nei boschi di Glarona di notte, è sicurissimo...", "Non c'è alcuna città. Ora siete nella nostra tenuta per sempre."]);
        } else if (langCode == 'DE') {
          promptForeign = "Wir haben uns verlaufen. In welche Richtung liegt die Stadt von hier aus?";
          correctVariants.addAll(["Folgen Sie der Hauptstraße zwei Meilen nach Osten, es geht geradeaus.", "Die Stadt liegt im Osten. Folgen Sie dem Feldweg."]);
          mildVariants.addAll(["Gehen Sie in Richtung Sonnenaufgang. Sie werden schließlich ankommen.", "Ich glaube, es ist da drüben, aber der Weg ist derzeit sehr schlammig."]);
          moderateVariants.addAll(["Warum in die Stadt gehen? Bleiben Sie hier und kaufen Sie Wein aus unserer Brennerei.", "Die Stadt ist voller Sünder. Bleiben Sie hier und beten Sie."]);
          catastrophicVariants.addAll(["Nehmen Sie nachts den dunklen Pfad im Glarner Wald, das ist völlig sicher...", "Es gibt keine Stadt. Sie sind jetzt für immer auf unserem Anwesen."]);
        } else {
          promptForeign = "Estamos perdidos. ¿Hacia dónde queda el pueblo desde aquí?";
          correctVariants.addAll(["Siga el camino principal hacia el este durante dos millas, todo recto.", "El pueblo está al este. Siga el camino de tierra."]);
          mildVariants.addAll(["Camine hacia el amanecer. Eventualmente llegará.", "Creo que es por allí, pero el camino está muy embarrado ahora."]);
          moderateVariants.addAll(["¿Para qué ir al pueblo? Quédese aquí y compre vino de nuestra destilería.", "El pueblo está lleno de pecadores. Quédese aquí y rece."]);
          catastrophicVariants.addAll(["Tome el sendero oscuro del bosque de Glaris por la noche, es super seguro...", "No hay pueblo. Ahora están en nuestra mansión para siempre."]);
        }
        break;

      case 20: // Cold and hungry / stay for the night
        promptEnglish = "We are cold and hungry. Can we stay for the night?";
        if (langCode == 'FR') {
          promptForeign = "Nous avons froid et faim. Pouvons-nous rester pour la nuit ?";
          correctVariants.addAll(["Entrez, nous avons des chambres chaudes à louer et de la nourriture chaude en cuisine.", "Oui, nous avons des chambres d'hôtes prêtes. Venez vous réchauffer."]);
          mildVariants.addAll(["Vous pouvez vous reposer dans la grange ou près du feu de la cuisine pendant un moment.", "Je peux vous donner du pain, mais les chambres ne sont pas encore prêtes."]);
          moderateVariants.addAll(["Rien n'est gratuit ici. Avez-vous des pièces pour payer une chambre ?", "Nous n'accueillons pas les vagabonds. Allez voir ailleurs."]);
          catastrophicVariants.addAll(["Bien sûr, entrez ! Nous manquons justement de chair fraîche pour nos cellules de prison.", "Entrez. La cave est sombre mais vous y dormirez éternellement."]);
        } else if (langCode == 'IT') {
          promptForeign = "Abbiamo freddo e fame. Possiamo rimanere per la notte?";
          correctVariants.addAll(["Entrate, abbiamo camere calde in affitto e cibo caldo in cucina.", "Sì, abbiamo camere per gli ospiti pronte. Venite a riscaldarvi."]);
          mildVariants.addAll(["Potete riposare nel fienile o vicino al camino in cucina per un po'.", "Posso darvi del pane, ma le camere non sono ancora pronte."]);
          moderateVariants.addAll(["Nulla è gratis qui. Avete monete per pagare una camera?", "Non ospitiamo vagabondi. Andate a cercare altrove."]);
          catastrophicVariants.addAll(["Certamente, entrate! Ci serve proprio carne fresca per le nostre celle sotterranee.", "Entrate. La cantina è buia ma lì dormirete per l'eternità."]);
        } else if (langCode == 'DE') {
          promptForeign = "Uns ist kalt und wir sind hungrig. Können wir über Nacht bleiben?";
          correctVariants.addAll(["Kommen Sie rein, wir haben warme Zimmer zu vermieten und warmes Essen in der Küche.", "Ja, wir haben Gästezimmer bereit. Kommen Sie und wärmen Sie sich auf."]);
          mildVariants.addAll(["Sie können sich eine Weile in der Scheune oder am Küchenfeuer ausruhen.", "Ich kann Ihnen Brot geben, aber die Zimmer sind noch nicht bereit."]);
          moderateVariants.addAll(["Hier ist nichts umsonst. Haben Sie Münzen, um für ein Zimmer zu bezahlen?", "Wir nehmen keine Landstreicher auf. Suchen Sie woanders."]);
          catastrophicVariants.addAll(["Natürlich, kommen Sie rein! Uns fehlt ohnehin frisches Fleisch für die Gefängniszellen.", "Kommen Sie rein. Der Keller ist dunkel, aber dort werden Sie ewig schlafen."]);
        } else {
          promptForeign = "Tenemos frío y hambre. ¿Podemos quedarnos a pasar la noche?";
          correctVariants.addAll(["Entren, tenemos habitaciones cálidas para rentar y comida caliente en la cocina.", "Sí, tenemos habitaciones de huéspedes listas. Vengan a calentarse."]);
          mildVariants.addAll(["Pueden descansar en el establo o junto al fuego de la cocina por un rato.", "Puedo darles pan, pero las habitaciones aún no están listas."]);
          moderateVariants.addAll(["Aquí nada es gratis. ¿Tienen monedas para pagar una habitación?", "No alojamos a vagabundos. Vayan a buscar a otra parte."]);
          catastrophicVariants.addAll(["¡Claro, entren! Nos hace falta carne fresca para las celdas subterráneas.", "Entren. El sótano es oscuro pero allí dormirán eternamente."]);
        }
        break;
    }

    // Roll one variant from each category
    final correctTxt = correctVariants[random.nextInt(correctVariants.length)];
    final mildTxt = mildVariants[random.nextInt(mildVariants.length)];
    final modTxt = moderateVariants[random.nextInt(moderateVariants.length)];
    final catTxt = catastrophicVariants[random.nextInt(catastrophicVariants.length)];

    final correctOpt = LanguageOption(
      text: correctTxt,
      grade: 1,
      effectDescription: "+0.5 Standing with $faction.",
    );
    final mildOpt = LanguageOption(
      text: mildTxt,
      grade: 2,
      effectDescription: "-0.2 Standing with $faction. Wasted time/dirtiness.",
    );
    final modOpt = LanguageOption(
      text: modTxt,
      grade: 3,
      effectDescription: "-0.5 Standing with $faction, -0.2 Respect.",
    );
    final catOpt = LanguageOption(
      text: catTxt,
      grade: 4,
      effectDescription: "-1.0 Standing with $faction, -1.0 Admiration, possible disaster.",
    );

    // Create the shuffled Options 1-4
    final List<LanguageOption> options = [correctOpt, mildOpt, modOpt, catOpt];
    options.shuffle(random);

    final hostileOpt = LanguageOption(
      text: "We don't serve your kind here.",
      grade: 5,
      effectDescription: "Rebuff customer. Witnesses get Fear. Random Admiration/Respect loss.",
    );

    return LanguageEncounter(
      id: id,
      promptEnglish: promptEnglish,
      promptForeign: promptForeign,
      languageName: langName,
      languageCode: langCode,
      faction: faction,
      options: options,
      hostileOption: hostileOpt,
    );
  }
}
