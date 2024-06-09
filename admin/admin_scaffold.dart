import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:my_application/admin/add_provider.dart';
import 'package:my_application/admin/admin_service/admin_service.dart';
import 'package:my_application/admin/categories/manage/categories.dart';
import 'package:my_application/admin/categories/model/add_category.dart';
import 'package:my_application/admin/dashboard_screen.dart';
import 'package:my_application/admin/dashbors_statistic/clients_list.dart';
import 'package:my_application/admin/invoice/create_invoice.dart';
import 'package:my_application/admin/products/manage/products.dart';
import 'package:my_application/admin/products/manage/update_product_screen.dart';
import 'package:my_application/admin/products/model/addproduct.dart';
import 'package:my_application/admin/reduction/add_reduction.dart';
import 'package:my_application/admin/signin_admin/firebase_auth_helper.dart';
import 'package:sidebar_with_animation/animated_side_bar.dart';
import 'package:my_application/admin/signin_admin/signin_admin.dart';

class AdminScaffoldPage extends StatefulWidget {
  const AdminScaffoldPage({super.key});

  @override
  State<AdminScaffoldPage> createState() => _AdminScaffoldPageState();
}

class _AdminScaffoldPageState extends State<AdminScaffoldPage> {
  Widget _selectedItem = const DashbordScreen();
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
  }

  screenSlector(item) {
    switch (item.route) {
      case DashbordScreen.routeName:
        setState(() {
          _selectedItem = const DashbordScreen();
        });
        break;
      case AddCategoryPage.routeName:
        setState(() {
          _selectedItem = const AddCategoryPage();
        });
        break;
      case AddProductPage.routeName:
        setState(() {
          _selectedItem = const AddProductPage();
        });
        break;
      case CategoryManage.routeName:
        setState(() {
          _selectedItem = const CategoryManage();
        });
        break;
      case ProductManage.routeName:
        setState(() {
          _selectedItem = const ProductManage();
        });
        break;
      case CreateInvoice.routeName:
        setState(() {
          _selectedItem = const CreateInvoice();
        });
        break;
      case Provider.routeName:
        setState(() {
          _selectedItem = const Provider();
        });
        break;

      case ListReduction.routeName:
        setState(() {
          _selectedItem = const ListReduction();
        });
        break;

      case ClientList.routeName:
        setState(() {
          _selectedItem = const ClientList();
        });
        break;
    }
  }

  Widget coloredIcon(IconData iconData, Color color, {double size = 24.0}) {
    return Icon(
      iconData,
      color: color,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      appBar: AppBar(
        iconTheme:
            const IconThemeData(color: Colors.white, size: 30, opticalSize: 30),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.teal.shade400.withOpacity(.8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
        ),
        title: Container(
          width: 250,
          decoration: BoxDecoration(
            border: const Border(
              bottom: BorderSide(color: Colors.blueGrey),
              top: BorderSide(color: Colors.blueGrey),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: _searchController,
            onChanged: (text) {
              _performSearch(text);
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'بحث',
              hintStyle: const TextStyle(color: Colors.white),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  _performSearch(_searchController.text);
                },
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      sideBar: SideBar(
        width: 230,
        scrollController: ScrollController(keepScrollOffset: true),
        iconColor: const Color.fromARGB(255, 3, 35, 61),
        activeBackgroundColor: Colors.red,
        activeIconColor: Colors.red,
        activeTextStyle: const TextStyle(color: Colors.red),
        borderColor: Colors.transparent,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(
          color: Color.fromARGB(255, 3, 35, 61),
        ),
        items: const [
          AdminMenuItem(
              title: 'لوحة القيادة',
              icon: Icons.dashboard_rounded,
              route: DashbordScreen.routeName),
          AdminMenuItem(
            title: 'العملاء',
            icon: Icons.supervised_user_circle_outlined,
            route: ClientList.routeName,
          ),
          AdminMenuItem(
            title: 'الفئات',
            icon: Icons.category_rounded,
            route: CategoryManage.routeName,
          ),
          AdminMenuItem(
            title: 'إضافة فئة',
            icon: Icons.add_to_photos_outlined,
            route: AddCategoryPage.routeName,
          ),
          AdminMenuItem(
            title: 'مورد',
            icon: Icons.person_2,
            route: Provider.routeName,
          ),
          AdminMenuItem(
            title: 'المنتجات',
            icon: Icons.storage_sharp,
            route: ProductManage.routeName,
          ),
          AdminMenuItem(
            title: 'إضافة منتج',
            icon: Icons.add_shopping_cart,
            route: AddProductPage.routeName,
          ),
          AdminMenuItem(
            title: 'إضافة فاتورة',
            icon: Icons.fact_check_outlined,
            route: CreateInvoice.routeName,
          ),
          AdminMenuItem(
            title: 'إضافة تخفيض',
            icon: Icons.trending_down,
            route: ListReduction.routeName,
          ),
        ],
        selectedRoute: '',
        onSelected: (item) {
          screenSlector(item);
          _toggleSidebar();
        },
        header: Container(
          height: 150,
          width: double.infinity,
          color: Colors.teal.shade400.withOpacity(.8),
          // ignore: sort_child_properties_last
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminProfile(),
            ],
          ),
        ),
        footer: Container(
          height: 50,
          width: double.infinity,
          color: Colors.teal.shade400.withOpacity(.8),
          child: TextButton(
            onPressed: () async {
              try {
                User? currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  await FirebaseAuth.instance.signOut();
                  FirebaseAuthHelper firebaseAuthHelper = FirebaseAuthHelper();
                  await firebaseAuthHelper.googleSignIn.signOut();
                  await FirebaseFirestore.instance
                      .collection('admin')
                      .doc(currentUser.uid)
                      .update({
                    'isActive': false,
                  });

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AdminSignInEmail()));
                }
              } catch (e) {
                print('Error signing out: $e');
              }
            },
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.grey.withOpacity(0.2);
                  }
                  if (states.contains(MaterialState.pressed)) {
                    return Colors.grey.withOpacity(0.4);
                  }
                  return null;
                },
              ),
            ),
            child: const Text(
              'خروج',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_searchResults.isNotEmpty) {
      return _buildSearchResults();
    } else {
      return _selectedItem;
    }
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        if (index >= _searchResults.length) {
          return const SizedBox();
        }
        var productData = _searchResults[index].data() as Map<String, dynamic>;
        String name = productData['name'];
        var price = productData['price'];
        String imageUrl = productData['image'];
        String productId = _searchResults[index].id;
        return ListTile(
          leading: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromARGB(255, 3, 35, 61),
                width: 4.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : Container(),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Price: DA$price',
            style: const TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProductPage(productId: productId),
              ),
            );
          },
        );
      },
    );
  }

// search product
  void _performSearch(String searchText) async {
    if (searchText.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('name', isGreaterThanOrEqualTo: searchText)
            .get();

        setState(() {
          _searchResults = snapshot.docs;
        });
      } catch (e) {
        print('Error searching products: $e');
      }
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }
}
