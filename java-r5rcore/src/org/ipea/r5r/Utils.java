package org.ipea.r5r;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.LoggerContext;
import org.slf4j.LoggerFactory;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

public class Utils {

    public static int getSecondsFromMidnight(String departureTime) throws ParseException {
        DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss");
        Date reference = dateFormat.parse("00:00:00");
        Date date = dateFormat.parse(departureTime);
        return (int) ((date.getTime() - reference.getTime()) / 1000L);
    }

    public static void setLogMode(String mode) {
        LoggerContext loggerContext = (LoggerContext) LoggerFactory.getILoggerFactory();

        Logger logger = loggerContext.getLogger("com.conveyal.r5");
        logger.setLevel(Level.valueOf(mode));

        logger = loggerContext.getLogger("com.conveyal.osmlib");
        logger.setLevel(Level.valueOf(mode));

        logger = loggerContext.getLogger("com.conveyal.gtfs");
        logger.setLevel(Level.valueOf(mode));

        logger = loggerContext.getLogger("com.conveyal.r5.profile.ExecutionTimer");
        logger.setLevel(Level.valueOf(mode));

        logger = loggerContext.getLogger("org.ipea.r5r.R5RCore");
        logger.setLevel(Level.valueOf(mode));
    }
}
