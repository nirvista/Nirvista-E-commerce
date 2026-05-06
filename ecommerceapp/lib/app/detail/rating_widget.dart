import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/widget_utils.dart';
import '../../services/review_api.dart';
import '../../app/model/api_models.dart';
import '../../base/get/login_data_controller.dart';
import 'image_viewer.dart';

/// 5-star rating widget for products and deliveries
class StarRatingWidget extends StatefulWidget {
  final double initialRating;
  final Function(double)? onRatingChanged;
  final bool isReadOnly;
  final double starSize;
  final MainAxisAlignment alignment;
  final bool showLabel;

  const StarRatingWidget({
    Key? key,
    this.initialRating = 0.0,
    this.onRatingChanged,
    this.isReadOnly = false,
    this.starSize = 32.0,
    this.alignment = MainAxisAlignment.start,
    this.showLabel = true,
  }) : super(key: key);

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(covariant StarRatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: widget.alignment,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: widget.isReadOnly
                  ? null
                  : () {
                      setState(() {
                        _currentRating = (index + 1).toDouble();
                      });
                      if (widget.onRatingChanged != null) {
                        widget.onRatingChanged!(_currentRating);
                      }
                    },
              child: Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Icon(
                  index < _currentRating.toInt()
                      ? Icons.star
                      : (index < _currentRating && _currentRating % 1 != 0)
                          ? Icons.star_half
                          : Icons.star_outline,
                  color: ratedColor,
                  size: widget.starSize.w,
                ),
              ),
            );
          }),
        ),
        if (widget.showLabel) ...[
          SizedBox(height: 8.h),
          getCustomFont(
            _currentRating == 0.0 && !widget.isReadOnly
                ? "Please rate this product"
                : "${_currentRating.toStringAsFixed(1)}/5.0",
            13,
            (_currentRating == 0.0 && !widget.isReadOnly) ? Colors.red : Colors.green,
            1,
            fontWeight: FontWeight.w600,
          ),
        ],
      ],
    );
  }
}

/// Product review card with star rating
class ProductReviewCard extends StatelessWidget {
  final String reviewerName;
  final double rating;
  final String reviewText;
  final String reviewDate;
  final String? reviewHeadline;
  final String? reviewerAvatar;
  final List<String>? media;
  final bool isVerified;

  const ProductReviewCard({
    Key? key,
    required this.reviewerName,
    required this.rating,
    required this.reviewText,
    required this.reviewDate,
    this.reviewHeadline,
    this.reviewerAvatar,
    this.media,
    this.isVerified = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: getCardColor(context),
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (reviewerAvatar != null)
                CircleAvatar(
                  radius: 16.w,
                  backgroundImage: NetworkImage(reviewerAvatar!),
                )
              else
                CircleAvatar(
                  radius: 16.w,
                  backgroundColor: accentColor.withOpacity(0.1),
                  child: Icon(Icons.person, size: 16.w, color: accentColor),
                ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        getCustomFont(
                          reviewerName,
                          13,
                          getFontColor(context),
                          1,
                          fontWeight: FontWeight.w700,
                        ),
                        if (isVerified) ...[
                          SizedBox(width: 6.w),
                          Icon(Icons.verified, color: Colors.green, size: 14.w),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    getCustomFont(
                      reviewDate,
                      11,
                      getFontGreyColor(context),
                      1,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating.toInt() ? Icons.star : Icons.star_outline,
                    color: ratedColor,
                    size: 14.w,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          if (reviewHeadline != null && reviewHeadline!.isNotEmpty) ...[
            getCustomFont(reviewHeadline!, 14, getFontColor(context), 1, fontWeight: FontWeight.w700),
            SizedBox(height: 4.h),
          ],

          getMultilineCustomFont(reviewText, 12, getFontGreyColor(context), fontWeight: FontWeight.w400),

          if (media != null && media!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            SizedBox(
              height: 80.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: media!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: () {
                        Get.to(() => FullScreenImageViewer(
                          images: media!,
                          initialIndex: index,
                        ));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.w),
                        child: Image.network(
                          media![index],
                          width: 80.w,
                          height: 80.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80.w,
                            height: 80.h,
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Delivery rating dialog
class DeliveryRatingDialog extends StatefulWidget {
  final String orderId;
  final Function(double) onRatingSubmitted;

  const DeliveryRatingDialog({
    Key? key,
    required this.orderId,
    required this.onRatingSubmitted,
  }) : super(key: key);

  @override
  State<DeliveryRatingDialog> createState() => _DeliveryRatingDialogState();
}

class _DeliveryRatingDialogState extends State<DeliveryRatingDialog> {
  double _deliveryRating = 0.0;
  TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.w)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(16.w),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: getCustomFont("Rate Your Delivery", 18, getFontColor(context), 1, fontWeight: FontWeight.w800)),
              SizedBox(height: 20.h),
              Center(child: getCustomFont("How would you rate the delivery service?", 14, getFontGreyColor(context), 2, fontWeight: FontWeight.w500, textAlign: TextAlign.center)),
              SizedBox(height: 24.h),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() { _deliveryRating = (index + 1).toDouble(); });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Icon(index < _deliveryRating ? Icons.star : Icons.star_outline, color: ratedColor, size: 40.w),
                      ),
                    );
                  }),
                ),
              ),

              if (_deliveryRating > 0)
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 12.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20.w)),
                    child: getCustomFont("${_deliveryRating.toInt()} Stars", 12, Colors.green, 1, fontWeight: FontWeight.w700),
                  ),
                ),

              SizedBox(height: 24.h),
              getCustomFont("Delivery Feedback (Optional)", 14, getFontColor(context), 1, fontWeight: FontWeight.w600),
              SizedBox(height: 10.h),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                style: TextStyle(color: getFontColor(context), fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "Tell us about your delivery experience...",
                  hintStyle: TextStyle(color: getFontGreyColor(context), fontSize: 13.sp),
                  filled: true, fillColor: getGreyCardColor(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.w), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.all(16.w),
                ),
              ),
              SizedBox(height: 24.h),

              Row(
                children: [
                  Expanded(child: getButtonFigma(context, getCardColor(context), true, "Cancel", getFontColor(context), () { Navigator.pop(context); }, EdgeInsets.zero, isBorder: true, borderColor: dividerColor)),
                  SizedBox(width: 12.w),
                  Expanded(child: getButtonFigma(context, accentColor, true, "Submit", Colors.white, () {
                    if (_deliveryRating > 0) {
                      widget.onRatingSubmitted(_deliveryRating);
                      Navigator.pop(context);
                    }
                  }, EdgeInsets.zero)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Product rating dialog
class ProductRatingDialog extends StatefulWidget {
  final String productId;
  final String userId;
  final Function(ReviewModel) onReviewSubmitted;

  const ProductRatingDialog({
    Key? key,
    required this.productId,
    required this.userId,
    required this.onReviewSubmitted,
  }) : super(key: key);

  @override
  State<ProductRatingDialog> createState() => _ProductRatingDialogState();
}

class _ProductRatingDialogState extends State<ProductRatingDialog> {
  double _rating = 0.0;
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final List<String> _media = [];
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _headlineController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a rating")));
      return;
    }
    if (_headlineController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add a headline")));
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add your review comment")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final loginController = Get.find<LoginDataController>();
      final res = await ReviewApiService.createReview(
        accessToken: loginController.accessToken ?? '',
        productId: widget.productId,
        userId: widget.userId,
        headline: _headlineController.text.trim(),
        comment: _commentController.text.trim(),
        rating: _rating.toInt(),
        media: _media,
      );

      // ✅ FIXED: Safely extracting JSON mapping without assuming nested 'data' wrappers.
      if (res['success'] == true && res['data'] != null) {
        final payload = res['data'];
        final reviewJson = payload is Map<String, dynamic> 
            ? (payload['data'] != null ? payload['data'] : payload) 
            : null;
            
        if (reviewJson != null) {
          final review = ReviewModel.fromJson(reviewJson);
          widget.onReviewSubmitted(review);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted successfully!"), backgroundColor: Colors.green));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Error submitting review")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.w)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(16.w),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: getCustomFont("Rate Product", 18, getFontColor(context), 1, fontWeight: FontWeight.w800)),
              SizedBox(height: 20.h),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() { _rating = (index + 1).toDouble(); });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Icon(index < _rating ? Icons.star : Icons.star_outline, color: ratedColor, size: 36.w),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 24.h),

              getCustomFont("Headline", 14, getFontColor(context), 1, fontWeight: FontWeight.w600),
              SizedBox(height: 8.h),
              TextField(
                controller: _headlineController,
                style: TextStyle(color: getFontColor(context), fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "Summarize your review in a few words",
                  hintStyle: TextStyle(color: getFontGreyColor(context), fontSize: 13.sp),
                  filled: true, fillColor: getGreyCardColor(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.w), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.all(12.w),
                ),
              ),
              SizedBox(height: 16.h),

              getCustomFont("Comment", 14, getFontColor(context), 1, fontWeight: FontWeight.w600),
              SizedBox(height: 8.h),
              TextField(
                controller: _commentController,
                maxLines: 4,
                style: TextStyle(color: getFontColor(context), fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "What did you like or dislike about this product?",
                  hintStyle: TextStyle(color: getFontGreyColor(context), fontSize: 13.sp),
                  filled: true, fillColor: getGreyCardColor(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.w), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.all(16.w),
                ),
              ),

              SizedBox(height: 20.h),
              getCustomFont("Add Images", 14, getFontColor(context), 1, fontWeight: FontWeight.w600),
              SizedBox(height: 10.h),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _media.add('data:image/jpeg;base64,${base64Encode(bytes)}');
                        });
                      }
                    },
                    child: Container(
                      width: 60.w, height: 60.w,
                      decoration: BoxDecoration(color: getGreyCardColor(context), borderRadius: BorderRadius.circular(12.w), border: Border.all(color: dividerColor)),
                      child: Icon(Icons.add_a_photo, color: accentColor, size: 24.w),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 60.w,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _media.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12.w),
                                  child: Image.memory(
                                    base64Decode(_media[index].split(',').last),
                                    width: 60.w, height: 60.w, fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0, right: 8.w,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() { _media.removeAt(index); });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(2.w),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Icon(Icons.close, color: Colors.white, size: 12.w),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(child: getButtonFigma(context, getCardColor(context), true, "Cancel", getFontColor(context), () { Navigator.pop(context); }, EdgeInsets.zero, isBorder: true, borderColor: dividerColor)),
                        SizedBox(width: 12.w),
                        Expanded(child: getButtonFigma(context, accentColor, true, "Submit", Colors.white, () { _submitReview(); }, EdgeInsets.zero)),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}