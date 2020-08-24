package org.ipea.r5r;

import java.util.ArrayList;
import java.util.LinkedHashMap;

public class RDataFrame {
    LinkedHashMap<String, Object> dataFrame;

    public RDataFrame() {
        dataFrame = new LinkedHashMap<>();
    }

    public ArrayList<String> addStringColumn(String columnName) {
        ArrayList<String> column = new ArrayList<>();
        dataFrame.put(columnName, column);

        return column;
    }

    public ArrayList<Integer> addIntegerColumn(String columnName) {
        ArrayList<Integer> column = new ArrayList<>();
        dataFrame.put(columnName, column);

        return column;
    }

    public ArrayList<Double> addDoubleColumn(String columnName) {
        ArrayList<Double> column = new ArrayList<>();
        dataFrame.put(columnName, column);

        return column;
    }
}

