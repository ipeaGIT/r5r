package org.ipea.r5r.Fares;

import com.fasterxml.jackson.annotation.JsonIgnore;

public class FarePerRoute {

    private String agencyId;
    private String agencyName;
    private String routeId;
    private String routeShortName;
    private String routeLongName;
    private String mode;
    private float routeFare;
    private String fareType;
    @JsonIgnore
    private int integerFare;

    @JsonIgnore
    private int modeIndex;

    public FarePerRoute(String agencyId, String agencyName, String routeId, String routeShortName, String routeLongName,
                        String mode, float routeFare, String fareType) {
        this.agencyId = agencyId;
        this.agencyName = agencyName;
        this.routeId = routeId;
        this.routeShortName = routeShortName;
        this.routeLongName = routeLongName;
        this.mode = mode;
        this.routeFare = routeFare;
        this.integerFare = Math.round(routeFare * 100.0f);
        this.fareType = fareType;
    }

    public FarePerRoute() {
        this("", "", "", "", "", "", 0.0f, "GENERIC");
    }

    public String getAgencyId() {
        return agencyId;
    }

    public void setAgencyId(String agencyId) {
        this.agencyId = agencyId;
    }

    public String getAgencyName() {
        return agencyName;
    }

    public void setAgencyName(String agencyName) {
        this.agencyName = agencyName;
    }

    public String getRouteId() {
        return routeId;
    }

    public void setRouteId(String routeId) {
        this.routeId = routeId;
    }

    public String getRouteShortName() {
        return routeShortName;
    }

    public void setRouteShortName(String routeShortName) {
        this.routeShortName = routeShortName;
    }

    public String getRouteLongName() {
        return routeLongName;
    }

    public void setRouteLongName(String routeLongName) {
        this.routeLongName = routeLongName;
    }

    public String getMode() {
        return mode;
    }

    public void setMode(String mode) {
        this.mode = mode;
    }

    public float getRouteFare() {
        return routeFare;
    }

    public int getIntegerFare() {
        return this.integerFare;
    }

    public void setRouteFare(float routeFare) {
        this.routeFare = routeFare;
        this.integerFare = Math.round(routeFare * 100.0f);
    }

    public String getFareType() {
        return fareType;
    }

    public void setFareType(String fareType) {
        this.fareType = fareType;
    }

    public void setModeIndex(int modeIndex) {
        this.modeIndex = modeIndex;
    }

    public int getModeIndex() {
        return modeIndex;
    }

    @Override
    public String toString() {
        return "FarePerRoute{" +
                "agencyId='" + agencyId + '\'' +
                ", agencyName='" + agencyName + '\'' +
                ", routeId='" + routeId + '\'' +
                ", routeShortName='" + routeShortName + '\'' +
                ", routeLongName='" + routeLongName + '\'' +
                ", mode='" + mode + '\'' +
                ", routeFare=" + routeFare +
                ", fareType='" + fareType + '\'' +
                '}';
    }
}
