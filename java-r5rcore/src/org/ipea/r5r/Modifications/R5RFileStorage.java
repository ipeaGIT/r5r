package org.ipea.r5r.Modifications;

import com.conveyal.file.FileStorage;
import com.conveyal.file.FileStorageKey;
import com.conveyal.file.LocalFileStorage;
import com.conveyal.r5.analyst.PersistenceBuffer;

import java.io.File;

public class R5RFileStorage implements FileStorage {

    private final String urlPrefix;

    public R5RFileStorage (LocalFileStorage.Config config) {
        this.urlPrefix = "http://localhost:%s/files";
    }

    @Override
    public void moveIntoStorage(FileStorageKey fileStorageKey, File file) {

    }

    @Override
    public void moveIntoStorage(FileStorageKey fileStorageKey, PersistenceBuffer persistenceBuffer) {

    }

    @Override
    public File getFile(FileStorageKey key) {
        return new File(key.path);
    }

    @Override
    public String getURL(FileStorageKey key) {
        return String.join("/", urlPrefix, key.category.directoryName(), key.path);
    }

    @Override
    public void delete(FileStorageKey fileStorageKey) {

    }

    @Override
    public boolean exists(FileStorageKey key) {
        return getFile(key).exists();
    }
}
