package org.ipea.r5r.Process;

import static org.ipea.r5r.Process.R5Process.LOG;

import java.text.ParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ForkJoinPool;

import org.ipea.r5r.RDataFrame;
import org.ipea.r5r.RoutingProperties;
import org.ipea.r5r.Utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.conveyal.r5.transit.TransportNetwork;

public abstract class R5DataFrameProcess extends R5Process<RDataFrame> {
    private static final Logger LOG = LoggerFactory.getLogger(R5DataFrameProcess.class);

    public R5DataFrameProcess(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
    }

    protected RDataFrame mergeResults(List<RDataFrame> processResults) {
        LOG.info("Consolidating results...");

        int nRows;
        nRows = processResults.stream()
                .mapToInt(RDataFrame::nRow)
                .sum();

        RDataFrame mergedDataFrame = buildDataFrameStructure("", nRows);
        if (Utils.benchmark) {
            mergedDataFrame.addLongColumn("execution_time", 0L);
        }

        mergedDataFrame.getDataFrame().keySet().stream().parallel().forEach(
                key -> {
                    ArrayList<Object> destinationArray = mergedDataFrame.getDataFrame().get(key);
                    processResults.forEach(
                            dataFrame -> {
                                ArrayList<Object> originArray = dataFrame.getDataFrame().get(key);
                                destinationArray.addAll(originArray);

                                originArray.clear();
                            });
                }
        );
        mergedDataFrame.updateRowCount();

        LOG.info(" DONE!");

        return mergedDataFrame;
    }

    protected abstract RDataFrame buildDataFrameStructure(String fromId, int nRows);

    @Override
    public RDataFrame run() throws ExecutionException, InterruptedException {
        buildDestinationPointSet();
        int[] requestIndices = IntStream.range(0, nOrigins).toArray();
        AtomicInteger totalProcessed = new AtomicInteger(1);

        List<RDataFrame> processResults = r5rThreadPool.submit(() ->
                Arrays.stream(requestIndices).parallel().
                        mapToObj(index -> tryRunProcess(totalProcessed, index)).
                        filter(Objects::nonNull).
                        collect(Collectors.toList())).get();

        LOG.info(".. DONE!");

        RDataFrame results = mergeResults(processResults);

        return results;
    }
    
}
