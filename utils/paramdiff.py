
# paramsdiff.py: compare ArduPilot param file to another param file, log file or live MAVLink connection

from pymavlink import mavutil
import tempfile
import subprocess
import pytest
import argparse
import sys

def parse_param_line(l, n):
    head = l.rstrip("\r\n")
    if (head.startswith("#")):
        # comment (comments must start at the beginning of a line)
        return None, head
    if head.strip() != head:
        raise ValueError(f"unexpected whitespace in '{head}' (line {n})")
    try:
        p,v = head.split(",")
    except ValueError as e:
        raise ValueError(f"expecting 'PARAM,VALUE', found '{head}' (line {n})") from None
    if p.strip() != p or v.strip() != v:
        raise ValueError(f"unexpected whitespace in '{head}' (line {n})")
    try:
        nv = int(v)
    except ValueError as e:
        try:
            nv = float(v)
        except ValueError as e:
            raise ValueError(f"expecting numeric value, found '{v}' (line {n})") from None
    return p, nv

def test_parse_param_line():
    assert parse_param_line("FOO,100", 0) == ("FOO", 100)
    assert parse_param_line("FOO,100.5", 0) == ("FOO", 100.5)
    assert parse_param_line("# comment\r", 0) == (None, "# comment")
    with pytest.raises(ValueError) as e:
        parse_param_line(" # indented comment", 1)
    assert e.value.args[0] == "unexpected whitespace in ' # indented comment' (line 1)"
    with pytest.raises(ValueError) as e:
        parse_param_line(" FOO,BAR ", 1)
    assert e.value.args[0] == "unexpected whitespace in ' FOO,BAR ' (line 1)"
    with pytest.raises(ValueError) as e:
        parse_param_line("FOO,BAR,BAZ", 1)
    assert e.value.args[0] == "expecting 'PARAM,VALUE', found 'FOO,BAR,BAZ' (line 1)"
    with pytest.raises(ValueError) as e:
        parse_param_line("FOO", 1)
    assert e.value.args[0] == "expecting 'PARAM,VALUE', found 'FOO' (line 1)"
    with pytest.raises(ValueError) as e:
        parse_param_line("FOO ,BAR", 1)
    assert e.value.args[0] == "unexpected whitespace in 'FOO ,BAR' (line 1)"
    with pytest.raises(ValueError) as e:
        parse_param_line("FOO, BAR", 1)
    assert e.value.args[0] == "unexpected whitespace in 'FOO, BAR' (line 1)"
    with pytest.raises(ValueError) as e:
        parse_param_line("FOO,string", 1)
    assert e.value.args[0] == "expecting numeric value, found 'string' (line 1)"

def str_value(v):
    # All values are numeric; Parameters have types (signed and
    # unsigned ints of various widths, floats). MissionPlanner ignores
    # these types when writing parameters to files; it writes them
    # with or without a decimal point depending on values rather than
    # types.
    return f"{v:g}"

def test_str_value():
    assert str_value(0) == "0"
    assert str_value(0.0) == "0"
    assert str_value(0.1) == "0.1"

def write_param_line(f, param_name, value):
    return f.write(param_name + "," + str_value(value) + "\r\n")
    
def params_from_param_file(f):
    params = {}
    for n, l in enumerate(f.readlines(), 1):
        p, nv = parse_param_line(l, n)
        if p:
            params[p] = nv
    return params

def params_from_log_file(f):
    log = mavutil.mavlink_connection(f)
    params = {}
    while (msg := log.recv_match(type="PARAM_VALUE")):
        params[msg.param_id] = msg.param_value
    return params

def diff_params(local, master):
    with tempfile.NamedTemporaryFile("w") as local_f, tempfile.NamedTemporaryFile("w") as master_f:
        for p, v in local.items():
            write_param_line(local_f, p, v)
            try:
                master_v = master[p]
                write_param_line(master_f, p, master_v)
            except KeyError:
                # parameter present in local, absent in remote
                #
                # printing an empty line instead of skipping the
                # parameter altogether helps side-by-side diff(1)
                # associate relevant lines in remove and local
                master_f.write("\r\n")
        local_f.flush()
        master_f.flush()
        print(f"{'local':<30}  log")
        subprocess.run(args=["diff", "-d", "--side-by-side", "-W60", "--suppress-common-lines", local_f.file.name, master_f.file.name])
        #subprocess.run(args=["diff", "-u0", "--color", "--label", "master", "--label", "local", master_f.file.name, local_f.file.name])


if __name__ == "__main__":
    argp = argparse.ArgumentParser()
    argp.add_argument("-l", "--log", required=True)
    argp.add_argument("infile", type=argparse.FileType('r'))
    args = argp.parse_args()

    diff_params(params_from_param_file(args.infile),
                params_from_log_file(args.log))
