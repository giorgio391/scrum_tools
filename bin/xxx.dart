import 'dart:convert';

import 'package:scrum_tools/src/server/rally_proxy.dart';

String _defectID = r'112807782192'; // DE6071

String _user = r'mruiz1@emergya.com';
String _pass = r"yus89(H21T'RvA";


/*
https://rally1.rallydev.com/slm/webservice/v2.0/Tags?pagesize=100&query=(Name = "PRO")

{
"_rallyAPIMajor": "2",
"_rallyAPIMinor": "0",
"_ref": "https://rally1.rallydev.com/slm/webservice/v2.0/tag/55550759656",
"_refObjectUUID": "58f335e2-5d44-420b-945b-fe4092b57dd7",
"_refObjectName": "UAT",
"_type": "Tag"
}

{
"_rallyAPIMajor": "2",
"_rallyAPIMinor": "0",
"_ref": "https://rally1.rallydev.com/slm/webservice/v2.0/tag/55550758971",
"_refObjectUUID": "2094cd74-f6c6-49e4-a769-390ba2756bbd",
"_refObjectName": "PRE",
"_type": "Tag"
}

{
"_rallyAPIMajor": "2",
"_rallyAPIMinor": "0",
"_ref": "https://rally1.rallydev.com/slm/webservice/v2.0/tag/55550759466",
"_refObjectUUID": "0942e90c-e77b-444c-8fdc-9f06df92eeb4",
"_refObjectName": "PRO",
"_type": "Tag"
}

 */

void main(List<String> args) {
  RallyDevProxy proxy = new RallyDevProxy(_user, _pass);

  /*
  proxy.getString('/fresh/defect/${_defectID}').then((String s) {
    print(s);
  });
  */

  //Map m = {'Defect' : { 'Description' : 'ABC'}};
  Map m = {'Defect' : { 'Tags' : [{'_ref': '/tag/55550758971'}, {'_ref': '/tag/55550759656'}] }};
  proxy.post('/defect/${_defectID}', JSON.encode(m)).then((Map<String, dynamic> result) {
    print(result);
    proxy.close();
  });
}