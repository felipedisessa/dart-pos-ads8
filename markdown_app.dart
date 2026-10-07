import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const OrganizadorMarkdownApp());

class OrganizadorMarkdownApp extends StatelessWidget {
  const OrganizadorMarkdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Organizador em Markdown',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OrganizadorPage(),
    );
  }
}

class OrganizadorPage extends StatefulWidget {
  const OrganizadorPage({super.key});

  @override
  State<OrganizadorPage> createState() => _OrganizadorPageState();
}

class _OrganizadorPageState extends State<OrganizadorPage> {
  final TextEditingController _controller = TextEditingController();
  bool _carregando = true;
  bool _mostrarPreview = false;

  @override
  void initState() {
    super.initState();
    _carregarMarkdown();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> get _arquivoMarkdown async {
    final diretorio = await getApplicationDocumentsDirectory();
    return '${diretorio.path}/organiza.md';
  }

  Future<void> _carregarMarkdown() async {
    try {
      final arquivo = File(await _arquivoMarkdown);
      if (!await arquivo.exists()) {
        if (!mounted) return;
        setState(() {
          _controller.text = '# Organizador\n\nEscreva seu conteúdo em Markdown aqui...';
          _carregando = false;
        });
        return;
      }

      final conteudo = await arquivo.readAsString();
      if (!mounted) return;
      setState(() {
        _controller.text = conteudo;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _salvarMarkdown() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite algo para salvar no organizador Markdown.')),
      );
      return;
    }

    final arquivo = File(await _arquivoMarkdown);
    await arquivo.writeAsString(texto);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arquivo salvo em organiza.md.')),
    );
  }

  Future<void> _limparMarkdown() async {
    final arquivo = File(await _arquivoMarkdown);
    if (await arquivo.exists()) {
      await arquivo.delete();
    }

    if (!mounted) return;
    setState(() {
      _controller.clear();
      _mostrarPreview = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Organizador limpo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizador Markdown'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Escreva o conteúdo do seu organizador em Markdown:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Editar'), icon: Icon(Icons.edit)),
                ButtonSegment(value: true, label: Text('Preview'), icon: Icon(Icons.preview)),
              ],
              selected: {_mostrarPreview},
              onSelectionChanged: (selection) {
                setState(() => _mostrarPreview = selection.first);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _mostrarPreview
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            child: MarkdownBody(
                              data: _controller.text.isEmpty
                                  ? '_Ainda não há conteúdo para visualizar._'
                                  : _controller.text,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(fontSize: 16),
                                h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                h2: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                                listBullet: const TextStyle(fontSize: 16),
                                code: const TextStyle(
                                  fontFamily: 'monospace',
                                  backgroundColor: Color(0xFFEAEAEA),
                                ),
                              ),
                            ),
                          ),
                        )
                      : TextField(
                          controller: _controller,
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            labelText: 'Conteúdo do Markdown',
                            border: OutlineInputBorder(),
                            hintText: '# Título\n\n- item 1\n- item 2\n\n**destaque**',
                          ),
                        ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _salvarMarkdown,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar em organiza.md'),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _limparMarkdown,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Limpar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
