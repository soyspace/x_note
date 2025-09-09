import 'package:XNote/controller/notebook_controller.dart';
import 'package:XNote/controller/system_controller.dart';
import 'package:XNote/pages/left/left_index.dart';
import 'package:XNote/pages/right/right_index.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class HomeIndex extends StatefulWidget {
  const HomeIndex({super.key});

  @override
  State<HomeIndex> createState() => _HomeIndexState();
}

class _HomeIndexState extends State<HomeIndex> with WindowListener {
  bool isLeftExpanded = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemController.to.lockScreen();
    });

  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        onPointerDown: (event) {
          //debugPrint('onPointerDown${event.localPosition}');
          SystemController.to.refreshTime=0;
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 在使用LeftIndex的地方
            LeftIndex(
              isExpanded: isLeftExpanded,
              onToggle: () => setState(() => isLeftExpanded = !isLeftExpanded),
            ),
            Expanded(
              child: RightIndex(
                isExpanded: isLeftExpanded,
                onToggle: () => setState(() => isLeftExpanded = !isLeftExpanded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onWindowBlur() async {
    if(NotebookController.to.currentTreeNote!=null) {
      NotebookController.to.saveNote(NotebookController.to.currentTreeNote!.data);

    }
  }

  @override
  void onWindowEvent(String eventName) {
    //debugPrint('[WindowManager] onWindowEvent: $eventName');
    SystemController.to.refreshTime=0;
  }
}
