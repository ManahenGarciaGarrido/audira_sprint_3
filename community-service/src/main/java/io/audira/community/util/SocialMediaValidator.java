package io.audira.community.util;

import java.util.regex.Pattern;

public class SocialMediaValidator {

    // Regex patterns for social media URLs
    // Updated to allow query parameters (e.g., ?t=...&s=...)
    private static final Pattern TWITTER_PATTERN = Pattern.compile(
        "^https?://(www\\.)?(twitter\\.com|x\\.com)/[a-zA-Z0-9_]{1,15}(/?(\\?[^\\s]*)?)?$"
    );

    private static final Pattern INSTAGRAM_PATTERN = Pattern.compile(
        "^https?://(www\\.)?instagram\\.com/[a-zA-Z0-9_.]+(/?(\\?[^\\s]*)?)?$"
    );

    private static final Pattern FACEBOOK_PATTERN = Pattern.compile(
        "^https?://(www\\.)?facebook\\.com/[a-zA-Z0-9.]+(/?(\\?[^\\s]*)?)?$"
    );

    private static final Pattern YOUTUBE_PATTERN = Pattern.compile(
        "^https?://(www\\.)?youtube\\.com/(c/|channel/|@)[a-zA-Z0-9_-]+(/?(\\?[^\\s]*)?)?$"
    );

    private static final Pattern SPOTIFY_PATTERN = Pattern.compile(
        "^https?://open\\.spotify\\.com/artist/[a-zA-Z0-9]+(/?(\\?[^\\s]*)?)?$"
    );

    private static final Pattern TIKTOK_PATTERN = Pattern.compile(
        "^https?://(www\\.)?tiktok\\.com/@[a-zA-Z0-9_.]+(/?(\\?[^\\s]*)?)?$"
    );

    /**
     * Validates a Twitter/X URL
     */
    public static boolean isValidTwitterUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true; // Empty is valid (optional field)
        }
        return TWITTER_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Validates an Instagram URL
     */
    public static boolean isValidInstagramUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true;
        }
        return INSTAGRAM_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Validates a Facebook URL
     */
    public static boolean isValidFacebookUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true;
        }
        return FACEBOOK_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Validates a YouTube URL
     */
    public static boolean isValidYoutubeUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true;
        }
        return YOUTUBE_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Validates a Spotify artist URL
     */
    public static boolean isValidSpotifyUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true;
        }
        return SPOTIFY_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Validates a TikTok URL
     */
    public static boolean isValidTiktokUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true;
        }
        return TIKTOK_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Extracts username from Twitter/X URL
     * @param url Twitter/X URL
     * @return username without @
     */
    public static String extractTwitterUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remove query parameters
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        // Extract from https://twitter.com/username or https://x.com/username
        String[] parts = cleanUrl.split("/");
        if (parts.length > 3) {
            String username = parts[3].replace("@", "");
            return username;
        }
        return "";
    }

    /**
     * Extracts username from Instagram URL
     */
    public static String extractInstagramUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remove query parameters
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        String[] parts = cleanUrl.split("/");
        if (parts.length > 3) {
            return parts[3].replace("@", "");
        }
        return "";
    }

    /**
     * Extracts username from Facebook URL
     */
    public static String extractFacebookUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remove query parameters
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        String[] parts = cleanUrl.split("/");
        if (parts.length > 3) {
            return parts[3].replace("@", "");
        }
        return "";
    }

    /**
     * Extracts channel name from YouTube URL
     */
    public static String extractYoutubeUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remove query parameters
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        String[] parts = cleanUrl.split("/");
        if (parts.length > 4) {
            return parts[4].replace("@", "");
        }
        return "";
    }

    /**
     * Extracts artist ID from Spotify URL
     */
    public static String extractSpotifyUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remove query parameters
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        String[] parts = cleanUrl.split("/");
        if (parts.length > 4) {
            return parts[4];
        }
        return "";
    }

    /**
     * Extracts username from TikTok URL
     */
    public static String extractTiktokUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remove query parameters
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        String[] parts = cleanUrl.split("/");
        if (parts.length > 3) {
            return parts[3].replace("@", "");
        }
        return "";
    }
}
