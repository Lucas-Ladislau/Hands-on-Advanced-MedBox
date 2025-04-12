class HuffmanNode {
  String? char;
  int freq;
  HuffmanNode? left;
  HuffmanNode? right;

  HuffmanNode(this.char, this.freq, {this.left, this.right});
}

class HuffmanCoding {
  final Map<String, String> _codes = {};
  final Map<String, int> _frequencies = {};
  HuffmanNode? _root;

  // Construtor vazio
  HuffmanCoding();

  // Gerar frequência de cada caractere
  void _buildFrequencyMap(String text) {
    _frequencies.clear();
    for (var char in text.split('')) {
      _frequencies[char] = (_frequencies[char] ?? 0) + 1;
    }
  }

  // Criar a fila de prioridade
  List<HuffmanNode> _buildPriorityQueue() {
    List<HuffmanNode> queue = _frequencies.entries
        .map((e) => HuffmanNode(e.key, e.value))
        .toList();
    queue.sort((a, b) => a.freq.compareTo(b.freq));
    return queue;
  }

  // Criar a árvore de Huffman
  HuffmanNode _buildTree(List<HuffmanNode> queue) {
    while (queue.length > 1) {
      var left = queue.removeAt(0);
      var right = queue.removeAt(0);
      var merged = HuffmanNode(null, left.freq + right.freq, left: left, right: right);
      queue.add(merged);
      queue.sort((a, b) => a.freq.compareTo(b.freq));
    }
    return queue.first;
  }

  // Gerar os códigos binários
  void _generateCodes(HuffmanNode node, String code) {
    if (node.char != null) {
      _codes[node.char!] = code;
    } else {
      _generateCodes(node.left!, code + '0');
      _generateCodes(node.right!, code + '1');
    }
  }

  // Comprimir
  String compress(String text) {
    _codes.clear();
    _buildFrequencyMap(text);
    var queue = _buildPriorityQueue();
    _root = _buildTree(queue);
    _generateCodes(_root!, '');

    return text.split('').map((char) => _codes[char]).join();
  }

  // Descomprimir
  String decompress(String encodedText) {
    if (_root == null) {
      throw Exception("Árvore de Huffman não construída.");
    }

    String result = '';
    HuffmanNode current = _root!;
    for (var bit in encodedText.split('')) {
      current = bit == '0' ? current.left! : current.right!;
      if (current.char != null) {
        result += current.char!;
        current = _root!;
      }
    }
    return result;
  }

  Map<String, String> get codes => _codes;
}
