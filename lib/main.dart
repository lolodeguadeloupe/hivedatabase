import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('shopping_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _quantitycontroller = TextEditingController();

  List<Map<String,dynamic>> _items =[];
  final _shoppingBox = Hive.box('shopping_box');

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  Future<void> _createItem(Map<String,dynamic> newItem) async {
    await _shoppingBox.add(newItem);
    print("amount data is ${_shoppingBox.length}");
    _refreshItems();
  }

  Future<void> _updateItem(int itemKey,Map<String,dynamic> item) async {
    await _shoppingBox.put(itemKey,item);
    _refreshItems();
  }

  Future<void> _deleteItem(int itemKey) async {
    await _shoppingBox.delete(itemKey);
    _refreshItems();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An item is deleted"))
    );
  }

  void _refreshItems() {
    final data = _shoppingBox.keys.map((key) {
      final item = _shoppingBox.get(key);
      print("Item: $item"); // Impression pour vérifier les éléments
      return {
        "key": key,
        "name": item["name"],
        "quantity": item["quantity"]
      };
    }).toList();

    setState(() {
      _items = data.reversed.toList();
      print("Total items: ${_items.length}"); // Impression pour vérifier la longueur de la liste
    });
  }


  void _showForm(BuildContext context,int? itemKey) async {
    print("item key : ${itemKey}");

    if(itemKey != null){
      final existingItem = _items.firstWhere((element) => element['key'] == itemKey);
      _namecontroller.text = existingItem['name'];
      _quantitycontroller.text = existingItem['quantity'];
    }

    showModalBottomSheet(
        elevation: 5,
        context: context,
        builder: (_) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 15,
              left:15,
              right: 15
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _namecontroller,
                  decoration: const InputDecoration(hintText: 'Name'),
                ),
                SizedBox(height: 10,),
                TextField(
                  controller: _quantitycontroller,
                  decoration: const InputDecoration(hintText: 'Quantity'),
                ),
                SizedBox(height: 20,),
                ElevatedButton(
                    onPressed: () {

                      if(itemKey != null){
                        _updateItem(
                          itemKey,
                          {
                            "name":_namecontroller.text.trim(),
                            "quantity":_quantitycontroller.text.trim(),
                          }
                        );
                        _namecontroller.text = '';
                        _quantitycontroller.text = '';
                      }else{
                        _createItem({
                          "name": _namecontroller.text,
                          "quantity": _quantitycontroller.text
                        });
                        _namecontroller.text = '';
                        _quantitycontroller.text = '';
                      }
                      _namecontroller.text = '';
                      _quantitycontroller.text = '';
                      Navigator.of(context).pop();

                    },
                    child: Text(itemKey != null ? "Update" :"Create New")
                )
              ],
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Hive'),
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_,index){
          final currentItem = _items[index];
          return Card(
            color: Colors.orange.shade100,
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              title: Text(currentItem['name']),
              subtitle: Text("${currentItem['quantity']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showForm(context, currentItem['key']),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () => _deleteItem(currentItem['key']),
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


}
