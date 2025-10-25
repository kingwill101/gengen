---
title: 'Flutter gridview simple pagination'
description: 'Adding pagination to a GridView in Flutter'
date: 2021-02-27T06:44:49-05:00
draft: false
tags : [flutter, dart, gridview, android,ios,web,linux]
author: "Glenford Williams"
---

In this post i'll cover how to do a quick and dirty pagination using the `GridView` widget in Flutter. 
This approach will also work with other components such as the `ListView` or just a collection of widgets 
layed out in a `Column` or `Row`, with a few tweaks of course.

If you just want to see how it works, you can have a look at it [here](https://dartpad.dev/28695a1ef33ea1cdb48dcee41c64786a?null_safety=true) running on dartpad. 

So pagination as the name states, we want to break up a list of items into multiple pages. This would require us knowing how many items
we want to show on the screen at any given time. So if we have 100 products to display in our shopping app and we 
want the user to only see 10 items, our variables would look something like

```dart
int totalProducts = 100;
int productsPerPage = 10;
```

And to find out how many pages our app will have we'll do

```dart
int pageCount = totalProducts/productsPerPage;
```

And of course we are gonna need to keep track of the current page being showed.

```dart
int currentPage = 0;
```

Also while we are at it, let's generate a list of products to show our users

```dart
class Product {
  final int id;
  final String name;
  Product(this.id, this.name);
}

final List<Product> myProducts = 
  List.generate(100, (index) => Product(index,"Product $index")).toList();
```

Now that we have our list of products and we know how many items we want to show, let's create our `GridView` using `GridView.builder()`.

By default `GridView.builder` has 2 required parameters, a `SliverGridDelegate gridDelegate` a `IndexedWidgetBuilder itemBuilder` 
and of course we need to tell the builder how many items we'll be providing which we'll pass to `int itemCount`. With that we have

```dart
 GridView.builder(
...
    itemCount: productsPerPage,
    itemBuilder: (BuildContext ctx, index) {
      return Container(
        alignment: Alignment.center,
        child: Text(myProducts[index + (currentPage * productsPerPage)].name),
...
      );
    })
```

Notice that the use of `myProducts[index + (currentPage * productsPerPage)]` is how we access the current page.

And if your current page is 0(our first page) we'll be doing the following for each index

```dart
//index = 0
myProducts[0 + (0 * 10)] //1st item in myProducts
//index = 1
myProducts[1 + (0 * 10)] //2nd item in myProducts
//index = 2
myProducts[2 + (0 * 10)] //3rd item in myProducts
```

So if our current page is page 5, we'll be doing the following for each index

```dart
//index = 0
myProducts[0 + (5 * 10)] //50th item in myProducts
//index = 1
myProducts[1 + (5 * 10)] //51st item in myProducts
//index = 2
myProducts[2 + (5 * 10)] //52nd item in myProducts
```
And so on for each page.

Now that we have our our `GridView` running let's add buttons to navigate our list of products

```dart
Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      TextButton(
        child: Text("Previous page"),
        onPressed: previousPage,
      ),
      SizedBox(width: 10),
      TextButton(
        child: Text("Next page"),
        onPressed: nextPage,
      )
    ])
```

Of course to change page our  `previousPage` and `nextPage` methods will be decrementing and incrementing the value of our `currentPage` variable

```dart
previousPage() {
  setState(() {
    currentPage -= 1;
  });
}

nextPage() {
  setState(() {
    currentPage += 1;
  });
}
```

So now let's make sure that we do not attempt to show more pages than we have, let's add boundaries!
```dart

  num pageCount() {
    return totalProducts / productsPerPage;
  }

  nextPage() {
    if ((currentPage + 1) < pageCount()) {
      setState(() {
        currentPage += 1;
      });
    }
  }

```

also let's not go below zero 🥶
```dart

  previousPage() {
    //lets not go bellow 0 :-)
    if (currentPage != 0) {
      setState(() {
        currentPage -= 1;
      });
    }
  }

```
We can also go a bit further and disable our buttons when the next index will be out of range.

```dart
 Row(
...
    children: [
        TextButton(
            child: Text("Previous page"),
            onPressed: (currentPage - 1) < 0 ? null: previousPage,
        ),
      ...
      TextButton(
            child: Text("Next page"),
            onPressed: (currentPage + 1) < pageCount()
            ? nextPage
                : null,
        )
    ]
)
```

The final result 

![image alt text](/flutter_pagination.gif)


And that pretty much covers the basics of building a simple paginator when using the `GridView` in Flutter. 
Of course I know this will not work for every use case, but I hope it will provide you the starting point you need to build some awesome widgets!