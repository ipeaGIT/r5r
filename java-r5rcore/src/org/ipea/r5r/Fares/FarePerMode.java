package org.ipea.r5r.Fares;

public class FarePerMode {
    private String mode;
    private boolean unlimitedTransfers = false;
    private boolean allowSameRouteTransfer = false;
    private boolean useRouteFare = false;
    private float fare = 0.0f;

    public FarePerMode(String mode, boolean unlimitedTransfers, boolean allowSameRouteTransfer, boolean useRouteFare, float fare) {
        this.mode = mode;
        this.unlimitedTransfers = unlimitedTransfers;
        this.allowSameRouteTransfer = allowSameRouteTransfer;
        this.useRouteFare = useRouteFare;
        this.fare = fare;
    }

    public FarePerMode() {
        this("BUS", false, false, false, 0.0f);
    }

    public String getMode() {
        return mode;
    }

    public void setMode(String mode) {
        this.mode = mode;
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

    public void setFare(float fare) {
        this.fare = fare;
    }

    @Override
    public String toString() {
        return "FarePerMode{" +
                "mode='" + mode + '\'' +
                ", unlimitedTransfers=" + unlimitedTransfers +
                ", allowSameRouteTransfer=" + allowSameRouteTransfer +
                ", useRouteFare=" + useRouteFare +
                ", fare=" + fare +
                '}';
    }
}
