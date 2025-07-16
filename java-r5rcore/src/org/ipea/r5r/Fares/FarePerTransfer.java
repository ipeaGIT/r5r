package org.ipea.r5r.Fares;

import com.fasterxml.jackson.annotation.JsonIgnore;

public class FarePerTransfer {
    private String alightLeg;
    private String boardLeg;
    private float fare;
    @JsonIgnore
    private int integerFare;

    public int getAlightLegFullIntegerFare() {
        return alightLegFullIntegerFare;
    }

    public void setAlightLegFullIntegerFare(int alightLegFullIntegerFare) {
        this.alightLegFullIntegerFare = alightLegFullIntegerFare;
    }

    public int getBoardLegFullIntegerFare() {
        return boardLegFullIntegerFare;
    }

    public void setBoardLegFullIntegerFare(int boardLegFullIntegerFare) {
        this.boardLegFullIntegerFare = boardLegFullIntegerFare;
    }

    @JsonIgnore
    private int alightLegFullIntegerFare;
    @JsonIgnore
    private int boardLegFullIntegerFare;

    public FarePerTransfer(String alightLeg, String boardLeg, float fare) {
        this.alightLeg = alightLeg;
        this.boardLeg = boardLeg;
        this.fare = fare;
        this.integerFare = Math.round(fare * 100.0f);
    }

    public FarePerTransfer() {
        this("BUS", "BUS", 0.0f);
    }

    public String getAlightLeg() {
        return alightLeg;
    }

    public void setAlightLeg(String alightLeg) {
        this.alightLeg = alightLeg;
    }

    public String getBoardLeg() {
        return boardLeg;
    }

    public void setBoardLeg(String boardLeg) {
        this.boardLeg = boardLeg;
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
                "alightLeg='" + alightLeg + '\'' +
                ", boardLeg='" + boardLeg + '\'' +
                ", fare=" + fare +
                '}';
    }
}
