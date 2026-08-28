import 'package:flutter/material.dart';
import 'payment.dart';


class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  final packages = [
  {
    'name': 'Adagio Pack',
    'price': 99,
    'coins': 50,
  },
  {
    'name': 'Allegro Pack',
    'price': 199,
    'coins': 120,
  },
  {
    'name': 'Business',
    'price': 399,
    'coins': 300,
  },
];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color.fromARGB(255, 21, 21, 21),
        foregroundColor: Colors.white,
        leading: IconButton( 
          icon:const Icon(Icons.arrow_back_ios_new_rounded,color:Colors.yellow),
          onPressed: (){
            Navigator.pop(context);
          },
          ),
        title: Row(
          children: [
             Image.asset(
              'assets/images/FuzikLogo.png',
              width: 35,
              height: 35,
              fit: BoxFit.cover,
            ),
            const Spacer(),
            Row(
              children: [
                Image.asset(
                  'assets/images/premium_coin.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
              ),
              Text("120",style:TextStyle(color:Colors.yellow,fontSize:15,fontWeight:FontWeight.bold)),
              ],
                  ),
                  const SizedBox(width: 10),
            Row(
              children: [
                Image.asset(
                  'assets/images/fuzik_coin.png',
                  width: 35,
                  height: 35,
                  fit: BoxFit.cover,
              ),
              Text("120",style:TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.bold)),
              ],
                  ),
          ],
        ),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buy Coins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: packages.map((package) {
                    return SizedBox(
                      width: 170,
                      child: _buildPackageCard(
                        context,
                        package['name'] as String,
                        package['price'] as int,
                        package['coins'] as int,
                      ),
                    );
                  }).toList(),
                                ),
                )
              ],
              ),
),
    );
  }
}

Widget _buildPackageCard(
  BuildContext context,
  String name,
  int price,
  int coins,
) {
  return Card(
    color: Colors.grey.shade900,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '$coins Coins',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '$price THB',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            decoration:BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withValues(alpha:0.3),
                  spreadRadius: 0.3,
                  blurRadius: 10,
   
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                // Buy package
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Payment(
                      packageName: name,
                      price: price,
                      coins: coins,
                    ),
                  ),
                );
              },
              child: const Text('Buy'),
            ),
          ),
        ],
      ),
    ),
  );
}