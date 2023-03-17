import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(systemNavigationBarColor: Colors.black));
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: AppBarTheme(
            color: Colors.black,
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20)),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.grey).copyWith(background: Colors.black, ),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: const MyHomePage(title: 'Гонки разума'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool showDevices = false;
  List<BluetoothDiscoveryResult> results = <BluetoothDiscoveryResult>[];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String attention = "--";
  String meditation = "--";
  bool status = false;
  String json = "";
  String consoleOutput = "";

  void startDiscovery() {
    var streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        setState(() {
          results.add(r);
        });

    });

    streamSubscription.onDone(() {
      //Do something when the discovery process ends
    });
  }

  void findDevices(){
    results.clear();
    setState(() {
      startDiscovery();
    });
  }

  void connectedToDevice(String address, BuildContext context) async {
    // Some simplest connection :F
    //98:D3:31:FC:9B:DA
    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress("98:D3:31:FC:9B:DA");
      print('Connected to the device');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Подключение к $address успешно!"), backgroundColor: Colors.green));
      setState(() {
        status = connection.isConnected;
      });

      final ByteData bytes = ByteData(20);
      final Uint8List list = bytes.buffer.asUint8List();
      final Uint8List list1 = Uint8List(500);

      connection.output.add(list);
      connection.input?.listen((list1) {
        setState(() {
          consoleOutput += ascii.decode(list1);
        });
        var temp = ascii.decode(list1);

        if (temp.contains("")){
          json += temp;
        }
        if (json[json.length-1] == "\n"){
          try{
            print(json.toString());
            Map<String, dynamic> map = jsonDecode(json.toString());
            setState(() {
              attention = map["Attention"].toString();
              meditation = map["Meditation"].toString();
            });
          }
          catch (exception) {
            json = '';
            print(exception);
          }
        }
      }).onDone(() {
        print('Disconnected by remote request');
        setState(() {
          status = connection.isConnected;
          attention = "0";
          meditation = "0";
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Машинка отключена"), backgroundColor: Colors.blue));
      });
    }
    catch (exception) {
      print('Cannot connect, exception occured');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка! Переподключись!"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if(!status)
                  ElevatedButton(onPressed: () => connectedToDevice("a", context), child: const Text("Подключиться к hc-06")),
                Text("Статус: ${status? "подключено": "отключено"}")
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Вращение левого колеса", style: TextStyle(fontSize: 24)),
                    Text(attention.toString(), style: TextStyle(fontSize: 24))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Вращение правого колеса", style: TextStyle(fontSize: 24)),
                    Text(meditation.toString(), style: TextStyle(fontSize: 24))
                  ],
                ),
              ]),
            ),

            Container(
              margin: EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text("Логи", style: TextStyle(fontSize: 26),)),
                  Container(
                      height: 200,
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.all(Radius.circular(20))
                      ),
                      child: SingleChildScrollView(
                        child: Text(consoleOutput),
                      )
                  ),
                ],
              ),
            )


          ],
        ),
      ),
    );
  }
}
