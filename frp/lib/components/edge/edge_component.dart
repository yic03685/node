library node_component;

import 'package:angular/angular.dart';

class NodelModel{

}


class EdgeModel{

}

@NgComponent(
    selector: 'node-component',
    templateUrl: '../lib/components/node/node_component.html',
    cssUrl: '../lib/components/node/node_component.css',
    publishAs: 'cmp'
)
class NodeComponent {


  static const String _starOnChar = "\u2605";
  static const String _starOffChar = "\u2606";
  static const String _starOnClass = "star-on";
  static const String _starOffClass = "star-off";

  static final int DEFAULT_MAX = 5;

  List<int> stars = [];
  List<String> nodeTypes = [
    "VALUE NODE",
    "ASNYCHRONOUS NODE"
  ];

  @NgTwoWay('rating')
  int rating;

  @NgAttr('max-rating')
  set maxRating(String value) {
    var count = value == null ? DEFAULT_MAX :
    int.parse(value, onError: (_) => DEFAULT_MAX);
    stars = new List.generate(count, (i) => i+1);
  }

  String selectedNodeType = "VALUE NODE";


  void setNodeType(String value){
    print(value);
  }

  String starClass(int star) {
    return star > rating ? _starOffClass : _starOnClass;
  }

  String starChar(int star) {
    return star > rating ? _starOffChar : _starOnChar;
  }

  void handleClick(int star) {
    rating = (star == 1 && rating == 1) ? 0 : star;
  }
}
