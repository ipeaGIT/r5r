package org.ipea.r5r.Utils;

import java.util.HashMap;

public class RMapBuilder {
    public static HashMap<Long, Float> buildSpeedMap(String osmIds, String scale){
        String[] osmIdsArray = osmIds.split(",");
        String[] scaleArray = scale.split(",");

        HashMap<Long, Float> map = new HashMap<>();
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

        HashMap<Long, Integer> map = new HashMap<>();
        for (int i = 0; i < osmIdsArray.length; i++) {
            long osmId = Long.parseLong(osmIdsArray[i]);
            int jLts = Integer.parseInt(ltsArray[i]);
            map.put(osmId, jLts);
        }
        return map;
    }
}
