package org.ipea.r5r.Fares;

import java.util.HashMap;
import java.util.Map;

public class FareStructure {

    /**
     * When fares are not found in farePerMode or farePerTransfer, the value of baseFare is used.
     */
    private int baseFare;

    /**
     * Maximum number of transfers that can have a discount. The transfer fare is obtained from the farePerTransfer
     * Map up to the number of transfers informed in this field. After that, each new leg gets the full fare from the
     * farePerMode Map.
     */
    private int maxDiscountedTransfers;


    Map<String, Integer> farePerMode;
    Map<String, Integer> farePerTransfer;
    Map<String, String> modeOfRoute;

    public FareStructure() {
        this.baseFare = 100;
        this.maxDiscountedTransfers = 1;

        this.farePerMode = new HashMap<>();
        this.farePerTransfer = new HashMap<>();
        this.modeOfRoute = new HashMap<>();
    }

}
