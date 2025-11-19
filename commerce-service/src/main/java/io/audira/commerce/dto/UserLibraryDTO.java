package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserLibraryDTO {

    private Long userId;
    private List<PurchasedItemDTO> songs = new ArrayList<>();
    private List<PurchasedItemDTO> albums = new ArrayList<>();
    private List<PurchasedItemDTO> merchandise = new ArrayList<>();
    private Integer totalItems;

    public UserLibraryDTO(Long userId) {
        this.userId = userId;
        this.songs = new ArrayList<>();
        this.albums = new ArrayList<>();
        this.merchandise = new ArrayList<>();
        this.totalItems = 0;
    }

    public void addSong(PurchasedItemDTO song) {
        this.songs.add(song);
        this.totalItems++;
    }

    public void addAlbum(PurchasedItemDTO album) {
        this.albums.add(album);
        this.totalItems++;
    }

    public void addMerchandise(PurchasedItemDTO item) {
        this.merchandise.add(item);
        this.totalItems++;
    }
}
