import 'package:cashier/widget/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MasterLoginScreen extends StatefulWidget {
  const MasterLoginScreen({super.key});

  @override
  State<MasterLoginScreen> createState() => _MasterLoginScreenState();
}

class _MasterLoginScreenState extends State<MasterLoginScreen> {

  final TextEditingController passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool loading = false;

 Future<void> loginMaster() async {

  setState(() {
    loading = true;
  });

  try {

    final passwordInput = passwordController.text;

    // TEMPORARY PASSWORD
    if (passwordInput == "1")   {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNav(role: "master"),
        ),
      );

      return;
    }

    final response = await supabase
        .from('master_users')
        .select('password')
        .limit(1)
        .single();

    final dbPassword = response['password'];

    if (passwordInput == dbPassword) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNav(role: "master"),
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wrong password"),
        ),
      );

    }

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
      ),
    );

  }

  setState(() {
    loading = false;
  });

}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Master Login")),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "Enter Master Password",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: loading ? null : loginMaster,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Login",
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}