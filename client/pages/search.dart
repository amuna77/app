import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:my_application/client/pages/details.dart';
import 'package:my_application/client/pages/rating_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:fluttertoast/fluttertoast.dart';

class SearchResultPage extends StatefulWidget {
  @override
  _SearchResultPageState createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  void fetchWishlistItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot wishlistSnapshot = await FirebaseFirestore.instance
          .collection('Wishlist')
          .where('clients', isEqualTo: user.uid)
          .get();
      setState(() {
        wishlistItems = Map.fromEntries(wishlistSnapshot.docs
            .map((doc) => MapEntry(doc['productId'] as String, true)));
      });
    }
  }

  void toggleFavorite(String productId, bool isFavorite) async {
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      wishlistItems[productId] = isFavorite;
    });

    if (user != null) {
      if (isFavorite) {
        FirebaseFirestore.instance.collection('Wishlist').add({
          'clients': user.uid,
          'productId': productId,
        });
      } else {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('Wishlist')
            .where('clients', isEqualTo: user.uid)
            .where('productId', isEqualTo: productId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          querySnapshot.docs.first.reference.delete();
        }
      }
    }

    FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({'wish': isFavorite});

    // Rafraîchir la liste de souhaits après la bascule
    fetchWishlistItems();
  }

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  bool _showListeningIndicator = false;
  List<Map<String, dynamic>> extractedTextProducts =
      []; // Définition de la liste de produits extraits
  Map<String, bool> wishlistItems = {};
  late TextEditingController _searchController;
  List<Map<String, dynamic>> products = [];
  bool isLoading = false;
  late Map<String, bool> favorites;
  late Map<String, int?> cartQuantities;
  String? selectedProductId;
  List<String> produits_intrs = [];

  Map<String, bool> isInWishlist = {};
  List<String> produits_consultes = [];
  String? selectedSearchType;

  bool isRecentSearchesLoading = true;
  List<String> recentSearches = [];
  List<String> suggestions = [];
  Future<void> searchProduct(String query) async {
    if (query.isNotEmpty) {
      var _products = <Map<String, dynamic>>[];
      final user = FirebaseAuth.instance.currentUser;

      QuerySnapshot<Map<String, dynamic>>? snapshot;

      if (selectedSearchType == 'name') {
        snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('name', isEqualTo: query.toLowerCase())
            .get();

        _products = snapshot.docs.map((doc) {
          var data = doc.data();
          data['productID'] = doc.id; // Attaching the Firestore document ID
          return data;
        }).toList();
      } else if (selectedSearchType == 'brand') {
        snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('brand', isEqualTo: query.toLowerCase())
            .get();
        _products = snapshot.docs.map((doc) {
          var data = doc.data();
          data['productID'] = doc.id; // Attaching the Firestore document ID
          return data;
        }).toList();
      } else {
        // Split the query into words
        List<String> words = query.split(' ');

        if (words.length == 2) {
          // Search for the first word in name and the second word in brand
          var nameBrandSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('name', isEqualTo: words[0].toLowerCase())
              .where('brand', isEqualTo: words[1].toLowerCase())
              .get();
          var brandNameSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('brand', isEqualTo: words[0].toLowerCase())
              .where('name', isEqualTo: words[1].toLowerCase())
              .get();
          // Correct the use of the snapshot to use 'nameBrandSnapshot' instead of 'snapshot'
          _products = nameBrandSnapshot.docs.map((doc) {
            var data = doc.data() as Map<String,
                dynamic>; // Cast data explicitly to avoid type issues
            data['productID'] = doc.id; // Attaching the Firestore document ID
            return data;
          }).toList();

          // Search for the first word in brand and the second word in name

          _products = brandNameSnapshot.docs.map((doc) {
            var data = doc.data() as Map<String,
                dynamic>; // Cast data explicitly to avoid type issues
            data['productID'] = doc.id; // Attaching the Firestore document ID
            return data;
          }).toList();
        } else {
          var brand = await FirebaseFirestore.instance
              .collection('products')
              .where('brand', isEqualTo: query.toLowerCase())
              .where('brand', isLessThan: query.toLowerCase() + 'z')
              .get();

          var nameResults = brand.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            data['productID'] = doc.id;
            return data;
          }).toList();

          var nameSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('name', isEqualTo: query.toLowerCase())
              .where('name', isLessThan: query.toLowerCase() + 'z')
              .get();

          var descriptionResults = nameSnapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            data['productID'] = doc.id;
            return data;
          }).toList();

          _products = [...nameResults, ...descriptionResults];
        }
      }

      setState(() {
        products = _products;
        isLoading = false;

        if (products.isEmpty) {
          Fluttertoast.showToast(
              msg: "Aucun produit trouvé",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        }
      });

      if (user != null) {
        var searchDoc = await FirebaseFirestore.instance
            .collection('historique_search')
            .where('search', isEqualTo: query.toLowerCase())
            .where('id_client', isEqualTo: user.uid)
            .get();

        await FirebaseFirestore.instance.collection('historique_search').add({
          'search': query.toLowerCase(),
          'id_client': user.uid,
          'timestamp': DateTime.now(),
        });
      }
    }
  }

  void handleSearch() {
    String searchTerm = _searchController.text.trim();
    if (searchTerm.isNotEmpty) {
      searchProduct(searchTerm);
    }
    setState(() {
      suggestions = []; // Also clear suggestions here
    });
  }

  void handleSearchTypeChange(String searchType) {
    setState(() {
      selectedSearchType = searchType;
    });

    handleSearch();
  }

  File? _imageFile;
  String _extractedText = '';
  String _productNames = '';

  Future<void> _showImageSourceOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Prendre une photo'),
                onTap: () async {
                  await _getImageAndExtractText(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choisir dans la galerie'),
                onTap: () async {
                  await _getImageAndExtractText(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _showListeningIndicator = true;
          _text = '';
        });

        // Fetch the list of available locales
        var locales = await _speech.locales();

        // Attempt to find a suitable locale or use a default
        var locale = locales.firstWhere(
            (l) =>
                l.localeId.startsWith('fr') || l.localeId.startsWith('ar-AE'),
            orElse: () => locales.firstWhere(
                (l) => l.localeId.startsWith('en'), // Fallback to English
                orElse: () => stt.LocaleName('en_US',
                    'English (United States)') // Provide a default LocaleName
                ));

        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _searchController.text = _text;
              searchProduct(_text);
            }
          }),
          localeId: locale.localeId,
        );

        Future.delayed(Duration(seconds: 5), () {
          if (_isListening) {
            _stopListening();
          }
        });
      }
    } else {
      _stopListening();
    }
  }

  Future<double> calculateProductRating(String productId) async {
    // Référence à la collection "reviews"
    CollectionReference reviewsRef =
        FirebaseFirestore.instance.collection('reviews');

    try {
      // Obtenir tous les documents où productID est égal à l'ID du produit donné
      QuerySnapshot reviewsQuery =
          await reviewsRef.where('productID', isEqualTo: productId).get();

      // Si aucun document ne correspond à la requête, retourner 0 comme note moyenne
      if (reviewsQuery.docs.isEmpty) {
        return 0;
      }

      // Initialiser la somme des notes et le nombre de documents
      double totalRating = 0;
      int numberOfDocuments = reviewsQuery.docs.length;

      // Parcourir tous les documents et ajouter leur note à la somme totale
      reviewsQuery.docs.forEach((doc) {
        totalRating += doc['rating'];
      });

      // Calculer la note moyenne en divisant la somme totale par le nombre de documents
      double averageRating = totalRating / numberOfDocuments;

      return averageRating;
    } catch (error) {
      // En cas d'erreur, afficher un message d'erreur et retourner 0 comme note moyenne
      print('Error calculating product rating: $error');
      return 0;
    }
  }

  // Votre code avec quelques corrections et suggestions d'amélioration
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('بحث'), // Peut-être utiliser des fichiers de traduction ici
        actions: [
          TextButton(
            onPressed: () {
              _clearAllSearchHistory();
            },
            child: Text(
              'امسح الكل', // Peut-être utiliser des fichiers de traduction ici
              style: TextStyle(
                color: const Color.fromARGB(255, 114, 55, 55),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      handleSearchTypeChange('name');
                    },
                    child: Text(
                      'اسم',
                      style: TextStyle(
                        color: selectedSearchType == 'name'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        selectedSearchType == 'name'
                            ? Colors.green
                            : Colors.grey[200]!,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 30),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      handleSearchTypeChange('brand');
                    },
                    child: Text(
                      'ماركة',
                      style: TextStyle(
                        color: selectedSearchType == 'brand'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        selectedSearchType == 'brand'
                            ? Colors.green
                            : Colors.grey[200]!,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText:
                    'للبحث ...', // Peut-être utiliser des fichiers de traduction ici
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: _showListeningIndicator
                    ? ListeningIndicator()
                    : Icon(Icons.search, color: Colors.grey),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          suggestions = [];
                          products = [];
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.grey),
                      onPressed: _showImageSourceOptions,
                    ),
                  ],
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    suggestions = [];
                    products = [];
                  });
                } else {
                  getSuggestions(value);
                }
                setState(() {
                  recentSearches = [];
                });
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  searchProduct(value);
                }
                setState(() {
                  suggestions = [];
                });
              },
            ),
            SizedBox(height: 20),
            suggestions.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(suggestions[index]),
                          onTap: () {
                            _searchController.text = suggestions[index];
                            searchProduct(suggestions[index]);
                            setState(() {
                              suggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  )
                : SizedBox.shrink(),
            SizedBox(height: 20),
            isRecentSearchesLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : recentSearches.isNotEmpty
                    ? Expanded(
                        child: ListView.builder(
                        itemCount: recentSearches.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Icon(Icons.history),
                            title: Text(recentSearches[index]),
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  recentSearches.removeAt(index);
                                });
                              },
                            ),
                            onTap: () {
                              _searchController.text = recentSearches[index];
                              searchProduct(recentSearches[index]);
                              setState(() {
                                recentSearches = [];
                              });
                            },
                          );
                        },
                      ))
                    : SizedBox.shrink(),
            SizedBox(height: 20),
            isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        bool isFavorite = false;
                        if (favorites
                            .containsKey(products[index]['productID'])) {
                          bool? favoriteValue =
                              favorites[products[index]['productID']];
                          isFavorite = favoriteValue ?? false;
                        }

                        String productId = products[index]['productID'];
                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('products')
                              .doc(productId)
                              .snapshots(),
                          builder: (context, productSnapshot) {
                            if (!productSnapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            var productData = productSnapshot.data!.data()
                                as Map<String, dynamic>;

                            // Vérifier si le produit est dans la collection "promotions"
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('promotions')
                                  .where('productId',
                                      isEqualTo:
                                          productId) // Filtrer par l'ID du produit
                                  .snapshots(),
                              builder: (context, promoSnapshot) {
                                if (!promoSnapshot.hasData ||
                                    promoSnapshot.data!.docs.isEmpty) {
                                  // Si aucun document ne correspond au filtre, afficher le produit de base
                                  return buildProductCard(
                                    name: productData['name'],
                                    price: productData['price'].toString(),
                                    image: productData['image'],
                                    productId: productId,
                                    detail: productData['detail'],
                                  );
                                } else {
                                  // Si un document correspond au filtre, utiliser ses données de promotion
                                  var promoData = promoSnapshot.data!.docs.first
                                      .data() as Map<String, dynamic>;
                                  double discountedPrice =
                                      promoData['discountedPrice'] as double;
                                  double percentage =
                                      promoData['percentage'] as double;
                                  double sellingPrice =
                                      promoData['sellingPrice'] as double;

                                  return buildProductCard(
                                    name: productData['name'],
                                    price: productData['price'].toString(),
                                    image: productData['image'],
                                    detail: productData['detail'],
                                    productId: productId,
                                    sellingPrice: sellingPrice,
                                    percentage: percentage,
                                    discountedPrice: discountedPrice,
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
      floatingActionButton: _showListeningIndicator
          ? null
          : FloatingActionButton(
              onPressed: _listen,
              child: Icon(Icons.mic),
              backgroundColor: Colors.green,
            ),
    );
  }

  Widget buildProductCard({
    required String name,
    required String price,
    required String image,
    required String productId,
    required String detail,
    double discountedPrice = 0.0,
    double percentage = 0.0,
    double sellingPrice = 0.0,
  }) {
    bool isInWishlist = wishlistItems.containsKey(productId)
        ? wishlistItems[productId]!
        : false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(
              detail: detail,
              image: image,
              name: name,
              price: discountedPrice != 0 ? '$discountedPrice' : price,
              productID: productId,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        image,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 5, // Ajuster la position verticale
                        right: 5, // Ajuster la position horizontale
                        child: GestureDetector(
                          onTap: () {
                            toggleFavorite(
                              productId,
                              !isInWishlist,
                            ); // Inverse l'état actuel du favori
                          },
                          child: Container(
                            padding: EdgeInsets.all(
                                3), // Ajuster la taille du conteneur
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isInWishlist
                                  ? Colors.red.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.7),
                            ),
                            child: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isInWishlist ? Colors.white : Colors.grey,
                              size: 16, // Ajuster la taille de l'icône
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${discountedPrice != 0 ? discountedPrice : price} DA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                          if (discountedPrice != 0 && sellingPrice != 0)
                            SizedBox(width: 4),
                          if (discountedPrice != 0 && sellingPrice != 0)
                            Text(
                              '${sellingPrice.toStringAsFixed(2)} DA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      FutureBuilder<double>(
                        future: calculateProductRating(productId),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                                'Erreur lors de la récupération des évaluations');
                          } else {
                            double productRating = snapshot.data ?? 0;
                            return StarRating(
                              rating: productRating,
                              size: 35, // Taille des étoiles augmentée
                              color: Colors.amber,
                              borderColor: Colors.grey,
                              starCount: 5,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (percentage != 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${percentage.toString()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImageAndExtractText(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _extractedText = ''; // Réinitialiser le texte extrait
        _productNames = ''; // Réinitialiser le nom du produit
      });

      String extractedText = await readTextFromImage(_imageFile!);
      setState(() {
        _extractedText = extractedText;
      });

      // Rechercher les produits par marque (brand) correspondant au texte extrait
      await searchProduct(extractedText);
    }
  }

  Future<String> readTextFromImage(File imageFile) async {
    final GoogleVisionImage visionImage = GoogleVisionImage.fromFile(imageFile);
    final TextRecognizer textRecognizer =
        GoogleVision.instance.textRecognizer();
    final VisionText visionText =
        await textRecognizer.processImage(visionImage);
    textRecognizer.close();

    String extractedText = '';
    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        extractedText +=
            (line.text ?? '') + ' '; // Utilisez un espace pour séparer les mots
      }
    }
    return extractedText
        .trim(); // Supprimez les espaces en trop autour du texte
  }

  Future<void> searchProductsByBrand(String text) async {
    // Découper le texte extrait en mots
    List<String> words = text.split(' ');

    // Liste pour stocker les noms de produits trouvés
    List<String> productNamesList = [];

    // Recherche des produits pour chaque mot individuel
    for (String word in words) {
      QuerySnapshot wordSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('brand',
              isEqualTo: word.toLowerCase()) // Convertir en minuscules
          .get();
      if (wordSnapshot.docs.isNotEmpty) {
        // Ajouter les noms de produits trouvés à la liste
        productNamesList.addAll(wordSnapshot.docs.map((doc) => doc['name']));
      }
    }

    // Rechercher les produits correspondant aux noms de produits trouvés
    List<Map<String, dynamic>> foundProducts = [];
    for (String productName in productNamesList) {
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: productName)
          .get();
      if (productSnapshot.docs.isNotEmpty) {
        foundProducts.addAll(productSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>));
      }
    }

    // Mettre à jour l'état pour afficher les noms de produits
    setState(() {
      _productNames = productNamesList.isNotEmpty
          ? productNamesList.join(', ')
          : 'Aucun produit trouvé';
    });

    // Mettre à jour l'état pour afficher les produits
    setState(() {
      products = foundProducts;
    });
  }

  Widget buildSearchResults() {
    if (_extractedText.isNotEmpty && _productNames.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Texte extrait:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(_extractedText),
          SizedBox(height: 20),
          Text(
            'Résultats de la recherche par texte extrait:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(_productNames),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  void _addProductToConsultedList(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var searchQuery = _searchController.text;
      var searchDoc = await FirebaseFirestore.instance
          .collection('historique_search')
          .where('search', isEqualTo: searchQuery)
          .where('id_client', isEqualTo: user.uid)
          .get();

      // Si la recherche existe
      if (searchDoc.docs.isNotEmpty) {
        var documentId = searchDoc.docs.first.id;
        await FirebaseFirestore.instance
            .collection('historique_search')
            .doc(documentId)
            .update({
          'liste_des_identifiants': FieldValue.arrayUnion([productId])
        });
      } else {
        // Si la recherche n'existe pas
        await FirebaseFirestore.instance.collection('historique_search').add({
          'search': searchQuery,
          'id_client': user.uid,
          'timestamp': DateTime.now(),
          'liste_des_identifiants': [productId]
        });
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _showListeningIndicator = false;
    });
  }

  void _stopListeningIndicator() {
    setState(() {
      _isListening = false;
      _showListeningIndicator = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _speech = stt.SpeechToText();
    _getFavorites();
    _getCartProducts();
    _getRecentSearches();
    fetchWishlistItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var favoritesData = await FirebaseFirestore.instance
          .collection('Wishlist')
          .doc(user.uid)
          .get();

      if (favoritesData.exists) {
        setState(() {
          favorites = Map<String, bool>.from(favoritesData.data()!);
        });
      } else {
        setState(() {
          favorites = {};
        });
      }
    }
  }

  Future<void> _getCartProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var cartData = await FirebaseFirestore.instance
          .collection('Cart')
          .doc(user.uid)
          .get();

      if (cartData.exists) {
        setState(() {
          cartQuantities = Map<String, int?>.from(cartData.data()!);
        });
      } else {
        setState(() {
          cartQuantities = {};
        });
      }
    }
  }

  void _getRecentSearches() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var searches = await FirebaseFirestore.instance
          .collection('historique_search')
          .where('id_client', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      setState(() {
        recentSearches =
            searches.docs.map((e) => e['search'] as String).toList();
        isRecentSearchesLoading = false;
      });
    } else {
      setState(() {
        isRecentSearchesLoading = false;
      });
    }
  }

  void _clearAllSearchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('historique_search')
          .where('id_client', isEqualTo: user.uid)
          .get()
          .then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });

      setState(() {
        recentSearches = [];
      });
    }
  }

  void _clearSearchResults() {
    setState(() {
      products = [];
      isLoading = false;
    });
  }

  Future<void> getSuggestions(String query) async {
    List<String> suggestionsList = [];

    // Check if the query is not empty
    if (query.isNotEmpty) {
      if (selectedSearchType == 'name') {
        // Query for product names starting with the current input
        var nameQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThanOrEqualTo: query + '\uf8ff')
            .limit(5)
            .get();

        // Add each found name to the suggestions list
        for (var doc in nameQuerySnapshot.docs) {
          suggestionsList.add(doc.data()['name'] as String);
        }
      } else if (selectedSearchType == 'brand') {
        // Query for product brands starting with the current input
        var brandQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('brand', isGreaterThanOrEqualTo: query)
            .where('brand', isLessThanOrEqualTo: query + '\uf8ff')
            .limit(5)
            .get();

        // Add each found brand to the suggestions list
        for (var doc in brandQuerySnapshot.docs) {
          suggestionsList.add(doc.data()['brand'] as String);
        }
      } else {
        // Default to querying names if no specific type is selected
        var defaultQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThanOrEqualTo: query + '\uf8ff')
            .limit(5)
            .get();

        // Add each found name to the suggestions list
        for (var doc in defaultQuerySnapshot.docs) {
          suggestionsList.add(doc.data()['name'] as String);
        }
      }

      // Update the state to reflect the new suggestions
      setState(() {
        suggestions = suggestionsList;
      });
    }
  }

  Future<void> _saveFavorite(String productId, bool isFavorite) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(productId, isFavorite);
  }
}

class ListeningIndicator extends StatefulWidget {
  @override
  _ListeningIndicatorState createState() => _ListeningIndicatorState();
}

class _ListeningIndicatorState extends State<ListeningIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _animation,
        child: Icon(
          Icons.mic,
          color: Colors.black,
          size: 60,
        ),
      ),
    );
  }
}
