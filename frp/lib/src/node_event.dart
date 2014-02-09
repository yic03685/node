part of node;

class NodeEvent  {
  NodeEvent._internal(dynamic this._currentValue, [Node this._currentNode, NodeEvent this._src]) {
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Variables
  //
  //--------------------------------------------------------------------------------------------------------------------

  Node      _currentNode;
  dynamic   _currentValue;
  NodeEvent _src;

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Public Methods
  //
  //--------------------------------------------------------------------------------------------------------------------


  Node get node=>_currentNode;
  dynamic get value=>_currentValue;
  NodeEvent get src=> _src;

  List<Step> get path{
    List<Step> p = [value];
    NodeEvent current = _src;
    while(current!=null){
      p.add(current.value);
      current = current.src;
    }
    return p.reversed.toList();
  }


  void trace(){
    if(path.length==0){
      print("The node has no value");
      return;
    }

    print("\nThe node event has current value "+ path[path.length-1].value.toString());

    for(int i=path.length-2; i>=0; --i){
      print("previous value: "+path[i].toString());
    }
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Private Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void init(){
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Static Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  static create(dynamic value){

  }

  static next(dynamic value, [Node currentNode, NodeEvent src]){
    return new NodeEvent._internal(value, currentNode, src);
  }

}

class NextEvent<TYPE> extends NodeEvent<TYPE>{

}

class InitialEvent<TYPE> extends NodeEvent<TYPE>{

}
