package org.ipea.r5r.Scenario;

import com.conveyal.r5.shapefile.ShapefileMatcher;
import com.conveyal.r5.streets.StreetLayer;
import com.conveyal.r5.util.ShapefileReader;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.index.strtree.STRtree;
import org.opengis.feature.simple.SimpleFeature;

import java.io.File;

public class R5RShapefileMatcher extends ShapefileMatcher {

    public R5RShapefileMatcher(StreetLayer streets) {
        super(streets);
    }

    @Override
    public void indexFeatures (String shapefileName, String attributeName) throws Throwable {
        var fFeatureIndex = ShapefileMatcher.class.getDeclaredField("featureIndex");
        var fAttrIndex    = ShapefileMatcher.class.getDeclaredField("ltsAttributeIndex");
        fFeatureIndex.setAccessible(true);
        fAttrIndex.setAccessible(true);

        STRtree idx = new STRtree();

        try (ShapefileReader reader = new ShapefileReader(new File(shapefileName))) {
            LOG.info("Indexing shapefile features");

            // Get the attribute index while the reader is open
            int attrIdx = reader.findAttribute(attributeName, Number.class);

            // Ensure the stream/iterator is closed
            try (java.util.stream.Stream<org.opengis.feature.simple.SimpleFeature> stream = reader.wgs84Stream()) {
                stream.forEach(feature -> {
                    LineString featureGeom = R5extractLineString(feature);
                    idx.insert(featureGeom.getEnvelopeInternal(), feature);
                });
            }

            idx.build(); // Index is now immutable.

            fFeatureIndex.set(this, idx);
            fAttrIndex.set(this, attrIdx);
        }
    }

    private static LineString R5extractLineString(SimpleFeature feature) {
        MultiLineString multiLineString = (MultiLineString)feature.getDefaultGeometry();
        if (multiLineString.getNumGeometries() != 1) {
            throw new RuntimeException("Feature does not contain a single linestring.");
        } else {
            return (LineString)multiLineString.getGeometryN(0);
        }
    }
}
