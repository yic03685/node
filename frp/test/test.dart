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

  test("Can map a node with a mapping function", (){

    Stream<int> s = createIntStream().asBroadcastStream();
    Node<int> node = new ValueNode<int>(stream:s,initValue:0);
    Node<int> deNode = node.map((int value)=>value+1);
    Node<int> deNode2 = deNode.map((int value)=>value+1);

    List<int> output = [];
    deNode2.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [2,3,4,5,6,7]);
    });
  });

  test("Can map a node with an error function", (){

    Node<int> node = new ValueNode<int>(initValue:0);
    Node<int> deNode = node.map((int value){
      if(value<1)
        throw new NodeError(value-1);
      else
        return value+1;
    }).mapError((NodeError e)=>e.value);
    Node<int> deNode2 = deNode.map((int value)=>value);

    node<=1;

    List<int> output = [];
    deNode2.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [-1,2]);
    });
  });

  test("Can map a node with an error function and have correct event path", (){

    Node<int> node = new ValueNode<int>(initValue:0);
    Node<int> deNode = node.map((int value){
      if(value<1)
        throw new NodeError(value-1);
      else
        return value+1;
    }).mapError((NodeError e)=>e.value);

    node<=1;

    List<int> output = [];
    deNode.onEvent((NodeEvent evt){
      output.addAll(evt.path.map((dynamic value)=>value));
    });

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [0,null,-1,1,2]);
    });
  });

  test("Can map a node to a different type", (){

    Node<int> node = new ValueNode<int>(initValue:0);
    Node<String> deNode = node.map((int value)=>(value+1).toString());

    List<int> output = [];
    deNode.onValue((String s)=>output.add(s));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, ["1"]);
    });
  });

  test("Can have a valid node event (Path is valid)", (){

    Node<int> node = new ValueNode<int>(initValue:0);
    Node<int> deNode = node.map((int value)=>value+1);
    Node<int> deNode2 = deNode.map((int value)=>value+1);

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

    Node<int> deNode = filteredNode.map((int value)=>value+1);

    List<int> output = [];
    deNode.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [2]);
    });
  });

  test("Can safe map a node", (){

    Node<int> node = new ValueNode<int>(initValue:0);
    Node<int> deNode = node.safeMap((int value)=>value+1);

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
    Node<int> node3 = new ValueNode<int>(initValue:3).map((int value)=>value+1);
    Node<int> node4 = new ValueNode<int>(initValue:4);
    Node<int> deNode = Node.join([node1, node2, node3],(int value1, int value2, int value3)=>value1+value2+value3);
    Node<int> deNode2 = Node.join([node1, node2, node3, node4],(int value1, int value2, int value3, int value4)=>value1+value2+value3+value4);

    List<int> output = [];
    deNode.onValue((int i)=>output.add(i));
    deNode2.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [7,11]);
    });
  });

  test("Can join several nodes into an asynchronous one", (){

    Node<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = new ValueNode<int>(initValue:2).map((int value)=>value+1);
    Node<int> node3 = new ValueNode<int>();
    Node<int> adenode = Node.join([node1, node2, node3],(int value1, int value2, int value3){
      if(value1 == null || value2 == null || value3 == null)
        return -1;
      else
        return value1+value2+value3;
    },false);

    Node<int> sdenode = Node.join([node1, node2, node3],(int value1, int value2, int value3){
      if(value1 == null || value2 == null || value3 == null)
        return -1;
      else
        return value1+value2+value3;
    });

    List<int> output = [];
    adenode.onValue((int i)=>output.add(i));
    sdenode.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [-1]);
    });
  });

  test("Can get init ValueNode with a future value", (){

    Completer completer = new Completer();

    Node<int> node1 = new FutureValueNode<int>(initValue:completer.future);

    List<int> output = [];
    node1.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:500), (){
      completer.complete(6);
    });

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [6]);
    });

  });

  test("Can map a node with async mapping", (){

    Completer completer = new Completer();

    Node<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = node1.mapFromFuture((int value)=>completer.future).map((int value)=>value+1);

    List<int> output = [];
    node2.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:500), (){
      completer.complete(6);
    });

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [7]);
    });
  });

  test("Can map a node with async mapping and catch the error if async fails", (){

    Node<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = node1.mapFromFuture((int value){
      Completer completer = new Completer();
      if(value<2){
        new Future.delayed(new Duration(milliseconds:500), (){
          completer.complete(6);
        });
      }
      else{
        new Future.delayed(new Duration(milliseconds:500), (){
          completer.completeError(new NodeError(-1));
        });
      }

      return completer.future;
    }).mapError((NodeError error)=>error.value).map((int value)=>value+1);

    node1<=2;

    List<int> output = [];
    node2.onValue((int i)=>output.add(i));


    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [7,0]);
    });
  });

  test("Can map a node with async mappingm, catch the error if async fails, and have a valid event path.", (){

    Node<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = node1.mapFromFuture((int value){
      Completer completer = new Completer();
      if(value<2){
        new Future.delayed(new Duration(milliseconds:500), (){
          completer.complete(6);
        });
      }
      else{
        new Future.delayed(new Duration(milliseconds:500), (){
          completer.completeError(new NodeError(-1));
        });
      }

      return completer.future;
    }).mapError((NodeError error)=>error.value).map((int value)=>value+1);

    node1<=2;

    List output = [];
    node2.onEvent((NodeEvent evt){
      output.addAll(evt.path.map((dynamic value)=>value));
    });


    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [1,6,7,2,null,-1,0]);
    });
  });


  test("Can map a node with async mapping and have correct node event path", (){

    Completer completer = new Completer();

    Node<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = node1.mapFromFuture((int value)=>completer.future).map((int value)=>value+1);

    List output = [];
    node2.onEvent((NodeEvent evt){
      output.addAll(evt.path.map((dynamic value)=>value));
    });

    new Future.delayed(new Duration(milliseconds:500), (){
      completer.complete(6);
    });

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [1,6,7]);
    });
  });

  test("Can filter an async node", (){

    Completer completer = new Completer();
    Completer completer2 = new Completer();

    Node<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = node1.filterFromFuture((int value)=>completer.future).map((int value)=>value+1);
    Node<int> node3 = node1.filterFromFuture((int value)=>completer2.future).map((int value)=>value+1);

    List<int> output = [];
    node2.onValue((int i)=>output.add(i));
    node3.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:500), (){
      completer.complete(true);
      completer2.complete(false);
    });

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [2]);
    });
  });

  test("Can join several nodes synchronously with an async mapping", (){

    Completer completer2 = new Completer();

    Node<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = new ValueNode<int>(initValue:2).map((int value)=>value+1);
    Node<int> node3 = new ValueNode<int>(initValue:3);

    Node<int> node4 = Node.joinFromFuture([node1, node2, node3], (int value1, int value2, int value3){
      Completer completer = new Completer();

      new Future.delayed(new Duration(milliseconds:500), (){
        completer.complete(value1+value2+value3);
      });
      return completer.future;
    });

    List<int> output = [];
    node4.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [7]);
    });
  });

  test("Can join several nodes asynchronously with an async mapping", (){

    Completer completer2 = new Completer();

    Node<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = new ValueNode<int>(initValue:2).map((int value)=>value+1);
    Node<int> node3 = new ValueNode<int>();

    Node<int> node4 = Node.joinFromFuture([node1, node2, node3], (int value1, int value2, int value3){
      if(value1==null || value2==null || value3==null)
        return new Future(()=>1);
      else{
        Completer completer = new Completer();

        new Future.delayed(new Duration(milliseconds:500), (){
          completer.complete(value1+value2+value3);
        });
        return completer.future;
      }
    },false);

    List<int> output = [];
    node4.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [1]);
    });
  });

  test("Can join several nodes asynchronously with an async mapping with an error", (){

    Completer completer2 = new Completer();

    Node<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = new ValueNode<int>(initValue:2).map((int value)=>value+1);
    Node<int> node3 = new ValueNode<int>(initValue:2);

    Node<int> node4 = Node.joinFromFuture([node1, node2, node3], (int value1, int value2, int value3){
      if(value1==null || value2==null || value3==null)
        return new Future(()=>1);
      else{
        Completer completer = new Completer();

        new Future.delayed(new Duration(milliseconds:500), (){
          completer.completeError(new NodeError(value1+value2+value3));
        });
        return completer.future;
      }
    },false).mapError((NodeError error)=>error.value+1);

    List<int> output = [];
    node4.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [7]);
    });
  });

  test("Can map nodes between using sync or async mapping", (){

    ValueNode<int> node = new ValueNode<int>(initValue:2);
    Node<int> node1 = node.map((int value)=>value+1).mapFromFuture((int value){

      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:500), (){
        completer.complete(value+1);
      });
      return completer.future;
    }).filter((int value){
      return value>3;
    }).map((int value)=>value+1);

    node<=3;
    node<=1;

    List<int> output = [];
    node1.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [5,6]);
    });
  });

  test("Can map nodes between using sync or async mapping and have correct path", (){

    ValueNode<int> node = new ValueNode<int>(initValue:2);
    Node<int> node1 = node.map((int value)=>value+1).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:500), (){
        completer.complete(value+1);
      });
      return completer.future;
    }).filter((int value){
      return value>3;
    }).map((int value)=>value+1);

    List<int> path = [];
    node1.onEvent((NodeEvent evt){
      path.addAll(evt.path.map((dynamic value)=>value));
    });

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(path, [2,3,4,4,5]);
    });
  });

  test("Can join several (synchronous or asynchronous) nodes", (){
    ValueNode<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = new ValueNode<int>(initValue:1).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:500), (){
        completer.complete(value+1);
      });
      return completer.future;
    });
    Node<int> node3 = new ValueNode<int>(initValue:3).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:700), (){
        completer.complete(value+1);
      });
      return completer.future;
    });
    Node<int> node4 = Node.join([node1, node2, node3], (int value1, int value2, int value3)=>value1+value2+value3);

    List<int> output = [];
    node4.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [7]);
    });
  });

  test("Can join several (synchronous or asynchronous) nodes into a synchronus one and (if any of them has an error, it never executes)", (){
    ValueNode<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = new ValueNode<int>(initValue:1).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:500), (){
        completer.complete(value+1);
      });
      return completer.future;
    });
    Node<int> node3 = new ValueNode<int>(initValue:3).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:700), (){
        completer.completeError(value+1);
      });
      return completer.future;
    });
    Node<int> node4 = Node.join([node1, node2, node3], (int value1, int value2, int value3){
      return value1 + value2 + value3;
    });

    List<int> output = [];
    node4.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, []);
    });
  });

  test("Can join several (synchronous or asynchronous) nodes into a synchronus one and (if any of them has an error but maps back, it's fine)", (){
    ValueNode<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = new ValueNode<int>(initValue:1).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:500), (){
        completer.complete(value+1);
      });
      return completer.future;
    });
    Node<int> node3 = new ValueNode<int>(initValue:3).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:700), (){
        completer.completeError(new NodeError(value+1));
      });
      return completer.future;
    }).mapError((NodeError error)=>error.value);
    Node<int> node4 = Node.join([node1, node2, node3], (int value1, int value2, int value3){
      return value1 + value2 + value3;
    });

    List<int> output = [];
    node4.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [7]);
    });
  });

  test("Can join several (synchronous or asynchronous) nodes and generate an error", (){
    ValueNode<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = new ValueNode<int>(initValue:1).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:500), (){
        completer.complete(value+1);
      });
      return completer.future;
    });
    Node<int> node3 = new ValueNode<int>(initValue:3).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:700), (){
        completer.complete(value+1);
      });
      return completer.future;
    });
    Node<int> node4 = Node.join([node1, node2, node3], (int value1, int value2, int value3){
      throw new NodeError(-1);
    }).mapError((NodeError error)=>error.value);

    List<int> output = [];
    node4.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [-1]);
    });
  });

  test("Can join several (synchronous or asynchronous) nodes with a valid path", (){
    ValueNode<int> node1 = new ValueNode<int>(initValue:1);
    Node<int> node2 = new ValueNode<int>(initValue:1).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:500), (){
        completer.complete(value+1);
      });
      return completer.future;
    });
    Node<int> node3 = new ValueNode<int>(initValue:3).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:700), (){
        completer.complete(value+1);
      });
      return completer.future;
    });
    Node<int> node4 = Node.join([node1, node2, node3], (int value1, int value2, int value3)=>value1+value2+value3);

    List<int> output = [];
    node4.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [7]);
    });
  });

  test("Can join several nodes with different types", (){
    ValueNode<int> node1 = new ValueNode<int>(initValue:1);
    Node<String> node2 = new ValueNode<int>(initValue:1).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:500), (){
        completer.complete((value+1).toString());
      });
      return completer.future;
    });
    Node<double> node3 = new ValueNode<int>(initValue:3).mapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:700), (){
        completer.complete((value+1.1));
      });
      return completer.future;
    });
    Node<int> node4 = Node.join([node1, node2, node3], (int value1, String value2, double value3)=>(value1+value3).toString()+value2);

    List<String> output = [];
    node4.onValue((String i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, ["5.12"]);
    });
  });

  test("Can safe map with an asynchronous mapping", (){
    ValueNode<int> node1 = new ValueNode<int>(initValue:1);
    Node<String> node2 = node1.safeMapFromFuture((int value){
      Completer completer = new Completer();
      new Future.delayed(new Duration(milliseconds:500), (){
        completer.complete(value+1);
      });
      return completer.future;
    });

    node1 <= null;
    node1 <= 3;

    List<int> output = [];
    node2.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [2,4]);
    });
  });

  test("Can add two nodes", (){
    Node<bool> node1 = new ValueNode<int>(initValue:1).map((int value)=>value==1);
    Node<bool> node2 = new ValueNode<int>(initValue:2).map((int value)=>value==2);
    Node<bool> node4 = new ValueNode<int>(initValue:1).map((int value)=>value==2);
    Node<int> node3 = node1.and(node2).map((bool value)=>3);
    Node<int> node5 = node1.and(node4).map((bool value)=>6);

    List<int> output = [];
    node3.onValue((int i)=>output.add(i));
    node5.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [3]);
    });
  });

  test("Can or two nodes", (){
    Node<bool> node1 = new ValueNode<int>(initValue:1).map((int value)=>value==1);
    Node<bool> node2 = new ValueNode<int>(initValue:2).map((int value)=>value==2);
    Node<bool> node4 = new ValueNode<int>(initValue:1).map((int value)=>value==2);
    Node<int> node3 = node1.or(node2).map((bool value)=>3);
    Node<int> node5 = node1.or(node4).map((bool value)=>6);

    List<int> output = [];
    node3.onValue((int i)=>output.add(i));
    node5.onValue((int i)=>output.add(i));

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [3,6]);
    });
  });

  test("Can do recursion", (){

    StreamController controller = new StreamController();
    Stream s = controller.stream;
    ValueNode<int> node1 = new ValueNode<int>();
    Node<int> node2 = node1.filter((int value)=>value>0).map((int value)=>value-1);

    node1<=5;

    List<int> output = [];
    node2.onValue((int value){
      output.add(value);
      node1<=value;
    });

    new Future.delayed(new Duration(milliseconds:1000), (){
      expect(output, [4,3,2,1,0]);
    });
  });

}