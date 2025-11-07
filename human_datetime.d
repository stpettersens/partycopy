/* Simple functions for working with human readable dates and times for D (dlang).
   Written by Sam Saint-Pettersen, 2025.

   Released to Public domain. Use as you wish.
*/

import std.uni;
import std.stdio;
import std.array;
import std.format;
import std.datetime;
import std.datetime.timezone;
import std.conv : to;

struct DateTimeTZ {
    int day;
    int month;
    int year;
    int hh;
    int mm;
    int ss;
    Tz tz;
    bool error;
}

enum HumanDateStyle {
    DD_MON_YYYY = 0,
    MON_DD_YYYY = 1,
    YYYY_MON_DD = 2,

    DD_MONTH_YYYY = 3,
    MONTH_DD_YYYY = 4,
    YYYY_MONTH_DD = 5,

    DD_MM_YYYY = 6,
    MM_DD_YYYY = 7,
    YYYY_MM_DD = 8,

    DD_MM_YY = 9,
    MM_DD_YY = 10,
    YY_MM_DD = 11,

    DASHED_YYYY_MON_DD = 12
}

enum ShortMonth {
    JAN = 1,
    FEB = 2,
    MAR = 3,
    APR = 4,
    MAY = 5,
    JUN = 6,
    JUL = 7,
    AUG = 8,
    SEP = 9,
    OCT = 10,
    NOV = 11,
    DEC = 12
}

enum LongMonth {
    JANUARY = 1,
    FEBRUARY = 2, // 28 or 29 days.
    MARCH = 3,
    APRIL = 4, // 30 days.
    MAY = 5,
    JUNE = 6, // 30 days.
    JULY = 7,
    AUGUST = 8,
    SEPTEMBER = 9, // 30 days.
    OCTOBER = 10,
    NOVEMEBER = 11, // 30 days.
    DECEMBER = 12
}

enum Tz {
    EST = -5,
    EDT = -4,
    ART = -3,
    GST = -2,
    CVT = -1,
    UTC = 0,
    CET = 1,
    EET = 2,
    AST = 3,
    AMT = 4,
    PKT = 5,
    OMST = 6,
    KRAT = 7,
    IRKST = 8,
    YAKT = 9,
    VLAT = 10,
    MAGT = 11,
    PET = 12
}

Tz get_timezone(string timezone) {
    Tz tz = Tz.UTC;

    // Map equivalent timezones to the master Tz enum.
    switch (timezone.toUpper) {
        case "ACT":
        case "CDT":
        case "COT":
        case "EASST":
        case "ECT":
        case "PET":
            tz = Tz.EST; // -5
            break;

        case "VET":
            tz = Tz.EDT; // -4
            break;

        case "ADT":
        case "AMST":
        case "ART":
        case "BRT":
        case "CLST":
        case "FKST":
        case "GFT":
        case "PMST":
        case "PYST":
        case "ROTT":
        case "SRT":
        case "UYT":
        case "WGST":
            tz = Tz.ART; // -3
            break;

        case "Z":
        case "GMT":
        case "WET":
        case "AZOST":
        case "EGST":
            tz = Tz.UTC; // 0
            break;

        case "BST":
        case "IST":
        case "WAT":
        case "WEST":
            tz = Tz.CET; // + 1
            break;

        case "CEST":
        case "KALT":
            tz = Tz.EET; // + 2
            break;

        case "EEST":
        case "MSK":
            tz = Tz.AST; // + 3
            break;

        case "AZT":
        case "GET":
        case "GST":
        case "MUT":
        case "RET":
        case "SAMT":
        case "SCT":
        case "VOLT":
            tz = Tz.AMT; // + 4
            break;

        case "HMT":
        case "MAWT":
        case "MVT":
        case "ORAT":
        case "TFT":
        case "TJT":
        case "TMT":
        case "UZT":
        case "YEKT":
            tz = Tz.PKT; // + 5
            break;

        case "BTT":
        case "XJT":
        case "KGT":
            tz = Tz.OMST; // + 6
            break;

        case "ICT":
        case "IWST":
        case "HOVT":
        case "NOVT":
            tz = Tz.KRAT; // + 7
            break;

        case "AWST":
        case "BNT":
        case "CST":
        case "ICST":
        case "MYT":
        case "CHOT":
        case "ULAT":
        case "PHT":
        case "SST":
        case "TST":
            tz = Tz.IRKST; // + 8
            break;

        case "TLT":
        case "IEST":
        case "JST":
        case "PWT":
        case "KST":
            tz = Tz.YAKT; // + 9
            break;

        case "AEST":
        case "CHUT":
        case "PGT":
            tz = Tz.VLAT; // + 10
            break;

        case "AEDT":
        case "LHST":
        case "PONT":
        case "SAKT":
        case "SBT":
        case "VUT":
            tz = Tz.MAGT; // + 11
            break;

        case "FJT":
        case "GILT":
        case "MHT":
        case "NRT":
        case "TVT":
            tz = Tz.PET; // + 12
            break;

        default: // Resolve as is.
            tz = to!Tz(timezone.toUpper);
            break;
    }

    return tz;
}

bool is_leap_year(int year) {
    bool leap = false;
    if (year % 4 == 0)
        leap = true;

    if (year % 100 == 0 && year % 400 != 0)
        leap = false;

    return leap;
}

// Common method so that we can define other functions in the future.
// Not just get Unix timestamps.
private DateTimeTZ create_datetime_tz(string human_datetime, HumanDateStyle style) {
    DateTimeTZ date;
    long unixtime = 0L;

    if (style == HumanDateStyle.DASHED_YYYY_MON_DD) {
        human_datetime = human_datetime.replace("-", " ");
        style = HumanDateStyle.YYYY_MON_DD;
    }

    string[] in_date = human_datetime.split();
    int d = 0;
    int m = 0;
    int y = 0;

    int hh = 0;
    int mm = 0;
    int ss = 0;

    Tz tz = Tz.UTC; // Default to UTC.

    try {
        if (in_date.length == 5)
            tz = get_timezone(in_date[4]);

        switch (style) {
            case HumanDateStyle.DD_MON_YYYY:
                d = to!int(in_date[0]);
                m = to!ShortMonth(in_date[1].toUpper);
                y = to!int(in_date[2]);
                break;

            case HumanDateStyle.MON_DD_YYYY:
                m = to!ShortMonth(in_date[0].toUpper);
                d = to!int(in_date[1]);
                y = to!int(in_date[2]);
                break;

            case HumanDateStyle.YYYY_MON_DD:
                y = to!int(in_date[0]);
                m = to!ShortMonth(in_date[1].toUpper);
                d = to!int(in_date[2]);
                break;

            case HumanDateStyle.DD_MONTH_YYYY:
                d = to!int(in_date[0]);
                m = to!LongMonth(in_date[1].toUpper);
                y = to!int(in_date[2]);
                break;

            case HumanDateStyle.MONTH_DD_YYYY:
                m = to!LongMonth(in_date[0].toUpper);
                d = to!int(in_date[1]);
                y = to!int(in_date[2]);
                break;

            case HumanDateStyle.YYYY_MONTH_DD:
                y = to!int(in_date[0]);
                m = to!LongMonth(in_date[1].toUpper);
                d = to!int(in_date[2]);
                break;

            case HumanDateStyle.DD_MM_YYYY:
                d = to!int(in_date[0]);
                m = to!int(in_date[1]);
                y = to!int(in_date[2]);
                break;

            case HumanDateStyle.MM_DD_YYYY:
                m = to!int(in_date[0]);
                d = to!int(in_date[1]);
                y = to!int(in_date[2]);
                break;

            case HumanDateStyle.YYYY_MM_DD:
                y = to!int(in_date[0]);
                m = to!int(in_date[1]);
                d = to!int(in_date[2]);
                break;

             // Short year dates start at 2000 and end at 2099
             // (i.e. 00 is 2000 and 99 is 2099).
            case HumanDateStyle.DD_MM_YY:
                d = to!int(in_date[0]);
                m = to!int(in_date[1]);
                y = (2000 + to!int(in_date[2]));
                break;

            case HumanDateStyle.MM_DD_YY:
                m = to!int(in_date[0]);
                d = to!int(in_date[1]);
                y = (2000 + to!int(in_date[2]));
                break;

            case HumanDateStyle.YY_MM_DD:
                y = (2000 + to!int(in_date[0]));
                m = to!int(in_date[1]);
                d = to!int(in_date[2]);
                break;

            default:
                break;
        }

        // February constraints.
        if (m == 2) {
            int max = is_leap_year(y) ? 29 : 28;
            if (d > max || d < 1)
                throw new Exception(format("February in %d can only have 1-%d days.", y, max));
        }

        // April, June, September, November contraints.
        if ((d > 30 || d < 1) && (m == 4 || m == 6 || m == 9 || m == 11)) {
            throw new Exception("April, June, September or November can only have 1-30 days.");
        }

        // Any other month constraints.
        if (d > 31 || d < 1) {
            throw new Exception("A month can only have 1-31 days.");
        }

        string[] time = in_date[3].split(':');

        hh = to!int(time[0]);
        mm = to!int(time[1]);
        ss = to!int(time[2]);

        if (hh < 0 || hh > 23) {
            throw new Exception("Hour must be between 0-23.");
        }

        if (mm < 0 || mm > 59) {
            throw new Exception("Minutes must be between 0-59.");
        }

        if (ss < 0 || ss > 59) {
            throw new Exception("Seconds must be between 0-59.");
        }
    }
    catch (Exception e) {
        writeln("Invalid date and/or time provided.");
        writeln(e);
        date.error = true;
        return date;
    }

    date.year = y;
    date.month = m;
    date.day = d;
    date.hh = hh;
    date.mm = mm;
    date.ss = ss;
    date.tz = tz;
    date.error = false;
    return date;
}

// Use long as return type as this supports unix timestamps
// beyond year 2038.
long human_to_unix(string human_datetime, HumanDateStyle style) {
    DateTimeTZ date = create_datetime_tz(human_datetime, style);
    if (date.error)
        return -1;

    // Unix time constraint.
    if (date.year < 1970) {
        writeln("Error: Dates before 1970 cannot be used to determine Unix timestamp.");
        return -1;
    }

    long unixtime = SysTime(DateTime(date.year, date.month, date.day, date.hh, date.mm, date.ss),
    new immutable SimpleTimeZone(dur!"hours"(date.tz), to!string(date.tz))).toUnixTime();

    return unixtime;
}

long human_to_unix(string human_datetime) {
    return human_to_unix(human_datetime, HumanDateStyle.DD_MON_YYYY);
}
