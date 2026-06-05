// lib/widgets/custom_image_widget.dart
//
// Fixes applied:
// 1. Removed `../core/app_export.dart` — replaced with direct imports
// 2. Added explicit `cached_network_image` import
// 3. Added explicit `flutter_svg` import
// 4. Removed dart:io import (only needed for File — kept as is since it's used)

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (startsWith('http') || startsWith('https')) {
      return ImageType.network;
    } else if (endsWith('.svg')) {
      return ImageType.svg;
    } else if (startsWith('file://')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, file, unknown }

class CustomImageWidget extends StatelessWidget {
  const CustomImageWidget({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder = 'assets/images/no-image.jpg',
    this.errorWidget,
    this.semanticLabel,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final String placeHolder;
  final Color? color;
  final Alignment? alignment;
  final VoidCallback? onTap;
  final BorderRadius? radius;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final Widget? errorWidget;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(alignment: alignment!, child: _buildWidget())
        : _buildWidget();
  }

  Widget _buildWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(onTap: onTap, child: _buildCircleImage()),
    );
  }

  Widget _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(
        borderRadius: radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(),
      );
    }
    return _buildImageWithBorder();
  }

  Widget _buildImageWithBorder() {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(
          border: border,
          borderRadius: radius,
        ),
        child: _buildImageView(),
      );
    }
    return _buildImageView();
  }

  Widget _buildImageView() {
    if (imageUrl == null) return const SizedBox.shrink();

    switch (imageUrl!.imageType) {
      case ImageType.svg:
        return SizedBox(
          height: height,
          width: width,
          child: SvgPicture.asset(
            imageUrl!,
            height: height,
            width: width,
            fit: fit ?? BoxFit.contain,
            colorFilter: color != null
                ? ColorFilter.mode(color!, BlendMode.srcIn)
                : null,
            semanticsLabel: semanticLabel,
          ),
        );

      case ImageType.file:
        return Image.file(
          File(imageUrl!),
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          color: color,
          semanticLabel: semanticLabel,
        );

      case ImageType.network:
        return CachedNetworkImage(
          imageUrl: imageUrl!,
          height: height,
          width: width,
          fit: fit,
          color: color,
          placeholder: (context, url) => SizedBox(
            height: height ?? 30,
            width: width ?? 30,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFF2A2A2A),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) =>
          errorWidget ??
              Image.asset(
                placeHolder,
                height: height,
                width: width,
                fit: fit ?? BoxFit.cover,
                semanticLabel: semanticLabel,
              ),
        );

      case ImageType.png:
      default:
        return Image.asset(
          imageUrl!,
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          color: color,
          semanticLabel: semanticLabel,
        );
    }
  }
}