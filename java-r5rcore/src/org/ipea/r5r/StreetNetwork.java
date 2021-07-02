package org.ipea.r5r;

import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.streets.EdgeStore;
import com.conveyal.r5.streets.VertexStore;
import com.conveyal.r5.transit.TransportNetwork;

import java.util.HashSet;

public class StreetNetwork {

    public RDataFrame verticesTable;
    public RDataFrame edgesTable;


    // R5 creates additional vertices on the street network to represent transit stops, so this HashSet is used to
    // uniquely identify street vertices that are connected to the original street edges that came from OSM
    private final HashSet<Integer> verticesSet;

    public StreetNetwork(TransportNetwork transportNetwork) {
        verticesSet = new HashSet<Integer>();

        buildEdgesTable(transportNetwork);
        buildVerticesTable(transportNetwork);
    }

    private void buildEdgesTable(TransportNetwork transportNetwork) {
        // Build edges return table
        edgesTable = new RDataFrame();
        edgesTable.addIntegerColumn("from_vertex", 0);
        edgesTable.addIntegerColumn("to_vertex", 0);
        edgesTable.addDoubleColumn("length", 0.0);
        edgesTable.addBooleanColumn("walk", false);
        edgesTable.addBooleanColumn("bicycle", false);
        edgesTable.addBooleanColumn("car", false);
        edgesTable.addStringColumn("geometry", "");

        EdgeStore edges = transportNetwork.streetLayer.edgeStore;

        EdgeStore.Edge edgeCursor = edges.getCursor();
        while (edgeCursor.advance()) {
            // edges that have the LINK flag are created by R5 specifically to link the OSM street network to bus stops,
            // so such edges are removed from the return data.frame
            if (!edgeCursor.getFlag(EdgeStore.EdgeFlag.LINK)) {
                edgesTable.append();
                edgesTable.set("from_vertex", edgeCursor.getFromVertex());
                edgesTable.set("to_vertex", edgeCursor.getToVertex());
                edgesTable.set("length", edgeCursor.getLengthM());
                edgesTable.set("walk", edgeCursor.allowsStreetMode(StreetMode.WALK));
                edgesTable.set("bicycle", edgeCursor.allowsStreetMode(StreetMode.BICYCLE));
                edgesTable.set("car", edgeCursor.allowsStreetMode(StreetMode.CAR));
                edgesTable.set("geometry", edgeCursor.getGeometry().toString());

                // if the edge is originally from OSM, add its from/to vertices to the vertices HashSet, so they can
                // be returned later in the vertices data.frame
                verticesSet.add(edgeCursor.getFromVertex());
                verticesSet.add(edgeCursor.getToVertex());
            }
        }
    }

    private void buildVerticesTable(TransportNetwork transportNetwork) {
        // Build vertices return table
        verticesTable = new RDataFrame();
        verticesTable.addIntegerColumn("index", 0);
        verticesTable.addDoubleColumn("lat", 0.0);
        verticesTable.addDoubleColumn("lon", 0.0);
        verticesTable.addBooleanColumn("park_and_ride", false);
        verticesTable.addBooleanColumn("bike_sharing", false);

        VertexStore vertices = transportNetwork.streetLayer.vertexStore;
        VertexStore.Vertex vertexCursor = vertices.getCursor();

        // iterate over vertices previously identified in the edges table, and add them to the return data.frame
        verticesSet.forEach(v -> {
            vertexCursor.seek(v);

            verticesTable.append();
            verticesTable.set("index", vertexCursor.index);
            verticesTable.set("lat", vertexCursor.getLat());
            verticesTable.set("lon", vertexCursor.getLon());
            verticesTable.set("park_and_ride", vertexCursor.getFlag(VertexStore.VertexFlag.PARK_AND_RIDE));
            verticesTable.set("bike_sharing", vertexCursor.getFlag(VertexStore.VertexFlag.BIKE_SHARING));
        });
    }
}
