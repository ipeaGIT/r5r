package org.ipea.r5r;

public class SampleR5RCore {
    public static void main(String[] args) {
        try {
            String dataFolder = "../r-package/inst/extdata/poa";
            System.out.println("Using data folder: " + dataFolder);
            R5RCore core = new R5RCore(dataFolder, true, "NONE");
            System.out.println("R5RCore initialized successfully!");

        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Failed to initialize R5RCore: " + e.getMessage());
            throw new RuntimeException(e);
        }
    }
}