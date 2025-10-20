import { describe, it, expect } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;

describe("Medical Supply Tracking", () => {
  it("registers supply and distributes to verified identity", () => {
    // Register identity for recipient (address1)
    let res = simnet.callPublicFn(
      "RefugeeID",
      "register-identity",
      [
        Cl.stringAscii("Alice Patient"),
        Cl.stringAscii("1991-02-02"),
        Cl.stringAscii("Homs"),
        Cl.stringAscii("Syrian"),
        Cl.stringAscii("x".repeat(64)),
      ],
      address1
    );
    expect(res.result).toBeOk(Cl.principal(address1));

    // Owner registers address2 as authorized verifier
    res = simnet.callPublicFn(
      "RefugeeID",
      "register-verifier",
      [
        Cl.principal(address2),
        Cl.stringAscii("Health Verifier"),
        Cl.stringAscii("Medical Org"),
      ],
      deployer
    );
    expect(res.result).toBeOk(Cl.principal(address2));

    // Verifier verifies recipient identity
    res = simnet.callPublicFn(
      "RefugeeID",
      "verify-identity",
      [Cl.principal(address1), Cl.uint(3)],
      address2
    );
    expect(res.result).toBeOk(Cl.principal(address1));

    // Verifier registers medical supply
    res = simnet.callPublicFn(
      "RefugeeID",
      "register-medical-supply",
      [
        Cl.stringAscii("VACCINE-A"),
        Cl.stringAscii("Vaccine A"),
        Cl.stringAscii("Initial stock"),
        Cl.stringAscii("dose"),
        Cl.uint(100),
      ],
      address2
    );
    expect(res.result).toBeOk(Cl.stringAscii("VACCINE-A"));

    // Distribute 3 doses to recipient
    res = simnet.callPublicFn(
      "RefugeeID",
      "distribute-medical-supply",
      [
        Cl.principal(address1),
        Cl.stringAscii("VACCINE-A"),
        Cl.stringAscii("DIST-001"),
        Cl.uint(3),
        Cl.stringAscii("Clinic One"),
      ],
      address2
    );
    expect(res.result).toBeOk(Cl.stringAscii("DIST-001"));

    // Check availability decreased to 97
    const supplyInfo = simnet.callReadOnlyFn(
      "RefugeeID",
      "get-medical-supply",
      [Cl.stringAscii("VACCINE-A")],
      address1
    ).result;
    expect(supplyInfo).toContain("available-quantity");
    expect(supplyInfo).toContain("97");
  });

  it("prevents duplicate supply, out-of-stock and duplicate distribution", () => {
    // Setup: verifier and verified recipient
    simnet.callPublicFn(
      "RefugeeID",
      "register-verifier",
      [
        Cl.principal(address2),
        Cl.stringAscii("Verifier"),
        Cl.stringAscii("Org"),
      ],
      deployer
    );
    simnet.callPublicFn(
      "RefugeeID",
      "register-identity",
      [
        Cl.stringAscii("Bob Patient"),
        Cl.stringAscii("1990-01-01"),
        Cl.stringAscii("Aleppo"),
        Cl.stringAscii("Syrian"),
        Cl.stringAscii("y".repeat(64)),
      ],
      address1
    );
    simnet.callPublicFn(
      "RefugeeID",
      "verify-identity",
      [Cl.principal(address1), Cl.uint(2)],
      address2
    );

    // Register small stock
    simnet.callPublicFn(
      "RefugeeID",
      "register-medical-supply",
      [
        Cl.stringAscii("KIT-001"),
        Cl.stringAscii("First Aid Kit"),
        Cl.stringAscii("Contains basic supplies"),
        Cl.stringAscii("kit"),
        Cl.uint(2),
      ],
      address2
    );

    // Duplicate registration should error u113
    let r = simnet.callPublicFn(
      "RefugeeID",
      "register-medical-supply",
      [
        Cl.stringAscii("KIT-001"),
        Cl.stringAscii("First Aid Kit"),
        Cl.stringAscii("Dup"),
        Cl.stringAscii("kit"),
        Cl.uint(1),
      ],
      address2
    );
    expect(r.result).toBeErr(Cl.uint(113));

    // Out-of-stock attempt should error u116
    r = simnet.callPublicFn(
      "RefugeeID",
      "distribute-medical-supply",
      [
        Cl.principal(address1),
        Cl.stringAscii("KIT-001"),
        Cl.stringAscii("DIST-002"),
        Cl.uint(5),
        Cl.stringAscii("Camp A"),
      ],
      address2
    );
    expect(r.result).toBeErr(Cl.uint(116));

    // Valid distribution then duplicate distribution-id should error u117
    simnet.callPublicFn(
      "RefugeeID",
      "distribute-medical-supply",
      [
        Cl.principal(address1),
        Cl.stringAscii("KIT-001"),
        Cl.stringAscii("DIST-003"),
        Cl.uint(1),
        Cl.stringAscii("Camp A"),
      ],
      address2
    );

    r = simnet.callPublicFn(
      "RefugeeID",
      "distribute-medical-supply",
      [
        Cl.principal(address1),
        Cl.stringAscii("KIT-001"),
        Cl.stringAscii("DIST-003"),
        Cl.uint(1),
        Cl.stringAscii("Camp A"),
      ],
      address2
    );
    expect(r.result).toBeErr(Cl.uint(117));
  });
});
