package io.audira.community.exception;

/**
 * Excepción personalizada para operaciones de Rating
 * GA01-128, GA01-129, GA01-130
 */
public class RatingException extends RuntimeException {

    public RatingException(String message) {
        super(message);
    }

    public RatingException(String message, Throwable cause) {
        super(message, cause);
    }

    public static class RatingNotFoundException extends RatingException {
        public RatingNotFoundException(Long ratingId) {
            super("Rating with ID " + ratingId + " not found");
        }
    }

    public static class UnauthorizedRatingAccessException extends RatingException {
        public UnauthorizedRatingAccessException() {
            super("You are not authorized to modify this rating");
        }
    }

    public static class DuplicateRatingException extends RatingException {
        public DuplicateRatingException(String entityType, Long entityId) {
            super("You have already rated this " + entityType.toLowerCase() + " (ID: " + entityId + ")");
        }
    }

    public static class InvalidRatingValueException extends RatingException {
        public InvalidRatingValueException() {
            super("Rating value must be between 1 and 5 stars");
        }
    }

    public static class InvalidCommentLengthException extends RatingException {
        public InvalidCommentLengthException() {
            super("Comment cannot exceed 500 characters");
        }
    }

    public static class ProductNotPurchasedException extends RatingException {
        public ProductNotPurchasedException(String entityType, Long entityId) {
            super("You must purchase this " + entityType.toLowerCase() + " before rating it (ID: " + entityId + ")");
        }
    }
}
