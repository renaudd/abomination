import random

categories = [
    "trash", "zoology", "medicine", "chemistry", "psychology", "physics",
    "perception", "judgment", "morality", "courage", "hygiene", "temperament"
]

templates = {
    "trash": ["The Secret of {noun}", "Romance in the {place}", "A {adjective} Tale", "Memoirs of a {noun}", "The {adjective} {noun}", "Midnight {noun}"],
    "zoology": ["A Study of the {animal}", "Anatomy of the {animal}", "The Behavior of {animal}s", "Creatures of the {place}", "Observations on the {animal}"],
    "medicine": ["Principles of {medical_noun}", "Treatise on the {organ}", "A Guide to {medical_adj} Surgery", "The Science of Healing {illness}", "Diseases of the {organ}"],
    "chemistry": ["Alchemical {noun}", "The Elements of {substance}", "On the Nature of {substance}", "Reactions in {noun}", "The Path of {substance} Transform"],
    "psychology": ["The Mind of the {noun}", "Dreams and {noun}", "Understanding {emotion}", "The Subconscious {noun}", "Analysis of {emotion}"],
    "physics": ["Mechanics of the {noun}", "The Physics of {phenomenon}", "A Treatise on {phenomenon}", "Dynamics of {phenomenon}", "The Forces of {place}"],
    "perception": ["Seeing the {adjective} World", "Exercises in Observation", "The Art of Noticing {noun}", "Perspectives on {place}", "The Keen Eye"],
    "judgment": ["Justice and the {noun}", "The Ethics of {noun}", "A Guide to Wise Decisions", "Principles of Equity", "Weighing the {noun}"],
    "morality": ["The Virtuous {noun}", "On Good and Evil in the {place}", "The Path of Righteousness", "Ethics for the {noun}", "A Moral {noun}"],
    "courage": ["Tales of the Brave {noun}", "Facing the {adjective} Unknown", "Overcoming {emotion}", "The Hero's {noun}", "Valor in the {place}"],
    "hygiene": ["The Clean {noun}", "A Treatise on Sanitation", "Purifying the {place}", "Bathing Rituals of the {place}", "Health and Cleanliness"],
    "temperament": ["Calming the {emotion}", "The Balanced {noun}", "Mastering Your {emotion}", "Achieving Inner Peace", "The Stoic {noun}"]
}

vocab = {
    "noun": ["Soul", "Heart", "Shadow", "Crown", "Sword", "Rose", "Moon", "Sun", "Star", "Ocean", "Mountain", "River", "Forest", "City", "Village", "Kingdom", "Empire", "Temple"],
    "adjective": ["Dark", "Light", "Silent", "Loud", "Cold", "Hot", "Ancient", "Modern", "Lost", "Found", "Hidden", "Revealed", "Sacred", "Profane", "Beautiful", "Ugly", "Strong", "Weak"],
    "place": ["Abyss", "Heavens", "Underworld", "Earth", "Sea", "Sky", "Desert", "Jungle", "Tundra", "Swamp", "Cave", "Castle", "Dungeon", "Tower", "Labyrinth"],
    "animal": ["Wolf", "Bear", "Lion", "Tiger", "Eagle", "Hawk", "Snake", "Spider", "Dragon", "Unicorn", "Griffin", "Phoenix", "Leviathan", "Kraken", "Behemoth"],
    "medical_noun": ["Anatomy", "Physiology", "Pathology", "Pharmacology", "Surgery", "Therapeutics", "Diagnostics", "Epidemiology", "Immunology", "Genetics"],
    "medical_adj": ["Clinical", "Surgical", "Medical", "Preventive", "Therapeutic", "Diagnostic", "Epidemiological", "Immunological", "Genetic"],
    "organ": ["Heart", "Brain", "Lungs", "Liver", "Kidneys", "Stomach", "Intestines", "Skin", "Bones", "Muscles", "Nerves", "Blood", "Eyes", "Ears"],
    "illness": ["Plague", "Fever", "Cough", "Pox", "Consumption", "Ague", "Dropsy", "Gout", "Scurvy", "Rickets", "Leprosy", "Cholera", "Typhus", "Dysentery"],
    "substance": ["Gold", "Silver", "Iron", "Copper", "Lead", "Tin", "Mercury", "Sulfur", "Salt", "Water", "Fire", "Earth", "Air", "Aether", "Quintessence"],
    "emotion": ["Love", "Hate", "Joy", "Sorrow", "Anger", "Fear", "Disgust", "Surprise", "Anticipation", "Trust", "Pride", "Shame", "Guilt", "Envy", "Jealousy"],
    "phenomenon": ["Motion", "Gravity", "Light", "Sound", "Heat", "Magnetism", "Electricity", "Radiation", "Relativity", "Quantum", "Chaos", "Complexity"]
}

unique_books = set()
output = []

output.append("enum BookCategory {")
output.append("  " + ", ".join(categories))
output.append("}")
output.append("")
output.append("class LeisureBook {")
output.append("  final String title;")
output.append("  final BookCategory category;")
output.append("  const LeisureBook(this.title, this.category);")
output.append("}")
output.append("")
output.append("class LeisureBooksLibrary {")
output.append("  static const List<LeisureBook> books = [")

for cat in categories:
    count = 0
    attempts = 0
    while count < 100 and attempts < 1000:
        attempts += 1
        template = random.choice(templates[cat])
        
        # Determine which placeholders are in the template
        import re
        placeholders = re.findall(r'\{(.*?)\}', template)
        
        title_args = {}
        for p in placeholders:
            title_args[p] = random.choice(vocab[p])
            
        title = template.format(**title_args)
        
        if title not in unique_books:
            unique_books.add(title)
            output.append(f'    LeisureBook("{title}", BookCategory.{cat}),')
            count += 1

output.append("  ];")
output.append("}")

with open("lib/data/leisure_books_library.dart", "w") as f:
    f.write("\n".join(output))

print("Successfully generated lib/data/leisure_books_library.dart with {} books.".format(len(unique_books)))
