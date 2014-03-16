part of node;

class NodeError<TYPE> extends Error{
  NodeError(TYPE this.value){

  }

  TYPE value;

  String toString(){
    return "NodeError("+this.value.toString()+")";
  }
}

class NodeEvent  {
  NodeEvent._internal(dynamic this._currentValue, [Node this._currentNode, NodeEvent this._src, Error this._error]) {
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Variables
  //
  //--------------------------------------------------------------------------------------------------------------------

  Node      _currentNode;
  dynamic   _currentValue;
  NodeEvent _src;
  Error     _error;

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Public Methods
  //
  //--------------------------------------------------------------------------------------------------------------------


  Node get node=>_currentNode;
  dynamic get value=>_currentValue;
  NodeEvent get src=> _src;
  Error get error=>_error;

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
    int stackLevel = 0;
    print("\n"+(stackLevel++).toString()+": "+toString());

    NodeEvent current = src;
    while(current!=null){
      print( (stackLevel++).toString()+": "+current.toString());
      current = current.src;
    }
  }

  String toString(){
    String str = this._currentNode.toString()+" => value:"+this.value.toString();
    str = error == null? str : str+", error:"+ error.toString();
    return str;
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

  static NodeEvent nextWithError(Error error, [dynamic value, Node currentNode, NodeEvent src]){
    return new NodeEvent._internal(value, currentNode, src, error);
  }
}

class NextEvent<TYPE> extends NodeEvent<TYPE>{

}

class InitialEvent<TYPE> extends NodeEvent<TYPE>{

}
