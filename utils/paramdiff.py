
# paramsdiff.py: compare ArduPilot param file in MissionPlanner format to another param file, log file or live MAVLink connection

from pymavlink import mavutil
import functools
import pytest
import argparse
import math
import os.path
import sys


class Params(dict):
    """A dictionary of parsed parameters, with a name and can diff against another instance"""
    ABS_TOL = 0.000001
    def __init__(self, name):
        self.name = name
    def longest_p_len(self):
        return max(map(len, self.keys()))
    def longest_v_len(self):
        return max(map(len, map(str_value, self.values())))
    def print_diff(self, other):
        diff = Params(None)
        for p, v in self.items():
            try:
                if not math.isclose(v, other[p], abs_tol=self.ABS_TOL):
                    diff[p] = v
            except KeyError:
                diff[p] = v
        if diff:
            print(f"   {self.name:>{diff.longest_p_len()+diff.longest_v_len()}} | {other.name}")
        for p, v in diff.items():
            print(f"{p:<{diff.longest_p_len()}} = {str_value(self[p]):<{self.longest_v_len()}} | {str_value(other[p])}")
def test_Params():
    p = Params("local")
    p["a"] = 1
    p["ab"] = 123
    p["b"] = 2
    assert p.name == "local"
    assert p["a"] == 1
    assert p.longest_p_len() == 2
    assert p.longest_v_len() == 3

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
    # All values are numeric; Parameters have types (signed and
    # unsigned ints of various widths, floats). MissionPlanner ignores
    # these types when writing parameters to files; it writes them
    # with or without a decimal point depending on values rather than
    # types. Type information is lost in MP files. Consequently, there
    # is no advantage in trying to deduce type from format, and I
    # treat all values as floats.
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
    params = Params(os.path.basename(f.name))
    for n, l in enumerate(f.readlines(), 1):
        p, nv = parse_param_line(l, n)
        if p:
            params[p] = nv
    return params

def params_from_log_file(fp):
    log = mavutil.mavlink_connection(fp)
    params = Params(os.path.basename(fp))
    while (msg := log.recv_match(type="PARAM_VALUE")):
        params[msg.param_id] = msg.param_value
    return params


if __name__ == "__main__":
    argp = argparse.ArgumentParser()
    argp.add_argument("-l", "--log", required=True)
    argp.add_argument("infile", type=argparse.FileType('r'))
    args = argp.parse_args()

    params_from_param_file(args.infile).print_diff(params_from_log_file(args.log))
