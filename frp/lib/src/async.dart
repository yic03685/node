part of node;

class FutureValueNode<TYPE> extends ValueNode<TYPE>{
  FutureValueNode({Stream<Future<TYPE>> stream, Future<TYPE> initValue}):super(stream:stream==null?null:stream.map((Future<TYPE> value)=>NodeEvent.next(value))){
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

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void onInputValue(NodeEvent<Future> evt){

    Future<TYPE> futureValue = evt.value;

    futureValue.then((TYPE value){
      if(lastValue != value){
        // cache the latest value
        lastValue = value;
        // update the status of this node
        dataReady = true;
        // issue the event
        streamController.add(NodeEvent.next(value));
      }
    },onError:(NodeError e){
      // issue the event
      streamController.add(NodeEvent.nextWithError(e));
    });
  }

  String toString(){
    return "FutureValueNode("+this.hashCode.toString()+")";
  }
}

class FutureDerivedNode<TYPE> extends DerivedNode<TYPE>{

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Constructor
  //
  //--------------------------------------------------------------------------------------------------------------------

  FutureDerivedNode(Stream<NodeEvent> stream, Function mapping):super(stream,mapping){
  }

  String toString(){
    return "FutureDerivedNode("+this.hashCode.toString()+")";
  }

}

class FutureInjectiveNode<TYPE> extends InjectiveNode<TYPE>{

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Constructor
  //
  //--------------------------------------------------------------------------------------------------------------------

  FutureInjectiveNode(Node input, Function mapping):super(input, mapping){
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void onInputValue(NodeEvent evt){
    Future<TYPE> newFutureValue;

    newFutureValue = mapping(evt.value);

    newFutureValue.then((TYPE newValue){
      signal(newValue, evt);
    }).catchError((NodeError e){
      // There's an error occurred
      signalError(null,evt,e);
    });
  }

  String toString(){
    return "FutureInjectiveNode("+this.hashCode.toString()+")";
  }
}

class FutureFilteredNode<TYPE> extends FilteredNode<TYPE>{

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Constructor
  //
  //--------------------------------------------------------------------------------------------------------------------

  FutureFilteredNode(Node input, Function mapping):super(input, mapping){
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void onInputValue(NodeEvent evt){
    Future<TYPE> newFutureValue = mapping(evt.value);

    newFutureValue.then((TYPE newValue){
      signal(newValue, evt);
    });
  }

  String toString(){
    return "InjectiveNode("+this.hashCode.toString()+")";
  }
}

class FutureMapNode<TYPE> extends MapNode<TYPE>{

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Constructor
  //
  //--------------------------------------------------------------------------------------------------------------------

  FutureMapNode(List<Node> inputs, Function mapping):super(inputs, mapping){
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void onInputValue(NodeEvent evt){
    if(dataIsReady()){
      Function.apply(mapping,getDataFromInputs(evt)).then((TYPE newValue){
        signal(newValue, evt);
      }).catchError((NodeError error){
        // There's an error occurred
        signalError(null,evt,error);
      });
    }
  }

  String toString(){
    return "FutureMapNode("+this.hashCode.toString()+")";
  }
}

class FutureSyncMapNode<TYPE> extends FutureMapNode<TYPE>{
  FutureSyncMapNode(List<Node> input, Function mapping):super(input, mapping){
  }

  bool dataIsReady(){
    return inputs.every((Node node)=>node.dataReady);
  }

  String toString(){
    return "FutureSyncMapNode("+this.hashCode.toString()+")";
  }
}

class FutureAsyncMapNode<TYPE> extends FutureMapNode<TYPE>{

  FutureAsyncMapNode(List<Node> input, Function mapping):super(input, mapping){
  }

  bool dataIsReady(){
    return inputs.any((Node node)=>node.dataReady);
  }

  String toString(){
    return "FutureAsyncMapNode("+this.hashCode.toString()+")";
  }
}