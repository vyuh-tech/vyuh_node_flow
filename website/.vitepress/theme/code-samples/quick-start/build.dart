@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('My Flow Editor'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _addNode,
        ),
      ],
    ),
    body: NodeFlowEditor<String, dynamic>(
      controller: controller,
      theme: NodeFlowTheme.light,
      nodeBuilder: (context, node) => Center(
        child: Text(
          node.data,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}
