#!/usr/bin/env python3
"""One source-pinned UI case on one disposable, identity-checked CI simulator."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import selectors
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time
import uuid

SEAL = "docs/results/2026/11-04/ui-acceptance-source-native-uuid.json"
WORKFLOW = ".github/workflows/ui-acceptance.yml"
CASE = "ConductorUITests/ConductorUITests/testPlanAndRunSurviveRelaunchWithExplicitCompletion"
SCOPE = {"scheme": "ConductorUIAcceptance", "testIdentifier": CASE, "expectedCases": 1,
         "xcodeVersion": "16.4", "xcodeBuild": "16F6", "sdk": "18.5",
         "runtime": "com.apple.CoreSimulator.SimRuntime.iOS-18-5",
         "deviceType": "com.apple.CoreSimulator.SimDeviceType.iPhone-16"}
ATTACHMENTS = {"paused-after-relaunch", "done-after-relaunch"}


class Refused(Exception):
    pass


def require(condition, code):
    if not condition:
        raise Refused(code)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def identifier(value):
    require(isinstance(value, str) and re.fullmatch(r"[0-9a-fA-F-]{36}", value), "device_uuid_invalid")
    return str(uuid.UUID(value)).upper()


class Acceptance:
    def __init__(self, commit):
        require(os.environ.get("GITHUB_ACTIONS") == "true" and os.environ.get("CI") == "true"
                and os.environ.get("GITHUB_REPOSITORY") == "alvarovillalbaa/conductor"
                and os.environ.get("GITHUB_REF") == "refs/heads/main", "public_ci_scope_required")
        self.repo = Path.cwd().resolve()
        runner_tmpdir = os.environ["TMPDIR"]
        require(os.path.isabs(runner_tmpdir) and Path(runner_tmpdir).is_dir(), "runner_tmpdir_invalid")
        self.parent = Path(os.environ["RUNNER_TEMP"]).resolve(strict=True)
        self.root = Path(tempfile.mkdtemp(prefix="conductor-ui-acceptance-", dir=self.parent))
        self.identity = self.root.stat()
        self.nonce = uuid.uuid4().hex
        (self.root / "owner").write_text(self.nonce, encoding="utf-8")
        self.commit, self.interrupted, self.active = commit, False, None
        self.deadline, self.cleanup_deadline = time.monotonic() + 900, None
        self.env = {"PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "HOME": os.environ["HOME"],
                    "TMPDIR": runner_tmpdir, "LANG": "en_US.UTF-8",
                    "DEVELOPER_DIR": "/Applications/Xcode_16.4.app/Contents/Developer"}
        self.commands, self.simulator, self.planned, self.seal_hash = [], None, None, None
        self.create_attempted = False
        self.report = {"schemaVersion": "conductor.ui-acceptance.v1", "sourceCommit": commit,
                       "scope": SCOPE, "status": "failed", "commands": self.commands,
                       "screenshots": {"pixelsRetained": False, "viewed": False, "metadata": []}}

    def owner(self):
        s = self.root.lstat()
        marker = self.root / "owner"
        require(self.root.parent == self.parent and stat.S_ISDIR(s.st_mode)
                and (s.st_dev, s.st_ino) == (self.identity.st_dev, self.identity.st_ino)
                and marker.is_file() and not marker.is_symlink()
                and marker.read_text(encoding="utf-8") == self.nonce, "scratch_identity_changed")

    def clean(self, data, limit=2000, head=False):
        text = data.decode("utf-8", errors="replace")
        text = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", text)
        text = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", "", text)
        text = text.replace(str(self.root), "[owned-scratch]").replace(str(self.repo), "[repository]")
        text = text.replace(self.env["HOME"], "[runner-home]")
        raw = text.encode("utf-8")
        return (raw[:limit] if head else raw[-limit:]).decode("utf-8", errors="replace")

    def run(self, label, args, seconds=30, cap=262144, cleanup=False, accept_failure=False):
        self.owner()
        require(cleanup or not self.interrupted, "interrupted_before_command")
        deadline = min(time.monotonic() + seconds, self.cleanup_deadline if cleanup else self.deadline)
        require(deadline > time.monotonic(), "command_deadline_exhausted")
        p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             env=self.env, start_new_session=True)
        self.active = p
        streams, counts, buffers = selectors.DefaultSelector(), [0, 0], [bytearray(), bytearray()]
        for index, stream in enumerate((p.stdout, p.stderr)):
            streams.register(stream, selectors.EVENT_READ, index)
        stopped, killed, reason, code = None, False, None, None
        try:
            while streams.get_map() or p.poll() is None:
                now = time.monotonic()
                if stopped is None and ((self.interrupted and not cleanup) or now >= deadline):
                    reason = "interrupted" if self.interrupted and not cleanup else "timeout"
                    stopped = now
                    try:
                        os.killpg(p.pid, signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                if stopped is not None and not killed and now - stopped >= 3:
                    killed = True
                    try:
                        os.killpg(p.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                if killed and now - stopped >= 6:
                    reason = "post_kill_drain_timeout"
                    break
                for key, _ in streams.select(0.1):
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        streams.unregister(key.fileobj)
                        key.fileobj.close()
                        continue
                    i = key.data
                    counts[i] += len(chunk)
                    limit = cap if i == 0 else min(cap, 1024 * 1024)
                    if counts[i] <= limit:
                        buffers[i].extend(chunk)
                    elif stopped is None:
                        reason, stopped = "output_limit", time.monotonic()
                        try:
                            os.killpg(p.pid, signal.SIGTERM)
                        except ProcessLookupError:
                            pass
            try:
                code = p.wait(timeout=3)
            except subprocess.TimeoutExpired:
                reason = "reap_timeout"
        finally:
            for key in list(streams.get_map().values()):
                streams.unregister(key.fileobj)
                key.fileobj.close()
            streams.close()
            if p.poll() is None:
                try:
                    os.killpg(p.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                try:
                    code = p.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    reason = "reap_timeout"
            self.active = None
        out, err = bytes(buffers[0]), bytes(buffers[1])
        row = {"label": label, "exitCode": code, "stop": reason,
               "stdout": {"observedBytes": counts[0], "capturedBytes": len(out), "sha256": sha(out)},
               "stderr": {"observedBytes": counts[1], "capturedBytes": len(err), "sha256": sha(err)}}
        if code or reason:
            row["failureTail"] = self.clean(err or out)
            row["firstFailureMessagesByStream"] = {}
            for name, data in (("stdout", out), ("stderr", err)):
                for line in data.splitlines():
                    if re.search(rb"\berror:|Test Case .*failed|Assertion Failure", line, re.I):
                        row["firstFailureMessagesByStream"][name] = self.clean(line, 1500, head=True)
                        break
            if label == "ui-test":
                try:
                    evidence = self.destination_diagnostic(err)
                    if evidence is not None:
                        row["destinationEvidence"] = evidence
                except Exception:
                    row["destinationEvidence"] = {"diagnosticOnly": True, "status": "unavailable"}
        row["reaped"] = p.poll() is not None
        self.commands.append(row)
        require(accept_failure or (code == 0 and reason is None), label + "_failed")
        return out, row

    def destination_diagnostic(self, data):
        lines = data.splitlines()
        head = next((i for i, line in enumerate(lines)
                     if b"xcodebuild: error:" in line.lower() and b"destination" in line.lower()), None)
        if head is None:
            return None
        tokens = [value.encode().lower() for value in
                  (self.simulator, self.planned.get("name") if self.planned else None) if value]
        matches, total, section = [], 0, "unclassified"
        for number, line in enumerate(lines, 1):
            lower = line.lower()
            if b"available destinations" in lower:
                section = "available"
            elif b"ineligible destinations" in lower:
                section = "ineligible"
            if any(token in lower for token in tokens):
                total += 1
                if len(matches) < 4:
                    matches.append({"sourceLine": number, "section": section,
                                    "text": self.clean(line, 384, head=True)})
        evidence = {"diagnosticOnly": True, "source": "ui-test.stderr", "sourceLines": len(lines),
                    "errorHead": {"sourceLine": head + 1, "text": self.clean(lines[head], 500, head=True)},
                    "ownedDestinationLines": matches, "ownedMatchingLineCount": total,
                    "omittedMatchingLines": total - len(matches)}
        # Leave room for the field wrapper within the three-KiB diagnostic cap.
        while len(json.dumps(evidence, separators=(",", ":")).encode()) > 3000 and matches:
            matches.pop()
            evidence["omittedMatchingLines"] = total - len(matches)
        if len(json.dumps(evidence, separators=(",", ":")).encode()) > 3000:
            return {"diagnosticOnly": True, "status": "unavailable", "reason": "destination_evidence_bound"}
        return evidence

    def json_command(self, label, args, cleanup=False, seconds=30):
        raw, _ = self.run(label, args, seconds=seconds, cap=1024 * 1024, cleanup=cleanup)
        return json.loads(raw.decode("utf-8")), raw

    def guard(self, label, cleanup=False):
        require(self.run(label + "-head", ["git", "rev-parse", "HEAD"], cleanup=cleanup)[0].decode().strip() == self.commit,
                "source_head_changed")
        seal_path = self.repo / SEAL
        require(seal_path.is_file() and not seal_path.is_symlink() and seal_path.stat().st_size <= 1024 * 1024,
                "seal_file_invalid")
        raw = seal_path.read_bytes()
        pinned = self.run(label + "-seal", ["git", "show", "HEAD:" + SEAL], cap=1024 * 1024, cleanup=cleanup)[0]
        require(raw == pinned and (self.seal_hash is None or self.seal_hash == sha(raw)), "seal_changed")
        self.seal_hash = sha(raw)
        m = json.loads(raw)
        require(m.get("schemaVersion") == "conductor.ui-acceptance-source.v1"
                and m.get("excludedPrefixes") == ["docs/results/"] and m.get("scope") == SCOPE,
                "seal_scope_invalid")
        tracked = self.run(label + "-index", ["git", "ls-files", "--stage", "-z"], cap=1024 * 1024, cleanup=cleanup)[0]
        index = {}
        for record in tracked.decode("utf-8").split("\0"):
            if not record:
                continue
            header, path = record.split("\t", 1)
            mode, blob, stage = header.split(" ")
            require(stage == "0", "unmerged_index")
            if not path.startswith("docs/results/"):
                index[path] = (mode, blob)
        head = self.run(label + "-tree", ["git", "ls-tree", "-r", "-z", "HEAD"], cap=1024 * 1024, cleanup=cleanup)[0]
        tree = {}
        for entry in head.decode("utf-8").split("\0"):
            if entry:
                header, path = entry.split("\t", 1)
                mode, kind, blob = header.split(" ")
                if not path.startswith("docs/results/"):
                    require(kind == "blob", "source_tree_kind_invalid")
                    tree[path] = (mode, blob)
        require(index == tree, "source_index_or_head_changed")
        files = m.get("files")
        require(isinstance(files, list) and len(files) == m.get("fileCount")
                and WORKFLOW not in index and len({x["path"] for x in files}) == len(files)
                and set(index) == {x["path"] for x in files}, "source_path_set_changed")
        total = 0
        for f in files:
            path = f["path"]
            require(isinstance(path, str) and not path.startswith("/") and "\\" not in path
                    and all(x not in ("", ".", "..") for x in path.split("/"))
                    and str(PurePosixPath(path)) == path, "source_path_invalid")
            p = self.repo / path
            s = p.lstat()
            if stat.S_ISLNK(s.st_mode):
                data, mode = os.fsencode(os.readlink(p)), "120000"
            else:
                require(stat.S_ISREG(s.st_mode) and s.st_size <= 8 * 1024 * 1024, "source_kind_or_size")
                data, mode = p.read_bytes(), "100755" if s.st_mode & 0o111 else "100644"
            blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
            require(index[path] == (f["mode"], f["gitBlob"]) and mode == f["mode"]
                    and blob == f["gitBlob"] and len(data) == f["bytes"] and sha(data) == f["sha256"],
                    "source_fingerprint_changed")
            total += len(data)
        require(total == m.get("totalBytes"), "source_total_changed")
        self.report[label] = {"passed": True, "files": len(files), "totalBytes": total, "sealSha256": self.seal_hash}

    def devices(self, cleanup=False):
        value, _ = self.json_command("cleanup-devices" if cleanup else "devices",
                                     ["xcrun", "simctl", "list", "devices", "-j"], cleanup=cleanup, seconds=90)
        require(isinstance(value.get("devices"), dict), "devices_schema_invalid")
        return [(runtime, row) for runtime, rows in value["devices"].items() for row in rows]

    def owned_device(self, cleanup=False):
        all_rows = self.devices(cleanup)
        named = [(runtime, row) for runtime, row in all_rows if row.get("name") == self.planned["name"]]
        rows = named if self.simulator is None else [(runtime, row) for runtime, row in all_rows
                                                     if identifier(row["udid"]) == self.simulator]
        require(len(rows) <= 1, "owned_device_ambiguous")
        if not rows:
            require(not named, "owned_device_uuid_substituted")
            return None
        runtime, row = rows[0]
        found = identifier(row["udid"])
        require(row.get("name") == self.planned["name"] and runtime == SCOPE["runtime"]
                and row.get("deviceTypeIdentifier") == SCOPE["deviceType"]
                and (self.simulator is None or found == self.simulator), "owned_device_identity_changed")
        return {"uuid": found, "name": row["name"], "runtime": runtime,
                "deviceType": row["deviceTypeIdentifier"], "state": row.get("state")}

    def prepare(self):
        self.guard("beforeSourceGuard")
        version = self.run("xcode", ["xcodebuild", "-version"])[0].decode().strip()
        require(version == "Xcode 16.4\nBuild version 16F6", "xcode_pin_unavailable")
        sdk = self.run("sdk", ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"])[0].decode().strip()
        require(sdk == "18.5", "sdk_pin_unavailable")
        runtimes, _ = self.json_command("runtimes", ["xcrun", "simctl", "list", "runtimes", "-j"], seconds=90)
        selected = [r for r in runtimes.get("runtimes", []) if r.get("identifier") == SCOPE["runtime"]]
        require(len(selected) == 1 and selected[0].get("isAvailable") is True
                and selected[0].get("version") == "18.5", "runtime_pin_unavailable")
        supported = selected[0].get("supportedDeviceTypes")
        require(isinstance(supported, list) and any(r.get("identifier") == SCOPE["deviceType"] for r in supported),
                "runtime_device_intersection_unavailable")
        types, _ = self.json_command("device-types", ["xcrun", "simctl", "list", "devicetypes", "-j"])
        require(any(r.get("identifier") == SCOPE["deviceType"] and r.get("name") == "iPhone 16"
                    for r in types.get("devicetypes", [])), "device_type_unavailable")
        self.report["toolchain"] = {"xcode": version, "sdk": sdk, "runtime": SCOPE["runtime"], "deviceType": SCOPE["deviceType"]}
        self.planned = {"name": "conductor-ui-" + self.nonce, "runtime": SCOPE["runtime"], "deviceType": SCOPE["deviceType"]}
        require(not any(r.get("name") == self.planned["name"] for _, r in self.devices()), "device_name_already_exists")
        self.write_ledger("planned-device.json", self.planned)
        self.create_attempted = True
        raw, _ = self.run("create", ["xcrun", "simctl", "create", self.planned["name"], SCOPE["deviceType"], SCOPE["runtime"]])
        self.simulator = identifier(raw.decode().strip())
        self.write_ledger("owned-device.json", {**self.planned, "uuid": self.simulator})
        self.report["createdSimulator"] = {**self.planned, "uuid": self.simulator}
        self.verify_ledgers()
        device = self.owned_device()
        require(device is not None and device["state"] == "Shutdown", "fresh_device_not_shutdown")
        self.run("boot", ["xcrun", "simctl", "boot", self.simulator])
        self.run("boot-status", ["xcrun", "simctl", "bootstatus", self.simulator, "-b"], seconds=120)
        require(self.owned_device()["state"] == "Booted", "owned_device_not_booted")

    def write_ledger(self, name, value):
        self.owner()
        with (self.root / name).open("x", encoding="utf-8") as file:
            file.write(json.dumps(value, sort_keys=True))
            file.flush()
            os.fsync(file.fileno())

    def verify_ledgers(self):
        if self.planned is not None:
            expected = {"planned-device.json": self.planned}
            if self.simulator is not None:
                expected["owned-device.json"] = {**self.planned, "uuid": self.simulator}
            for name, value in expected.items():
                p = self.root / name
                require(p.is_file() and not p.is_symlink() and p.stat().st_size < 4096
                        and json.loads(p.read_text()) == value, "device_ledger_changed")

    def test(self):
        result = self.root / "ui.xcresult"
        _, outcome = self.run("ui-test", ["xcodebuild", "-project", "Conductor.xcodeproj", "-scheme", SCOPE["scheme"],
            "-configuration", "Debug", "-sdk", "iphonesimulator", "-destination", "id=" + self.simulator,
            "-destination-timeout", "60", "-derivedDataPath", str(self.root / "DerivedData"),
            "-resultBundlePath", str(result), "-resultBundleVersion", "3", "-only-testing:" + CASE,
            "-parallel-testing-enabled", "NO", "-enableCodeCoverage", "NO",
            "-test-timeouts-enabled", "YES",
            "-disableAutomaticPackageResolution", "-skipPackageUpdates", "CODE_SIGNING_ALLOWED=NO", "test"],
            seconds=600, cap=4 * 1024 * 1024, accept_failure=True)
        summary, summary_raw = self.json_command("result-summary", ["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(result)])
        failures = summary.get("testFailures")
        self.report["xcresult"] = {"summarySha256": sha(summary_raw),
            "summary": {k: summary.get(k) for k in ("totalTestCount", "passedTests", "failedTests", "skippedTests", "testResults")}}
        self.report["xcresult"]["testFailures"] = [
            {key: self.clean(f[key].encode(), 2000 if key == "message" else 256, head=True)
             for key in ("testIdentifier", "testName", "message") if isinstance(f.get(key), str)}
            for f in failures[:4] if isinstance(f, dict)] if isinstance(failures, list) else None
        self.report["xcresult"]["testFailureCount"] = len(failures) if isinstance(failures, list) else None
        tests, tests_raw = self.json_command("result-tests", ["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", str(result)])
        self.report["xcresult"]["testsSha256"] = sha(tests_raw)
        nodes, cases = [(n, []) for n in tests.get("testNodes", [])], []
        while nodes:
            node, parents = nodes.pop()
            if node.get("nodeType") == "Test Case":
                cases.append((node, parents))
            nodes.extend((child, parents + [node.get("name")]) for child in node.get("children", []))
        self.report["xcresult"]["cases"] = [{"name": n.get("name"), "parents": p, "status": n.get("result"),
                                            "identifier": n.get("nodeIdentifier")} for n, p in cases]
        require(len(cases) == 1, "xcresult_case_count")
        node, parents = cases[0]
        require(node.get("name") == CASE.split("/")[-1] + "()"
                and parents.count("ConductorUITests") >= 2 and node.get("result") == "Passed", "xcresult_case_identity_or_status")
        for key, expected in (("totalTestCount", 1), ("passedTests", 1), ("failedTests", 0), ("skippedTests", 0)):
            require(type(summary.get(key)) is int and summary[key] == expected, "xcresult_totals")
        require(summary.get("testResults") == "Passed" and not summary.get("testFailures"), "xcresult_not_passed")
        require(outcome["exitCode"] == 0 and outcome["stop"] is None, "ui_test_exit_failed")
        # Attachment metadata is optional evidence, never an acceptance substitute.
        try:
            activities, raw = self.json_command("result-activities", ["xcrun", "xcresulttool", "get", "test-results", "activities", "--path", str(result), "--test-id", node["nodeIdentifier"]])
            pending, found = [activities], []
            while pending:
                item = pending.pop()
                if isinstance(item, dict):
                    if item.get("name") in ATTACHMENTS:
                        found.append({k: self.clean(str(item[k]).encode(), 256, head=True)
                                      for k in ("name", "uniformTypeIdentifier", "payloadRef", "timestamp")
                                      if isinstance(item.get(k), (str, int, float))})
                    pending.extend(item.values())
                elif isinstance(item, list):
                    pending.extend(item)
            self.report["screenshots"].update({"activitiesSha256": sha(raw), "metadata": found[:2], "matchingRecords": len(found)})
        except (Refused, ValueError, KeyError, TypeError):
            self.report["screenshots"]["metadataStatus"] = "unavailable"

    def cleanup(self):
        if self.cleanup_deadline is None:
            self.cleanup_deadline = time.monotonic() + 180
        errors = []
        try:
            self.verify_ledgers()
            if self.planned is not None and self.create_attempted:
                device = self.owned_device(cleanup=True)
                if device is not None:
                    self.simulator = device["uuid"]
                    self.report["ownedSimulator"] = device
                    if device["state"] != "Shutdown":
                        _, shutdown = self.run("shutdown", ["xcrun", "simctl", "shutdown", self.simulator], cleanup=True, accept_failure=True)
                        if shutdown["exitCode"] or shutdown["stop"]:
                            errors.append("owned_simulator_shutdown_failed")
                    require(self.owned_device(cleanup=True) is not None, "owned_device_lost_before_delete")
                    self.run("delete", ["xcrun", "simctl", "delete", self.simulator], cleanup=True)
                    require(self.owned_device(cleanup=True) is None, "owned_device_still_present")
            self.report["simulatorCleanup"] = "passed"
        except Exception as error:
            errors.append(type(error).__name__ + ":" + str(error))
            self.report["simulatorCleanup"] = "failed"
        try:
            self.owner()
            shutil.rmtree(self.root)
            self.report["scratchCleanup"] = "passed"
        except Exception:
            errors.append("scratch_cleanup_refused")
            self.report["scratchCleanup"] = "failed"
        return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-commit", required=True)
    commit = parser.parse_args().source_commit
    require(re.fullmatch(r"[a-f0-9]{40}", commit) is not None, "source_commit_invalid")
    check = Acceptance(commit)
    handlers = {}
    for kind in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        handlers[kind] = signal.signal(kind, lambda _sig, _frame: setattr(check, "interrupted", True))
    errors = []
    try:
        check.prepare()
        check.test()
    except Exception as error:
        errors.append(type(error).__name__ + ":" + str(error))
    finally:
        check.cleanup_deadline = time.monotonic() + 180
        try:
            check.guard("afterSourceGuard", cleanup=True)
        except Exception as error:
            errors.append("after_source_guard:" + type(error).__name__ + ":" + str(error))
        errors.extend(check.cleanup())
        for kind, handler in handlers.items():
            signal.signal(kind, handler)
    check.report["errors"] = [check.clean(e.encode()) for e in errors]
    processes_reaped = all(row["reaped"] for row in check.commands)
    check.report["processesReaped"] = processes_reaped
    if not processes_reaped:
        errors.append("command_process_unreaped")
        check.report["errors"].append("command_process_unreaped")
        if check.report.get("scratchCleanup") == "passed":
            check.report["scratchCleanup"] = "removed_with_unreaped_command"
    check.report["interrupted"] = check.interrupted
    check.report["status"] = "passed" if not errors and not check.interrupted else "failed"
    output = json.dumps(check.report, separators=(",", ":"))
    if len(output.encode()) > 65536:
        output = json.dumps({"schemaVersion": "conductor.ui-acceptance.v1", "status": "failed", "reason": "report_cap_exceeded"})
        errors.append("report_cap_exceeded")
    print(output, flush=True)
    return 1 if errors or check.interrupted else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        print(json.dumps({"schemaVersion": "conductor.ui-acceptance.v1", "status": "failed", "reason": "controller_setup_failed"}))
        sys.exit(1)
