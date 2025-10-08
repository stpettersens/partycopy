/*
  Partycopy (partycopy/pcp)
  Simple CLI file transfer utility for copyparty servers.

  Author: Sam Saint-Pettersen, September/October 2025.
  s.stpettersen+github at gmail dot com
  https://stpettersen.xyz

  This program is public domain.
  See LICENSE file (Unlicense).

  This is not an official project of Copyparty.
*/

import std.file;
import std.path;
import std.conv;
import std.stdio;
import std.string;
import std.process;
import std.algorithm;

struct copyparty_server {
    string username;
    string password;
    string proto;
    string domain;
    string want_format;
    bool none;
}

enum Op {
    PUT = 0,
    DEL = 1,
    GET = 2
}

string get_exe(string program) {
    string[] path = program.split("\\");
    return path[(path.length - 1)];
}

int interact_with_copyparty(bool verbose, Op operation, string server_name,
copyparty_server* s, string dir, string file) {
    string endpoint = format("%s://%s/%s/", s.proto, s.domain, dir);
    string curl_switch = "";

    version(Windows) {
        curl_switch = " -k";
    }

    // Op GET to download a remote file.
    if (operation == Op.GET) {
        string request0 = format("curl%s -s -O %s%s --user %s:%s",
        curl_switch,
        endpoint,
        file,
        s.username,
        s.password);

        executeShell(request0);

        if (verbose) {
            writeln(request0);
            writeln();
        }

        bool fforbidden = false;
        bool fexists = true;
        if (exists(file)) {
            auto f = File(file);
            foreach (line; f.byLine()) {
                string l = to!string(line);
                if (l.startsWith("403 forbidden")) {
                    fforbidden = true;
                    break;
                }
                if (l.startsWith("404 not found")) {
                    fexists = false;
                    break;
                }
            }
        }

        if (fforbidden) {
            writefln("Failed to download remote file: '%s'", file);
            writefln("from copyparty server '%s' remote '%s' as Forbidden.", server_name, dir);
            writefln("PLEASE CHECK YOUR USERNAME AND PASSWORD.");
            remove(file);
            return -1;
        }

        if (!fexists) {
            writefln("Failed to download non-existant remote file: '%s'", file);
            writefln("from copyparty server '%s' remote dir '%s'.", server_name, dir);
            writeln();
            remove(file);
            return -1;
        }
        else {
            writefln("Downloading remote file: '%s' from copyparty server '%s' remote dir '%s'.",
            file, server_name, dir);
            writeln();
            return 0;
        }
    }

    string request1 = format("curl%s -s -I %s%s --user %s:%s",
    curl_switch,
    endpoint,
    file,
    s.username,
    s.password);

    auto exists = executeShell(request1);

    if (verbose) {
        writeln(request1);
        writeln(exists.output);
        writeln();
    }

    if (exists.status != 0) {
        writefln("Failed to check existence of remote file: '%s'.", file);
        writeln();
        return -1;
    }

    if (operation == Op.PUT) {
        // Check file exists locally before attempting to upload it.
        if (!file.exists) {
            writefln("Error: File '%s' does not exist locally.", file);
            return -1;
        }

        writefln("Uploading '%s' to copyparty server '%s' remote directory '%s'.",
        file, server_name, dir);
        writeln();
    }

    // PUT Op: If the file exists, delete it first before uploading the replacement file.
    // DEL Op: Just delete the file if it exists.
    if (operation == Op.PUT || operation == Op.DEL) {
        if (operation == Op.DEL && canFind(strip(exists.output), "OK")) {
            writefln("Deleting '%s' from copyparty server '%s' remote directory '%s'.",
            file, server_name, dir);
            writeln();
        }
        else if (operation == Op.DEL) {
            writefln("Remote file '%s' from copyparty server '%s' remote directory '%s'",
            file, server_name, dir);
            writeln("does not exist, so cannot delete it.");
            writeln();
            return -1;
        }

        string request2 = format("curl%s -s -X DELETE %s%s --user %s:%s",
        curl_switch,
        endpoint,
        file,
        s.username,
        s.password);

        auto _delete = executeShell(request2);

        if (verbose) {
            writeln(request2);
            writeln(_delete.output);
        }

        if (_delete.status != 0) {
            writefln("Failed to delete remote file: '%s'.", file);
            return -1;
        }
    }

    if (operation == Op.PUT) {
        string request3 = format("curl%s -s -u %s:%s -F f=@%s %s",
        curl_switch,
        s.username,
        s.password,
        file,
        endpoint);

        request3 ~= format("?want=%s", s.want_format);
        request3 ~= " | jq .status";

        auto upload = executeShell(request3);

        if (verbose) writeln(request3);
        if (upload.status != 0) {
            writefln("Failed to upload file: '%s'.", file);
            writefln("Server status: %s", upload.output);
            return -1;
        }

        writefln("Uploaded file: '%s'.", file);
        writefln("Server status: %s", upload.output);
    }

    return 0;
}

copyparty_server read_server_cfg(string program, string server_name) {
    copyparty_server s;
    string cfg = format("/etc/partycopy/%s.cfg", server_name);
    version(Windows) {
        string exe = format("\\%s", get_exe(program));
        string dir = to!string(thisExePath()).replace(exe, "");
        cfg = buildPath(dir, format("%s.cfg", server_name));
    }

    if (cfg.exists) {
        auto f = File(cfg);
        foreach (line; f.byLine()) {
            string l = to!string(line);

            if (l.startsWith("#")) {
                // Ignore any comment lines.
                continue;
            }

            if (s.username.length == 0)
                s.username = to!string(l);

            else if (s.password.length == 0)
                s.password = to!string(l);

            else if (s.proto.length == 0)
                s.proto = to!string(l);

            else if (s.domain.length == 0)
                s.domain = to!string(l);

            else if (s.want_format.length == 0)
                s.want_format = to!string(l).toLower();
        }

        s.none = false;
        return s;
    }

    writefln("Aborting, there was no server configuration for server named '%s'", server_name);
    s.none = true;
    return s;
}

int run_partycopy(string program, Op operation, bool verbose,
string server_name, string file, string remote_dir) {
    copyparty_server server_cfg = read_server_cfg(program, server_name);
    if (server_cfg.none)
        return -1;

    return interact_with_copyparty
    (verbose, operation, server_name, &server_cfg, remote_dir, baseName(file));
}

int display_error(string program, string message) {
    writefln("Error: %s.\n", message);
    return display_usage(program, -1);
}

int display_usage(string program, int exit_code) {
    writeln("Partycopy: simple file transfer utility for copyparty servers.");
    writeln("Written by Sam Saint-Pettersen <s.stpettersen+github at gmail dot com>");
    writefln("\nUsage: %s [\"usage\"|\"help\"|\"version\"] [<server_name> <file> <remote_directory> [op = PUT] [\"verbose\"]]", program);
    writeln();
    writeln("Switches");
    writeln("usage|help: Display usage information and exit.");
    writeln("version: Display version information and exit.");
    writeln();
    writeln("Ops:");
    writeln("0 (PUT): Upload a file <file> (default action if omitted)");
    writeln("1 (DEL): Delete a remote file <file>.");
    writeln("2 (GET): Download a remote file <file>.");
    writeln();
    return exit_code;
}

int display_version(string program) {
    writefln("Partycopy (%s) v0.1.0 (2025-10-08)", get_exe(program));
    return 0;
}

int main(string[] args) {
    immutable string program = args[0];
    bool verbose = false;
    Op operation = Op.PUT;

    if (args.length == 2 && args[1] == "version") {
        return display_version(program);
    }
    else if (args.length == 2 && (args[1] == "usage" || args[1] == "help")) {
        return display_usage(program, 0);
    }
    else if (args.length < 4) {
        return display_error(program, "Not enough parameters given");
    }
    else if (args.length > 4) {
        try {
            int iop = -1;
            if (!isNumeric(args[4])) {
                switch (args[4]) {
                    case "PUT":
                        iop = 0;
                        break;

                    case "DEL":
                        iop = 1;
                        break;

                    case "GET":
                        iop = 2;
                        break;

                    default:
                        return display_error(program,
                        "Invalid operation: Must be between PUT, DEL or GET");
                }
            }
            else iop = to!int(args[4]);

            if (iop < 0 || iop > 2) {
                return display_error
                (program, "Invalid operation: Must be between 0 and 2");
            }
            operation = cast(Op)iop;
        }
        catch (Exception e) {
            return display_error
            (program, format("Invalid operation:\n%s", e.msg));
        }
    }

    if (args.length == 6 && args[5] == "verbose")
        verbose = true;

    return run_partycopy(args[0], operation, verbose, args[1], args[2], args[3]);
}
