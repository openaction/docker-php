# Converts the nginx and PHP-FPM output to JSON events, one per line, with a
# "source" field (awk -v source=nginx|php-fpm). JSON lines (nginx access log,
# application logs written by PHP-FPM workers) are kept as is, except the
# "x_forwarded_for" string of the nginx access log, converted to an array of
# IPs. Only warnings and errors are emitted: notices, deprecations and stack
# traces are dropped.

function emit(level, message) {
    # Join instead of gsub: awk implementations differ on backslashes in replacements
    count = split(message, parts, "\\")
    message = parts[1]
    for (i = 2; i <= count; i++) {
        message = message "\\\\" parts[i]
    }
    gsub(/"/, "\\\"", message)
    gsub(/\t/, "\\t", message)
    gsub(/[\001-\037]/, "", message)

    printf "{\"source\":\"%s\",\"level\":\"%s\",\"message\":\"%s\"}\n", source, level, message
    fflush()
}

# Empty lines and stack traces (exceptions are reported to Sentry)
/^[[:space:]]*$/ || /^(PHP )?Stack trace:/ || /^(PHP )?#[0-9]+ / || /^(PHP )?  thrown in / {
    next
}

# Already JSON
/^\{.*\}$/ {
    # nginx access log: "x_forwarded_for":"1.2.3.4, 10.0.0.1" becomes ["1.2.3.4","10.0.0.1"].
    # The value is already escaped by nginx, which never escapes commas.
    if (source == "nginx" && match($0, /"x_forwarded_for":"([^"\\]|\\.)*"/)) {
        count = split(substr($0, RSTART + 19, RLENGTH - 20), parts, ",")
        ips = ""
        for (i = 1; i <= count; i++) {
            gsub(/^ +| +$/, "", parts[i])
            if (parts[i] != "") {
                ips = ips (ips == "" ? "" : ",") "\"" parts[i] "\""
            }
        }
        $0 = substr($0, 1, RSTART - 1) "\"x_forwarded_for\":[" ips "]" substr($0, RSTART + RLENGTH)
    }

    print
    fflush()
    next
}

# nginx: "2026/10/19 20:00:00 [error] 12#12: *3 message" or "nginx: [warn] message"
match($0, /^([0-9]+\/[0-9]+\/[0-9]+ [0-9:]+ |nginx: )\[[a-z]+\] /) {
    level = substr($0, 1, RLENGTH - 2)
    sub(/^.*\[/, "", level)
    message = substr($0, RLENGTH + 1)
    sub(/^[0-9]+#[0-9]+: /, "", message)

    if (level == "warn") {
        emit("warning", message)
    } else if (level == "error" || level == "crit" || level == "alert" || level == "emerg") {
        emit("error", message)
    }
    next
}

# PHP errors: "PHP message: PHP Warning:  message" (PHP-FPM workers) or
# "[19-Oct-2026 20:00:00 Europe/Paris] PHP Warning:  message"
match($0, /^(\[[^]]*\] )?(PHP message: )?PHP [A-Za-z ]+:  ?/) {
    type = substr($0, 1, RLENGTH)
    message = substr($0, RLENGTH + 1)

    if (type ~ /Warning/) {
        emit("warning", message)
    } else if (type !~ /Notice|Deprecated|Strict/) {
        emit("error", message)
    }
    next
}

# PHP-FPM: "[19-Oct-2026 20:00:00] WARNING: [pool www] message"
match($0, /^(\[[^]]*\] )?(WARNING|ERROR|ALERT): /) {
    type = substr($0, 1, RLENGTH)
    emit(type ~ /WARNING/ ? "warning" : "error", substr($0, RLENGTH + 1))
    next
}

# Any other output, such as a truncated application log
{
    emit("warning", $0)
}
