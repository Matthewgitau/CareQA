import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/services/daily_note_service.dart';

class DailyNoteForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;
  final String carerId;
  const DailyNoteForm({super.key, required this.serviceUserId, required this.serviceUserName, required this.carerId});
  @override
  State<DailyNoteForm> createState() => _DailyNoteFormState();
}

class _DailyNoteFormState extends State<DailyNoteForm> {
  final _service = DailyNoteService(Supabase.instance.client);
  final _noteFormCtxCtrl = TextEditingController();
  bool _saving = false;
  String _care = 'accepted';
  String _mood = 'calm';
  bool _pad = false;
  bool _med = false;
  bool _incident = false;
  String _skin = 'normal';
  String _skinDetail = '';
  static const _moods = ['calm','happy','anxious','agitated','sad','confused','in_pain','tired'];
  static const _skins = ['normal','bruising','redness','swelling','rash','wound'];
  @override void dispose() { _noteFormCtxCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(()=>_saving=true);
    try {
      final n=DateTime.now();
      final t='${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}';
      await _service.createNote({
        'service_user_id':widget.serviceUserId,'service_user_name':widget.serviceUserName,
        'carer_id':widget.carerId,'visit_date':n.toIso8601String().split('T').first,
        'visit_time':t,'visit_type':'visit','care_accepted':_care,
        'emotional_state':[_mood],'pad_changed':_pad,'medication_taken':_med,
        'incident_occurred':_incident,
        'incident_description':_incident?_noteFormCtxCtrl.text.trim():null,
        'skin_condition':_skin,'skin_notes':_skinDetail.isNotEmpty?_skinDetail:null,
        'manual_notes':_noteFormCtxCtrl.text.trim().isNotEmpty?_noteFormCtxCtrl.text.trim():null,
        'status':'completed','created_at':n.toIso8601String(),'updated_at':n.toIso8601String()
      });
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Daily note saved'),backgroundColor:Colors.green,behavior:SnackBarBehavior.floating));Navigator.pop(context);}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Failed: $e'),backgroundColor:Colors.red));}
    finally{if(mounted)setState(()=>_saving=false);}
  }

  @override
  Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text('Daily Note - ${widget.serviceUserName}')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Text('Care',style:TextStyle(fontWeight:FontWeight.bold)),SizedBox(height:4),
      Row(children:['accepted','refused','partial'].map((v)=>Padding(padding:EdgeInsets.only(right:6),child:ChoiceChip(label:Text(v),selected:_care==v,onSelected:(_)=>setState(()=>_care=v)))).toList()),SizedBox(height:12),
      Text('Mood',style:TextStyle(fontWeight:FontWeight.bold)),SizedBox(height:4),
      Wrap(spacing:6,children:_moods.map((m)=>ActionChip(label:Text(m),backgroundColor:_mood==m?Colors.indigo.shade100:null,onPressed:()=>setState(()=>_mood=m))).toList()),SizedBox(height:12),
      SwitchListTile(contentPadding:EdgeInsets.zero,dense:true,title:Text('Pad changed'),value:_pad,onChanged:(v)=>setState(()=>_pad=v)),
      SwitchListTile(contentPadding:EdgeInsets.zero,dense:true,title:Text('Medication taken'),value:_med,onChanged:(v)=>setState(()=>_med=v)),
      SwitchListTile(contentPadding:EdgeInsets.zero,dense:true,title:Text('Incident occurred'),value:_incident,onChanged:(v)=>setState(()=>_incident=v)),SizedBox(height:12),
      Text('Skin',style:TextStyle(fontWeight:FontWeight.bold)),SizedBox(height:4),
      Wrap(spacing:6,children:_skins.map((s)=>ActionChip(label:Text(s),backgroundColor:_skin==s?Colors.indigo.shade100:null,onPressed:()=>setState(()=>_skin=s))).toList()),
      if(_skin=='bruising')...[SizedBox(height:8),TextFormField(decoration:InputDecoration(labelText:'Bruising details',border:OutlineInputBorder()),maxLines:2,onChanged:(v)=>_skinDetail=v),SizedBox(height:4),Text('Use Body Map to mark location',style:TextStyle(fontSize:12,color:Colors.grey.shade600))],
      SizedBox(height:12),
      TextFormField(controller:_noteFormCtxCtrl,decoration:InputDecoration(labelText:'Additional notes',border:OutlineInputBorder()),maxLines:3),SizedBox(height:20),
      ElevatedButton.icon(onPressed:_saving?null:_save,icon:_saving?SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):Icon(Icons.save),label:Text(_saving?'Saving...':'Save Daily Note'),style:ElevatedButton.styleFrom(backgroundColor:Colors.indigo,foregroundColor:Colors.white,minimumSize:Size(double.infinity,48))),
      SizedBox(height:32)
    ]));
}
