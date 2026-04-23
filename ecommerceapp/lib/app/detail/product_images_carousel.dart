import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/app/detail/image_viewer.dart';

/// Product images carousel with swipe, tap-to-expand, and favorites
class ProductImagesCarousel extends StatefulWidget {
  final List<String> images;
  final double containerHeight;
  final VoidCallback? onHeartTap;
  final bool isWishlisted;

  const ProductImagesCarousel({
    Key? key,
    required this.images,
    this.containerHeight = 300,
    this.onHeartTap,
    this.isWishlisted = false,
  }) : super(key: key);

  @override
  State<ProductImagesCarousel> createState() => _ProductImagesCarouselState();
}

class _ProductImagesCarouselState extends State<ProductImagesCarousel> {
  late int _currentImageIndex;
  late CarouselSliderController _carouselController;

  @override
  void initState() {
    super.initState();
    _currentImageIndex = 0;
    _carouselController = CarouselSliderController();
  }

  @override
  Widget build(BuildContext context) {
    final displayImages =
        widget.images.isNotEmpty ? widget.images : ["https://placehold.co/400"];

    return Stack(
      children: [
        // Main carousel
        Container(
          width: double.infinity,
          height: widget.containerHeight.h,
          color: getGreyCardColor(context),
          child: GestureDetector(
            onTap: () {
              // Open full-screen image viewer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImageViewer(
                    images: displayImages,
                    initialIndex: _currentImageIndex,
                  ),
                ),
              );
            },
            child: CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: displayImages.length,
              itemBuilder: (context, index, realIndex) {
                return _buildCarouselImage(displayImages[index]);
              },
              options: CarouselOptions(
                height: widget.containerHeight.h,
                viewportFraction: 1.0,
                scrollPhysics: const BouncingScrollPhysics(),
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
            ),
          ),
        ),

        // Heart button - top right
        Positioned(
          top: 12.h,
          right: 12.w,
          child: GestureDetector(
            onTap: widget.onHeartTap,
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8.w,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    widget.isWishlisted
                        ? Icons.favorite
                        : Icons.favorite_border,
                    key: ValueKey(widget.isWishlisted),
                    color: widget.isWishlisted
                        ? accentColor
                        : getFontGreyColor(context),
                    size: 24.w,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Image counter - top center
        if (displayImages.length > 1)
          Positioned(
            top: 12.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${displayImages.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

        // Image indicators at bottom
        if (displayImages.length > 1)
          Positioned(
            bottom: 12.h,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  displayImages.length,
                  (index) => GestureDetector(
                    onTap: () {
                      _carouselController.animateToPage(index);
                    },
                    child: Container(
                      width: _currentImageIndex == index ? 28.w : 8.w,
                      height: 8.w,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4.w),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Tap to expand hint (bottom left)
        if (displayImages.isNotEmpty)
          Positioned(
            bottom: 12.h,
            left: 12.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, color: Colors.white, size: 16.w),
                  SizedBox(width: 4.w),
                  Text(
                    'Tap to zoom',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCarouselImage(String imageUrl) {
    return ClipRRect(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
        errorWidget: (context, url, error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 50.w, color: Colors.grey),
              SizedBox(height: 8.h),
              Text(
                'Image not found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
