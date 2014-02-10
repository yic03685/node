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
    print("\nThe node event has current value "+ value.toString());

    NodeEvent current = src;
    while(current!=null){
      print("previous value: "+current.value.toString());
      current = current.src;
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

  static NodeEvent next(dynamic value, [Node currentNode, NodeEvent src]){
    return new NodeEvent._internal(value, currentNode, src);
  }

}

class NextEvent<TYPE> extends NodeEvent<TYPE>{

}

class InitialEvent<TYPE> extends NodeEvent<TYPE>{

}
