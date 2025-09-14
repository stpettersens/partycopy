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

int upload_file_to_copyparty(bool verbose, copyparty_server* s, string dir, string file) {
    string endpoint = format("%s://%s/%s/", s.proto, s.domain, dir);
    string curl_switch = "";

    version(Windows) {
        curl_switch = " -k";
    }

    string request1 = format("curl%s -s -I %s%s --user %s:%s",
    curl_switch,
    endpoint,
    file,
    s.username,
    s.password);

    auto exists = executeShell(request1);

    if (verbose) {
        writefln(request1);
        writeln(exists.output);
    }

    if (exists.status != 0) {
        writefln("Failed to check existence of remote file: '%s'.", file);
        return -1;
    }

    // If the file exists, delete it first
    // before uploading the replacement file.
    if (canFind(strip(exists.output), "OK")) {
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
    return 0;
}

copyparty_server read_server_cfg(string server_name) {
    copyparty_server s;
    string cfg = format("/etc/partycopy/%s.cfg", server_name);
    version(Windows) {
        cfg = buildPath(getcwd(), format("%s.cfg", server_name));
    }

    if (cfg.exists) {
        auto f = File(cfg);
        foreach (line; f.byLine()) {
            string l = to!string(line);
            if (l.startsWith("#")) {
                // Ignore any comment lines.
                continue;

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
        }

        s.none = false;
        return s;
    }

    writefln("Aborting, there was no server configuration for server named '%s'", server_name);
    s.none = true;
    return s;
}

int run_partycopy(bool verbose, string server_name, string file, string remote_dir) {
    copyparty_server server_cfg = read_server_cfg(server_name);
    if (server_cfg.none)
        return -1;

    writefln("Uploading '%s' to copyparty server '%s' remote directory '%s'.",
    baseName(file), server_name,  remote_dir);
    writeln();

    return upload_file_to_copyparty(verbose, &server_cfg, remote_dir, baseName(file));
}

int display_error(string program, string message) {
    writefln("Error: %s.\n", message);
    return display_usage(program, -1);
}

int display_usage(string program, int exit_code) {
    writeln("Partycopy: simple file transfer utility for copyparty servers.");
    writeln("Written by Sam Saint-Pettersen, September 2025.");
    writefln("\nUsage: %s <server_name> <local_file> <remote_directory> [\"--verbose\"]", program);
    writeln();
    return exit_code;
}

int main(string[] args) {
    bool verbose = false;
    immutable string program = args[0];
    if (args.length == 1)
        return display_usage(program, 0);
    else if (args.length < 4) {
        return display_error(program, "Not enough parameters given");
    }

    if (args.length == 5 && args[4] == "--verbose") verbose = true;

    return run_partycopy(verbose, args[1], args[2], args[3]);
}
