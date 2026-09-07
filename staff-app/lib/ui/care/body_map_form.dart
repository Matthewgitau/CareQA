import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/services/body_map_service.dart';

class BodyMapForm extends StatefulWidget {
  final String serviceUserId;
  final String carerId;
  const BodyMapForm({super.key, required this.serviceUserId, required this.carerId});
  @override
  State<BodyMapForm> createState() => _BodyMapFormState();
}

class _BodyMapFormState extends State<BodyMapForm> {
  final _service = BodyMapService(Supabase.instance.client);
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  bool _noNewMarks = true;
  final List<_Mark> _marks = [];

  static const _bodyZones = ['Head','Neck','Left shoulder','Right shoulder','Chest','Abdomen','Back','Left arm','Right arm','Left hand','Right hand','Left hip','Right hip','Left leg','Right leg','Left foot','Right foot'];

  void _addMark() => setState(() => _marks.add(_Mark()));
  void _removeMark(int i) => setState(() => _marks.removeAt(i));

  Future<void> _save() async {
    setState(()=>_saving=true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      final orgId = await _getOrgId();
      await _service.createAssessment(
        serviceUserId: widget.serviceUserId,
        assessedById: uid ?? widget.carerId,
        organisationId: orgId,
        noNewMarks: _noNewMarks,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        marks: _marks.where((m)=>m.zone.isNotEmpty).map((m)=>{'body_part':m.zone,'description':m.description,'size':m.size}).toList(),
      );
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Body map saved'),backgroundColor:Colors.green,behavior:SnackBarBehavior.floating));Navigator.pop(context);}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Failed: $e'),backgroundColor:Colors.red));}
    finally{if(mounted)setState(()=>_saving=false);}
  }

  Future<String?> _getOrgId() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if(uid==null)return null;
      final r = await Supabase.instance.client.from('profiles').select('organisation_id').eq('id',uid).maybeSingle();
      return r?['organisation_id'] as String?;
    }catch(_){return null;}
  }

  @override void dispose() { _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text('Body Map')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(color:Colors.amber.shade50,child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[Icon(Icons.info_outline,color:Colors.amber.shade800),SizedBox(width:8),Expanded(child:Text('Document any new marks, bruises, or skin changes found during care.',style:TextStyle(fontSize:13,color:Colors.amber.shade900)))]))),
      SizedBox(height:12),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('No new marks found',style:TextStyle(fontWeight:FontWeight.bold)),value:_noNewMarks,onChanged:(v)=>setState((){_noNewMarks=v;if(v)_marks.clear();})),
      if(!_noNewMarks)...[
        SizedBox(height:8),
        ...List.generate(_marks.length, (i)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Expanded(child:DropdownButtonFormField<String>(value:_marks[i].zone.isNotEmpty?_marks[i].zone:null,decoration:InputDecoration(labelText:'Body zone',border:OutlineInputBorder(),contentPadding:EdgeInsets.symmetric(horizontal: 10, vertical: 8)),items:_bodyZones.map((z)=>DropdownMenuItem(value:z,child:Text(z))).toList(),onChanged:(v)=>setState(()=>_marks[i].zone=v??''))),SizedBox(width:8),IconButton(icon:Icon(Icons.delete,color:Colors.red.shade300),onPressed:()=>_removeMark(i))]),
          SizedBox(height:6),TextFormField(decoration:InputDecoration(labelText:'Description',border:OutlineInputBorder(),contentPadding:EdgeInsets.symmetric(horizontal:10,vertical:8)),onChanged:(v)=>_marks[i].description=v),
          SizedBox(height:6),TextFormField(decoration:InputDecoration(labelText:'Size (e.g. 2cm x 3cm)',border:OutlineInputBorder(),contentPadding:EdgeInsets.symmetric(horizontal:10,vertical:8)),onChanged:(v)=>_marks[i].size=v),
        ])),)),
        SizedBox(height:8),
        OutlinedButton.icon(onPressed:_addMark,icon:Icon(Icons.add),label:Text('Add mark'),style:OutlinedButton.styleFrom(minimumSize:Size(double.infinity,44))),
      ],
      SizedBox(height:12),
      TextFormField(controller:_notesCtrl,decoration:InputDecoration(labelText:'Additional notes',border:OutlineInputBorder()),maxLines:3),SizedBox(height:20),
      ElevatedButton.icon(onPressed:_saving?null:_save,icon:_saving?SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):Icon(Icons.save),label:Text(_saving?'Saving...':'Save Body Map'),style:ElevatedButton.styleFrom(backgroundColor:Colors.red,foregroundColor:Colors.white,minimumSize:Size(double.infinity,48))),
      SizedBox(height:32)
    ]));
}

class _Mark { String zone='',description='',size=''; }
