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
      if (roll < 0.40) return 'Gnomes of Zurich';
      if (roll < 0.80) return 'Rosicrucians';
      final rem = allFactions.where((f) => f != 'Gnomes of Zurich' && f != 'Rosicrucians').toList();
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
    final langName = lang['name']!;

    final faction = selectFactionForLanguage(langCode, random);

    // Prompt texts
    String promptEnglish = '';
    String promptForeign = '';

    // Options variants
    final List<String> correctVariants = [];
    final List<String> mildVariants = [];
    final List<String> moderateVariants = [];
    final List<String> catastrophicVariants = [];

    switch (selectedId) {
      case 1: // Restroom Query
        promptEnglish = "Excuse me, where is the restroom?";
        if (langCode == 'FR') promptForeign = "Excusez-moi, où sont les toilettes?";
        if (langCode == 'IT') promptForeign = "Scusi, dov'è il bagno?";
        if (langCode == 'DE') promptForeign = "Entschuldigung, wo ist die Toilette?";
        if (langCode == 'ES') promptForeign = "¿Disculpe, dónde está el baño?";

        correctVariants.addAll([
          "Go down the main hall and take the first door on your left.",
          "First door on the left, down the corridor."
        ]);
        mildVariants.addAll([
          "I think there is one somewhere in the backyard, or maybe the kitchen?",
          "Somewhere upstairs. Just walk around until you find a door."
        ]);
        moderateVariants.addAll([
          "Just use the nearest bush outside. We do not have public facilities.",
          "Clean teeth? No, we do not brush here. Go away."
        ]);
        catastrophicVariants.addAll([
          "The cellar is open, just relieve yourself down there next to the alchemical jars.",
          "Downstairs. Open door." // Slipping in cellar
        ]);
        break;

      case 2: // Closing Time
        promptEnglish = "What time do you close?";
        if (langCode == 'FR') promptForeign = "À quelle heure fermez-vous?";
        if (langCode == 'IT') promptForeign = "A che ora chiudete?";
        if (langCode == 'DE') promptForeign = "Um wie viel Uhr schließen Sie?";
        if (langCode == 'ES') promptForeign = "¿A qué hora cierran?";

        correctVariants.addAll([
          "We close at ten o'clock in the evening, but you are welcome to stay until then.",
          "Ten o'clock tonight."
        ]);
        mildVariants.addAll([
          "Usually we close whenever we feel like it. Maybe in an hour?",
          "Soon, probably. Or later. Depending on the moon."
        ]);
        moderateVariants.addAll([
          "Why do you care? Just buy your things and leave.",
          "Yes, we sell fine local potatoes. Two coins a pound."
        ]);
        catastrophicVariants.addAll([
          "We closed an hour ago. You are trespassing right now!",
          "We closed for dirty peasants like you long ago. Get off my lawn!"
        ]);
        break;

      case 3: // Open Status
        promptEnglish = "Are you open right now?";
        if (langCode == 'FR') promptForeign = "Êtes-vous ouvert actuellement?";
        if (langCode == 'IT') promptForeign = "Siete aperti in questo momento?";
        if (langCode == 'DE') promptForeign = "Haben Sie gerade geöffnet?";
        if (langCode == 'ES') promptForeign = "¿Están abiertos ahora mismo?";

        correctVariants.addAll([
          "Yes, we are open and ready to serve you. Please come in!",
          "Yes, come in!"
        ]);
        mildVariants.addAll([
          "Well, the doors are unlocked, so I guess we are open.",
          "Door open. You enter, maybe? We do stuff."
        ]);
        moderateVariants.addAll([
          "No, but you can stand outside in the rain and wait.",
          "Bananas are yellow. Do you like bananas?"
        ]);
        catastrophicVariants.addAll([
          "Open? No, this is a restricted zone! Guards, seize this spy!",
          "We only open to drain the blood of travellers. Enter!"
        ]);
        break;

      case 4: // Direction to Town
        promptEnglish = "How do I get to town from here?";
        if (langCode == 'FR') promptForeign = "Comment aller en ville depuis d'ici?";
        if (langCode == 'IT') promptForeign = "Come arrivo in città da qui?";
        if (langCode == 'DE') promptForeign = "Wie komme ich von hier aus in die Stadt?";
        if (langCode == 'ES') promptForeign = "¿Cómo se va al pueblo desde aquí?";

        correctVariants.addAll([
          "Follow the main dirt road east for two miles, you can't miss it.",
          "Take dirt road east. Two miles straight."
        ]);
        mildVariants.addAll([
          "Just head towards the sunrise. It's somewhere out that way.",
          "Walk past the big tree, then turn where the old cow died."
        ]);
        moderateVariants.addAll([
          "Go through the Glarus forest path at night. It's a shortcut.",
          "Town is boring. Stay here and drink raw alcohol instead."
        ]);
        catastrophicVariants.addAll([
          "Walk straight through the militarized watchtower lane without showing papers.",
          "Go lane. Don't stop." // Shot by guards
        ]);
        break;

      case 5: // Manager Escalation
        promptEnglish = "I would like to speak with the manager!";
        if (langCode == 'FR') promptForeign = "Je voudrais parler au responsable!";
        if (langCode == 'IT') promptForeign = "Vorrei parlare con il manager!";
        if (langCode == 'DE') promptForeign = "Ich möchte mit dem Geschäftsführer sprechen!";
        if (langCode == 'ES') promptForeign = "¡Me gustaría hablar con el gerente!";

        correctVariants.addAll([
          "I am the Master of the manor. How can I help resolve your issue?",
          "I am in charge. What is wrong?"
        ]);
        mildVariants.addAll([
          "The manager is currently dissecting a specimen. You can wait a couple of hours.",
          "Boss busy cutting meat. Wait or go."
        ]);
        moderateVariants.addAll([
          "There is no manager. I run this place, and I say your complaint is invalid.",
          "Manager? We only sell cabbage. Want cabbage?"
        ]);
        catastrophicVariants.addAll([
          "You want a manager? Let me introduce you to my flesh golem. He handles customer service.",
          "Idiots like you don't deserve manager attention. Get out before I test my poisons on you."
        ]);
        break;

      case 6: // Business Tenure
        promptEnglish = "How long have you been in business?";
        if (langCode == 'FR') promptForeign = "Depuis combien de temps êtes-vous en activité?";
        if (langCode == 'IT') promptForeign = "Da quanto tempo siete in attività?";
        if (langCode == 'DE') promptForeign = "Wie lange sind Sie schon im Geschäft?";
        if (langCode == 'ES') promptForeign = "¿Cuánto tiempo llevan en the negocio?";

        correctVariants.addAll([
          "Our family estate has served this Canton for over three generations.",
          "Three generations in Glarus."
        ]);
        mildVariants.addAll([
          "A few years, I think. Time blends together in the laboratory.",
          "We here since some years. I do not count days."
        ]);
        moderateVariants.addAll([
          "None of your business. We don't keep records for nosey strangers.",
          "We opened at seven. Breakfast is done."
        ]);
        catastrophicVariants.addAll([
          "Since before the outbreak. Back when we didn't have to hide the bodies.",
          "Since the government allowed us to experiment on the local orphans."
        ]);
        break;

      case 7: // Restaurant Recommendations
        promptEnglish = "Do you know anywhere good to eat around here?";
        if (langCode == 'FR') promptForeign = "Connaissez-vous un bon endroit pour manger par ici?";
        if (langCode == 'IT') promptForeign = "Conosce un buon posto dove mangiare qui vicino?";
        if (langCode == 'DE') promptForeign = "Kennen Sie hier in der Nähe ein gutes Restaurant?";
        if (langCode == 'ES') promptForeign = "¿Conoce algún buen lugar para comer por aquí?";

        correctVariants.addAll([
          "Our own Manor Dining Hall serves the finest local cuisine in the Canton.",
          "Eat here! Our Dining Hall is excellent."
        ]);
        mildVariants.addAll([
          "The tavern down the road has some decent bread and cheap beer.",
          "Try town. Some places have food, if the rats haven't eaten it."
        ]);
        moderateVariants.addAll([
          "I heard the local soldiers eat wild crows. Maybe try that?",
          "Eating is a weakness of the biological flesh. Purge it."
        ]);
        catastrophicVariants.addAll([
          "Eat? The alchemical waste dump has some glowing mushrooms that look delicious.",
          "Mushrooms in cellar. Eat."
        ]);
        break;

      case 8: // Warranty Spam (Humorous)
        promptEnglish = "Do you have a moment to talk about your car’s extended warranty?";
        if (langCode == 'FR') promptForeign = "Avez-vous un moment pour parler de la garantie prolongée de votre véhicule?";
        if (langCode == 'IT') promptForeign = "Ha un momento per parlare della garanzia estesa della sua auto?";
        if (langCode == 'DE') promptForeign = "Haben Sie einen Moment Zeit, um über die verlängerte Garantie Ihres Autos zu sprechen?";
        if (langCode == 'ES') promptForeign = "¿Tiene un momento para hablar sobre la garantía extendida de su auto?";

        correctVariants.addAll([
          "We only operate wooden steam-carriages here, so we must decline your offer.",
          "We do not own cars. Good day."
        ]);
        mildVariants.addAll([
          "What is a 'car'? Is this some new alchemical engine?",
          "Tell me more about this warranty. Does it cover dragon attacks?"
        ]);
        moderateVariants.addAll([
          "I am going to cast a spell on you if you don't step off my porch.",
          "My teeth are clean. Go away, dentist."
        ]);
        catastrophicVariants.addAll([
          "I will sign up! Here is my signature and 400 CHF in gold coins.",
          "Yes, take money. Write papers."
        ]);
        break;

      case 9: // Wait Time
        promptEnglish = "How long is the wait?";
        if (langCode == 'FR') promptForeign = "Combien de temps faut-il attendre?";
        if (langCode == 'IT') promptForeign = "Quanto tempo c'è da aspettare?";
        if (langCode == 'DE') promptForeign = "Wie lange ist die Wartezeit?";
        if (langCode == 'ES') promptForeign = "¿Cuánto dura la espera?";

        correctVariants.addAll([
          "It should be no longer than ten minutes. Please make yourself comfortable.",
          "Ten minutes. Sit down, please."
        ]);
        mildVariants.addAll([
          "Maybe twenty minutes, maybe an hour. We are very busy today.",
          "Some time. Depending on how many people die inside first."
        ]);
        moderateVariants.addAll([
          "It takes as long as it takes. Stop asking.",
          "We don't take reservations. Stand outside."
        ]);
        catastrophicVariants.addAll([
          "The wait is indefinite. Actually, we are selecting volunteers for human experimentation now!",
          "Wait forever, you dog! Your face is offending my eyes."
        ]);
        break;

      case 10: // Bible Preachers
        promptEnglish = "We're just stopping by for a few minutes to share a positive, encouraging thought from the Bible with our neighbors.";
        if (langCode == 'FR') promptForeign = "Nous passons juste quelques minutes pour partager une pensée positive et encourageante de la Bible avec nos voisins.";
        if (langCode == 'IT') promptForeign = "Ci fermiamo solo per pochi minuti per condividere un pensiero positivo e incoraggiante della Bibbia con i nostri vicini.";
        if (langCode == 'DE') promptForeign = "Wir schauen nur kurz vorbei, um einen positiven, ermutigenden Gedanken aus der Bibel mit unseren Nachbarn zu teilen.";
        if (langCode == 'ES') promptForeign = "Sólo pasamos unos minutos para compartir un pensamiento positivo y alentador de la Biblia con nuestros vecinos.";

        correctVariants.addAll([
          "Thank you for your blessings. Have a peaceful day on your travels.",
          "Thank you. Blessings on your journey."
        ]);
        mildVariants.addAll([
          "We are busy with scientific work, but thank you anyway.",
          "No bible. We do research. Go away but nicely."
        ]);
        moderateVariants.addAll([
          "Keep your holy texts away from my manor. We worship logic and science here.",
          "No, the restrooms are closed. Use the grass."
        ]);
        catastrophicVariants.addAll([
          "Heretics! Release the undead bats to cleanse this holy nuisance!",
          "Your god is dead and my creations will consume your souls. Die!"
        ]);
        break;

      case 11: // Room Rental (Tavern / Hotel)
        promptEnglish = "Is it possible to rent a room?";
        if (langCode == 'FR') promptForeign = "Est-il possible de louer une chambre?";
        if (langCode == 'IT') promptForeign = "È possibile affittare una camera?";
        if (langCode == 'DE') promptForeign = "Kann man hier ein Zimmer mieten?";
        if (langCode == 'ES') promptForeign = "¿Es possibile alquilar una habitación?";

        correctVariants.addAll([
          "Yes, we have clean rooms available in the Guest Wing for 40 CHF a night.",
          "Yes, rooms are 40 CHF. Guest wing."
        ]);
        mildVariants.addAll([
          "We have an old closet in the servants quarters if you don't mind the rats.",
          "Maybe a bed. Servants room. Rats are free."
        ]);
        moderateVariants.addAll([
          "Rent? No, we only house members of the secret societies.",
          "I do not know. Go ask the horse in the stable."
        ]);
        catastrophicVariants.addAll([
          "We only rent rooms to those willing to sleep in the dissection laboratory.",
          "We do not rent to trash like you. Go sleep in the manure pile!"
        ]);
        break;

      case 12: // Clinic Emergency (Infirmary)
        promptEnglish = "My father is having a medical emergency!";
        if (langCode == 'FR') promptForeign = "Mon père a une urgence médicale!";
        if (langCode == 'IT') promptForeign = "Mio padre ha un'emergenza medica!";
        if (langCode == 'DE') promptForeign = "Mein Vater hat einen medizinischen Notfall!";
        if (langCode == 'ES') promptForeign = "¡Mi padre tiene una emergencia médica!";

        correctVariants.addAll([
          "Bring him to the Infirmary immediately. I will fetch the physician.",
          "Infirmary is open. Bring him inside now."
        ]);
        mildVariants.addAll([
          "Fill out these intake documents first, then wait in the queue.",
          "Paperwork first. Name, age, blood type. Write it down."
        ]);
        moderateVariants.addAll([
          "We don't treat non-residents. Try the apothecary in town.",
          "Have you tried giving him warm beer? It cures most fevers."
        ]);
        catastrophicVariants.addAll([
          "A medical emergency? Perfect, we need fresh organs for our next golem construction!",
          "Let him die. It saves us the trouble of burying him."
        ]);
        break;

      case 13: // Sickness (Dentistry / Outbreak Ward)
        promptEnglish = "I’ve been coughing up blood, is it alright if I come in?";
        if (langCode == 'FR') promptForeign = "Je crache du sang, puis-je entrer?";
        if (langCode == 'IT') promptForeign = "Ho sputato sangue, posso entrare?";
        if (langCode == 'DE') promptForeign = "Ich habe Blut gehustet, darf ich reinkommen?";
        if (langCode == 'ES') promptForeign = "He estado tosiendo sangre, ¿está bien si entro?";

        correctVariants.addAll([
          "Please enter the quarantine ward immediately so we can treat your lungs safely.",
          "Quarantine ward. Enter quickly."
        ]);
        mildVariants.addAll([
          "Coughing blood? Try drinking some warm tea with honey first.",
          "Drink vinegar. It stops the bleeding, sometimes."
        ]);
        moderateVariants.addAll([
          "Stay away! You are going to infect the entire estate! Go back to the valley.",
          "My teeth are fine, thank you. Go see the barber."
        ]);
        catastrophicVariants.addAll([
          "No problem, just sit in the main dining hall next to the kitchen prep table.",
          "Sit in dining room. Eat soup." // Sickness outbreak
        ]);
        break;

      case 14: // Reservations (Dining Hall)
        promptEnglish = "Do you take reservations?";
        if (langCode == 'FR') promptForeign = "Prenez-vous des réservations?";
        if (langCode == 'IT') promptForeign = "Accettate prenotazioni?";
        if (langCode == 'DE') promptForeign = "Nehmen Sie Reservierungen an?";
        if (langCode == 'ES') promptForeign = "¿Aceptan reservas?";

        correctVariants.addAll([
          "Yes, we can reserve a private table for your party. For what time?",
          "Yes. Table for how many?"
        ]);
        mildVariants.addAll([
          "Only if you pay a reservation deposit of 20 CHF upfront.",
          "Maybe, if we have tables. We are very popular, you know."
        ]);
        moderateVariants.addAll([
          "No reservations. You line up outside like everyone else.",
          "We only cook potatoes. No seats, just potatoes."
        ]);
        catastrophicVariants.addAll([
          "Reservations are reserved for nobility. Peasants are not allowed to book tables.",
          "We don't take bookings for pigs. Go eat in the mud!"
        ]);
        break;

      case 15: // Distributor (Distillery)
        promptEnglish = "Are you happy with your present liquor distributor?";
        if (langCode == 'FR') promptForeign = "Êtes-vous satisfait de votre distributeur d'alcool actuel?";
        if (langCode == 'IT') promptForeign = "È soddisfatto del suo attuale distributore di alcolici?";
        if (langCode == 'DE') promptForeign = "Sind Sie mit Ihrem aktuellen Spirituosen-Händler zufrieden?";
        if (langCode == 'ES') promptForeign = "¿Está contento con su actual distribuidor de licores?";

        correctVariants.addAll([
          "We distill our own high-quality spirits, but we are open to reviewing raw ingredient offers.",
          "We make our own. But we buy yeast/grain."
        ]);
        mildVariants.addAll([
          "Yes, our current supplier is fine. We don't need changes.",
          "Maybe. Bring a sample of your gin, and we will talk later."
        ]);
        moderateVariants.addAll([
          "Your distributor prices are probably a scam anyway. Leave us alone.",
          "No, we only drink milk here. Milk is pure."
        ]);
        catastrophicVariants.addAll([
          "We only buy illegal black-market spirits, are you selling those?",
          "If you try to sell me your cheap poison again, I will lock you in the cellar with the rats."
        ]);
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
      id: selectedId,
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
