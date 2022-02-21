package org.ipea.r5r.Fares;

public class FarePerTransfer {
    private String firstLeg;
    private String secondLeg;
    private float fare;

    public FarePerTransfer(String firstLeg, String secondLeg, float fare) {
        this.firstLeg = firstLeg;
        this.secondLeg = secondLeg;
        this.fare = fare;
    }

    public FarePerTransfer() {
        this("BUS", "BUS", 0.0f);
    }

    public String getFirstLeg() {
        return firstLeg;
    }

    public void setFirstLeg(String firstLeg) {
        this.firstLeg = firstLeg;
    }

    public String getSecondLeg() {
        return secondLeg;
    }

    public void setSecondLeg(String secondLeg) {
        this.secondLeg = secondLeg;
    }

    public float getFare() {
        return fare;
    }

    public void setFare(float fare) {
        this.fare = fare;
    }

    @Override
    public String toString() {
        return "FarePerTransfer{" +
                "firstLeg='" + firstLeg + '\'' +
                ", secondLeg='" + secondLeg + '\'' +
                ", fare=" + fare +
                '}';
    }
}
