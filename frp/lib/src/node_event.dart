part of node;

class Step{

  Step(Node this.node, dynamic this.value){

  }

  Node    node;
  dynamic value;

  String toString(){
    return value.toString();
  }

}

class NodeEvent  {
  NodeEvent(this.value) {
    init();
  }

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Variables
  //
  //--------------------------------------------------------------------------------------------------------------------

  List<Step> path;
  dynamic value;

  //--------------------------------------------------------------------------------------------------------------------
  //
  //                                          Public Methods
  //
  //--------------------------------------------------------------------------------------------------------------------

  void log(Node n){
    path.add(new Step(n,value));
  }

  Node lastNode(){
    if(path.length == 0)
      return null;
    else
      return path[path.length-1].node;
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
    path = new List<Step>();
  }
}

class NextEvent<TYPE> extends NodeEvent<TYPE>{

}

class InitialEvent<TYPE> extends NodeEvent<TYPE>{

}
