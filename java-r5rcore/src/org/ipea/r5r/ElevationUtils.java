package org.ipea.r5r;

public class ElevationUtils {

    /** constants for slope computation */
    final static double tx[] = { 0.0000000000000000E+00, 0.0000000000000000E+00, 0.0000000000000000E+00,
            2.7987785324442748E+03, 5.0000000000000000E+03, 5.0000000000000000E+03,
            5.0000000000000000E+03 };
    final static double ty[] = { -3.4999999999999998E-01, -3.4999999999999998E-01, -3.4999999999999998E-01,
            -7.2695627831828688E-02, -2.4945814335295903E-03, 5.3500304527448035E-02,
            1.2191105175593375E-01, 3.4999999999999998E-01, 3.4999999999999998E-01,
            3.4999999999999998E-01 };
    final static double coeff[] = { 4.3843513168660255E+00, 3.6904323727375652E+00, 1.6791850199667697E+00,
            5.5077866957024113E-01, 1.7977766419113900E-01, 8.0906832222762959E-02,
            6.0239305785343762E-02, 4.6782343053423814E+00, 3.9250580214736304E+00,
            1.7924585866601270E+00, 5.3426170441723031E-01, 1.8787442260720733E-01,
            7.4706427576152687E-02, 6.2201805553147201E-02, 5.3131908923568787E+00,
            4.4703901299120750E+00, 2.0085381385545351E+00, 5.4611063530784010E-01,
            1.8034042959223889E-01, 8.1456939988273691E-02, 5.9806795955995307E-02,
            5.6384893192212662E+00, 4.7732222200176633E+00, 2.1021485412233019E+00,
            5.7862890496126462E-01, 1.6358571778476885E-01, 9.4846184210137130E-02,
            5.5464612133430242E-02 };

    public static double bikeSpeedCoefficientOTP(double slope, double altitude) {
        /*
         * computed by asking ZunZun for a quadratic b-spline approximating some values from
         * http://www.analyticcycling.com/ForcesSpeed_Page.html fixme: should clamp to local speed
         * limits (code is from ZunZun)
         */

        int nx = 7;
        int ny = 10;
        int kx = 2;
        int ky = 2;

        double h[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
        double hh[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
        double w_x[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
        double w_y[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };

        int i, j, li, lj, lx, ky1, nky1, ly, i1, j1, l2;
        double f, temp;

        int kx1 = kx + 1;
        int nkx1 = nx - kx1;
        int l = kx1;
        int l1 = l + 1;

        while ((altitude >= tx[l1 - 1]) && (l != nkx1)) {
            l = l1;
            l1 = l + 1;
        }

        h[0] = 1.0;
        for (j = 1; j < kx + 1; j++) {
            for (i = 0; i < j; i++) {
                hh[i] = h[i];
            }
            h[0] = 0.0;
            for (i = 0; i < j; i++) {
                li = l + i;
                lj = li - j;
                if (tx[li] != tx[lj]) {
                    f = hh[i] / (tx[li] - tx[lj]);
                    h[i] = h[i] + f * (tx[li] - altitude);
                    h[i + 1] = f * (altitude - tx[lj]);
                } else {
                    h[i + 1 - 1] = 0.0;
                }
            }
        }

        lx = l - kx1;
        for (j = 0; j < kx1; j++) {
            w_x[j] = h[j];
        }

        ky1 = ky + 1;
        nky1 = ny - ky1;
        l = ky1;
        l1 = l + 1;

        while ((slope >= ty[l1 - 1]) && (l != nky1)) {
            l = l1;
            l1 = l + 1;
        }

        h[0] = 1.0;
        for (j = 1; j < ky + 1; j++) {
            for (i = 0; i < j; i++) {
                hh[i] = h[i];
            }
            h[0] = 0.0;
            for (i = 0; i < j; i++) {
                li = l + i;
                lj = li - j;
                if (ty[li] != ty[lj]) {
                    f = hh[i] / (ty[li] - ty[lj]);
                    h[i] = h[i] + f * (ty[li] - slope);
                    h[i + 1] = f * (slope - ty[lj]);
                } else {
                    h[i + 1 - 1] = 0.0;
                }
            }
        }

        ly = l - ky1;
        for (j = 0; j < ky1; j++) {
            w_y[j] = h[j];
        }

        l = lx * nky1;
        for (i1 = 0; i1 < kx1; i1++) {
            h[i1] = w_x[i1];
        }

        l1 = l + ly;
        temp = 0.0;
        for (i1 = 0; i1 < kx1; i1++) {
            l2 = l1;
            for (j1 = 0; j1 < ky1; j1++) {
                l2 = l2 + 1;
                temp = temp + coeff[l2 - 1] * h[i1] * w_y[j1];
            }
            l1 = l1 + nky1;
        }

        return temp;
    }


}
