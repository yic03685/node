import 'package:unittest/unittest.dart';
import "../lib/node.dart";
import "dart:async";


void main(){

  Stream<int> createIntStream(){
    return new Stream.fromIterable([1,2,3,4,5]);
  }

  test("Can listen to a value node", (){

    Stream<int> s = createIntStream();
    ValueNode<int> node = new Node<int>(stream:s,initValue:0);

    List<int> output = [];
    node.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [0,1,2,3,4,5]);
    });
  });

  test("Can give a value directly to a value node", (){

    ValueNode<int> node = new Node<int>(initValue:0);

    List<int> output = [];
    node.onValue((int i)=>output.add(i));

    node<=6;

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [0,6]);
    });

  });

  test("Can initiate a value node without initial value", (){

    ValueNode<int> node = new Node<int>();

    List<int> output = [];
    node.onValue((int i)=>output.add(i));

    node<=6;

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [6]);
    });

  });

  test("Can initiate a value node with stream without initial value", (){

    Stream<int> s = createIntStream();
    ValueNode<int> node = new Node<int>(stream:s);


    List<int> output = [];
    node.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [1,2,3,4,5]);
    });
  });

  test("Can have two value nodes with the same broadcast stream", (){

    Stream<int> s = createIntStream().asBroadcastStream();
    ValueNode<int> node = new Node<int>(stream:s);
    ValueNode<int> node2 = new Node<int>(stream:s);

    List<int> output = [];
    node.onValue((int i)=>output.add(i));
    node2.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [1,1,2,2,3,3,4,4,5,5]);
    });
  });

  test("Can derive a node with a mapping function", (){

    Stream<int> s = createIntStream().asBroadcastStream();
    ValueNode<int> node = new Node<int>(stream:s,initValue:0);
    ValueNode<int> deNode = node.derive((int value)=>value+1);

    List<int> output = [];
    deNode.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [1,2,3,4,5,6]);
    });
  });
}