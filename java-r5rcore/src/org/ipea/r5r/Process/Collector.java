package org.ipea.r5r.Process;

import org.apache.arrow.memory.BufferAllocator;
import org.apache.arrow.vector.VectorSchemaRoot;
import org.apache.arrow.vector.ipc.message.ArrowRecordBatch;
import org.apache.arrow.vector.types.pojo.Schema;

final class Collector implements Runnable {
    private final BufferAllocator parentAlloc;
    private final Schema schema;
    private final java.util.concurrent.BlockingQueue<BatchWithSeq> in;
    private final java.nio.channels.WritableByteChannel channel;
    private final int expectedBatches; // nOrigins
    private volatile boolean started = false;

    Collector(BufferAllocator parentAlloc,
              Schema schema,
              java.util.concurrent.BlockingQueue<BatchWithSeq> in,
              java.nio.channels.WritableByteChannel channel,
              int expectedBatches) {
        this.parentAlloc = parentAlloc;
        this.schema = schema;
        this.in = in;
        this.channel = channel;
        this.expectedBatches = expectedBatches;
    }

    @Override public void run() {
        started = true;
        try (BufferAllocator alloc = parentAlloc.newChildAllocator("collector", 0, Long.MAX_VALUE);
             VectorSchemaRoot writerRoot = VectorSchemaRoot.create(schema, alloc);
             org.apache.arrow.vector.ipc.ArrowStreamWriter writer =
                     new org.apache.arrow.vector.ipc.ArrowStreamWriter(writerRoot, null, channel)) {

            writer.start();
            org.apache.arrow.vector.VectorLoader loader = new org.apache.arrow.vector.VectorLoader(writerRoot);

            int written = 0;
            int nextSeq = 0;
            java.util.Map<Integer, BatchWithSeq> buffer = new java.util.HashMap<>();

            while (written < expectedBatches) {
                BatchWithSeq item = in.poll(250, java.util.concurrent.TimeUnit.MILLISECONDS);
                if (item != null) {
                    buffer.put(item.seq, item);
                    // drain in order if possible
                    while (buffer.containsKey(nextSeq)) {
                        try (ArrowRecordBatch b = buffer.remove(nextSeq).batch) {
                            loader.load(b);
                            writer.writeBatch();
                            written++;
                            nextSeq++;
                        }
                    }
                }
            }

            writer.end();
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Collector interrupted", ie);
        } catch (Exception e) {
            throw new RuntimeException("Collector failure", e);
        }
    }

    public boolean isStarted() { return started; }
}

