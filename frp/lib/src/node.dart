part of node;

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

  Node derive(Function map){
    return new InjectiveNode<dynamic>(this, map);
  }

  Node safeDerive(Function map){
    return new FilteredNode<dynamic>(this, (TYPE value)=>value!=null).derive(map);
  }

  Node filter(Function map){
    return new FilteredNode<dynamic>(this, map);
  }

  Node sample(int internalInMs);
  Node add(Node n);
  Node or(Node n);

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
}

class ValueNode<TYPE> extends Node<TYPE>{
  ValueNode({Stream<TYPE> stream, TYPE initValue}):super(stream:stream==null?null:stream.map((TYPE value)=>NodeEvent.next(value))){
    if(initValue!=null){
      onInputValue(NodeEvent.next(initValue));
    }
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Variables
  //
  //--------------------------------------------------------------------------------------------------------------------

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void operator <=(TYPE value){
    onInputValue(NodeEvent.next(value));
  }


  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------


  void onInputValue(NodeEvent evt){
    // cache the latest value
    lastValue = evt.value;
    // update the status of this node
    dataReady = true;
    // issue the event
    streamController.add(evt);
  }
}

class DerivedNode<TYPE> extends Node<TYPE>{

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Constructor
  //
  //--------------------------------------------------------------------------------------------------------------------

  DerivedNode(Stream stream, Function mapping):super(stream:stream){
    this.mapping = mapping;
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Variables
  //
  //--------------------------------------------------------------------------------------------------------------------

  Function  mapping;
}

class InjectiveNode<TYPE> extends DerivedNode<TYPE>{

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Constructor
  //
  //--------------------------------------------------------------------------------------------------------------------

  InjectiveNode(Node input, Function mapping):super(input.outputStream, mapping){
    this.input = input;
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Variables
  //
  //--------------------------------------------------------------------------------------------------------------------

  Node      input;

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void onInputValue(NodeEvent evt){
    TYPE newValue = mapping(evt.value);
    if(newValue != lastValue){
      // cache the latest value
      lastValue = newValue;
      // update the status of this node
      dataReady = true;
      // issue the event
      streamController.add(NodeEvent.next(lastValue, this, evt));
    }
  }
}

class FilteredNode<TYPE> extends InjectiveNode<TYPE>{

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Constructor
  //
  //--------------------------------------------------------------------------------------------------------------------

  FilteredNode(Node input, Function mapping):super(input, mapping){
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void onInputValue(NodeEvent evt){
    TYPE newValue = mapping(evt.value);
    if(newValue != lastValue && newValue){
      // update the status of this node
      dataReady = true;
      // cache the latest value
      lastValue = newValue;
      // issue the event
      streamController.add(NodeEvent.next(evt.value, this, evt));
    }
  }
}

class MapNode<TYPE> extends DerivedNode<TYPE>{

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Constructor
  //
  //--------------------------------------------------------------------------------------------------------------------

  MapNode(List<Node> inputs, Function mapping):super(Node.joinInputStreams(inputs),mapping){
    this.inputs = inputs;
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Variables
  //
  //--------------------------------------------------------------------------------------------------------------------

  List<Node>     inputs;

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  bool dataIsReady()=>true;

  TYPE getDataFromInputs(NodeEvent evt){
    Node eventTrigger = evt.node;

    List params = new List(inputs.length);
    for(int i=0; i<inputs.length; ++i){
      if(inputs[i]!=eventTrigger)
        params[i] = inputs[i].lastValue;
      else
        params[i] = evt.value;
    }
    return Function.apply(mapping,(params));
  }

  void onInputValue(NodeEvent evt){
    if(dataIsReady()){
      TYPE newValue = getDataFromInputs(evt);
      if(newValue != lastValue){
        // cache the latest value
        lastValue = newValue;
        // update the status of this node
        dataReady = true;
        // issue the event
        streamController.add(NodeEvent.next(lastValue, this, evt));
      }
    }
  }
}

class SyncMapNode<TYPE> extends MapNode<TYPE>{
  SyncMapNode(List<Node> input, Function mapping):super(input, mapping){
  }

  bool dataIsReady(){
    return inputs.every((Node node)=>node.dataReady);
  }
}

class AsyncMapNode<TYPE> extends MapNode<TYPE>{

  AsyncMapNode(List<Node> input, Function mapping):super(input, mapping){
  }

  bool dataIsReady(){
    return inputs.any((Node node)=>node.dataReady);
  }
}
