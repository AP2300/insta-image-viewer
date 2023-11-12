library insta_image_viewer;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _kRouteDuration = Duration(milliseconds: 300);

class InstaImageViewer extends StatelessWidget {
  const InstaImageViewer({
    Key? key,
    required this.child,
    required this.item,
    this.backgroundColor = Colors.black,
    this.backgroundIsTransparent = true,
    this.disposeLevel,
    required this.userPicture,
  }) : super(key: key);

  /// Image widget
  /// For example Image(image:Image.network("https://picsum.photos/id/507/1000").image,)
  final Widget child;

  /// Background in the full screen mode, Colors.black by default
  final Color backgroundColor;

  /// Make background transparent
  final bool backgroundIsTransparent;

  /// After what level of drag from top image should be dismissed
  /// high - 300px, middle - 200px, low - 100px
  final DisposeLevel? disposeLevel;

  /// if true the swipe down\up will be disabled
  /// - it gives more predictable behaviour

  final dynamic item;

  final String userPicture;

  @override
  Widget build(BuildContext context) {
    final UniqueKey tag = UniqueKey();
    return Hero(
      tag: tag,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              PageRouteBuilder(
                  opaque: false,
                  barrierColor: backgroundIsTransparent
                      ? Colors.white.withOpacity(0)
                      : backgroundColor,
                  pageBuilder: (BuildContext context, _, __) {
                    return FullScreenViewer(
                      tag: tag,
                      child: child,
                      backgroundColor: backgroundColor,
                      backgroundIsTransparent: backgroundIsTransparent,
                      disposeLevel: disposeLevel,
                      item: item,
                      userPicture: userPicture,
                    );
                  }));
        },
        child: child,
      ),
    );
  }
}

enum DisposeLevel { high, medium, low }

class FullScreenViewer extends StatefulWidget {
  const FullScreenViewer({
    Key? key,
    required this.child,
    required this.tag,
    required this.item,
    this.backgroundColor = Colors.black,
    this.backgroundIsTransparent = true,
    this.disposeLevel = DisposeLevel.medium,
    required this.userPicture,
  }) : super(key: key);

  final Widget child;
  final Color backgroundColor;
  final bool backgroundIsTransparent;
  final DisposeLevel? disposeLevel;
  final UniqueKey tag;
  final dynamic item;
  final String userPicture;

  @override
  _FullScreenViewerState createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer> {
  double? _initialPositionY = 0;

  double? _currentPositionY = 0;

  double _positionYDelta = 0;

  double _opacity = 1;

  double _disposeLimit = 150;

  Duration _animationDuration = Duration.zero;

  bool showOverlay = true;

  @override
  void initState() {
    super.initState();
    setDisposeLevel();
  }

  setDisposeLevel() {
    if (widget.disposeLevel == DisposeLevel.high) {
      _disposeLimit = 300;
    } else if (widget.disposeLevel == DisposeLevel.medium) {
      _disposeLimit = 200;
    } else {
      _disposeLimit = 100;
    }
  }

  void _dragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPositionY = details.globalPosition.dy;
      _positionYDelta = _currentPositionY! - _initialPositionY!;
      setOpacity();
    });
  }

  void _dragStart(DragStartDetails details) {
    setState(() {
      _initialPositionY = details.globalPosition.dy;
    });
  }

  _dragEnd(DragEndDetails details) {
    if (_positionYDelta > _disposeLimit || _positionYDelta < -_disposeLimit) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _animationDuration = _kRouteDuration;
        _opacity = 1;
        _positionYDelta = 0;
      });

      Future.delayed(_animationDuration).then((_) {
        setState(() {
          _animationDuration = Duration.zero;
        });
      });
    }
  }

  void _onTap() {
    setState(() {
      showOverlay = !showOverlay;
    });
  }

  setOpacity() {
    final double tmp = _positionYDelta < 0
        ? 1 - ((_positionYDelta / 1000) * -1)
        : 1 - (_positionYDelta / 1000);

    if (tmp > 1) {
      _opacity = 1;
    } else if (tmp < 0) {
      _opacity = 0;
    } else {
      _opacity = tmp;
    }

    if (_positionYDelta > _disposeLimit || _positionYDelta < -_disposeLimit) {
      _opacity = 1;
    }
    if (kDebugMode) {
      print(_opacity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPosition = 0 + max(_positionYDelta, -_positionYDelta) / 15;
    return Hero(
      tag: widget.tag,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: Colors.black.withOpacity(0),
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                AnimatedPositioned(
                  duration: _animationDuration,
                  curve: Curves.fastOutSlowIn,
                  top: 0 + _positionYDelta,
                  bottom: 0 - _positionYDelta,
                  left: horizontalPosition,
                  right: horizontalPosition,
                  child: KeymotionGestureDetector(
                    onStart: (details) => _dragStart(details),
                    onUpdate: (details) => _dragUpdate(details),
                    onEnd: (details) => _dragEnd(details),
                    onTap: () => _onTap(),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(40),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: widget.child,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: showOverlay ? 1.0 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 24,
                          shape: CircleBorder(),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.close_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: showOverlay ? 1.0 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(widget.userPicture),
                            ),
                            title: Text(
                              widget.item.trackName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                                "${widget.item.trackAlbum} • ${widget.item.trackArtist}"),
                            trailing: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.share_rounded),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              "${DateFormat.yMMMEd().format(widget.item.dateCreated)} • ${DateFormat.jm().format(widget.item.dateCreated)}",
                            ),
                            subtitle: Text(
                              getFileSizeString(bytes: widget.item.size),
                            ),
                            trailing: IconButton(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
                              onPressed: () {},
                              icon: Icon(Icons.delete_forever_rounded,
                                  color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String getFileSizeString({required int bytes, int decimals = 0}) {
  const suffixes = ["b", "kb", "mb", "gb", "tb"];
  if (bytes == 0) return '0${suffixes[0]}';
  var i = (log(bytes) / log(1024)).floor();
  return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + suffixes[i];
}

class KeymotionGestureDetector extends StatelessWidget {
  /// @macro
  const KeymotionGestureDetector({
    Key? key,
    required this.child,
    this.onUpdate,
    this.onEnd,
    this.onStart,
    this.onTap,
  }) : super(key: key);

  final Widget child;
  final GestureDragUpdateCallback? onUpdate;
  final GestureDragEndCallback? onEnd;
  final GestureDragStartCallback? onStart;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(child: child, gestures: <Type,
        GestureRecognizerFactory>{
      VerticalDragGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer()
          ..onStart = onStart
          ..onUpdate = onUpdate
          ..onEnd = onEnd,
        (instance) {},
      ),
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer()..onTap = onTap,
        (instance) {},
      )
      // DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
      //   () => DoubleTapGestureRecognizer()..onDoubleTap = onDoubleTap,
      //   (instance) {},
      // )
    });
  }
}
