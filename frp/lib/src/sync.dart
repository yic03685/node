part of node;

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
    if(lastValue != evt.value){
      // cache the latest value
      lastValue = evt.value;
      // update the status of this node
      dataReady = true;
      // issue the event
      streamController.add(evt);
    }
  }
}

class DerivedNode<TYPE> extends Node<TYPE>{

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Constructor
  //
  //--------------------------------------------------------------------------------------------------------------------

  DerivedNode(Stream<NodeEvent>  stream, Function mapping):super(stream:stream){
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
    signal(mapping(evt.value),evt);
  }

  void signal(TYPE newValue, NodeEvent lastEvent){
    if(newValue != lastValue){

      // cache the latest value
      lastValue = newValue;
      // update the status of this node
      dataReady = true;
      // issue the event
      streamController.add(NodeEvent.next(lastValue, this, lastEvent));
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
    signal(mapping(evt.value), evt);
  }

  void signal(TYPE newValue, NodeEvent lastEvent){
    if(newValue){
      // update the status of this node
      dataReady = true;
      // cache the latest value
      lastValue = newValue;
      // issue the event
      streamController.add(NodeEvent.next(lastEvent.value, this, lastEvent));
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

  List getDataFromInputs(NodeEvent evt){
    Node eventTrigger = evt.node;

    List params = new List(inputs.length);
    for(int i=0; i<inputs.length; ++i){
      if(inputs[i]!=eventTrigger)
        params[i] = inputs[i].lastValue;
      else
        params[i] = evt.value;
    }
    return params;
  }

  void onInputValue(NodeEvent evt){
    if(dataIsReady()){
      signal(Function.apply(mapping,getDataFromInputs(evt)),evt);
    }
  }

  void signal(TYPE newValue, NodeEvent lastEvent){
    if(newValue != lastValue){
      // cache the latest value
      lastValue = newValue;
      // update the status of this node
      dataReady = true;
      // issue the event
      streamController.add(NodeEvent.next(lastValue, this, lastEvent));
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