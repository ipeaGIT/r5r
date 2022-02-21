package org.ipea.r5r.Fares;

import com.fasterxml.jackson.annotation.JsonIgnore;

public class FarePerTransfer {
    private String firstLeg;
    private String secondLeg;
    private float fare;
    @JsonIgnore
    private int integerFare;

    public FarePerTransfer(String firstLeg, String secondLeg, float fare) {
        this.firstLeg = firstLeg;
        this.secondLeg = secondLeg;
        this.fare = fare;
        this.integerFare = Math.round(fare * 100.0f);
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

    public int getIntegerFare() {
        return this.integerFare;
    }

    public void setFare(float fare) {
        this.fare = fare;
        this.integerFare = Math.round(fare * 100.0f);
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
