package org.ipea.r5r.Fares;

import java.util.HashMap;
import java.util.Map;

public class FareStructure {

    /**
     * When fares are not found in farePerMode or farePerTransfer, the value of baseFare is used.
     */
    private int baseFare;

    public int getBaseFare() {
        return baseFare;
    }

    public void setBaseFare(int baseFare) {
        this.baseFare = baseFare;
    }

    public int getMaxDiscountedTransfers() {
        return maxDiscountedTransfers;
    }

    public void setMaxDiscountedTransfers(int maxDiscountedTransfers) {
        this.maxDiscountedTransfers = maxDiscountedTransfers;
    }

    public Map<String, Integer> getFarePerMode() {
        return farePerMode;
    }

    public Map<String, Integer> getFarePerTransfer() {
        return farePerTransfer;
    }

    public Map<String, String> getModeOfRoute() {
        return modeOfRoute;
    }

    /**
     * Maximum number of transfers that can have a discount. The transfer fare is obtained from the farePerTransfer
     * Map up to the number of transfers informed in this field. After that, each new leg gets the full fare from the
     * farePerMode Map.
     */
    private int maxDiscountedTransfers;
    
    private final Map<String, Integer> farePerMode;
    private final Map<String, Integer> farePerTransfer;
    private final Map<String, String> modeOfRoute;

    public FareStructure() {
        this.baseFare = 100;
        this.maxDiscountedTransfers = 1;

        this.farePerMode = new HashMap<>();
        this.farePerTransfer = new HashMap<>();
        this.modeOfRoute = new HashMap<>();
    }

}
