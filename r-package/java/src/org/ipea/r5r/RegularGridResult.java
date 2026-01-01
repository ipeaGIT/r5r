package org.ipea.r5r;

import com.conveyal.r5.analyst.cluster.TravelTimeResult;
import com.conveyal.r5.analyst.cluster.TravelTimeSurfaceTask;

/**
 * A RegularGridResult holds the result of a travel time surface calculation, as well as metadata about the result.
 */
public class RegularGridResult {
  // indexed by percentiles and then by row-major values
  public final int[][] values;

  // web mercator extents
  public final int zoom;
  public final int west;
  public final int north;
  public final int width;
  public final int height;
  public final int[] percentiles;

  public RegularGridResult(TravelTimeResult result, TravelTimeSurfaceTask task) {
    this.values = result.getValues();
    this.height = task.height;
    this.width = task.width;
    this.north = task.north;
    this.west = task.west;
    this.zoom = task.zoom;
    this.percentiles = task.percentiles;
  }
}
