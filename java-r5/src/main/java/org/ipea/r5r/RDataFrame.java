package org.ipea.r5r;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;

public class RDataFrame {
    private int rowCount = 0;

    public LinkedHashMap<String, ArrayList<Object>> getDataFrame() {
        return dataFrame;
    }

    public int nRow() {
        return rowCount;
    }

    private final LinkedHashMap<String, ArrayList<Object>> dataFrame;
    private final LinkedHashMap<String, Object> defaultValues;

    public RDataFrame() {
        dataFrame = new LinkedHashMap<>();
        defaultValues = new LinkedHashMap<>();
    }

    public void append() {
        dataFrame.forEach((columnName, columnContents) -> {
            Object defaultValue = defaultValues.get(columnName);

            columnContents.add(defaultValue);
        });
        rowCount++;
    }

    public void set(String columnName, String value) {
        List<Object> column = dataFrame.get(columnName);
        column.set(column.size() - 1, value);
    }

    public void set(String columnName, Integer value) {
        List<Object> column = dataFrame.get(columnName);
        column.set(column.size() - 1, value);
    }

    public void set(String columnName, Double value) {
        List<Object> column = dataFrame.get(columnName);
        column.set(column.size() - 1, value);
    }

    public void addStringColumn(String columnName, String defaultValue) {
        ArrayList<Object> column = new ArrayList<>();
        dataFrame.put(columnName, column);

        defaultValues.put(columnName, defaultValue);

    }

    public void addIntegerColumn(String columnName, Integer defaultValue) {
        ArrayList<Object> column = new ArrayList<>();
        dataFrame.put(columnName, column);

        defaultValues.put(columnName, defaultValue);

    }

    public void addDoubleColumn(String columnName, Double defaultValue) {
        ArrayList<Object> column = new ArrayList<>();
        dataFrame.put(columnName, column);

        defaultValues.put(columnName, defaultValue);
    }
}

