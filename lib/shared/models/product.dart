class CollectionData {
  final String bannerTitle;
  final String bannerSubtitle;
  final String bannerImage;
  final List<Product> products;

  CollectionData({
    required this.bannerTitle,
    required this.bannerSubtitle,
    required this.bannerImage,
    required this.products,
  });
}

class Product {
  final String name;
  final String creator;
  final String price;
  final String image;
  final bool isNew;
  final String? discount;
  final List<String> tags;

  Product({
    required this.name,
    required this.creator,
    required this.price,
    required this.image,
    this.isNew = false,
    this.discount,
    this.tags = const [],
  });
}

final List<Product> allMockProducts = [
  Product(name: 'Boubou Wax Royal', creator: 'MIDE Stores', price: '8 000', image: 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?q=80&w=800&auto=format&fit=crop', isNew: true, tags: ['Wax', 'Royal', 'MIDE', 'Habits', 'Dakar']),
  Product(name: 'Ensemble Ankara', creator: 'Aïsha K.', price: '12 500', image: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop', discount: '-30%', tags: ['Ankara', 'Ensemble', 'Habits']),
  Product(name: 'Tunique Kente', creator: 'Ghanart', price: '10 500', image: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=800&auto=format&fit=crop', tags: ['Kente', 'Tunique', 'Handmade']),
  Product(name: 'Sac Raphia Tressé', creator: 'Atelier Dakar', price: '9 800', image: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=800&auto=format&fit=crop', tags: ['Raphia', 'Sac', 'Sustainable']),
  Product(name: 'Sandales Cuir Bio', creator: 'Maro Dakar', price: '7 400', image: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?q=80&w=800&auto=format&fit=crop', isNew: true, tags: ['Cuir', 'Bio', 'Sandales', 'Sustainable']),
  Product(name: 'Boucles Cauri Gold', creator: 'Bijoux Baobab', price: '3 200', image: 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?q=80&w=800&auto=format&fit=crop', isNew: true, tags: ['Bijoux', 'Cauri', 'Gold', 'Cadeau']),
  Product(name: 'Chemise Bogolan', creator: 'MIDE Stores', price: '6 500', image: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=800&auto=format&fit=crop', tags: ['Bogolan', 'Chemise', 'Cadeau']),
  Product(name: 'Tableau Batik', creator: 'Galerie Nomade', price: '32 000', image: 'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?q=80&w=800&auto=format&fit=crop', tags: ['Batik', 'Tableau', 'Art', 'Handmade']),
  Product(name: 'Poupée Akan', creator: 'Heritage', price: '6 000', image: 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=800&auto=format&fit=crop', tags: ['Akan', 'Handmade', 'Cadeau']),
  Product(name: 'Robe Indigo', creator: 'Indigo Studio', price: '14 200', image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop', tags: ['Indigo', 'Robe', 'Wax']),
  Product(name: 'Bracelet Bronze', creator: 'Artisanat Mali', price: '5 500', image: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?q=80&w=800&auto=format&fit=crop', tags: ['Bijoux', 'Bronze', 'Handmade']),
  Product(name: 'Pochette Wax', creator: 'Aïsha K.', price: '4 500', image: 'https://images.unsplash.com/photo-1544441893-675973e31985?q=80&w=800&auto=format&fit=crop', tags: ['Wax', 'Pochette', 'Cadeau']),
  Product(name: 'Chapeau Paille', creator: 'Eco Wear', price: '3 800', image: 'https://images.unsplash.com/photo-1521335629791-ce4aec67dd15?q=80&w=800&auto=format&fit=crop', tags: ['Paille', 'Sustainable', 'Accessoire']),
  Product(name: 'Bague Argent', creator: 'Bijoux Baobab', price: '18 000', image: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?q=80&w=800&auto=format&fit=crop', tags: ['Bijoux', 'Argent', 'Cadeau']),
  Product(name: 'Pantalon Batik', creator: 'Indigo Studio', price: '11 000', image: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?q=80&w=800&auto=format&fit=crop', tags: ['Batik', 'Pantalon', 'Handmade']),
];
