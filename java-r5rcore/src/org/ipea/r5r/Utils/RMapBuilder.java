package org.ipea.r5r.Utils;

import java.util.HashMap;

public class RMapBuilder {
    public static HashMap<Long, Float> buildSpeedMap(String osmIds, String scale){
        String[] osmIdsArray = osmIds.split(",");
        String[] scaleArray = scale.split(",");

        HashMap<Long, Float> map = new HashMap<>();
        for (int i = 0; i < osmIdsArray.length; i++) {
            long osmId = Long.parseLong(osmIdsArray[i]);
            float maxSpeed = Float.parseFloat(scaleArray[i]);
            map.put(osmId, maxSpeed);
        }
        return map;
    }

    public static HashMap<Long, Integer> buildLtsMap(long[] osmIds, int[] lts){
        HashMap<Long, Integer> map = new HashMap<>();
        for (int i = 0; i < osmIds.length; i++) {
            map.put(osmIds[i], lts[i]);
        }
        return map;
    }
}
