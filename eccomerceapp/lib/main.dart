import 'package:eccomerceapp/services/api_service.dart';
import 'package:flutter/material.dart';
import 'RegisterPage.dart';
import 'Dashboard.dart';
void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    ));

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordHidden = true;
  String? userType;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
    backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
    elevation: 0,
    leading: Padding(
      padding: EdgeInsets.all(8),
      child: CircleAvatar(
        radius: 30,
        backgroundImage: AssetImage("assets/images/nirvista_logo.jpg"),
      ),
    ),
  ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange[600]!,
              Colors.orange[400]!,
              Colors.orange[300]!,
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(height: 70),
            Text(
              "Login",
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 40),
            Text(
              "Welcome",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 40),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(225, 95, 27, .3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                )
                              ]),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: <Widget>[
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey[300]!)),
                                ),
                                child: TextFormField(
                                  controller: emailController,          
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.person,color: Colors.orange[600]),
                                    hintText: "Email",
                                    hintStyle:
                                        TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                  validator: (value) {
                                    if(value == null || value.isEmpty){
                                      return "Email Required";
                                    }
                                    

                                    if(!value.contains("@")){
                                      return "Invalid Email";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(20),
                                child: TextFormField(
                                  controller: passwordController,
                                  obscureText: isPasswordHidden,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.lock_clock_rounded,color: Colors.orange[600]),
                                    hintText: "Password",
                                    hintStyle:
                                        TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isPasswordHidden
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isPasswordHidden =
                                              !isPasswordHidden;
                                        });
                                      },
                                    ),
                                  ),
                                  validator:(value) {
                                    if(value == null || value.isEmpty){
                                      return "Password Required";
                                    }
                                    return null;
                                  },
                                ),
                              )
                            ],
                          ),
                          ),
                        ),
                        SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.grey,decoration: TextDecoration.underline),

                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RegisterPage())
                                );
                              },
                              child: Text(
                                "Register Now",
                                style: TextStyle(color: Colors.grey,decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20,),
                        Text(
                          "Register as",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [                       
                            SizedBox(height: 20),
                            Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: "Customer",
                                groupValue: userType,
                                onChanged: (String? value) {
                                  setState(() {
                                    userType = value!;
                                  });
                                },
                              ),
                              Text("Customer"),
                            ],
                          ),
                        
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: "Vendor",
                                groupValue: userType,
                                onChanged: (String? value) {
                                  setState(() {
                                    userType = value!;
                                  });
                                },
                              ),
                              Text("Vendor"),
                            ],
                          ),
                          
                         
                          
                          ],
                        ),
                        SizedBox(height: 40),
                        GestureDetector(
                          onTap: () async{
                            if(_formKey.currentState!.validate()){
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Logging in...')),
                              );
                              final result = await ApiService.userLogin(
                                email: emailController.text, 
                                password: passwordController.text,
                              );
                              if (result['success']){
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => DashboardPage()),
                                );
                              } else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message'])),
                                );
                              }
                            }
                          },
                          child:
                          Container(

                          height: 50,
                          margin: EdgeInsets.symmetric(horizontal: 50),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.orange[600],
                          ),
                          child: Center(
                            child: Text(
                              "Login",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}