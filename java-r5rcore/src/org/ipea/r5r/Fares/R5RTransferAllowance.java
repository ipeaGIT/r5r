package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.TransferAllowance;

public class R5RTransferAllowance extends TransferAllowance  {
    public final int fareType;

    public R5RTransferAllowance(int fareType, int value, int number, int expirationTime){
        super(value, number, expirationTime);
        this.fareType = fareType;
    }

    public R5RTransferAllowance tightenExpiration(int maxClockTime){
        // cap expiration time of transfer at max clock time of search, so that transfer slips that technically have more time
        // remaining, but that time cannot be used within the constraints of this search, can be pruned.
        return new R5RTransferAllowance(this.fareType, this.value, this.number, Math.min(this.expirationTime, maxClockTime));

    }

    /**
     * Is this transfer allowance as good as or better than another transfer allowance? This does not consider the fare
     * paid so fare, and can be thought of as follows. If you are standing at a stop, and a perfectly trustworthy person
     * comes up to you and offers you two tickets, one with this transfer allowance, and one with the other transfer
     * allowance, is this one as good as or better than the other one for any trip that you might make? (Assume you have
     * no moral scruples about obtaining a transfer slip from someone else who is probably not supposed to be giving
     * them away).
     *
     * In the base class, this is true iff this transfer allowance has the same or higher value, and the same or later
     * expiration time, the same or higher number of transfers remaining. In subclasses for transit systems that have
     * different services, this may need to be overridden because not all transfer allowances are comparable. For example,
     * in Greater Boston, transfers from local bus can be applied to local bus, subway, or express bus; transfers from
     * subway can be applied to other subway services at the same station, local bus, or express bus, and transfers from
     * express bus can be applied to only local bus or subway. So the values of those three types of transfers are not
     * comparable.
     */
    public boolean atLeastAsGoodForAllFutureRedemptions(R5RTransferAllowance other){
        if (fareType != other.fareType) return false;
        return value >= other.value && expirationTime >= other.expirationTime && number >= other.number;
    }


}
