"""Turns Roblox's API-Dump.json into api.luau: every class's properties,
methods and events plus every enum, so the mock can reject typos."""

import json
import sys


def q(s):
    return json.dumps(s, ensure_ascii=False)


def main(dump_path, out_path):
    with open(dump_path, encoding="utf-8") as f:
        dump = json.load(f)
    out = ["return {", "classes = {"]
    for c in dump["Classes"]:
        props, ro, funcs, events, callbacks = [], [], [], [], []
        for m in c["Members"]:
            kind, name, tags = m["MemberType"], m["Name"], m.get("Tags") or []
            if kind == "Property":
                props.append(name)
                if "ReadOnly" in tags:
                    ro.append(name)
            elif kind == "Function":
                funcs.append(name)
            elif kind == "Event":
                events.append(name)
            elif kind == "Callback":
                callbacks.append(name)
        tags = c.get("Tags") or []

        def names(items):
            return ",".join(f"[{q(n)}]=true" for n in items)

        out.append(
            f"[{q(c['Name'])}]={{super={q(c['Superclass'])},"
            f"creatable={'false' if 'NotCreatable' in tags else 'true'},"
            f"service={'true' if 'Service' in tags else 'false'},"
            f"props={{{names(props)}}},ro={{{names(ro)}}},"
            f"funcs={{{names(funcs)}}},events={{{names(events)}}},"
            f"callbacks={{{names(callbacks)}}}}},"
        )
    out += ["},", "enums = {"]
    for e in dump["Enums"]:
        items = ",".join(f"[{q(i['Name'])}]={i['Value']}" for i in e["Items"])
        out.append(f"[{q(e['Name'])}]={{{items}}},")
    out += ["},", "}"]
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(out))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
