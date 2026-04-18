import 'package:fall_detect/provider/auth_provider.dart';
import 'package:fall_detect/provider/fcm_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  @override
  void initState() {
    super.initState();
    getFCMToken();
  }

  void getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      Provider.of<FcmProvider>(context, listen: false).setToken(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 39, 39, 39),
                ),
                child: Center(
                  child: Text(
                    "LOGIN",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 218, 213, 213),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            15,
                          ), // chỉnh góc ở đây
                          image: DecorationImage(
                            image: AssetImage("assets/image/a1.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.black, width: 0.2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              SizedBox(height: 20),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: "Username",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "Forgot password?",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                    const Color.fromARGB(255, 230, 80, 80),
                                  ),
                                  shape:
                                      MaterialStateProperty.all<
                                        RoundedRectangleBorder
                                      >(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                ),
                                onPressed: () async{
                                  final email = _emailController.text;
                                  final password = _passwordController.text;
                                  final mess = await  context
                                      .read<AuthProvider>()
                                      .login(
                                        email,
                                        password,
                                        context.read<FcmProvider>().token ?? "",
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(mess.toString())),
                                  );
                                  if (context.read<AuthProvider>().isLogin) {
                                    Navigator.pushNamed(context, '/hub');
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 100.0,
                                    left: 100.0,
                                  ),
                                  child: Text(
                                    "LOGIN",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Don't have an account?"),
                                  SizedBox(width: 5),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/signup');
                                    },
                                    child: Text(
                                      "Sign up",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 200),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
