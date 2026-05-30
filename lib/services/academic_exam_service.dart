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
import '../models/graduate_school_state.dart';

class ExamQuestion {
  final String question;
  final List<String> choices;
  final int correct;

  ExamQuestion({
    required this.question,
    required this.choices,
    required this.correct,
  });

  ExamQuestion copyWith({
    String? question,
    List<String>? choices,
    int? correct,
  }) {
    return ExamQuestion(
      question: question ?? this.question,
      choices: choices ?? this.choices,
      correct: correct ?? this.correct,
    );
  }
}

class AcademicTome {
  final String title;
  final String content;
  AcademicTome({required this.title, required this.content});
}

class AcademicExamService {
  static final _random = Random();

  static final List<AcademicTome> referenceTomes = [
    AcademicTome(
      title: "TOME I: JURISPRUDENCE & THE COVENANT OF THE CONTRACT",
      content: "THE PRINCIPLES OF CIVIC JURISPRUDENCE\n\n"
          "1. THE NATURE OF CONTRACTS: A covenant is legally established only when there is a clear, uncoerced Offer, a mutual and uncoerced Acceptance, and a valuable Consideration (representing a dynamic exchange of value, whether alchemical reagents, land, or coin). Without all three elements, no covenant stands.\n\n"
          "2. HEARSAY AND ADMISSIBILITY: Hearsay refers to any out-of-court statement offered by a witness in a trial to establish the absolute truth of the matter asserted. Such statements are fundamentally inadmissible due to the lack of direct cross-examination, unless they fall under a specific, recognized exception (such as dying declarations or business ledgers).\n\n"
          "3. DEGREE OF KINSHIP: Kinship consanguinity is calculated by tracing up to a common ancestor and down to the relation. Your grandmother's cousin's granddaughter is classified precisely in the sixth degree of consanguinity, commonly referred to in modern law as a second cousin once removed.\n\n"
          "4. ADVERSE POSSESSION: Land acquisition by continuous occupation requires uninterrupted, open, and hostile possession for a period of twenty consecutive years. If the landowner does not object within this twenty-year term, title passes to the occupier.",
    ),
    AcademicTome(
      title: "TOME II: PHARMACEUTICAL CHEMISTRY & ELECTROLYTE KINETICS",
      content: "ALCHEMICAL KINETICS & PHARMACY\n\n"
          "1. THE PH LOGARITHM: The pH scale measures the logarithmic concentration of hydrogen ions. Neutral pH is precisely 7.0. Any value below 7.0 is acidic, representing a high density of free protons. Any value above 7.0 is basic (alkaline).\n\n"
          "2. OXIDATION POTENTIALS: Oxidation represents a fundamental chemical reaction where a molecule or atom releases valence electrons to a catalytic medium. The substance that loses electrons is oxidized. The substance that gains them is reduced.\n\n"
          "3. ACID-BASE CONJUGATES: A conjugate base is the chemical species remaining after an acid has donated a proton. For instance, when bisulfate (HSO4-) donates its proton, it transforms into its conjugate base, sulfate (SO4^2-).\n\n"
          "4. LIQUID DISPENSING: A percent solution represents grams of solute dissolved in one hundred milliliters of solvent. A 10% solution therefore contains exactly 10 grams of alchemical salt per 100 mL of total liquid.",
    ),
    AcademicTome(
      title: "TOME III: DE HUMANI CORPORIS FABRICA: CLINICAL ANATOMY",
      content: "HUMAN ANATOMY & PHYSIOLOGY\n\n"
          "1. THE SKELETAL SYSTEM: The femur is the longest and strongest bone in the human skeletal framework, located inside the thigh. The humerus is the long bone of the upper arm, running from the shoulder joint to the elbow.\n\n"
          "2. PACEMAKER CURRENT: Cardiac pace and rhythm are coordinated by the sinoatrial (SA) node, which initiates spontaneous electrical depolarization waves across the atria.\n\n"
          "3. CRANIAL NERVES: The seventh cranial nerve (CN VII), commonly known as the facial nerve, controls all muscles of facial expression. Sensory trigeminal (CN V) manages facial sensation and mastication.\n\n"
          "4. SARCOMERE STRUCTURE: During active muscular contraction, the sarcomere shortens. The A band, representing thick myosin filaments, remains completely constant in length. Conversely, the I band and the H zone contract and shorten.",
    ),
    AcademicTome(
      title: "TOME IV: CLINICAL PATHOLOGY & SURGICAL METHODS",
      content: "SURGERY, DISPENSING & TRIAGE\n\n"
          "1. ABDOMINAL INCISIONS: From superficial to deep, a surgeon must incise through: Skin, Camper's fascia (superficial fatty layer), Scarpa's fascia (deep membranous layer), External oblique muscle, Internal oblique muscle, and Transversus abdominis.\n\n"
          "2. CARDIAC ISCHEMIA: A sudden-onset radiating chest pain accompanied by ST-segment elevations on a cardiograph indicates a severe ST-elevation myocardial infarction (STEMI), requiring immediate arterial reperfusion.\n\n"
          "3. REAGENT STORAGE: High-potency refined organic elixirs undergo photolytic degradation when exposed to ambient ultraviolet light. Storing them in amber glass vials absorbs light wavelengths and prevents degradation.\n\n"
          "4. DOSAGE CALCULATIONS: Pediatric and specialized dosages require multiplying the patient's weight in kilograms by the dosage per kilogram. If a patient weighs 80 kg and requires 5 mg/kg of a reagent, they require 400 mg total.",
    ),
  ];

  // LAW SCHOOL QUESTIONS (20 completely unique per stage = 60 total)
  static final List<ExamQuestion> _lawAdmissions = [
    ExamQuestion(question: "LSAT ANALYTICAL 1:\nFour scholars (Flaubert, Giles, Alphonse, Kael) speak. Alphonse speaks third. Giles speaks immediately after Kael. Who speaks first?", choices: ["Flaubert", "Giles", "Kael", "Alphonse"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 2:\nA must perform before B. C must perform immediately after D. D is scheduled second. Who performs first?", choices: ["A", "B", "C", "D"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 3:\nNo politicians are honest. All teachers are honest. Therefore, which is true?", choices: ["No teachers are politicians", "Some politicians are teachers", "All teachers are politicians", "None"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 4:\nIf X is older than Y, and Y is older than Z, which must be true?", choices: ["X is older than Z", "Z is older than X", "Y is younger than Z", "None"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 5:\nSome novelists are historians. All historians are academic. Therefore, which must be true?", choices: ["Some novelists are academic", "No novelists are academic", "All academics are novelists", "None"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 6:\nEvent A occurs before B. C occurs after B. If C is third, which is second?", choices: ["B", "A", "C", "Cannot tell"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 7:\nEvery zombie is slow. Some slow entities are constructs. Therefore, which is true?", choices: ["None of the below", "Zombies are constructs", "All constructs are slow", "No constructs are slow"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 8:\nGiles attends only if Flaubert attends. Flaubert never attends if Kael is present. If Kael is present:", choices: ["Giles does not attend", "Giles must attend", "Flaubert attends", "Kael does not attend"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 9:\nFive cases (1, 2, 3, 4, 5) are filed. 3 is filed after 2. 1 is before 2. 5 is last. Which is filed second?", choices: ["2", "1", "3", "4"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 10:\nIf Kael is older than Giles, and Giles is younger than Flaubert, who is the youngest?", choices: ["Cannot be determined", "Kael", "Giles", "Flaubert"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 11:\nNo alchemists are members. Some members are Glarus workers. Therefore:", choices: ["Some Glarus workers are not alchemists", "All Glarus workers are alchemists", "No alchemists are Glarus workers", "None"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 12:\nIf contract A is void, then contract B is also void. Contract B is not void. Therefore:", choices: ["Contract A is not void", "Contract A is void", "Contract B is void", "None"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 13:\nAll constructs are metallic. Some constructs are reanimated. Therefore:", choices: ["Some metallic entities are reanimated", "All metallic entities are reanimated", "No reanimated entities are metallic", "None"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 14:\nIf Alphonse graduates, Giles retires. Alphonse does not graduate. Therefore:", choices: ["Giles retirement is undetermined", "Giles must retire", "Giles does not retire", "Alphonse retires"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 15:\nFour elixirs are ranked. Reagent 1 is better than 2. Reagent 3 is worse than 2. Reagent 4 is equal to 1. Which is the worst?", choices: ["Reagent 3", "Reagent 2", "Reagent 1", "Reagent 4"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 16:\nEvery contract requires consideration. Covenants are contracts. Therefore:", choices: ["Covenants require consideration", "Covenants do not require consideration", "Consideration requires covenants", "None"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 17:\nIf Kael is in Rolle, Giles is in Rolle. Giles is in Lausanne. Therefore:", choices: ["Kael is not in Rolle", "Kael is in Rolle", "Kael is in Lausanne", "None"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 18:\nSome elixirs are poisonous. No healthy drinks are poisonous. Therefore:", choices: ["Some elixirs are not healthy drinks", "All elixirs are healthy drinks", "No healthy drinks are elixirs", "None"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 19:\nIf construct 1 is fast, construct 2 is slow. Construct 2 is fast. Therefore:", choices: ["Construct 1 is slow", "Construct 1 is fast", "Construct 2 is slow", "None"], correct: 0),
    ExamQuestion(question: "LSAT ANALYTICAL 20:\nAll lawyers are educated. Some educated are corrupt. Therefore:", choices: ["None of the below", "Some lawyers are corrupt", "No lawyers are corrupt", "All educated are lawyers"], correct: 0),
  ];

  static final List<ExamQuestion> _lawAcademic = [
    ExamQuestion(question: "LAW ACADEMIC 1:\nIn legal kinship consanguinity, what is the precise term for your grandmother's cousin's granddaughter?", choices: ["Second cousin once removed", "Third cousin", "Second cousin", "First cousin twice removed"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 2:\nWhat are the three core, globally foundational elements required to form a legally binding contract?", choices: ["Offer, Acceptance, and Consideration", "Agreement, Signature, and Notarization", "Offer, Witnessing, and Collateral", "Filing, Registration, and Fee Payment"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 3:\nWhich of the following qualifies as 'hearsay' in common law jurisdictions?", choices: ["An out-of-court statement offered to prove the truth of the matter asserted.", "Direct visual observation testified to by a witness.", "A written contract signed by both parties.", "An anatomy treatise description."], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 4:\nWhat is the term for an unintentional civil wrong resulting from a failure to take reasonable care?", choices: ["Negligence", "Trespass", "Libel", "Battery"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 5:\nWhat is the term for the mental intent required to constitute a crime in international legal theory?", choices: ["Mens rea", "Actus reus", "Habeas corpus", "Stare decisis"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 6:\nWhat is the term for the transfer of property ownership to another upon death without a valid will?", choices: ["Intestate succession", "Probate covenant", "Escheatment", "Adverse possession"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 7:\nWhat is the legal term for a court order forcing a party to perform a specific act required by contract?", choices: ["Specific performance", "Injunction", "Damages", "Rescission"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 8:\nUnder the statute of frauds, which of the following contracts must always be in writing to be enforceable?", choices: ["Contracts for the sale of land interests", "Contracts for minor household services", "Agreements to water garden beds", "Contracts under 50 CHF value"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 9:\nWhat is the legal term for a contract where one party is unfairly coerced or threatened into signing?", choices: ["Duress", "Undue influence", "Misrepresentation", "Mistake"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 10:\nWhich defense completely excuses criminal liability if the defendant acted to prevent an imminent greater harm?", choices: ["Necessity", "Duress", "Self-defense", "Entrapment"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 11:\nWhat is the standard of proof required to convict a defendant in a criminal trial?", choices: ["Beyond a reasonable doubt", "Preponderance of evidence", "Clear and convincing evidence", "Reasonable suspicion"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 12:\nWhat is the term for property that reverts to the state because there are no legal heirs or wills?", choices: ["Escheat", "Adverse possession", "Emminent domain", "Intestacy"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 13:\nWhich type of damage aims to punish a defendant for extremely reckless or malicious behavior?", choices: ["Punitive damages", "Compensatory damages", "Nominal damages", "Liquidated damages"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 14:\nWhat is the term for a written defamation that harms a person's reputation?", choices: ["Libel", "Slander", "Negligence", "Assault"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 15:\nWhat is the legal term for an agreement to accept a different performance than what was originally contracted?", choices: ["Accord and satisfaction", "Novation", "Rescission", "Breach of contract"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 16:\nWhich legal doctrine stands for the principle that past judicial decisions bind future decisions?", choices: ["Stare decisis", "Res judicata", "Obiter dictum", "Ratio decidendi"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 17:\nWhat is the term for a minor contract breach that does not excuse the non-breaching party from performance?", choices: ["Immaterial breach", "Material breach", "Anticipatory repudiation", "Fundamental breach"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 18:\nWhich type of contract is formed by spoken words rather than written text?", choices: ["Oral contract", "Implied contract", "Formal contract", "Adhesion contract"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 19:\nWhat is the term for an offer that remains open for a specified time because consideration was paid?", choices: ["Option contract", "Firm offer", "Counteroffer", "Gratuitous promise"], correct: 0),
    ExamQuestion(question: "LAW ACADEMIC 20:\nWhich standard of proof is utilized in standard civil tort trials?", choices: ["Preponderance of the evidence", "Beyond a reasonable doubt", "Clear and convincing", "Reasonable suspicion"], correct: 0),
  ];

  static final List<ExamQuestion> _lawBoard = [
    ExamQuestion(question: "LAW BOARD 1:\nAn alchemist sells a health potion that causes severe hair loss. The alchemist did not warn the client. What liability arises?", choices: ["Strict product liability due to failure to warn.", "Breach of trust without monetary damages.", "Criminal battery of Glarus.", "No liability since the client drank it willingly."], correct: 0),
    ExamQuestion(question: "LAW BOARD 2:\nDuring a murder trial, the prosecution attempts to introduce a diary entry where the deceased wrote 'Alphonse looks suspicious.' Is this admissible?", choices: ["Inadmissible hearsay, unless falling under a recognized exception.", "Fully admissible as direct character evidence.", "Inadmissible due to alchemical interference.", "Admissible only if validated by butler Giles."], correct: 0),
    ExamQuestion(question: "LAW BOARD 3:\nA neighbor occupies Glarus forestland for twenty continuous years without Alphonse's objection. What legal claim arises?", choices: ["Adverse possession / prescriptive easement.", "Immediate domain liquidation.", "Contractual buyout option.", "No claim; landowners retain perpetual title."], correct: 0),
    ExamQuestion(question: "LAW BOARD 4:\nAn estate administrator accepts private funds from a Rolle merchant in exchange for exclusive rights. What is this legal wrong?", choices: ["Bribery and breach of fiduciary duty", "Embezzlement", "Standard trade arrangement", "Larceny"], correct: 0),
    ExamQuestion(question: "LAW BOARD 5:\nIf a construct goes rogue and breaks regional property, under international vicarious liability, who bears responsibility?", choices: ["The construct's creator/owner (strict liability).", "The hamlet municipality.", "The butler Giles as head of household.", "No one; constructs are acts of nature."], correct: 0),
    ExamQuestion(question: "LAW BOARD 6:\nFlaubert promises to pay Kael 50 CHF if Kael finds Flaubert's lost journal. Kael finds it. What contract is established?", choices: ["Unilateral contract", "Bilateral contract", "Implied in law contract", "Void contract"], correct: 0),
    ExamQuestion(question: "LAW BOARD 7:\nA pamphlet prints that Glarus manor is breeding plague zombies, causing manor reputation to collapse. What action stands?", choices: ["Libel", "Slander", "Trespass to chattels", "Negligence"], correct: 0),
    ExamQuestion(question: "LAW BOARD 8:\nAlphonse rents Glarus outbuildings to a chemist. The chemist uses it to produce toxic opiate vapors that sicken neighbors. Is Alphonse liable?", choices: ["Yes, under strict liability for private nuisance", "No, because the tenant created the vapors", "No, since it was private land", "Yes, for trespass to land"], correct: 0),
    ExamQuestion(question: "LAW BOARD 9:\nA contract has a clause stating: 'If the set is not built by winter, the builder pays 500 CHF.' What is this clause called?", choices: ["Liquidated damages clause", "Punitive damages clause", "Exculpatory clause", "Condition precedent"], correct: 0),
    ExamQuestion(question: "LAW BOARD 10:\nAn alchemist buys glass vials under a contract. The supplier sends the wrong vials. The alchemist accepts and uses them anyway. Can he sue?", choices: ["No, acceptance of non-conforming goods waives breach", "Yes, under strict product liability", "Yes, because the contract is void", "No, unless he sues within 1 day"], correct: 0),
    ExamQuestion(question: "LAW BOARD 11:\nWhich defense protects a public inquisitor from defamation liability for statements made during an official court proceeding?", choices: ["Absolute privilege", "Qualified privilege", "Truth only", "No defense exists"], correct: 0),
    ExamQuestion(question: "LAW BOARD 12:\nA worker is injured at Glarus blacksmith forge due to his own carelessness, but the forge lacked safety guards. Under comparative negligence:", choices: ["Damages are reduced in proportion to the worker's fault", "The worker gets zero damages due to contributory fault", "The manor bears 100% liability regardless", "The contract is voided"], correct: 0),
    ExamQuestion(question: "LAW BOARD 13:\nAlphonse sells a carriage to Flaubert, stating: 'This carriage is sold as-is, with all faults.' What does this clause do?", choices: ["Excludes all implied warranties of merchantability", "Void the contract entirely", "Transfers all liability to Rolle council", "Guarantees carriage safety"], correct: 0),
    ExamQuestion(question: "LAW BOARD 14:\nKael enters Glarus cellar without permission to search for records. What civil wrong did Kael commit?", choices: ["Trespass to land", "Nuisance", "Conversion", "Larceny"], correct: 0),
    ExamQuestion(question: "LAW BOARD 15:\nA contract specifies: 'Subject to the manor architect approving the plans.' What is this approval requirement?", choices: ["Condition precedent", "Liquidated damage", "Accord and satisfaction", "Illusory promise"], correct: 0),
    ExamQuestion(question: "LAW BOARD 16:\nIf Alphonse dies without a will or heirs, what happens to Glarus manor under neutral Swiss law?", choices: ["Reverts to the state by escheat", "Stays with Giles indefinitely", "Sold at public auction immediately", "None of the above"], correct: 0),
    ExamQuestion(question: "LAW BOARD 17:\nA merchant promises to sell wood only to Glarus in exchange for Glarus buying all its wood from him. What contract is this?", choices: ["Exclusive dealing contract", "Requirements contract", "Outputs contract", "Unilateral contract"], correct: 0),
    ExamQuestion(question: "LAW BOARD 18:\nKael publishes Giles' private alchemical letters without Giles' consent. What tort did Kael commit?", choices: ["Invasion of privacy (public disclosure of private facts)", "Libel", "Conversion", "Infliction of emotional distress"], correct: 0),
    ExamQuestion(question: "LAW BOARD 19:\nAlphonse threatens to burn a supplier's shop down unless they sell sulfur at half price. The supplier signs. What defense stands?", choices: ["Duress", "Undue influence", "Unconscionability", "Fraud in execution"], correct: 0),
    ExamQuestion(question: "LAW BOARD 20:\nFlaubert transfers Glarus library ownership to Giles, but retains the right to use it during Flaubert's lifetime. What is Flaubert's interest?", choices: ["Life estate", "Fee simple absolute", "Reversionary interest", "Leasehold"], correct: 0),
  ];

  // PHARMACY SCHOOL QUESTIONS (20 completely unique per stage = 60 total)
  static final List<ExamQuestion> _pharmacyAdmissions = [
    ExamQuestion(question: "PHARMACY ENTRY 1:\nAccording to standard alchemical scales, what is the precise value of a neutral pH solution?", choices: ["pH = 7.0", "pH = 0.0", "pH = 14.0", "pH = 1.0"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 2:\nIf a chemical reagent is classified as acidic, its pH value must lie inside which range?", choices: ["Below 7.0", "Exactly 7.0", "Above 7.0", "Between 10.0 and 14.0"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 3:\nWhat occurs when a molecular species undergoes oxidation in an alchemical medium?", choices: ["It releases valence electrons", "It gains valence electrons", "Its atomic nucleus splits", "It turns completely inert"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 4:\nIn a solution of alchemical salt dissolved inside distilled water, what is the salt classified as?", choices: ["Solute", "Solvent", "Catalytic reagent", "Conjugate base"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 5:\nWhat is the primary thermodynamic function of an alchemical catalyst in a chemical reaction?", choices: ["To increase the rate of reaction without being consumed.", "To neutralise basic alkaline solutions.", "To lower the pH to highly acidic.", "To absorb all valence electrons."], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 6:\nIn a redox reaction, the substance that gains electrons is said to be:", choices: ["Reduced", "Oxidized", "Neutralized", "Dissolved"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 7:\nA solution with a pH of 1.0 is classified as:", choices: ["Highly acidic", "Highly basic", "Neutral", "Weakly basic"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 8:\nWhich of the following represents a highly basic (alkaline) substance pH?", choices: ["pH = 13.0", "pH = 7.0", "pH = 4.0", "pH = 1.0"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 9:\nWhen alchemical sugar is dissolved in water, what is the water classified as?", choices: ["Solvent", "Solute", "Catalyst", "Conjugate acid"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 10:\nWhat is the term for a reaction that releases heat energy into the surroundings?", choices: ["Exothermic", "Endothermic", "Isothermal", "Reversible"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 11:\nWhat is the term for a reaction that absorbs heat energy from the surroundings?", choices: ["Endothermic", "Exothermic", "Adiabatic", "Catalytic"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 12:\nWhich thermodynamic variable describes the degree of disorder in a chemical system?", choices: ["Entropy", "Enthalpy", "Gibbs free energy", "Temperature"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 13:\nWhat is the state of a reaction when the forward and reverse reaction rates are equal?", choices: ["Equilibrium", "Completion", "Saturation", "Dormancy"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 14:\nWhich scale measures the acidity or basicity of an aqueous solution?", choices: ["pH scale", "Kelvin scale", "Barometric scale", "Richter scale"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 15:\nWhat is the term for a substance that donates hydrogen ions (protons) in solution?", choices: ["Acid", "Base", "Solvent", "Catalyst"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 16:\nWhat is the term for a substance that accepts hydrogen ions (protons) in solution?", choices: ["Base", "Acid", "Solvent", "Catalyst"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 17:\nWhich law states that matter cannot be created or destroyed in a chemical reaction?", choices: ["Law of conservation of mass", "Avogadro's law", "Boyle's law", "Charles's law"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 18:\nWhat is the term for a solution that cannot dissolve any more solute at a given temperature?", choices: ["Saturated solution", "Unsaturated solution", "Supersaturated solution", "Dilute solution"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 19:\nWhich temperature scale starts at absolute zero?", choices: ["Kelvin", "Celsius", "Fahrenheit", "Rankine"], correct: 0),
    ExamQuestion(question: "PHARMACY ENTRY 20:\nWhat is the term for the substance formed as a result of a chemical reaction?", choices: ["Product", "Reactant", "Catalyst", "Solvent"], correct: 0),
  ];

  static final List<ExamQuestion> _pharmacyAcademic = [
    ExamQuestion(question: "PHARMACY ACADEMIC 1:\nWhat is the conjugate base of the bisulfate ion (HSO4-) in aqueous medium?", choices: ["SO4^2-", "H2SO4", "H3O+", "OH-"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 2:\nUsing the negative logarithm of hydrogen ion concentration, calculate the pH of a 0.01 M strong acid HCl solution:", choices: ["pH = 2.0", "pH = 1.0", "pH = 7.0", "pH = 12.0"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 3:\nUnder the Henderson-Hasselbalch formulation, if the concentration of conjugate base equals the concentration of acid, then:", choices: ["pH = pKa", "pH = 7.0", "pH = pKa + 1.0", "pH = 0.0"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 4:\nWhich organic reaction combines a carboxylic acid with an alcohol to form an ester?", choices: ["Esterification", "Saponification", "Hydrolysis", "Redox reduction"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 5:\nHow many grams of alchemical salt solute are present inside exactly 50 mL of a 10% solution?", choices: ["5.0 grams", "10.0 grams", "1.0 gram", "50.0 grams"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 6:\nIdentify the conjugate acid of water (H2O) in acidic solutions:", choices: ["H3O+", "OH-", "H2", "O2"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 7:\nWhat is the primary purpose of a buffer solution in alchemical kinetics?", choices: ["To resist changes in pH upon addition of small acid/base amounts.", "To accelerate oxidation reactions.", "To precipitate heavy alchemical metals.", "To preserve yeast in faba bean fermentation."], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 8:\nWhich functional group contains a carbon-oxygen double bond (C=O)?", choices: ["Carbonyl", "Hydroxyl", "Ether", "Amino"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 9:\nWhat is the term for compounds with the same molecular formula but different structures?", choices: ["Isomers", "Isotopes", "Allotrope", "Homologs"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 10:\nWhich organic functional group is characteristic of alcohols?", choices: ["Hydroxyl", "Carbonyl", "Carboxyl", "Ester"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 11:\nWhat type of chemical bond involves the sharing of electron pairs between atoms?", choices: ["Covalent bond", "Ionic bond", "Hydrogen bond", "Metallic bond"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 12:\nWhat type of chemical bond involves the electrostatic attraction between oppositely charged ions?", choices: ["Ionic bond", "Covalent bond", "Metallic bond", "Hydrogen bond"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 13:\nWhich equation describes pH changes in buffer solutions using pKa and logs?", choices: ["Henderson-Hasselbalch", "Nernst equation", "Gibbs-Helmholtz", "Arrhenius equation"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 14:\nWhat is the term for the minimum energy required to initiate a chemical reaction?", choices: ["Activation energy", "Enthalpy", "Entropy", "Free energy"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 15:\nWhich principle states that a system at equilibrium shifts to counteract disturbances?", choices: ["Le Chatelier's principle", "Hess's law", "Raoult's law", "Henry's law"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 16:\nWhat is the term for a solvent that contains the maximum possible amount of dissolved solute?", choices: ["Saturated", "Unsaturated", "Supersaturated", "Concentrated"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 17:\nWhat is the molecular geometry of a water molecule?", choices: ["Bent", "Linear", "Trigonal planar", "Tetrahedral"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 18:\nWhich functional group is characteristic of carboxylic acids?", choices: ["Carboxyl", "Hydroxyl", "Ester", "Ketone"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 19:\nWhat is the pH of a 0.001 M solution of the strong acid HNO3?", choices: ["pH = 3.0", "pH = 2.0", "pH = 1.0", "pH = 7.0"], correct: 0),
    ExamQuestion(question: "PHARMACY ACADEMIC 20:\nWhat organic compounds are characterized by a sweet fruit-like odor?", choices: ["Esters", "Carboxylic acids", "Alcohols", "Amines"], correct: 0),
  ];

  static final List<ExamQuestion> _pharmacyBoard = [
    ExamQuestion(question: "PHARMACY BOARD 1:\nA patient requires a dosage of 5 mg/kg of an alchemical reagent. The patient weighs 80 kg. The available stock vial has a concentration of 100 mg/5 mL. How many mL must you administer?", choices: ["20 mL", "10 mL", "5 mL", "40 mL"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 2:\nWhich internal organ serves as the primary site for the metabolic clearance and enzymatic detoxification of pharmaceutical reagents?", choices: ["Liver", "Kidneys", "Heart", "Lungs"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 3:\nSimultaneously administering a strong alkaline basic elixir with a highly acidic gastric elixir will trigger:", choices: ["Neutralization, reducing the elixir's absorption rate.", "A ten-fold increase in therapeutic potency.", "An immediate alchemical combustion.", "No kinetic alterations."], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 4:\nTo prepare a 20 mL ophthalmic vial of 0.05% solution using a 1% stock concentrate, what volume of stock solution is required?", choices: ["1.0 mL", "0.5 mL", "2.0 mL", "5.0 mL"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 5:\nRefined organic elixirs are highly susceptible to photolytic degradation. To block UV light, what packaging material is mandatory?", choices: ["Amber glass vials", "Clear flint glass", "Lead containers", "Silver flasks"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 6:\nIf a patient receives a toxic dose of an acidic reagent, alkalinizing the urine with sodium bicarbonate will:", choices: ["Increase renal excretion of the weak acid reagent.", "Lower excretion by increasing absorption.", "Cause immediate renal failure.", "Have no impact on renal clearance."], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 7:\nAn elixir has a shelf-life half-life of 24 hours. If you start with 100 mg, how much active reagent remains after 48 hours?", choices: ["25 mg", "50 mg", "12.5 mg", "0 mg"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 8:\nWhich mathematical model describes the rate at which a drug is cleared from the body relative to concentration?", choices: ["First-order elimination kinetics", "Zero-order elimination kinetics", "Michaelis-Menten saturation", "Arrhenius kinetics"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 9:\nWhat is the term for the fraction of an administered drug dose that reaches systemic circulation unchanged?", choices: ["Bioavailability", "Clearance", "Volume of distribution", "Half-life"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 10:\nWhich organ is the primary site for the excretion of water-soluble drugs and their metabolites?", choices: ["Kidneys", "Liver", "Skin", "Lungs"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 11:\nWhat is the primary mechanism of transport for most drugs across biological cell membranes?", choices: ["Passive diffusion", "Active transport", "Facilitated diffusion", "Endocytosis"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 12:\nAn alchemical elixir exhibits zero-order elimination kinetics. This means that:", choices: ["A constant amount of drug is eliminated per unit time.", "A constant fraction of drug is eliminated per unit time.", "Elimination rate is proportional to concentration.", "The half-life is constant regardless of dose."], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 13:\nWhich route of administration completely bypasses the first-pass hepatic metabolism of Rolle?", choices: ["Intravenous", "Oral", "Sublingual", "Rectal"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 14:\nWhat is the term for a drug that binds to a physiological receptor and activates it to produce a response?", choices: ["Agonist", "Antagonist", "Inhibitor", "Ligand"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 15:\nWhat is the term for a drug that binds to a physiological receptor and prevents activation?", choices: ["Antagonist", "Agonist", "Synergist", "Catalyst"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 16:\nWhich parameter represents the theoretical fluid volume required to contain the total drug dose at plasma concentration?", choices: ["Volume of distribution (Vd)", "Clearance (Cl)", "Bioavailability (F)", "Half-life (t1/2)"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 17:\nA drug has a volume of distribution (Vd) of 500 Liters. This indicates that the drug:", choices: ["Is highly distributed into tissues and fat.", "Is restricted completely to the vascular system.", "Is rapidly metabolized by the liver.", "Is highly bound to plasma proteins."], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 18:\nWhat type of drug interaction results in a combined effect greater than the sum of individual effects?", choices: ["Synergism", "Antagonism", "Tolerance", "Additivity"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 19:\nWhich drug clearance parameter measures the volume of blood cleared of drug per unit time?", choices: ["Clearance (Cl)", "Volume of distribution (Vd)", "Half-life", "Elimination rate constant"], correct: 0),
    ExamQuestion(question: "PHARMACY BOARD 20:\nTo prepare 1 Liter of a 0.9% saline solution, how many grams of NaCl solute must be dissolved?", choices: ["9.0 grams", "0.9 grams", "90.0 grams", "900.0 grams"], correct: 0),
  ];

  // MEDICINE SCHOOL QUESTIONS (20 completely unique per stage = 60 total)
  static final List<ExamQuestion> _medicineAdmissions = [
    ExamQuestion(question: "MEDICINE ENTRY 1:\nIn human skeletal anatomy, where is the humerus bone located?", choices: ["Upper Arm", "Leg", "Torso", "Skull"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 2:\nWhat is the primary physiological function of red blood cells in the human body?", choices: ["To transport oxygen via hemoglobin.", "To fight bacterial infections.", "To form clots over flesh wounds.", "To synthesize alchemical antibodies."], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 3:\nHow many distinct chambers are present in a healthy, fully developed human heart?", choices: ["Four", "Two", "Three", "Six"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 4:\nDuring cellular respiration, which metabolic waste gas is excreted by the lungs?", choices: ["Carbon Dioxide", "Oxygen", "Nitrogen", "Hydrogen"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 5:\nThe femur is the longest and strongest bone in the body, located in the:", choices: ["Thigh", "Arm", "Ribcage", "Spine"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 6:\nWhich blood vessels carry oxygen-depleted blood away from the heart to the lungs?", choices: ["Pulmonary arteries", "Pulmonary veins", "Aorta", "Vena cava"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 7:\nWhat are the primary cellular components of the nervous system responsible for transmitting signals?", choices: ["Neurons", "Glial cells", "Nephrons", "Osteocytes"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 8:\nWhich muscle separates the thoracic cavity from the abdominal cavity and aids in breathing?", choices: ["Diaphragm", "Intercostal muscles", "Rectus abdominis", "Pectoralis major"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 9:\nWhere in the human digestive tract does the majority of nutrient absorption occur?", choices: ["Small intestine", "Stomach", "Large intestine", "Esophagus"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 10:\nWhich organ produces bile, a fluid vital for digesting fats?", choices: ["Liver", "Gallbladder", "Pancreas", "Stomach"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 11:\nWhich organ stores bile until it is needed in the digestive process?", choices: ["Gallbladder", "Liver", "Pancreas", "Spleen"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 12:\nWhat is the term for the wave-like muscular contractions that move food through the digestive tract?", choices: ["Peristalsis", "Segmentation", "Mastication", "Deglutition"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 13:\nWhich blood vessels carry oxygenated blood away from the heart to Glarus tissues?", choices: ["Arteries", "Veins", "Capillaries", "Venules"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 14:\nWhat are the tiny air sacs in the lungs where gas exchange occurs?", choices: ["Alveoli", "Bronchi", "Bronchioles", "Trachea"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 15:\nWhich blood cells play a key role in the body's immune defense against pathogens?", choices: ["White blood cells (Leukocytes)", "Red blood cells", "Platelets (Thrombocytes)", "Erythrocytes"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 16:\nWhich component of blood is primarily responsible for initiating blood clotting?", choices: ["Platelets", "Red blood cells", "Plasma", "White blood cells"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 17:\nWhat is the liquid component of blood in which cells are suspended?", choices: ["Plasma", "Serum", "Lymph", "Hemoglobin"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 18:\nWhich endocrine gland is often called the 'master gland' of the body?", choices: ["Pituitary gland", "Thyroid gland", "Adrenal gland", "Pancreas"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 19:\nWhich hormone is produced by the thyroid gland to regulate basal metabolic rate?", choices: ["Thyroxine (T4)", "Calcitonin", "Parathyroid hormone", "TSH"], correct: 0),
    ExamQuestion(question: "MEDICINE ENTRY 20:\nWhich skeletal bone protects the human brain?", choices: ["Skull (Cranium)", "Ribcage", "Pelvis", "Spine"], correct: 0),
  ];

  static final List<ExamQuestion> _medicineAcademic = [
    ExamQuestion(question: "MEDICINE ACADEMIC 1:\nWhich cranial nerve is primarily responsible for facial expression?", choices: ["CN VII (Facial)", "CN V (Trigeminal)", "CN X (Vagus)", "CN XII (Hypoglossal)"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 2:\nDuring sarcomere contraction, which band/zone of the myofibril does NOT shorten?", choices: ["A Band", "I Band", "H Zone", "M Line"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 3:\nWhat is the primary electrical pacemaker of the human heart?", choices: ["Sinoatrial (SA) Node", "Atrioventricular (AV) Node", "Purkinje Fibers", "Bundle of His"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 4:\nWhich region of the brain is primarily responsible for motor coordination, balance, and posture?", choices: ["Cerebellum", "Cerebrum", "Medulla Oblongata", "Thalamus"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 5:\nWhich hormone is secreted by pancreatic beta cells to lower blood glucose concentration?", choices: ["Insulin", "Glucagon", "Adrenaline", "Cortisol"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 6:\nWhat functional units of the kidney filter blood plasma and generate urine?", choices: ["Nephrons", "Alveoli", "Neurons", "Lobules"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 7:\nWhich gastric cells secrete hydrochloric acid (HCl) into the stomach lumen?", choices: ["Parietal cells", "Chief cells", "G cells", "Mucous cells"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 8:\nWhich cranial nerve is responsible for motor control of the tongue?", choices: ["CN XII (Hypoglossal)", "CN IX (Glossopharyngeal)", "CN X (Vagus)", "CN V (Trigeminal)"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 9:\nWhat is the term for the functional junction between two communicating neurons?", choices: ["Synapse", "Axon", "Dendrite", "Myelin sheath"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 10:\nWhich neurotransmitter is released at the neuromuscular junction to initiate muscle contraction?", choices: ["Acetylcholine", "Dopamine", "Serotonin", "Noradrenaline"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 11:\nWhich heart valve separates the left atrium from the left ventricle?", choices: ["Mitral (Bicuspid) valve", "Tricuspid valve", "Aortic valve", "Pulmonary valve"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 12:\nWhich heart valve separates the right atrium from the right ventricle?", choices: ["Tricuspid valve", "Mitral valve", "Pulmonary valve", "Aortic valve"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 13:\nWhat is the term for the volume of blood pumped by one ventricle in one minute?", choices: ["Cardiac output", "Stroke volume", "End-diastolic volume", "Ejection fraction"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 14:\nWhich hormone is produced by the kidneys to stimulate red blood cell production?", choices: ["Erythropoietin", "Renin", "Calcitriol", "Aldosterone"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 15:\nWhich brain region regulates body temperature, hunger, thirst, and the pituitary gland?", choices: ["Hypothalamus", "Thalamus", "Pons", "Hippocampus"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 16:\nWhat is the term for the standard clinical measure of red blood cell volume percentage?", choices: ["Hematocrit", "Hemoglobin", "Mean corpuscular volume", "Platelet count"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 17:\nWhich structure contains the vocal cords and is located between the pharynx and trachea?", choices: ["Larynx", "Epiglottis", "Esophagus", "Bronchi"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 18:\nWhich salivary enzyme initiates the breakdown of dietary starches in the mouth?", choices: ["Amylase", "Pepsin", "Lipase", "Trypsin"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 19:\nWhat is the primary site of nutrient absorption in the small intestine?", choices: ["Jejunum", "Duodenum", "Ileum", "Cecum"], correct: 0),
    ExamQuestion(question: "MEDICINE ACADEMIC 20:\nWhich gastric cells secrete pepsinogen, the inactive precursor to pepsin?", choices: ["Chief cells", "Parietal cells", "G cells", "Mucous neck cells"], correct: 0),
  ];

  static final List<ExamQuestion> _medicineBoard = [
    ExamQuestion(question: "MEDICINE BOARD 1:\nWhen performing an appendectomy, what is the correct sequence of abdominal wall layers incised from superficial to deep?", choices: ["Skin, Camper's fascia, Scarpa's fascia, External oblique, Internal oblique, Transversus abdominis.", "Skin, Scarpa's fascia, Camper's fascia, Internal oblique, Transversus abdominis.", "Skin, Transversus abdominis, External oblique, Fascia.", "Skin, Fascia, Oblique muscle, Peritoneum."], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 2:\nA patient presents with sudden chest pain radiating to the left arm, and an ECG reveals ST-segment elevations. What is the diagnosis?", choices: ["ST-elevation myocardial infarction (STEMI).", "Acute pulmonary embolism.", "Gastroesophageal reflux disease.", "Asthmatic bronchospasm."], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 3:\nWhat is the primary therapeutic mechanism of digitalis in treating congestive heart failure?", choices: ["Inhibits the Na+/K+ ATPase pump, increasing intracellular calcium and contractility.", "Blocks beta-adrenergic receptors, slowing cardiac rhythm.", "Dilates coronary arteries to lower systemic blood pressure.", "Destroys arterial cholesterol plaques."], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 4:\nA clinic receives four emergencies simultaneously. Who must the practitioner treat first?", choices: ["A patient with an obstructed, compromised airway.", "A patient with a compound arm fracture.", "A patient complaining of sudden abdominal cramps.", "A patient with a flesh hound construct bite."], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 5:\nWhich drug is administered intravenously to treat bradycardia by blocking parasympathetic vagal inputs?", choices: ["Atropine", "Propranolol", "Digoxin", "Epinephrine"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 6:\nA post-operative patient develops unilateral leg edema and calf pain. What is the most critical risk if untreated?", choices: ["Pulmonary embolism due to DVT clot detachment.", "Immediate leg gangrene.", "Skeletal muscle paralysis.", "Spinal cord compression."], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 7:\nA patient presents with sudden facial drooping, inability to smile on one side, and loss of taste. Which cranial nerve is injured?", choices: ["Facial Nerve (CN VII)", "Trigeminal Nerve (CN V)", "Vagus Nerve (CN X)", "Glossopharyngeal (CN IX)"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 8:\nA patient presents with ST-elevations on leads II, III, and aVF. Which coronary artery is obstructed?", choices: ["Right coronary artery (RCA)", "Left anterior descending (LAD)", "Circumflex artery", "Left main coronary"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 9:\nA patient presents with sudden sharp back pain radiating to the abdomen, hypotension, and a pulsatile abdominal mass. What is the diagnosis?", choices: ["Ruptured abdominal aortic aneurysm (AAA)", "Acute cholecystitis", "Renal colic", "Perforated peptic ulcer"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 10:\nWhich medication is the drug of choice to treat acute anaphylactic shock?", choices: ["Epinephrine", "Atropine", "Diphenhydramine", "Hydrocortisone"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 11:\nA patient presents with a blood pressure of 70/40 mmHg, cold clammy skin, oliguria, and tachycardia after severe blood loss. What shock type is this?", choices: ["Hypovolemic shock", "Cardiogenic shock", "Anaphylactic shock", "Neurogenic shock"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 12:\nWhich diagnostic test is the gold standard to identify pulmonary embolisms in emergency settings?", choices: ["CT pulmonary angiography (CTPA)", "Chest X-ray", "D-dimer assay", "Ventilation-perfusion (V/Q) scan"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 13:\nA patient with liver cirrhosis presents with hematemesis and shock. What is the most likely cause of the bleeding?", choices: ["Ruptured esophageal varices", "Mallory-Weiss tear", "Peptic ulcer disease", "Gastric cancer"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 14:\nWhich hormone is measured in urine or blood to confirm early pregnancy?", choices: ["Human chorionic gonadotropin (hCG)", "Progesterone", "Estrogen", "Luteinizing hormone (LH)"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 15:\nWhat is the definitive diagnostic procedure to confirm a suspected malignant bone construct tumor?", choices: ["Biopsy", "MRI scan", "Bone scintigraphy", "Alchemical radiograph"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 16:\nA patient presents with severe left lower quadrant abdominal pain, fever, and leukocytosis. What is the most likely diagnosis?", choices: ["Acute diverticulitis", "Appendicitis", "Cholecystitis", "Small bowel obstruction"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 17:\nWhich cranial nerve is responsible for hearing and balance?", choices: ["Vestibulocochlear Nerve (CN VIII)", "Facial Nerve (CN VII)", "Vagus Nerve (CN X)", "Trigeminal Nerve (CN V)"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 18:\nWhat is the clinical term for the complete lack of electrical cardiac activity on an ECG?", choices: ["Asystole", "Ventricular fibrillation", "Atrial fibrillation", "Heart block"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 19:\nA patient presents with severe RUQ abdominal pain radiating to the right shoulder, triggered by fatty meals. What is the diagnosis?", choices: ["Acute cholecystitis", "Acute pancreatitis", "Appendicitis", "Gastroenteritis"], correct: 0),
    ExamQuestion(question: "MEDICINE BOARD 20:\nWhich pharmacological agent is the immediate antidote to reverse alchemical opium/narcotic overdose?", choices: ["Naloxone", "Flumazenil", "Atropine", "Acetylcysteine"], correct: 0),
  ];

  // Fetch a randomized set of questions
  static List<ExamQuestion> getExamQuestions({
    required AcademicSchoolType type,
    required int stage, // 0 = Entrance, 1-3 = Semester/Academic, 4/5 = Board
  }) {
    List<ExamQuestion> source = [];
    if (type == AcademicSchoolType.law) {
      if (stage == 0) {
        source = _lawAdmissions;
      } else if (stage >= 4) {
        source = _lawBoard;
      } else {
        source = _lawAcademic;
      }
    } else if (type == AcademicSchoolType.pharmacy) {
      if (stage == 0) {
        source = _pharmacyAdmissions;
      } else if (stage >= 4) {
        source = _pharmacyBoard;
      } else {
        source = _pharmacyAcademic;
      }
    } else {
      if (stage == 0) {
        source = _medicineAdmissions;
      } else if (stage >= 4) {
        source = _medicineBoard;
      } else {
        source = _medicineAcademic;
      }
    }

    // Shuffle source list first to pick unique question objects!
    final list = List<ExamQuestion>.from(source)..shuffle(_random);
    final count = stage >= 4 ? 6 : 4;
    
    // Grab unique slices
    final chosen = list.take(count).toList();

    // Dynamically shuffle the multiple-choice options of each question to prevent simple order memorization!
    return chosen.map((q) {
      final String correctVal = q.choices[q.correct];
      final List<String> shuffledChoices = List<String>.from(q.choices)..shuffle(_random);
      final int newCorrectIndex = shuffledChoices.indexOf(correctVal);
      return q.copyWith(
        choices: shuffledChoices,
        correct: newCorrectIndex,
      );
    }).toList();
  }
}
