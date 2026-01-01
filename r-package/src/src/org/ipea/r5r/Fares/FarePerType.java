package org.ipea.r5r.Fares;

import com.fasterxml.jackson.annotation.JsonIgnore;

public class FarePerType {
    private String type;
    private boolean unlimitedTransfers;
    private boolean allowSameRouteTransfer;
    private boolean useRouteFare;
    private float fare;
    @JsonIgnore
    private int integerFare;

    public FarePerType(String type, boolean unlimitedTransfers, boolean allowSameRouteTransfer, boolean useRouteFare, float fare) {
        this.type = type;
        this.unlimitedTransfers = unlimitedTransfers;
        this.allowSameRouteTransfer = allowSameRouteTransfer;
        this.useRouteFare = useRouteFare;
        this.fare = fare;
        this.integerFare = Math.round(fare * 100.0f);
    }

    public FarePerType() {
        this("BUS", false, false, false, 0.0f);
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public boolean isUnlimitedTransfers() {
        return unlimitedTransfers;
    }

    public void setUnlimitedTransfers(boolean unlimitedTransfers) {
        this.unlimitedTransfers = unlimitedTransfers;
    }

    public boolean isAllowSameRouteTransfer() {
        return allowSameRouteTransfer;
    }

    public void setAllowSameRouteTransfer(boolean allowSameRouteTransfer) {
        this.allowSameRouteTransfer = allowSameRouteTransfer;
    }

    public boolean isUseRouteFare() {
        return useRouteFare;
    }

    public void setUseRouteFare(boolean useRouteFare) {
        this.useRouteFare = useRouteFare;
    }

    public float getFare() {
        return fare;
    }

    public int getIntegerFare() {
        return integerFare;
    }

    public void setFare(float fare) {
        this.fare = fare;
        this.integerFare = Math.round(fare * 100.0f);
    }

    @Override
    public String toString() {
        return "FarePerMode{" +
                "mode='" + type + '\'' +
                ", unlimitedTransfers=" + unlimitedTransfers +
                ", allowSameRouteTransfer=" + allowSameRouteTransfer +
                ", useRouteFare=" + useRouteFare +
                ", fare=" + fare +
                '}';
    }
}
