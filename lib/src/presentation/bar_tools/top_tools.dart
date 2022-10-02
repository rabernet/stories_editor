import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stories_editor/src/domain/models/editable_items.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/painting_notifier.dart';
import 'package:stories_editor/src/domain/sevices/save_as_image.dart';
import 'package:stories_editor/src/presentation/utils/constants/item_type.dart';
import 'package:stories_editor/src/presentation/utils/constants/text_animation_type.dart';
import 'package:stories_editor/src/presentation/utils/modal_sheets.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';
import 'package:stories_editor/src/presentation/widgets/tool_button.dart';

class TopTools extends StatefulWidget {
  final GlobalKey contentKey;
  final BuildContext context;
  final Function renderWidget;
  const TopTools(
      {Key? key,
      required this.contentKey,
      required this.context,
      required this.renderWidget})
      : super(key: key);

  @override
  _TopToolsState createState() => _TopToolsState();
}

class _TopToolsState extends State<TopTools> {
  bool _createVideo = false;

  @override
  Widget build(BuildContext context) {
    return Consumer3<ControlNotifier, PaintingNotifier,
        DraggableWidgetNotifier>(
      builder: (_, controlNotifier, paintingNotifier, itemNotifier, __) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// close button
                ToolButton(
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () async {
                      var res = await exitDialog(
                          context: widget.context,
                          contentKey: widget.contentKey);
                      if (res) {
                        Navigator.pop(context);
                      }
                    }),
                if (controlNotifier.mediaPath.isEmpty)
                  _selectColor(
                      controlProvider: controlNotifier,
                      onTap: () {
                        if (controlNotifier.gradientIndex >=
                            controlNotifier.gradientColors!.length - 1) {
                          setState(() {
                            controlNotifier.gradientIndex = 0;
                          });
                        } else {
                          setState(() {
                            controlNotifier.gradientIndex += 1;
                          });
                        }
                      }),
                ToolButton(
                    child: const ImageIcon(
                      AssetImage('assets/icons/download.png',
                          package: 'stories_editor'),
                      color: Colors.white,
                      size: 20,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () async {
                      if (paintingNotifier.lines.isNotEmpty ||
                          itemNotifier.draggableWidget.isNotEmpty) {
                        for (var element in itemNotifier.draggableWidget) {
                          if (element.type == ItemType.gif ||
                              element.animationType != TextAnimationType.none) {
                            setState(() {
                              _createVideo = true;
                            });
                          }
                        }
                        if (_createVideo) {
                          debugPrint('creating video');
                          await widget.renderWidget();
                        } else {
                          debugPrint('creating image');
                          var response = await takePicture(
                              contentKey: widget.contentKey,
                              context: context,
                              saveToGallery: true);
                          if (response) {
                            Fluttertoast.showToast(msg: 'Successfully saved');
                          } else {
                            Fluttertoast.showToast(msg: 'Error');
                          }
                        }
                      }
                      setState(() {
                        _createVideo = false;
                      });
                    }),
                ToolButton(
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () async {
                      //POR RAFAEL 2 DE AGOSTO
                      var pathImagen = await _captureImage(ImageSource.camera);

                      // print('PATH IMAGE:: $pathImagen');

                      if (pathImagen != null && pathImagen.isNotEmpty) {
                        //RAFAEL 2 OCT
                        // controlNotifier.mediaPath = pathImagen.toString();
                        controlNotifier.mediaPath = pathImagen;
                        controlNotifier.notifyListeners();

                        if (controlNotifier.mediaPath.isNotEmpty) {
                          itemNotifier.draggableWidget.insert(
                              0,
                              EditableItem()
                                ..type = ItemType.image
                                ..position = const Offset(0.0, 0));
                        }
                      }
                    }),
                // ToolButton(
                //     child: const ImageIcon(
                //       AssetImage('assets/icons/stickers.png',
                //           package: 'stories_editor'),
                //       color: Colors.white,
                //       size: 20,
                //     ),
                //     backGroundColor: Colors.black12,
                //     onTap: () => createGiphyItem(
                //         context: context, giphyKey: controlNotifier.giphyKey)),
                ToolButton(
                    child: const ImageIcon(
                      AssetImage('assets/icons/draw.png',
                          package: 'stories_editor'),
                      color: Colors.white,
                      size: 20,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () {
                      controlNotifier.isPainting = true;
                      //createLinePainting(context: context);
                    }),
                // ToolButton(
                //   child: ImageIcon(
                //     const AssetImage('assets/icons/photo_filter.png',
                //         package: 'stories_editor'),
                //     color: controlNotifier.isPhotoFilter ? Colors.black : Colors.white,
                //     size: 20,
                //   ),
                //   backGroundColor:  controlNotifier.isPhotoFilter ? Colors.white70 : Colors.black12,
                //   onTap: () => controlNotifier.isPhotoFilter =
                //   !controlNotifier.isPhotoFilter,
                // ),
                ToolButton(
                  child: const ImageIcon(
                    AssetImage('assets/icons/text.png',
                        package: 'stories_editor'),
                    color: Colors.white,
                    size: 20,
                  ),
                  backGroundColor: Colors.black12,
                  onTap: () => controlNotifier.isTextEditing =
                      !controlNotifier.isTextEditing,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //CAPTURAR DE LA CAMARA
  _captureImage(ImageSource src) async {
    final pickedFile = await ImagePicker().pickImage(
      source: src,
      maxHeight: 680,
      maxWidth: 970,
    );
    if (pickedFile != null) {
      return pickedFile.path;

      // Navigator.of(context).push(
      //   MaterialPageRoute(
      //     builder: (context) => UploadImagePage(
      //       imageFile: File(pickedFile.path),
      //       imagePath: pickedFile.path,
      //     ),
      //   ),
      // );
    }
  }

  /// gradient color selector
  Widget _selectColor({onTap, controlProvider}) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, top: 8),
      child: AnimatedOnTapButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: controlProvider
                      .gradientColors![controlProvider.gradientIndex]),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
