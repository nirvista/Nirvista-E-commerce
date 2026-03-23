import 'package:eccomerceapp/services/api_service.dart';
import 'package:flutter/material.dart';
import 'main.dart';
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool isPasswordHidden = true;
  bool isConfirmHidden = true;
  String? userType;
  bool isChecked = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
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
              "Register Now",
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
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.note_add_rounded,color: Colors.orange[600]),
                                    hintText: "Full Name",
                                    hintStyle:
                                        TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                  validator : (value){
                                    if(value == null || value.isEmpty){
                                      return "Name is Required";
                                    }
                                    return null;
                                  }
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey[300]!)),
                                ),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.email,color: Colors.orange[600]),
                                    hintText: "Email address",
                                    hintStyle:
                                        TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                  validator: (value) {
                                    if(value == null || value.isEmpty){
                                      return "Email is Required";
                                    }
                                    if(!value.contains("@")){
                                      return "Enter Valid Email";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey[300]!)),
                                ),
                                child: TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.phone,color: Colors.orange[600]),
                                    hintText: "Phone number",
                                    counterText: "",
                                    hintStyle:
                                        TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                  validator: (value) {
                                    if(value == null || value.isEmpty){
                                      return "Phone Number is Required";
                                    }
                                    if (value.length != 10){
                                      return "Enter 10 Digit number";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              Container(
                                padding: EdgeInsets.all(20),
                                 decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey[300]!)),
                                ),
                                child: TextFormField(
                                  controller: passwordController,
                                  obscureText: isPasswordHidden,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.lock,color: Colors.orange[600]),
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty){
                                      return "Password Required";
                                    }
                                    if (value.length < 5){
                                      return "Min 6 Digit Password";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey[300]!)),
                                ),
                                child: TextFormField(
                                  controller: confirmController,
                                  obscureText: isConfirmHidden,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.password_rounded,color: Colors.orange[600]),
                                    hintText: "Confirm Password",
                                    hintStyle:
                                        TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isConfirmHidden
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isConfirmHidden =
                                              !isConfirmHidden;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if(value != passwordController.text){
                                      return "Password do not match";
                                    }
                                    return null;
                                  },
                                ),
                                
                              ),
                              if (userType == "Vendor") ...[
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.shop,color: Colors.orange[600]),
                                    hintText: "Shop Name",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                  validator: (value) {
                                    if(value == null || value.isEmpty){
                                      return "Enter the Shop Name";
                                    }
                                    return null;
                                  },
                                  ),
                                ),

                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey[300]!),
                                      ),
                                    ),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.link,color: Colors.orange[600]),
                                        hintText: "Shop URL",
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                      validator: (value) {
                                        if(value == null || value.isEmpty){
                                          return "Enter the Shop URL";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey[300]!),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 10,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.phone_android,color: Colors.orange[600]),
                                        hintText: "Phone Number",
                                        counterText: "",
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                      validator: (value) {
                                        if(value == null||value.isEmpty){
                                          return "Phone Number Required";
                                        }
                                        if(value.length !=10){
                                          return "Enter 10 digit number";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                              ],
                            ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20,),
                        Text(
                          "Register as",
                          style: TextStyle(color: Colors.grey),
                        ),
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
                        SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(value: isChecked, onChanged: (value){
                              setState(() {
                                isChecked = value!;
                              });
                            }),
                            Flexible(child:Text("I Accept the Terms & Privacy Policy",textAlign: TextAlign.center,))         
                          ],
                        ),
                        SizedBox(height: 40),
                        GestureDetector(
                          onTap: () async {
                            if(!isChecked){
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.all(20),
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.white),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text("Please accept Terms & Privacy Policy", 
                                          style: TextStyle(fontWeight: FontWeight.bold),)
                                      ),
                                    ],
                                  ),
                                  duration: Duration(seconds: 5),
                                ),
                              );
                              return;
                            }
                            if(_formKey.currentState!.validate()){
                              if(passwordController.text != confirmController.text){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Passwords do not match')),
                                );
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Creating account...')),
                              );
                              final result = await ApiService.userSignup(
                                name: nameController.text, 
                                email: emailController.text, 
                                password: passwordController.text,
                                phone: phoneController.text, 
                                userType: userType ?? 'Customer',
                              );
                              if (result['success']){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Account Created! Please Login')),
                                );
                                Navigator.pop(context);
                              } else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message'])),
                                );
                              }
                            }
                            if(!isChecked){
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                margin : EdgeInsets.all(20),
                                content :Row(
                                  children: [
                                    Icon(Icons.error,color: Colors.white),
                                    SizedBox(width: 10,),
                                    Expanded(
                                      child: Text("Please accept Terms & Privacy Policy", 
                                      style:TextStyle(fontWeight: FontWeight.bold),)
                                    ),
                                  ],
                                ),
                                duration:Duration(seconds: 5),
                                ),
                                

                                
                              );
                              return;
                            }
                            showDialog(context: context,
                              barrierDismissible: false,
                             builder: (context) => AlertDialog(
                              shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            
                              title : Row(
                              children: [
                                Icon(Icons.check_circle,color:Colors.green),
                                SizedBox(width: 10,),
                                Text("Success"),
                              ],
                            ),
                            content : Text("Registration Successful"),
                            actions :[
                              TextButton(onPressed: (){
                                Navigator.pop(context);
                                Navigator.pop(context);
                                Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => Homepage())
                              );
                              }, 
                              child: Text("OK"))
                            ]
                            ),
                            );
                          },
                          child: Container(
                            height: 50,
                            margin: EdgeInsets.symmetric(horizontal: 50),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.orange[600],
                            ),
                            child: Center(
                              child: Text(
                                "Register",
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
