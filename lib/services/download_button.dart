import 'package:flutter/material.dart';
import 'package:fuzik_mobile/main_layout.dart';
import 'package:fuzik_mobile/services/video_downloader.dart';
import 'package:fuzik_mobile/services/fetch_videos.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class DownloadButton extends StatefulWidget{
  final String videoUrl; //This videoUrl represents the code e.g 8A5xi09j50
  final String videoLink;
  const DownloadButton({super.key, required this.videoUrl, required this.videoLink});

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _downloading = false;
  final downloadPrice=150; //FZ coin
  final ValueNotifier<double?> _progress = ValueNotifier<double?>(0);
  final downloader = VideoDownloader();
  String baseUrl = "https://engine01.fuzikapp.com";
  Future<void> downloadVideo(String videoLink, String videoCode) async{
    DownloadResult result;
    if(_downloading) return;
    if(!await hasNetwork()){
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("You are offline!", style: TextStyle(color: Colors.white))
        )
      );
      return;
    }
    setState(() {
      _downloading = true;
    });
    _progress.value = 0;
    try{
      result = await downloader.downloadToGallery(
                   url: videoLink,                     // the media URL, not the jam2_watch API URL
                   fileName: 'fuzik_${widget.videoUrl}', //This videoUrl represents the code e.g 8A5xi09j50
                   onProgress: (p) {
                    if (mounted) _progress.value = p;   // null means the size is unknown
                  },
                );
        }finally{
          if (mounted) setState(() => _downloading = false);
        }
      if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: result.isSuccess ? Colors.green : Colors.red,
            content: Text(result.isSuccess ? 'Saved to your gallery' : result.message ?? 'Cancelled', style: TextStyle(color: Colors.white)),
          ));
  }

  Future<bool> showCoinUsageConfirmationForVideoDownload()async{
    if(!mounted) return false;
    final result= await showDialog<bool>(
      context:context,
      barrierDismissible:false,
      builder:(BuildContext context){
        return AlertDialog(
          title:Text("Confirm Download"),
          content:Text("Downloading this video will cost 10 FZ coins. Do you want to proceed?"),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      }
    );
    return result ?? false;
  }

  Future<bool> showMiniCoinShopDialog () async{
    if(!mounted) return false;
    final result= await showDialog<bool>(
      context:context,
      barrierDismissible:false,
      builder:(BuildContext context){
        return AlertDialog(
          title:Text("Insufficient Coins"),
          content:Text("You don't have enough FZ coins to download this video. Would you like to visit the coin shop?"),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Go to Coin Shop'),
            ),
          ],
        );
      }
    );
    return result ?? false;
  }
  
  String? get currentEmail => Supabase.instance.client.auth.currentUser?.email;

  Future<int> getBalance() async{
    if(currentEmail==null || currentEmail!.isEmpty){
      return 0;
    }
    final uri = Uri.parse("$baseUrl/check_balance?email_account=${currentEmail!}&realm_id=REALM00000001");
    try{
      final result= await http.get(uri);
      if(result.statusCode!=200){
        return 0;
      }
      final data=jsonDecode(result.body);    
      final String balance= data["balance"];
      return int.parse(balance);
    } catch (e) {
      print("Error fetching balance: $e");
      return 0;
    }
  }
  @override
  void dispose() {
    _progress.dispose();
    downloader.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return _downloading?
            SizedBox(
              width: 120,
              height: 200,
              child: Column(
                children: [
                  ValueListenableBuilder<double?>(
                    valueListenable: _progress,
                    builder: (context, p, _) {
                      final saving=p!=null && p>=1.0;
                      return Column(
                      children: [
                        LinearProgressIndicator(value: saving ? null : p),  // null shows the "unknown length" animation
                        const SizedBox(height: 6),
                        Text(saving?"Saving to gallary":p == null ? 'Downloading...' : '${(p * 100).toStringAsFixed(0)}%'),
                      ],
                    );}
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                    onPressed:(){
                    downloader.cancel();
                    setState(() {
                      _downloading=false;
                    });
                  } , child: const Text('Cancel')),
                ],
              ),
            )
          :
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color:Colors.yellow,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.5),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: IconButton(
                color:Colors.black,
                icon: const Icon(Icons.download),
                onPressed: () async{
                  try{
                    //final isConfirmed = await showCoinUsageConfirmationForVideoDownload();
                    // final checkDownloadAccess= await http.get(Uri.parse("$baseUrl/jam_download_access?email=${Supabase.instance.client.auth.currentUser?.email}&jam_id=${widget.videoUrl}"),headers:{"X-Jam-Download-Key":""});
                    // if(checkDownloadAccess.statusCode!=200){
                    //   throw Exception("Failed to check download access");
                    // }
                    // final data=jsonDecode(checkDownloadAccess.body);
                    // final bool hasAccess=data[0]['active']=='true';
                    final bool hasAccessMock=false;
                    if(hasAccessMock){
                      downloadVideo(widget.videoLink, widget.videoUrl);
                      return;
                    }
                    final balance=await getBalance();
                    final bool hasEnoughCoins= balance>=downloadPrice;
                    if(hasEnoughCoins){
                      //coin deduction logic here();
                      //final postDownloadAccess= await http.post(Uri.parse("$baseUrl/jam_download_access?email=${Supabase.instance.client.auth.currentUser?.email}&jam_id=${widget.videoUrl}"),headers:{"X-Jam-Download-Key":""});
                      final isConfirmed = await showCoinUsageConfirmationForVideoDownload();
                        if(isConfirmed){
                        downloadVideo(widget.videoLink, widget.videoUrl);
                        }
                    }else{
                      final goToCoinShop= await showMiniCoinShopDialog();
                      if(goToCoinShop){
                        if(!context.mounted) return;
                        debugPrint("Navigate to coin shop");
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>MainLayout(goToWallet: true)));
                      }
                    }
                  }catch(error){
                    if(!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error checking download access: $error'),
                      ),
                    );
                  }
                },
              ),
            );
  }
}