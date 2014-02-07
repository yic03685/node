part of node;

abstract class Node<TYPE> {

  factory Node({Stream stream, TYPE initValue,Function dataProvider}){
    if(dataProvider == null){
      Stream newStream = stream == null? null : stream.map((TYPE value)=>Node.createEvent(value));
      return new ValueNode(stream:newStream,initValue:initValue);
    }
    else{
      return new DrivedNode(stream:stream,dataProvider:dataProvider);
    }
  }

  Node._internal({Stream<NodeEvent> stream}) {
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

  DerivedNode derive(Function map){
    return new DerivedNode(stream:outputStream, dataProvider:map);
  }

  DerivedNode safeDerive(Function map){
    return new FilteredNode(stream:outputStream, dataProvider:(TYPE value)=>value!=null).derive(map);
  }

  DerivedNode filter(Function map){
    return new FilteredNode(stream:outputStream, dataProvider:map);
  }

  SyncDerivedNode sample(int internalInMs);
  SyncDerivedNode add(Node n);
  SyncDerivedNode or(Node n);

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

  static NodeEvent createEvent(value){
    // create a event with the latest value
    NodeEvent evt = new NodeEvent(value);
    return evt;
  }
}


class ValueNode<TYPE> extends Node<TYPE>{
  ValueNode({Stream<TYPE> stream, TYPE initValue}):super._internal(stream:stream){
    if(initValue!=null){
      onInputValue(Node.createEvent(initValue));
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
    onInputValue(Node.createEvent(value));
  }


  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void onInputValue(NodeEvent evt){
    // cache the latest value
    lastValue = evt.value;
    // log event
    evt.log(this);
    // issue the event
    streamController.add(evt);
  }
}

class DerivedNode<TYPE> extends Node<TYPE>{
  DerivedNode({Stream<TYPE> stream, Function dataProvider}):super._internal(stream:stream){
    this.dataProvider = dataProvider;
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Variables
  //
  //--------------------------------------------------------------------------------------------------------------------

  Function  dataProvider;

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void onInputValue(NodeEvent evt){
    TYPE newValue = dataProvider(evt.value);
    if(newValue != lastValue){
      // cache the latest value
      lastValue = newValue;
      // update event value
      evt.value = lastValue;
      evt.log(this);
      // issue the event
      streamController.add(evt);
    }
  }
}

class FilteredNode<TYPE> extends DerivedNode<TYPE>{
  FilteredNode({Stream<TYPE> stream, Function dataProvider}):super(stream:stream, dataProvider:dataProvider){
  }

  void onInputValue(NodeEvent evt){
    TYPE newValue = dataProvider(evt.value);
    if(newValue != lastValue && newValue){
      // cache the latest value
      lastValue = newValue;
      evt.log(this);
      // issue the event
      streamController.add(evt);
    }
  }
}
