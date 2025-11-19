package io.audira.community.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;
import lombok.Builder;

@Entity
@Table(name = "admins")
@DiscriminatorValue("ADMIN")
@Data
@EqualsAndHashCode(callSuper = true)
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class Admin extends User {

    @Enumerated(EnumType.STRING)
    @Column(name = "admin_level")
    @Builder.Default
    private AdminLevel adminLevel = AdminLevel.MODERATOR;

    @Column(name = "department")
    private String department;

    @Override
    public String getUserType() {
        return "ADMIN";
    }

    public enum AdminLevel {
        MODERATOR,
        ADMIN,
        SUPER_ADMIN
    }
}
