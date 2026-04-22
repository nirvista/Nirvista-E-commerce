import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/widget_utils.dart';

/// 5-star rating widget for products and deliveries
class StarRatingWidget extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;
  final bool isReadOnly;
  final double starSize;
  final MainAxisAlignment alignment;
  final bool showLabel;

  const StarRatingWidget({
    Key? key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
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
                      widget.onRatingChanged(_currentRating);
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
            _currentRating == 0.0
                ? "Please rate this product"
                : "${_currentRating.toStringAsFixed(1)}/5.0",
            13,
            _currentRating == 0.0 ? Colors.red : Colors.green,
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
  final String? reviewerAvatar;
  final bool isVerified;

  const ProductReviewCard({
    Key? key,
    required this.reviewerName,
    required this.rating,
    required this.reviewText,
    required this.reviewDate,
    this.reviewerAvatar,
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
          // Header with reviewer info
          Row(
            children: [
              if (reviewerAvatar != null)
                CircleAvatar(
                  radius: 16.w,
                  backgroundImage: NetworkImage(reviewerAvatar!),
                ),
              if (reviewerAvatar != null) SizedBox(width: 8.w),
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
                          Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 14.w,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
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
            ],
          ),

          SizedBox(height: 10.h),

          // Stars
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < rating.toInt()
                    ? Icons.star
                    : (index < rating && rating % 1 != 0)
                        ? Icons.star_half
                        : Icons.star_outline,
                color: ratedColor,
                size: 16.w,
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // Review text
          getCustomFont(
            reviewText,
            12,
            getFontGreyColor(context),
             4,
            fontWeight: FontWeight.w400,
          ),
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
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              getCustomFont(
                "Rate Your Delivery",
                18,
                getFontColor(context),
                1,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: 16.h),

              // Rating info
              getCustomFont(
                "How would you rate the delivery service for this order?",
                13,
                getFontGreyColor(context),
                2,
                fontWeight: FontWeight.w500,
              ),
              SizedBox(height: 20.h),

              // Star rating
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _deliveryRating = (index + 1).toDouble();
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Icon(
                          index < _deliveryRating
                              ? Icons.star
                              : Icons.star_outline,
                          color: accentColor,
                          size: 40.w,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              if (_deliveryRating > 0)
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: getGreyCardColor(context),
                    borderRadius: BorderRadius.circular(6.w),
                  ),
                  child: Center(
                    child: getCustomFont(
                      "${_deliveryRating.toStringAsFixed(1)}/5.0",
                      13,
                      getFontColor(context),
                      1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              SizedBox(height: 20.h),

              // Feedback text
              getCustomFont(
                "Additional Feedback (Optional)",
                13,
                getFontColor(context),
                1,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Share your delivery experience...",
                  hintStyle: TextStyle(
                    color: getFontGreyColor(context),
                    fontSize: 13.sp,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.w),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.w),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.w),
                    borderSide: BorderSide(color: accentColor),
                  ),
                  contentPadding: EdgeInsets.all(12.w),
                ),
              ),

              SizedBox(height: 20.h),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: dividerColor),
                          borderRadius: BorderRadius.circular(8.w),
                          color: getCardColor(context),
                        ),
                        child: Center(
                          child: getCustomFont(
                            "Cancel",
                            14,
                            getFontColor(context),
                            1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: _deliveryRating > 0
                          ? () {
                              widget.onRatingSubmitted(_deliveryRating);
                              Navigator.pop(context);
                            }
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: _deliveryRating > 0
                              ? accentColor
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                        child: Center(
                          child: getCustomFont(
                            "Submit",
                            14,
                            Colors.white,
                            1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
