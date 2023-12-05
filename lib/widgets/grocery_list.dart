import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  var _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  var _error = null;
  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'flutter-prep-7582a-default-rtdb.firebaseio.com', 'shopping-list.json');
      final response = await http.get(url);
      if(response.statusCode >= 400){
        throw Exception('Failed  to fetch data. Please try again later');
      }
      if(response.body == 'null'){

        return [];
      }
      print(response.body);
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category));
      }
      return loadedItems;


  }

  void addItem() async {
    final newItem =
    await Navigator.of(context)
        .push<GroceryItem>(MaterialPageRoute(builder: (ctx) => NewItem()));
    final url = Uri.https(
        'flutter-prep-7582a-default-rtdb.firebaseio.com', 'shopping-list.json');
    if(newItem == null){
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
      //  if (newItem == null) {
    //   return;
    // }
    // setState(() {
    //   _groceryItems.add(newItem);
    // });
  }

  void removeItem(GroceryItem groceryItem) async {
    final index = _groceryItems.indexOf(groceryItem);
    setState(() {
      _groceryItems.remove(groceryItem);
    });
    final url = Uri.https(
        'flutter-prep-7582a-default-rtdb.firebaseio.com', 'shopping-list/${groceryItem.id}.json');
    final response = await http.delete(url);
    if(response.statusCode >= 400){
      //Optional - Show error message
      setState(() {
        _groceryItems.insert(index, groceryItem);
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: addItem, icon: const Icon(Icons.add))],
      ),
      body: FutureBuilder(future: _loadedItems, builder: (context,snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator(),);
          }
          if(snapshot.hasError){
            return Center(child: Text(snapshot.error.toString()),);
          }
          if(snapshot.data!.isEmpty){
            return const Text('No items added yet.');
          }

          List<GroceryItem> localGroceryItemList = snapshot.data!;
          return ListView.builder(
              itemCount: localGroceryItemList.length,
              itemBuilder: (ctx, index) => Dismissible(
                key: ValueKey(localGroceryItemList[index].id),
                onDismissed: (direction) {
                  removeItem(localGroceryItemList[index]);
                },
                child: ListTile(
                  title: Text(localGroceryItemList[index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: localGroceryItemList[index].category.color,
                  ),
                  trailing: Text(localGroceryItemList[index].quantity.toString()),
                ),
              ));
      },),
    );
  }
}
