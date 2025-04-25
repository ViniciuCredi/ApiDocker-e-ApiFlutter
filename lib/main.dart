import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro com MockAPI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ====== TELA INICIAL ======
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Principal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FormPage()),
              ),
              child: const Text('Cadastrar Novo'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListaDadosPage()),
              ),
              child: const Text('Ver Cadastros'),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== TELA DE CADASTRO ======
class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  static const String apiUrl =
      'https://68093a831f1a52874cdc4734.mockapi.io/usuarios';

  Future<void> _enviarDados() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
          }),
        );

        if (response.statusCode == 201) {
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Cadastro realizado!')),
          );
        } else {
          throw Exception('Erro ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira seu nome' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) return 'Por favor, insira seu e-mail';
                  if (!value.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira seu telefone' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _enviarDados,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SALVAR CADASTRO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====== TELA DE LISTAGEM ======
class ListaDadosPage extends StatefulWidget {
  const ListaDadosPage({super.key});

  @override
  State<ListaDadosPage> createState() => _ListaDadosPageState();
}

class _ListaDadosPageState extends State<ListaDadosPage> {
  List<dynamic> _dados = [];
  bool _isLoading = true;
  bool _error = false;

  static const String apiUrl =
      'https://68093a831f1a52874cdc4734.mockapi.io/usuarios';

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _error = false;
    });
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        _dados = jsonDecode(response.body);
      } else {
        throw Exception('Erro ${response.statusCode}');
      }
    } catch (_) {
      _error = true;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastros Salvos'),
        actions: [
          IconButton(onPressed: _carregarDados, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: ElevatedButton(
                    onPressed: _carregarDados,
                    child: const Text('Tentar novamente'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: _dados.isEmpty
                      ? const Center(child: Text('Nenhum cadastro encontrado'))
                      : ListView.builder(
                          itemCount: _dados.length,
                          itemBuilder: (_, index) => ListTile(
                            title: Text(_dados[index]['name'] ?? 'Sem Nome'),
                            subtitle:
                                Text(_dados[index]['email'] ?? 'Sem Email'),
                          ),
                        ),
                ),
    );
  }
}
