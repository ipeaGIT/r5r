package org.ipea.r5r.Fares;

public class IntegratedFare {
    public int fare;
    public boolean usedDiscount;

    IntegratedFare(int fare, boolean discount) {
        this.fare = fare;
        this.usedDiscount = discount;
    }
}
