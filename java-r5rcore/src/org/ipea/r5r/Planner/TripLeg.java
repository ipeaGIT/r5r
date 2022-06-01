package org.ipea.r5r.Planner;

import com.conveyal.r5.api.util.StreetSegment;
import org.locationtech.jts.geom.LineString;

public class TripLeg {
    private String mode;
    private boolean isTransfer = false;

    private int legDurationSeconds;
    private int legDistance;
    private int cumulativeFare;

    private int boardStop;
    private int alightStop;

    private int waitTime;
    private String route;

    private LineString geometry;

    public String getMode() {
        return mode;
    }

    public int getLegDurationSeconds() {
        return legDurationSeconds;
    }

    public int getLegDistance() {
        return legDistance;
    }

    public int getCumulativeFare() {
        return cumulativeFare;
    }

    public int getBoardStop() {
        return boardStop;
    }

    public int getAlightStop() {
        return alightStop;
    }

    public int getWaitTime() {
        return waitTime;
    }

    public String getRoute() {
        return route;
    }

    public LineString getGeometry() {
        return geometry;
    }

    public static TripLeg newDirectLeg(String mode, StreetSegment streetSegment) {
        TripLeg newLeg = new TripLeg();

        newLeg.mode = mode;
        newLeg.legDistance = streetSegment.distance;
        newLeg.legDurationSeconds = streetSegment.duration;
        newLeg.cumulativeFare = 0;
        newLeg.route = "";
        newLeg.geometry = streetSegment.geometry;

        return newLeg;
    }

    public static TripLeg newTransferLeg(String mode, int duration, int fare, LineString geometry) {
        TripLeg newLeg = new TripLeg();

        newLeg.mode = mode;
        newLeg.isTransfer = true;
        newLeg.legDistance = (int) geometry.getLength();
        newLeg.legDurationSeconds = duration;
        newLeg.cumulativeFare = fare;
        newLeg.route = "";
        newLeg.geometry = geometry;

        return newLeg;
    }

    public static TripLeg newTransitLeg(String mode, int duration, int fare, int waitTime,
                                        int boardStop, int alightStop, String route,
                                        LineString geometry) {
        TripLeg newLeg = new TripLeg();

        newLeg.mode = mode;
        newLeg.legDistance = (int) geometry.getLength();
        newLeg.legDurationSeconds = duration;
        newLeg.cumulativeFare = fare;
        newLeg.waitTime = waitTime;
        newLeg.boardStop = boardStop;
        newLeg.alightStop = alightStop;
        newLeg.route = route;
        newLeg.geometry = geometry;

        return newLeg;
    }


}

