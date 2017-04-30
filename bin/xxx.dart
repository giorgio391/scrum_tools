import 'dart:convert';

import 'package:scrum_tools/src/server/rally_proxy.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/rally/basic_rally_service.dart';

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

{
"_rallyAPIMajor": "2",
"_rallyAPIMinor": "0",
"_ref": "https://rally1.rallydev.com/slm/webservice/v2.0/tag/98533801960",
"_refObjectUUID": "838dc04b-8f01-4738-be56-8b2a0e32daa6",
"_refObjectName": "NOT TO DEPLOY",
"_type": "Tag"
}

 */

void main1(List<String> args) {
  RallyDevProxy proxy = new RallyDevProxy(_user, _pass);

  /*
  proxy.getString('/fresh/defect/${_defectID}').then((String s) {
    print(s);
  });
  */

  //Map m = {'Defect' : { 'Description' : 'ABC'}};
  Map m = {
    'Defect': {
      'Tags': [{'_ref': '/tag/55550758971'}, {'_ref': '/tag/55550759656'}]
    }
  };
  proxy.post('/defect/${_defectID}', JSON.encode(m)).then((
      Map<String, dynamic> result) {
    print(result);
    proxy.close();
  });
}

//{CreateResult: {_rallyAPIMajor: 2, _rallyAPIMinor: 0, Errors: [Could not parse: Cannot convert "2017-04-29 20:23:51.188960" into a date.  You must use the ISO8601 date+time format.], Warnings: [Ignored JSON element Milestone.Nane during processing of this request.]}}

void main2(List<String> args) {
  Map<String, dynamic> data = {
    r'Milestone': {
      r'TargetProject': {r'_ref': r'/project/55308115013'},
      //r'Projects': [{r'_ref': r'/project/55308115013'}],
      r'Name': r'Test MS 01',
      r'TargetDate': '${new DateTime.now().toIso8601String()}',
      r'Artifacts': [{r'_ref': r'/defect/112807782192'}]
    }
  };

  RallyDevProxy proxy = new RallyDevProxy(_user, _pass);

  proxy.post('/milestone/create', JSON.encode(data)).then((
      Map<String, dynamic> result) {
    print(result);
    proxy.close();
  });

  //{CreateResult: {_rallyAPIMajor: 2, _rallyAPIMinor: 0, Errors: [], Warnings: [], Object: {_rallyAPIMajor: 2, _rallyAPIMinor: 0, _ref: https://rally1.rallydev.com/slm/webservice/v2.0/milestone/113445510236, _refObjectUUID: 219bdfa9-99ca-410a-a759-33263f9c2666, _objectVersion: 1, _refObjectName: Test MS 01, CreationDate: 2017-04-29T18:36:21.338Z, _CreatedAt: just now, ObjectID: 113445510236, ObjectUUID: 219bdfa9-99ca-410a-a759-33263f9c2666, VersionId: 1, Subscription: {_rallyAPIMajor: 2, _rallyAPIMinor: 0, _ref: https://rally1.rallydev.com/slm/webservice/v2.0/subscription/3674123363, _refObjectUUID: 77303dce-b73e-48b3-876a-766d0fe580b1, _refObjectName: Hewlett-Packard - TX, _type: Subscription}, Workspace: {_rallyAPIMajor: 2, _rallyAPIMinor: 0, _ref: https://rally1.rallydev.com/slm/webservice/v2.0/workspace/53300903887, _refObjectUUID: 1a34bce0-eec4-48a5-9443-72aeb7a850c8, _refObjectName: Content Management, _type: Workspace}, Artifacts: {_rallyAPIMajor: 2, _rallyAPIMinor: 0, _ref: https://rally1.rallydev.com/slm/webservice/v2.0/Milestone/113445510236/Artifacts, _type: Artifact, Count: 1}, DisplayColor: #848689, FormattedID: MI3, Name: Test MS 01, Notes: , Projects: {_rallyAPIMajor: 2, _rallyAPIMinor: 0, _ref: https://rally1.rallydev.com/slm/webservice/v2.0/Milestone/113445510236/Projects, _type: Project, Count: 1}, Recycled: false, RevisionHistory: {_rallyAPIMajor: 2, _rallyAPIMinor: 0, _ref: https://rally1.rallydev.com/slm/webservice/v2.0/revisionhistory/113445510240, _refObjectUUID: 1e3c5fcd-1354-433f-89cf-41e50d9fb214, _type: RevisionHistory}, TargetDate: 2017-04-29T08:00:00.000Z, TargetProject: {_rallyAPIMajor: 2, _rallyAPIMinor: 0, _ref: https://rally1.rallydev.com/slm/webservice/v2.0/project/55308115013, _refObjectUUID: ff775706-4f27-425a-a66e-d07d905ecc86, _refObjectName: Gordon, _type: Project}, TotalArtifactCount: 1, TotalProjectCount: 1, _type: Milestone}}}
}

void main(List<String> args) {

  RallyDevProxy proxy = new RallyDevProxy(_user, _pass);
  BasicRallyService rallyService = new BasicRallyService(proxy);

  rallyService.getDefect(r'DE6071').then((RDDefect defect) {
    rallyService.createMilestone(r'Test MS 02', artifacts: [defect]).then((RDMilestone milestone) {
      print(milestone.formattedID);
      proxy.close();
    });
  });


}