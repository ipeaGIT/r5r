package org.ipea.r5r.Scenario;

import com.conveyal.r5.analyst.scenario.ShapefileLts;
import com.conveyal.r5.shapefile.ShapefileMatcher;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.util.ExceptionUtils;
import gnu.trove.list.array.TIntArrayList;

import java.io.File;
import java.lang.reflect.Field;

public class R5RShapefileLts extends ShapefileLts {
    @Override
    public boolean apply (TransportNetwork network) {
        // Replicate the entire flags array so we can write to it (following copy-on-write policy).
        // Otherwise the TIntAugmentedList only allows extending the base graph. An alternative approach can be seen in
        // ModifyStreets, where all affected edges are marked deleted and then recreated in the augmented lists.
        // The appraoch here assumes a high percentage of edges changed, while ModifyStreets assumes a small percentage.
        network.streetLayer.edgeStore.flags = new TIntArrayList(network.streetLayer.edgeStore.flags);
        ShapefileMatcher shapefileMatcher = new R5RShapefileMatcher(network.streetLayer);
        try {
            Field field = ShapefileLts.class.getDeclaredField("localFile");
            field.setAccessible(true);
            File localFileValue = (File) field.get(this);

            shapefileMatcher.match(localFileValue.getAbsolutePath(), ltsAttribute);
        } catch (Exception e) {
            addError(ExceptionUtils.shortAndLongString(e));
        }
        return hasErrors();
    }
}
