package com.sejourfr.app.storage;

import com.sejourfr.app.storage.dto.StoredFile;
import org.springframework.web.multipart.MultipartFile;

public interface MediaStorageService {

    /** Stocke un fichier et retourne ses metadonnees + URL publique. */
    StoredFile store(MultipartFile file);

    /** Supprime un fichier a partir de sa cle de stockage. No-op si la cle est null. */
    void delete(String storageKey);
}
