package io.audira.catalog.model;

/**
 * Status of a collaboration invitation
 * GA01-154: Añadir/aceptar colaboradores
 */
public enum CollaborationStatus {
    PENDING,    // Invitation sent, waiting for response
    ACCEPTED,   // Collaboration accepted by artist
    REJECTED    // Collaboration rejected by artist
}
