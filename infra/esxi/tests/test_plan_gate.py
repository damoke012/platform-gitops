"""Tests for the plan gate. It is the only thing between a push and a power-cycled control plane."""
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))
from plan_gate import evaluate  # noqa: E402

NODES = {
    "cp-1": {"vmid": "140", "ip": "192.168.22.201", "numvcpus": 4, "memsize_mb": 16384},
    "cp-2": {"vmid": "93", "ip": "192.168.22.202", "numvcpus": 8, "memsize_mb": 24576},
}
BASE = {"guest_name": "ocp-cp-2", "numvcpus": "4", "memsize": "16384", "power": "on",
        "boot_firmware": "efi", "ip_address": "192.168.22.202"}


def rc(key, actions, before=None, after=None, importing=False, unknown=None):
    change = {"actions": actions, "before": before, "after": after, "after_unknown": unknown or {}}
    if importing:
        change["importing"] = {"id": NODES[key]["vmid"]}
    return {"address": f'esxi_guest.cp["{key}"]', "mode": "managed", "type": "esxi_guest",
            "index": key, "change": change}


def plan(*rcs):
    return {"resource_changes": list(rcs), "output_changes": {"nodes": {"after": NODES}}}


class Gate(unittest.TestCase):
    def test_pure_import_allowed(self):
        s, e = evaluate(plan(rc("cp-1", ["no-op"], BASE, BASE, importing=True)))
        self.assertEqual(e, [])
        self.assertEqual(s["imports"], ["cp-1"])
        self.assertEqual(s["disruptive"], [])

    def test_resize_is_disruptive(self):
        after = dict(BASE, numvcpus="8", memsize="24576")
        s, e = evaluate(plan(rc("cp-2", ["update"], BASE, after, unknown={"ip_address": True})))
        self.assertEqual(e, [])
        self.assertEqual(s["disruptive"][0]["key"], "cp-2")
        self.assertEqual(s["disruptive"][0]["vmid"], "93")
        self.assertEqual(s["disruptive"][0]["changed"], ["memsize", "numvcpus"])

    def test_other_attr_refused(self):
        after = dict(BASE, boot_firmware="bios")
        _, e = evaluate(plan(rc("cp-2", ["update"], BASE, after)))
        self.assertTrue(any("boot_firmware" in x for x in e))

    def test_replace_refused(self):
        _, e = evaluate(plan(rc("cp-2", ["delete", "create"], BASE, BASE)))
        self.assertTrue(any("never allowed" in x for x in e))

    def test_create_and_delete_refused(self):
        for a in (["create"], ["delete"], ["create", "delete"], ["forget"]):
            _, e = evaluate(plan(rc("cp-2", a, BASE, BASE)))
            self.assertTrue(e, a)

    def test_import_mixed_with_resize_refused(self):
        after = dict(BASE, numvcpus="8")
        _, e = evaluate(plan(rc("cp-1", ["no-op"], BASE, BASE, importing=True),
                             rc("cp-2", ["update"], BASE, after)))
        self.assertTrue(any("separate" in x or "first" in x for x in e))

    def test_expect_node(self):
        after = dict(BASE, numvcpus="8")
        p = plan(rc("cp-2", ["update"], BASE, after))
        self.assertEqual(evaluate(p, "cp-2")[1], [])
        self.assertTrue(evaluate(p, "cp-1")[1])

    def test_unknown_resource_type_change_refused(self):
        other = {"address": "null_resource.x", "mode": "managed", "type": "null_resource",
                 "index": None, "change": {"actions": ["create"]}}
        _, e = evaluate(plan(other))
        self.assertTrue(e)


if __name__ == "__main__":
    unittest.main()
