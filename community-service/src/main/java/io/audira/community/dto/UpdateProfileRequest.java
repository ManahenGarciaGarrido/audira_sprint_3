package io.audira.community.dto;

import lombok.Data;

@Data
public class UpdateProfileRequest {
    private String firstName;
    private String lastName;
    private String bio;
    private String profileImageUrl;
    private String bannerImageUrl;
    private String location;
    private String website;

    // Artist-specific fields
    private String artistName;
    private String artistBio;
    private String recordLabel;

    // Social media links
    private String twitterUrl;
    private String instagramUrl;
    private String facebookUrl;
    private String youtubeUrl;
    private String spotifyUrl;
    private String tiktokUrl;
}
