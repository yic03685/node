library node;

import "dart:async";

part "src/node_event.dart";
part "src/sync.dart";
part "src/async.dart";


abstract class Node<TYPE> {

  Node({Stream<NodeEvent> stream}) {
    init();

    if(stream!=null){
      stream.listen(onInputValue);
    }

  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Variables
  //
  //--------------------------------------------------------------------------------------------------------------------

  StreamController<TYPE>  streamController;
  Stream<NodeEvent>       outputStream;
  TYPE                    lastValue;
  bool                    dataReady = false;

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Public Methods
  //
  //--------------------------------------------------------------------------------------------------------------------
  void onValue(Function listener){
    // register with the output stream
    outputStream.listen((NodeEvent evt){
      listener(evt.value);
    });
  }

  /**
    * For debug purposes
    * @param listener Listen to a node event
    */
  void onEvent(Function listener){
    outputStream.listen((NodeEvent evt){
      listener(evt);
    });
  }

  Node map(Function map){
    return new InjectiveNode<dynamic>(this, map);
  }

  Node mapError(Function map){
    return new ErrorHandleNode<dynamic>(this, map);
  }

  Node mapFromFuture(Function map){
    return new FutureInjectiveNode<dynamic>(this, map);
  }

  Node safeMap(Function map){
    return new FilteredNode<dynamic>(this, (TYPE value)=>value!=null).map(map);
  }

  Node safeMapFromFuture(Function map){
    return new FilteredNode<dynamic>(this, (TYPE value)=>value!=null).mapFromFuture(map);
  }

  Node filter(Function map){
    return new FilteredNode<dynamic>(this, map);
  }

  Node filterFromFuture(Function map){
    return new FutureFilteredNode<dynamic>(this, map);
  }

  Node sample(int internalInMs);
  Node and(Node n){
    return join([this, n], (bool value0, bool value1)=>value0 && value1).filter((bool value)=>value);
  }

  Node or(Node n){
    return join([this, n], (bool value0, bool value1)=>value0 || value1).filter((bool value)=>value);
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void init(){
    streamController = new StreamController<NodeEvent>();
    outputStream = streamController.stream.asBroadcastStream();
  }

  void onInputValue();

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Static Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  static Stream<NodeEvent> joinInputStreams(List<Node> inputs){
    if(inputs == null)
      throw "Not a valid input node";

    if(inputs.length==1){
      return inputs[0].outputStream;
    }
    else{
      StreamController<NodeEvent> controller = new StreamController<NodeEvent>();
      inputs.forEach((Node node)=>node.outputStream.listen((NodeEvent evt)=>controller.add(evt)));
      return controller.stream;
    }
  }

  static Node join(List<Node> nodes, Function mapping, [isSync=true]){
    if(isSync)
      return new SyncMapNode(nodes, mapping);
    else
      return new AsyncMapNode(nodes, mapping);
  }

  static Node joinFromFuture(List<Node> nodes, Function mapping, [isSync=true]){
    if(isSync)
      return new FutureSyncMapNode(nodes, mapping);
    else
      return new FutureAsyncMapNode(nodes, mapping);
  }
}