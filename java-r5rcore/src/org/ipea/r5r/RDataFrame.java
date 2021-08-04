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
    private int capacity = 10;

    private final LinkedHashMap<String, ArrayList<Object>> dataFrame;
    private final LinkedHashMap<String, Object> defaultValues;

    private final ArrayList<String> columnNames;
    private final ArrayList<String> columnTypes;

    public RDataFrame() {
        this(10);
    }

    public RDataFrame(int capacity) {
        this.capacity = capacity;
        
        dataFrame = new LinkedHashMap<>();
        defaultValues = new LinkedHashMap<>();

        columnNames = new ArrayList<>();
        columnTypes = new ArrayList<>();
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

    public void set(String columnName, Boolean value) {
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
        ArrayList<Object> column = new ArrayList<>(capacity);
        dataFrame.put(columnName, column);

        defaultValues.put(columnName, defaultValue);

        columnNames.add(columnName);
        columnTypes.add("String");
    }

    public void addBooleanColumn(String columnName, Boolean defaultValue) {
        ArrayList<Object> column = new ArrayList<>(capacity);
        dataFrame.put(columnName, column);

        defaultValues.put(columnName, defaultValue);

        columnNames.add(columnName);
        columnTypes.add("Boolean");
    }

    public void addIntegerColumn(String columnName, Integer defaultValue) {
        ArrayList<Object> column = new ArrayList<>(capacity);
        dataFrame.put(columnName, column);

        defaultValues.put(columnName, defaultValue);

        columnNames.add(columnName);
        columnTypes.add("Integer");
    }

    public void addDoubleColumn(String columnName, Double defaultValue) {
        ArrayList<Object> column = new ArrayList<>(capacity);
        dataFrame.put(columnName, column);

        defaultValues.put(columnName, defaultValue);

        columnNames.add(columnName);
        columnTypes.add("Double");
    }

    public int getColumnCount() { return columnNames.size(); }
    public String getColumnName(int index) { return columnNames.get(index); }
    public String getColumnType(int index) { return columnTypes.get(index); }
}

