import 'package:flutter/material.dart';
import 'package:my_application/admin/dashbors_statistic/chart.dart';
import 'package:my_application/admin/dashbors_statistic/delivery_person_list.dart';
import 'package:my_application/admin/dashbors_statistic/favoris_chart.dart';
import 'package:my_application/admin/dashbors_statistic/order_list.dart';
import 'package:my_application/admin/dashbors_statistic/rating_list.dart';
import 'package:my_application/admin/dashbors_statistic/total_price_monthly.dart';
import 'package:my_application/admin/dashbors_statistic/waiting._order.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class DashbordScreen extends StatelessWidget {
  static const String routeName = '/dashboard';

  const DashbordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة القيادة'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              children: [
                Card(
                  color: const Color.fromARGB(255, 241, 162, 255),
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(SwipeablePageRoute(
                          canOnlySwipeFromEdge: true,
                          builder: (BuildContext context) => const OrdersList(),
                        ));
                      },
                      child: const Column(
                        children: [
                          Text(
                            'طلبات',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8.0),
                          Icon(
                            Icons.shop_2_sharp,
                            color: Colors.white,
                            size: 35.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  color: const Color.fromARGB(255, 12, 174, 255),
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(SwipeablePageRoute(
                          canOnlySwipeFromEdge: true,
                          builder: (BuildContext context) =>
                              const WaitingOredrs(),
                        ));
                      },
                      child: const Column(
                        children: [
                          Text(
                            'انتظار',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8.0),
                          Icon(
                            Icons.alarm_on,
                            color: Colors.white,
                            size: 35.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  color: Colors.yellow,
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(SwipeablePageRoute(
                          canOnlySwipeFromEdge: true,
                          builder: (BuildContext context) =>
                              const ReviewsProduct(),
                        ));
                      },
                      child: const Column(
                        children: [
                          Text(
                            'التعليقات',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8.0),
                          Icon(
                            Icons.reviews_outlined,
                            color: Colors.white,
                            size: 35.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  shadowColor: Colors.grey,
                  color: Colors.orange,
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(SwipeablePageRoute(
                          canOnlySwipeFromEdge: true,
                          builder: (BuildContext context) =>
                              const DeliveryPerson(),
                        ));
                      },
                      child: Container(
                        child: const Column(
                          children: [
                            Text(
                              'التوصيل',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.0),
                            Icon(
                              Icons.delivery_dining,
                              color: Colors.white,
                              size: 35.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 2,
            child: const TotalPriceSalesMonthly(),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: BestProductsChart(),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Center(
              child: ClientSignUpStatsScreen(),
            ),
          ),
          // const Expanded(
          //   flex: 2,
          //   child: Center(
          //     child: ClientsList(),
          //   ),

          // ),
        ],
      ),
    );
  }
}
