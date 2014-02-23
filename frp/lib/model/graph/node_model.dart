part of graph_model;

class NodeModel {

  String          name;
  NodeType        type;
  List<EdgeModel> input;
  List<EdgeModel> output;

  NodeModel(NodeType this.type, [String this.name]) {
  }
}
