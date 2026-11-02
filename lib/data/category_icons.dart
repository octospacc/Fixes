import 'package:flutter/material.dart';

const _iconMap = <String, IconData>{
  'coffee': Icons.coffee,
  'tea': Icons.emoji_food_beverage,
  'drink': Icons.local_drink,
  'bar': Icons.local_bar,
  'food': Icons.restaurant,
  'fast_food': Icons.fastfood,
  'snack': Icons.cookie,
  'dessert': Icons.cake,
  'groceries': Icons.shopping_cart,
  'smoke': Icons.smoking_rooms,
  'gambling': Icons.casino,
  'gaming': Icons.sports_esports,
  'leisure': Icons.weekend,
  'music': Icons.music_note,
  'movie': Icons.movie,
  'tv': Icons.tv,
  'reading': Icons.menu_book,
  'sport': Icons.sports_soccer,
  'gym': Icons.fitness_center,
  'running': Icons.directions_run,
  'walking': Icons.directions_walk,
  'cycling': Icons.directions_bike,
  'swimming': Icons.pool,
  'yoga': Icons.self_improvement,
  'health': Icons.local_hospital,
  'spa': Icons.spa,
  'sleep': Icons.bedtime,
  'beauty': Icons.brush,
  'haircut': Icons.content_cut,
  'clothing': Icons.checkroom,
  'travel': Icons.flight,
  'transport': Icons.directions_bus,
  'car': Icons.directions_car,
  'fuel': Icons.local_gas_station,
  'work': Icons.work,
  'study': Icons.school,
  'home': Icons.home,
  'utility': Icons.receipt,
  'phone': Icons.phone_iphone,
  'subscription': Icons.autorenew,
  'laundry': Icons.local_laundry_service,
  'cleaning': Icons.cleaning_services,
  'gift': Icons.card_giftcard,
  'pets': Icons.pets,
  'kids': Icons.child_care,
  'savings': Icons.savings,
  'income': Icons.payments,
  'expense': Icons.paid,
  'shopping': Icons.shopping_bag,
  'other': Icons.category,
};

const _aliases = <String, String>{
  // coffee
  'espresso': 'coffee', 'latte': 'coffee', 'cappuccino': 'coffee',
  'americano': 'coffee', 'mocha': 'coffee', 'coffee shop': 'coffee',
  // tea
  'chai': 'tea', 'matcha': 'tea',
  // drink
  'drinks': 'drink', 'beverage': 'drink', 'beverages': 'drink',
  'soda': 'drink', 'juice': 'drink', 'water': 'drink', 'smoothie': 'drink',
  'milkshake': 'drink', 'cocktail': 'drink', 'beer': 'drink', 'wine': 'drink',
  'alcohol': 'drink', 'booze': 'drink',
  // bar
  'pub': 'bar', 'nightlife': 'bar', 'night out': 'bar',
  // food
  'meal': 'food', 'meals': 'food', 'lunch': 'food', 'dinner': 'food',
  'breakfast': 'food', 'brunch': 'food', 'eating': 'food', 'dining': 'food',
  'eat out': 'food', 'lunch out': 'food', 'dinner out': 'food',
  'restaurant': 'food',
  // fast food
  'fast food': 'fast_food', 'burger': 'fast_food', 'burgers': 'fast_food',
  'takeout': 'fast_food', 'takeaway': 'fast_food', 'take-out': 'fast_food',
  'pizza': 'fast_food',
  // snack
  'snacks': 'snack', 'chips': 'snack', 'candy': 'snack', 'chocolate': 'snack',
  'cookie': 'snack', 'cookies': 'snack', 'biscuits': 'snack', 'sweets': 'snack',
  // dessert
  'desserts': 'dessert', 'cake': 'dessert', 'bakery': 'dessert',
  'pastry': 'dessert', 'ice cream': 'dessert', 'icecream': 'dessert',
  'gelato': 'dessert',
  // groceries
  'grocery': 'groceries', 'supermarket': 'groceries', 'market': 'groceries',
  // smoke
  'smoking': 'smoke', 'cigarette': 'smoke', 'cigarettes': 'smoke',
  'cigar': 'smoke', 'tobacco': 'smoke', 'vape': 'smoke', 'vaping': 'smoke',
  'nicotine': 'smoke', 'smoke break': 'smoke',
  // gambling
  'bet': 'gambling', 'betting': 'gambling', 'lottery': 'gambling',
  'scratch': 'gambling', 'scratch card': 'gambling', 'scratchcard': 'gambling',
  'casino': 'gambling', 'poker': 'gambling', 'slot': 'gambling',
  'slots': 'gambling',
  // gaming
  'game': 'gaming', 'games': 'gaming', 'video game': 'gaming',
  'video games': 'gaming', 'videogame': 'gaming', 'videogames': 'gaming',
  'gaming session': 'gaming', 'playstation': 'gaming', 'xbox': 'gaming',
  'nintendo': 'gaming', 'steam': 'gaming',
  // leisure
  'entertainment': 'leisure', 'hobby': 'leisure', 'hobbies': 'leisure',
  'relax': 'leisure', 'relaxing': 'leisure', 'chill': 'leisure',
  // music
  'song': 'music', 'songs': 'music', 'album': 'music', 'spotify': 'music',
  'concert': 'music',
  // movie
  'movies': 'movie', 'film': 'movie', 'cinema': 'movie', 'netflix': 'movie',
  // tv
  'television': 'tv', 'streaming': 'tv',
  // reading
  'book': 'reading', 'books': 'reading', 'read': 'reading', 'ebook': 'reading',
  // sport
  'sports': 'sport', 'football': 'sport', 'soccer': 'sport',
  'basketball': 'sport', 'tennis': 'sport', 'golf': 'sport', 'volleyball': 'sport',
  // gym
  'workout': 'gym', 'fitness': 'gym', 'exercise': 'gym', 'training': 'gym',
  'weights': 'gym', 'crossfit': 'gym', 'gym session': 'gym',
  // running
  'run': 'running', 'jog': 'running', 'jogging': 'running',
  // walking
  'walk': 'walking', 'steps': 'walking',
  // cycling
  'bike': 'cycling', 'biking': 'cycling', 'bicycle': 'cycling',
  // swimming
  'swim': 'swimming', 'pool': 'swimming',
  // yoga
  'meditation': 'yoga', 'meditate': 'yoga',
  // health
  'medical': 'health', 'medicine': 'health', 'doctor': 'health',
  'hospital': 'health', 'pharmacy': 'health', 'pill': 'health',
  'pills': 'health', 'medication': 'health',
  // spa
  'massage': 'spa', 'wellness': 'spa', 'self care': 'spa', 'selfcare': 'spa',
  // sleep
  'nap': 'sleep', 'rest': 'sleep',
  // beauty
  'cosmetics': 'beauty', 'makeup': 'beauty', 'skincare': 'beauty',
  // haircut
  'hair': 'haircut', 'barber': 'haircut', 'salon': 'haircut',
  // clothing
  'clothes': 'clothing', 'fashion': 'clothing', 'apparel': 'clothing',
  'outfit': 'clothing', 'shoes': 'clothing', 'sneakers': 'clothing',
  // travel
  'trip': 'travel', 'vacation': 'travel', 'holiday': 'travel',
  'flight': 'travel', 'plane': 'travel', 'journey': 'travel',
  // transport
  'transit': 'transport', 'bus': 'transport', 'subway': 'transport',
  'metro': 'transport', 'train': 'transport',
  // car
  'driving': 'car', 'drive': 'car', 'uber': 'car', 'taxi': 'car',
  'cab': 'car', 'lyft': 'car',
  // fuel
  'gas': 'fuel', 'gasoline': 'fuel', 'petrol': 'fuel',
  // work
  'job': 'work', 'office': 'work', 'business': 'work', 'meeting': 'work',
  // study
  'studying': 'study', 'school': 'study', 'learning': 'study',
  'course': 'study', 'education': 'study', 'university': 'study',
  'college': 'study',
  // home
  'house': 'home', 'rent': 'home', 'mortgage': 'home', 'apartment': 'home',
  'flat': 'home',
  // utility
  'utilities': 'utility', 'bill': 'utility', 'bills': 'utility',
  'electricity': 'utility', 'electric': 'utility', 'power': 'utility',
  // phone
  'mobile': 'phone', 'cell': 'phone', 'cellphone': 'phone',
  'internet': 'phone', 'wifi': 'phone', 'broadband': 'phone',
  // subscription
  'subscriptions': 'subscription', 'membership': 'subscription',
  'recurring': 'subscription',
  // laundry
  'washing': 'laundry',
  // cleaning
  'clean': 'cleaning', 'housekeeping': 'cleaning', 'soap': 'cleaning',
  'detergent': 'cleaning',
  // gift
  'gifts': 'gift', 'present': 'gift', 'donation': 'gift', 'charity': 'gift',
  // pets
  'pet': 'pets', 'dog': 'pets', 'cat': 'pets', 'animal': 'pets',
  'animals': 'pets', 'vet': 'pets',
  // kids
  'child': 'kids', 'children': 'kids', 'kid': 'kids', 'baby': 'kids',
  'toys': 'kids', 'toy': 'kids',
  // savings
  'saving': 'savings', 'save': 'savings', 'deposit': 'savings',
  // income
  'salary': 'income', 'wage': 'income', 'paycheck': 'income',
  'earnings': 'income', 'earn': 'income',
  // expense
  'expenses': 'expense', 'spend': 'expense', 'spending': 'expense',
  // shopping
  'buy': 'shopping', 'purchase': 'shopping', 'store': 'shopping',
  'shop': 'shopping',
  // other
  'misc': 'other', 'miscellaneous': 'other', 'unknown': 'other',
  'general': 'other', 'uncategorized': 'other', 'none': 'other',
  // Italian
  'caffè': 'coffee', 'caffe': 'coffee',
  'bevande': 'drink', 'bevanda': 'drink', 'bibite': 'drink', 'bibita': 'drink',
  'fumo': 'smoke', 'sigaretta': 'smoke', 'sigarette': 'smoke',
  'sigaro': 'smoke', 'tabacco': 'smoke', 'svapo': 'smoke',
  'cibo': 'food', 'pranzo': 'food', 'cena': 'food', 'colazione': 'food',
  'ristorante': 'food', 'mangiare': 'food', 'cena fuori': 'food',
  'pranzo fuori': 'food',
  'patatine': 'snack', 'snack': 'snack', 'merenda': 'snack',
  'dolci': 'dessert', 'dolce': 'dessert', 'torta': 'dessert',
  'pasticceria': 'dessert',
  'gioco d\'azzardo': 'gambling', 'scommesse': 'gambling',
  'gratta e vinci': 'gambling', 'casinò': 'gambling', 'lotteria': 'gambling',
  'videogiochi': 'gaming', 'videogioco': 'gaming', 'gioco': 'gaming',
  'sessione di gioco': 'gaming',
  'tempo libero': 'leisure', 'svago': 'leisure',
  'sport': 'sport', 'palestra': 'gym', 'allenamento': 'gym',
  'corsa': 'running', 'camminata': 'walking', 'passeggiata': 'walking',
  'bicicletta': 'cycling', 'nuoto': 'swimming', 'yoga': 'yoga',
  'salute': 'health', 'medicina': 'health', 'farmacia': 'health',
  'medico': 'health', 'spa': 'spa', 'massaggio': 'spa',
  'sonno': 'sleep', 'riposo': 'sleep',
  'bellezza': 'beauty', 'trucco': 'beauty',
  'parrucchiere': 'haircut', 'capelli': 'haircut',
  'vestiti': 'clothing', 'abbigliamento': 'clothing', 'scarpe': 'clothing',
  'viaggio': 'travel', 'vacanza': 'travel', 'volo': 'travel',
  'trasporti': 'transport', 'autobus': 'transport', 'treno': 'transport',
  'auto': 'car', 'macchina': 'car',
  'carburante': 'fuel', 'benzina': 'fuel',
  'lavoro': 'work', 'ufficio': 'work', 'riunione': 'work',
  'studio': 'study', 'scuola': 'study', 'università': 'study',
  'casa': 'home', 'affitto': 'home', 'mutuo': 'home',
  'bollette': 'utility', 'bolletta': 'utility', 'luce': 'utility',
  'telefono': 'phone',
  'abbonamento': 'subscription', 'abbonamenti': 'subscription',
  'lavanderia': 'laundry', 'bucato': 'laundry',
  'pulizia': 'cleaning', 'pulizie': 'cleaning',
  'regalo': 'gift', 'regali': 'gift', 'donazione': 'gift',
  'animali': 'pets', 'animale': 'pets', 'cane': 'pets', 'gatto': 'pets',
  'bambini': 'kids', 'bambino': 'kids', 'bambina': 'kids', 'giocattoli': 'kids',
  'risparmi': 'savings', 'risparmio': 'savings',
  'stipendio': 'income', 'entrate': 'income', 'guadagno': 'income',
  'spese': 'expense', 'spesa': 'expense',
  'acquisti': 'shopping', 'acquisto': 'shopping', 'negozio': 'shopping',
  'varie': 'other', 'altro': 'other', 'misto': 'other',
};

String _normalize(String s) => s.trim().toLowerCase();

String canonicalCategory(String category) {
  final key = _normalize(category);
  if (key.isEmpty) return '';
  return _aliases[key] ?? key;
}

IconData iconForCategory(String category) {
  final key = _normalize(category);
  if (key.isEmpty) return Icons.label_outline;
  final canonical = _aliases[key] ?? key;
  return _iconMap[canonical] ?? Icons.label_outline;
}