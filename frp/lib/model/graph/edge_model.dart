part of graph_model;

class EdgeModel{

  NodeModel from;
  NodeModel to;
  EdgeType  type;
  String    name;

  EdgeModel(NodeModel this.from, NodeModel this.to, EdgeType this.type, [String name]);
}