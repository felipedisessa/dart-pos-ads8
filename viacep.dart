import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Endereco> buscaEndereco(String cep) async {
  final resposta = await http.get(
    Uri.parse('https://viacep.com.br/ws/$cep/json/'),
    headers: {'Accept': 'application/json'},
  );

  if (resposta.statusCode == 200) {
    final json = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (json.containsKey('erro') && json['erro'] == true) {
      throw Exception('CEP não encontrado.');
    }
    return Endereco.fromJson(json);
  }

  throw Exception('Falha ao buscar o CEP.');
}

class Endereco {
  final String cep;
  final String rua;
  final String bairro;
  final String cidade;
  final String estado;

  const Endereco({
    required this.cep,
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      cep: (json['cep'] ?? '').toString(),
      rua: (json['logradouro'] ?? '').toString(),
      bairro: (json['bairro'] ?? '').toString(),
      cidade: (json['localidade'] ?? '').toString(),
      estado: (json['uf'] ?? '').toString(),
    );
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final _cepController = TextEditingController();
  final _numeroController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _cepController.dispose();
    _numeroController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _cepController.text = prefs.getString('cep_salvo') ?? '';
      _numeroController.text = prefs.getString('numero_casa') ?? '';
      _ruaController.text = prefs.getString('rua_salva') ?? '';
      _bairroController.text = prefs.getString('bairro_salvo') ?? '';
      _cidadeController.text = prefs.getString('cidade_salva') ?? '';
      _estadoController.text = prefs.getString('estado_salvo') ?? '';
    });
  }

  Future<void> _buscarEndereco() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      setState(() => _erro = 'Digite um CEP com 8 números.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final endereco = await buscaEndereco(cep);
      if (!mounted) return;

      setState(() {
        _cepController.text = endereco.cep;
        _ruaController.text = endereco.rua;
        _bairroController.text = endereco.bairro;
        _cidadeController.text = endereco.cidade;
        _estadoController.text = endereco.estado;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cep_salvo', endereco.cep);
      await prefs.setString('rua_salva', endereco.rua);
      await prefs.setString('bairro_salvo', endereco.bairro);
      await prefs.setString('cidade_salva', endereco.cidade);
      await prefs.setString('estado_salvo', endereco.estado);

      if (!mounted) return;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Endereço carregado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _salvarDados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'cep_salvo', _cepController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    await prefs.setString('numero_casa', _numeroController.text);
    await prefs.setString('rua_salva', _ruaController.text);
    await prefs.setString('bairro_salvo', _bairroController.text);
    await prefs.setString('cidade_salva', _cidadeController.text);
    await prefs.setString('estado_salvo', _estadoController.text);

    if (!mounted) return;
    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Dados salvos localmente.')),
    );
  }

  Future<void> _apagarDados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cep_salvo');
    await prefs.remove('numero_casa');
    await prefs.remove('rua_salva');
    await prefs.remove('bairro_salvo');
    await prefs.remove('cidade_salva');
    await prefs.remove('estado_salvo');

    if (!mounted) return;
    setState(() {
      _cepController.clear();
      _numeroController.clear();
      _ruaController.clear();
      _bairroController.clear();
      _cidadeController.clear();
      _estadoController.clear();
      _erro = null;
    });

    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Dados apagados.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta de endereço',
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Parte 6 — CEP e endereço'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informe o CEP e o número da casa para carregar o endereço.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cepController,
                keyboardType: TextInputType.number,
                maxLength: 9,
                decoration: const InputDecoration(
                  labelText: 'CEP',
                  hintText: 'Ex.: 01001-000',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _buscarEndereco(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número da casa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _carregando ? null : _buscarEndereco,
                child: _carregando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Buscar endereço'),
              ),
              const SizedBox(height: 12),
              if (_erro != null)
                Text(
                  _erro!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _ruaController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Rua',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bairroController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Bairro',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cidadeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _estadoController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarDados,
                child: const Text('Salvar dados'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _apagarDados,
                child: const Text('Apagar dados salvos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
