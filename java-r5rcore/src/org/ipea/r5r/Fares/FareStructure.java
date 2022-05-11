package org.ipea.r5r.Fares;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategy;
import java.util.ArrayList;
import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public class FareStructure {

    /**
     * When fares are not found in farePerMode or farePerTransfer, the value of baseFare is used.
     */
    private float baseFare;
    @JsonIgnore
    private int integerBaseFare;

    /**
     * Maximum number of transfers that can have a discount. The transfer fare is obtained from the farePerTransfer
     * Map up to the number of transfers informed in this field. After that, each new leg gets the full fare from the
     * farePerMode Map.
     */
    private int maxDiscountedTransfers;

    /**
     * Maximum time allowed for discounted transfers, counting from the time of  boarding first transit leg
    */
    private int transferTimeAllowance;

    /**
     * Maximum charged fare for any combination of trips.
     */
    private int fareCap;

    private final List<FarePerMode> faresPerMode;
    private final List<FarePerTransfer> faresPerTransfer;
    private final List <FarePerRoute> faresPerRoute;

    // Getters and Setters
    public float getBaseFare() {
        return baseFare;
    }

    public int getIntegerBaseFare() {
        return integerBaseFare;
    }

    public void setBaseFare(float baseFare) {
        this.baseFare = baseFare;
        this.integerBaseFare = Math.round(baseFare * 100.0f);
    }

    public int getMaxDiscountedTransfers() {
        return maxDiscountedTransfers;
    }

    public void setMaxDiscountedTransfers(int maxDiscountedTransfers) {
        this.maxDiscountedTransfers = maxDiscountedTransfers;
    }

    public int getTransferTimeAllowance() {
        return transferTimeAllowance;
    }

    public void setTransferTimeAllowance(int transferTimeAllowance) {
        this.transferTimeAllowance = transferTimeAllowance;
    }

    public int getFareCap() {
        return fareCap;
    }

    public void setFareCap(int fareCap) {
        this.fareCap = fareCap;
    }

    public List<FarePerMode> getFaresPerMode() {
        return faresPerMode;
    }
    public List<FarePerTransfer> getFaresPerTransfer() {
        return faresPerTransfer;
    }
    public List<FarePerRoute> getFaresPerRoute() {
        return faresPerRoute;
    }

    public FareStructure() {
        this(100);
    }

    public FareStructure(float fare) {
        this.baseFare = fare;
        this.integerBaseFare = Math.round(fare * 100.0f);

        this.maxDiscountedTransfers = 1;
        this.transferTimeAllowance = 120;
        this.fareCap = -1;

        this.faresPerMode = new ArrayList<>();
        this.faresPerTransfer = new ArrayList<>();
        this.faresPerRoute = new ArrayList<>();
    }

    public static FareStructure fromJson(String data) {
        ObjectMapper objectMapper = new ObjectMapper();
        try {
            objectMapper.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
            return objectMapper.readValue(data, FareStructure.class);
        } catch (JsonProcessingException e) {
            e.printStackTrace();
            return null;
        }
    }

    public String toJson() {
        ObjectMapper objectMapper = new ObjectMapper();
        try {
            objectMapper.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
            return objectMapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }

        return "";
    }

}
