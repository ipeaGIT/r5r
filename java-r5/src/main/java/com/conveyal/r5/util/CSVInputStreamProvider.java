package com.conveyal.r5.util;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

public class CSVInputStreamProvider implements InputStreamProvider {

    private final String fileName;

    public CSVInputStreamProvider(String fileName) {
        this.fileName = fileName;
    }

    @Override
    public InputStream getInputStream() throws IOException {
        return new FileInputStream(fileName);
    }

}
