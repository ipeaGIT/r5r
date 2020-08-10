package org.ipea.r5r;

import com.conveyal.r5.util.InputStreamProvider;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

public class CSVInputStreamProvider implements InputStreamProvider {

    //    private InputStream csvInputStream;
    private String fileName;

    public CSVInputStreamProvider(String fileName) {
        this.fileName = fileName;
    }

    @Override
    public InputStream getInputStream() throws IOException {
        return new FileInputStream(fileName);
    }
}