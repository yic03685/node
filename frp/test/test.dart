import 'package:unittest/unittest.dart';
import "../lib/node.dart";
import "dart:async";


void main(){

  Stream<int> createIntStream(){
    return new Stream.fromIterable([1,2,3,4,5]);
  }

  test("Can listen to a value node", (){

    Stream<int> s = createIntStream();
    Node<int> node = new ValueNode<int>(stream:s,initValue:0);

    List<int> output = [];
    node.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [0,1,2,3,4,5]);
    });
  });

  test("Can give a value directly to a value node", (){

    ValueNode<int> node = new ValueNode<int>(initValue:0);

    List<int> output = [];
    node.onValue((int i)=>output.add(i));

    node<=6;

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [0,6]);
    });

  });

  test("Can initiate a value node without initial value", (){

    Node<int> node = new ValueNode<int>();

    List<int> output = [];
    node.onValue((int i)=>output.add(i));

    node<=6;

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [6]);
    });

  });

  test("Can initiate a value node with stream without initial value", (){

    Stream<int> s = createIntStream();
    Node<int> node = new ValueNode<int>(stream:s);


    List<int> output = [];
    node.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [1,2,3,4,5]);
    });
  });

  test("Can have two value nodes with the same broadcast stream", (){

    Stream<int> s = createIntStream().asBroadcastStream();
    ValueNode<int> node = new ValueNode<int>(stream:s);
    ValueNode<int> node2 = new ValueNode<int>(stream:s);

    List<int> output = [];
    node.onValue((int i)=>output.add(i));
    node2.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [1,1,2,2,3,3,4,4,5,5]);
    });
  });

  test("Can derive a node with a mapping function", (){

    Stream<int> s = createIntStream().asBroadcastStream();
    Node<int> node = new ValueNode<int>(stream:s,initValue:0);
    Node<int> deNode = node.derive((int value)=>value+1);
    Node<int> deNode2 = deNode.derive((int value)=>value+1);

    List<int> output = [];
    deNode2.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [2,3,4,5,6,7]);
    });
  });

  test("Can derive a node to a different type", (){

    Node<int> node = new ValueNode<int>(initValue:0);
    Node<String> deNode = node.derive((int value)=>(value+1).toString());

    List<int> output = [];
    deNode.onValue((String s)=>output.add(s));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, ["1"]);
    });
  });

  test("Can have a valid node event (Path is valid)", (){

    Node<int> node = new ValueNode<int>(initValue:0);
    Node<int> deNode = node.derive((int value)=>value+1);
    Node<int> deNode2 = deNode.derive((int value)=>value+1);

    node<=1;

    List output = [];
    deNode2.onEvent((NodeEvent evt){
      output.addAll(evt.path.map((dynamic value)=>value));
    });

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [0,1,2,1,2,3]);
    });
  });

  test("Can filter data", (){

    Node<int> node = new ValueNode<int>(initValue:0);
    Node<int> filteredNode = node.filter((int value)=>value>0);

    node<=1;

    Node<int> deNode = filteredNode.derive((int value)=>value+1);

    List<int> output = [];
    deNode.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [2]);
    });
  });

  test("Can safe derive a node", (){

    Node<int> node = new ValueNode<int>(initValue:0);
    Node<int> deNode = node.safeDerive((int value)=>value+1);

    node<=null;

    List<int> output = [];
    deNode.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [1]);
    });
  });

  test("Can join several nodes into a synchronous one", (){

    Node<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = new ValueNode<int>(initValue:2);
    Node<int> node3 = new ValueNode<int>(initValue:3);
    Node<int> node4 = new ValueNode<int>(initValue:4);
    Node<int> deNode = Node.join([node1, node2, node3],(int value1, int value2, int value3)=>value1+value2+value3);
    Node<int> deNode2 = Node.join([node1, node2, node3, node4],(int value1, int value2, int value3, int value4)=>value1+value2+value3+value4);

    List<int> output = [];
    deNode.onValue((int i)=>output.add(i));
    deNode2.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [6,10]);
    });
  });

}