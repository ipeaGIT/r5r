package org.ipea.r5r.Utils;

import java.util.*;
import java.util.stream.Collectors;

public class RMapBuilder {
    public static HashMap<Long, Float> buildSpeedMap(String osmIds, String scale){
        String[] osmIdsArray = osmIds.split(",");
        String[] scaleArray = scale.split(",");

        if (osmIdsArray.length != scaleArray.length) {
            throw new IllegalArgumentException("osmIds and scale must have the same number of items.");
        }

        HashMap<Long, Float> map = new HashMap<>((int) Math.ceil(osmIdsArray.length / 0.74));
        for (int i = 0; i < osmIdsArray.length; i++) {
            long osmId = Long.parseLong(osmIdsArray[i]);
            float jScale = Float.parseFloat(scaleArray[i]);
            map.put(osmId, jScale);
        }
        return map;
    }

    public static HashMap<Long, Integer> buildLtsMap(String osmIds, String lts){
        String[] osmIdsArray = osmIds.split(",");
        String[] ltsArray = lts.split(",");

        if (osmIdsArray.length != ltsArray.length) {
            throw new IllegalArgumentException("osmIds and lts must have the same number of items.");
        }

        HashMap<Long, Integer> map = new HashMap<>((int) Math.ceil(osmIdsArray.length / 0.74));
        for (int i = 0; i < osmIdsArray.length; i++) {
            long osmId = Long.parseLong(osmIdsArray[i]);
            int jLts = Integer.parseInt(ltsArray[i]);
            map.put(osmId, jLts);
        }
        return map;
    }

    public static Map<String, Set<String>> buildStopsMap(String polyIds, String stops) {
        String[] polyIdsArray = polyIds.split(",");
        String[] stopsArray  = stops.split(";");

        if (polyIdsArray.length != stopsArray.length) {
            throw new IllegalArgumentException("polyIds and stopsGroups must have the same number of items.");
        }

        Map<String, Set<String>> map = new HashMap<>((int) Math.ceil(polyIdsArray.length / 0.74));

        for (int i = 0; i < polyIdsArray.length; i++) {
            String[] ids = stopsArray[i].split(",");
            Set<String> set = new HashSet<>(List.of(ids));
            map.put(polyIdsArray[i], set);
        }
        return map;
    }
}
